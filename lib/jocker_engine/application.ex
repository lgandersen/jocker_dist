defmodule Jocker.Engine.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  require Jocker.Engine.Config

  use Application

  def start_link() do
    start(nil, nil)
  end

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: JockTMod.Worker.start_link(arg)
      {Jocker.Engine.MetaData, [file: Jocker.Engine.Config.metadata_db()]},
      Jocker.Engine.Layer,
      {Jocker.Engine.Network, [{"10.13.37.1", "10.13.37.255"}, "jocker0"]},
      Jocker.Engine.ContainerPool,
      Jocker.Engine.APIServer
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Jocker.Engine.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
