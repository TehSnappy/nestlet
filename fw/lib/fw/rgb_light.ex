defmodule Fw.RgbLight do
  defstruct red_gpio_pin: nil,
            green_gpio_pin: nil,
            blue_gpio_pin: nil

  use GenServer

  alias Nestlet.Nest
  alias Nestlet.Nest.State
  alias Nestlet.Nest.Thermostat

  require Logger

  @off {255, 253, 253}
  @red {0, 255, 255}
  @blue {255, 255, 0}
  @orange {95, 95, 255}
  @yellow {150, 80, 225}
  @lime {190, 80, 225}

  @doc false
  def start_link([]) do
    GenServer.start_link(__MODULE__, initialize_data(), name: __MODULE__)
  end

  @doc """
    Sets the current value of the UvLevel within the range of 0 to 255.
  """

  def set_color(color) do
    {:ok, GenServer.call(__MODULE__, {:set_color, color})}
  end

  @impl true
  def init(%__MODULE__{} = state) do
    Nest.subscribe()
    {:ok, initialize_hardware(state)}
  end

  @impl true
  def handle_info({:state_updated, nest_state}, state) do
    state =
      nest_state
      |> color_for_current_device()
      |> do_set_color(state)

    {:noreply, state}
  end

  @impl true
  def handle_call({:set_color, color}, _from, state) do
    new_state = do_set_color(color, state)

    {:reply, new_state, new_state}
  end

  defp color_for_current_device(%State{
         current_device_id: current_device_id,
         device_list: device_list
       }) do
    case State.get_device(device_list, current_device_id) do
      nil ->
        @lime

      %Thermostat{connectivity: "OFFLINE"} ->
        @red

      %Thermostat{status: "OFF"} ->
        @off

      %Thermostat{status: "HEATING"} ->
        @orange

      %Thermostat{status: "COOLING"} ->
        @blue

      %Thermostat{status: other_status} ->
        Logger.warning("unknown status #{inspect(other_status)}")
        @yellow
    end
  end

  defp do_set_color(nil, state), do: state

  defp do_set_color(color, state) do
    set_gpio_pwm(color, state)

    state
  end

  defp set_gpio_pwm({red, green, blue} = colors, %__MODULE__{
         red_gpio_pin: red_gpio_pin,
         green_gpio_pin: green_gpio_pin,
         blue_gpio_pin: blue_gpio_pin
       }) do
    Logger.info("set button colors: #{inspect(colors)}")

    Pigpiox.Pwm.gpio_pwm(red_gpio_pin, red)
    Pigpiox.Pwm.gpio_pwm(green_gpio_pin, green)
    Pigpiox.Pwm.gpio_pwm(blue_gpio_pin, blue)
  end

  defp initialize_data do
    prefs = Application.get_env(:Fw, __MODULE__, [])

    %__MODULE__{
      red_gpio_pin: Keyword.get(prefs, :red_gpio_pin, 17),
      green_gpio_pin: Keyword.get(prefs, :green_gpio_pin, 27),
      blue_gpio_pin: Keyword.get(prefs, :blue_gpio_pin, 22)
    }
  end

  defp initialize_hardware(
         %__MODULE__{
           red_gpio_pin: red_gpio_pin,
           green_gpio_pin: green_gpio_pin,
           blue_gpio_pin: blue_gpio_pin
         } = state
       ) do
    Pigpiox.GPIO.set_mode(red_gpio_pin, :output)
    Pigpiox.Pwm.set_pwm_frequency(red_gpio_pin, 1000)
    Pigpiox.GPIO.set_mode(green_gpio_pin, :output)
    Pigpiox.Pwm.set_pwm_frequency(green_gpio_pin, 1000)
    Pigpiox.GPIO.set_mode(blue_gpio_pin, :output)
    Pigpiox.Pwm.set_pwm_frequency(blue_gpio_pin, 1000)
    state
  end
end
