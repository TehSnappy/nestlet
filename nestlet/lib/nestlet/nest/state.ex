defmodule Nestlet.Nest.State do
  defstruct auth_code: nil,
            project_id: nil,
            last_update: nil,
            access_token: nil,
            refresh_token: nil,
            current_device_id: nil,
            is_bumped?: false,
            device_list: [],
            is_rate_limited?: false

  use GenServer

  alias Nestlet.Nest.State

  def start_link(_vars) do
    GenServer.start_link(__MODULE__, initial_data(), name: __MODULE__)
  end

  def init(data), do: {:ok, data}

  def database_name, do: :nest_db

  def reset_authorization(),
    do:
      set_state(
        auth_code: nil,
        access_token: nil,
        is_bumped?: false,
        is_rate_limited?: false
      )

  def set_state(field_list),
    do: GenServer.call(__MODULE__, {:set_state, field_list})

  def get_state(),
    do: GenServer.call(__MODULE__, :get_state)

  def handle_call(:get_state, _from, state),
    do: {:reply, state, state}

  def handle_call({:set_state, fields_list}, _from, state) do
    new_state =
      state
      |> struct(fields_list)
      |> struct(last_update: DateTime.utc_now())
      |> flush_if_new(state)
      |> publish()

    {:reply, new_state, new_state}
  end

  defp initial_data do
    project_id =
      Application.get_env(:nestlet, State)
      |> Enum.into(%{})
      |> Map.get(:project_id)

    %State{
      access_token: CubDB.get(database_name(), :access_token),
      refresh_token: CubDB.get(database_name(), :refresh_token),
      current_device_id: CubDB.get(database_name(), :current_device_id),
      project_id: project_id
    }
  end

  defp flush_if_new(new_state, state) do
    flush_access_code(new_state, state)
    flush_refresh_code(new_state, state)
    flush_current_device(new_state, state)

    new_state
  end

  defp flush_access_code(%{access_token: access_token}, %{access_token: access_token}),
    do: :no_change

  defp flush_access_code(%{access_token: access_token}, _),
    do: CubDB.put(database_name(), :access_token, access_token)

  defp flush_refresh_code(%{refresh_token: refresh_token}, %{refresh_token: refresh_token}),
    do: :no_change

  defp flush_refresh_code(%{refresh_token: refresh_token}, _),
    do: CubDB.put(database_name(), :refresh_token, refresh_token)

  defp flush_current_device(%{current_device_id: current_device_id}, %{
         current_device_id: current_device_id
       }),
       do: :no_change

  defp flush_current_device(%{current_device_id: current_device_id}, _),
    do: CubDB.put(database_name(), :current_device_id, current_device_id)

  defp publish(state) do
    Phoenix.PubSub.broadcast(Nestlet.PubSub, "devices", {:state_updated, state})
    state
  end
end
