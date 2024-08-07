defmodule Fw.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        # Children for all targets
        # Starts a worker by calling: Fw.Worker.start_link(arg)
        # {Fw.Worker, arg},
      ] ++ children(Nerves.Runtime.mix_target())

    if target() != :host do
      VintageNetWizard.run_if_unconfigured()
    end

    opts = [strategy: :one_for_one, name: Fw.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  defp children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: Fw.Worker.start_link(arg)
      # {Fw.Worker, arg},
    ]
  end

  defp children(_target) do
    [
      Fw.RgbLight,
      Fw.PushButton
    ]
  end

  def target() do
    Application.get_env(:fw, :target)
  end
end
