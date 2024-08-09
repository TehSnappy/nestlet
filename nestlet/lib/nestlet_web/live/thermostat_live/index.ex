defmodule NestletWeb.ThermostatLive.Index do
  use NestletWeb, :live_view

  alias Nestlet.Nest
  alias Nestlet.Nest.State, as: NestState

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Nest.subscribe()

    {:ok, assign_nest_state(socket, Nest.get_state())}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :page_title, "All Thermostats")}
  end

  @impl true
  def handle_info({:state_updated, %NestState{} = nest_state}, socket) do
    {:noreply, assign_nest_state(socket, nest_state)}
  end

  @impl true
  def handle_event("nest-select", %{"therm-id" => device_id}, socket) do
    new_state = Nest.set_current_device(device_id)

    {:noreply, assign_nest_state(socket, new_state)}
  end

  def error_messages(%{project_id: nil}), do: "No project id set, please check your configuration"
  def error_messages(%{is_rate_limited?: true}), do: "Rate Limited!"
  def error_messages(%{device_list: [], last_update: nil}), do: "Initializing system"
  def error_messages(%{device_list: []}), do: "No thermostats detected"
  def error_messages(_), do: []

  def has_error_messages?(state), do: error_messages(state) != []

  def needs_auth_token?(%NestState{auth_code: nil, refresh_token: nil, last_update: last_update}),
    do: not is_nil(last_update)

  def needs_auth_token?(_), do: false

  defp assign_nest_state(socket, nest_state) do
    socket
    |> assign(nest_state: nest_state)
    |> assign(devices: nest_state.device_list)
  end
end
