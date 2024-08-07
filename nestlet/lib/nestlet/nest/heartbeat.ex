defmodule Nestlet.Nest.Heartbeat do
  defstruct beat_interval: 10_000

  use GenServer
  require Logger

  alias Nestlet.Nest.State
  alias Nestlet.Nest.Service

  @ten_minutes 600_000
  @initial_delay 1000

  def start_link(_vars) do
    GenServer.start_link(__MODULE__, initial_data(), name: __MODULE__)
  end

  def init(data) do
    Process.send_after(self(), :check_devices, @initial_delay, [])
    {:ok, data}
  end

  def handle_info(:check_devices, state) do
    State.get_state()
    |> Service.fetch_and_update_nest_state()
    |> reschedule_device_check(state)

    {:noreply, state}
  end

  defp reschedule_device_check(%State{is_rate_limited?: true}, _state),
    do: Process.send_after(self(), :check_devices, @ten_minutes, [])

  defp reschedule_device_check(_results, %__MODULE__{beat_interval: beat_interval}),
    do: Process.send_after(self(), :check_devices, beat_interval, [])

  defp initial_data() do
    prefs = Application.get_env(:nestlet, __MODULE__)

    %__MODULE__{
      beat_interval: Keyword.get(prefs, :beat_interval, 10_000)
    }
  end
end
