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

  def get_state(),
    do: GenServer.call(__MODULE__, :get_state)

  def set_state(field_list),
    do: GenServer.call(__MODULE__, {:set_state, field_list})

  def handle_call(:get_state, _from, state),
    do: {:reply, state, state}

  def handle_call({:set_state, fields_list}, _from, state) do
    new_state =
      state
      |> struct(fields_list)
      |> struct(last_update: DateTime.utc_now())
      |> maybe_persist_data(state)
      |> publish()

    {:reply, new_state, new_state}
  end

  defp maybe_persist_data(new_state, state) do
    maybe_persist_field(new_state, state, :access_token)
    maybe_persist_field(new_state, state, :refresh_token)
    maybe_persist_field(new_state, state, :current_device_id)

    new_state
  end

  defp publish(state) do
    Phoenix.PubSub.broadcast(Nestlet.PubSub, "devices", {:state_updated, state})
    state
  end

  def get_device(_, nil), do: nil

  def get_device(%State{device_list: device_list}, device_id) do
    Enum.find(device_list, &(&1.display_id == device_id))
  end

  def get_device(device_list, device_id) do
    Enum.find(device_list, &(&1.display_id == device_id))
  end

  defp maybe_persist_field(new_state, old_state, field) do
    new_value = Map.get(new_state, field)

    if new_value == Map.get(old_state, field) do
      :ok
    else
      CubDB.put(database_name(), field, new_value)
    end
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
end
