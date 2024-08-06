defmodule Nestlet.Nest do
  @moduledoc """
  The Nest context.
  """

  alias Nestlet.Nest.State

  def set_current_device(device_id),
    do: State.set_state(current_device_id: device_id)

  def get_state(),
    do: State.get_state()

  def subscribe(),
    do: Phoenix.PubSub.subscribe(Nestlet.PubSub, "devices")
end
