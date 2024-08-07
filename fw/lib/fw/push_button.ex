defmodule Fw.PushButton do
  defstruct btn_gpio_pin: nil,
            last_mousedown: nil

  use GenServer

  require Logger

  alias Nestlet.Nest.Thermostat
  alias Nestlet.Nest.State
  alias Nestlet.Nest.Service

  @ten_minutes 1000 * 60 * 10

  @doc false
  def start_link([]) do
    GenServer.start_link(__MODULE__, initialize_data(), name: __MODULE__)
  end

  @impl true
  def init(%__MODULE__{} = state) do
    {:ok, initialize_hardware(state)}
  end

  @impl true
  def handle_info({:gpio_leveL_change, _, 1}, %{last_mousedown: nil} = state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:gpio_leveL_change, _, 1}, %{last_mousedown: last_mousedown} = state) do
    Logger.info("handle mouse up")
    elapsed = :os.system_time(:millisecond) - last_mousedown

    cond do
      elapsed > 50000 ->
        :ok

      elapsed > 5000 ->
        VintageNetWizard.run_wizard()

      true ->
        Logger.info("bumping device")
        handle_button_click()
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:unbump_temp, device_id, target_temp}, state) do
    Logger.info("unbumping temp")

    nest_state = State.get_state()
    device = State.get_device(nest_state, device_id)

    Service.set_thermostat_target_temp(nest_state, device, target_temp)
    State.set_state(bumped_temp: nil)

    {:noreply, state}
  end

  @impl true
  def handle_info({:gpio_leveL_change, _, 0}, state) do
    {:noreply, %{state | last_mousedown: :os.system_time(:millisecond)}}
  end

  defp initialize_data do
    prefs = Application.get_env(:Fw, __MODULE__, [])

    %__MODULE__{
      btn_gpio_pin: Keyword.get(prefs, :btn_gpio_pin, 24)
    }
  end

  defp handle_button_click do
    %{is_bumped?: is_bumped?, current_device_id: current_device_id} =
      nest_state = State.get_state()

    if not is_bumped? do
      %{
        temperature_set_point: temperature_set_point
      } = device = State.get_device(nest_state, current_device_id)

      new_temp = bumped_temp(device)

      Service.set_thermostat_target_temp(nest_state, device, new_temp)
      State.set_state(is_bumped?: true)

      Process.send_after(
        self(),
        {:unbump_temp, current_device_id, temperature_set_point},
        @ten_minutes
      )
    end
  end

  defp bumped_temp(%Thermostat{current_mode: "COOL", status: "OFF", ambient_temp: ambient_temp}),
    do: ambient_temp - 2

  defp bumped_temp(%Thermostat{current_mode: "COOL", ambient_temp: ambient_temp}),
    do: ambient_temp + 2

  defp bumped_temp(%Thermostat{current_mode: "HEAT", status: "OFF", ambient_temp: ambient_temp}),
    do: ambient_temp + 2

  defp bumped_temp(%Thermostat{current_mode: "HEAT", ambient_temp: ambient_temp}),
    do: ambient_temp - 2

  defp bumped_temp(%Thermostat{temperature_set_point: temperature_set_point}),
    do: temperature_set_point

  defp initialize_hardware(%__MODULE__{btn_gpio_pin: btn_gpio_pin} = state) do
    Pigpiox.GPIO.set_mode(btn_gpio_pin, :input)
    Pigpiox.GPIO.write(btn_gpio_pin, 1)
    Pigpiox.GPIO.watch(btn_gpio_pin)
    state
  end
end
