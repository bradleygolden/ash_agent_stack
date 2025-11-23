defmodule AshAgent.Tools.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the ToolRegistry
      AshAgent.Tools.ToolRegistry
    ]

    opts = [strategy: :one_for_one, name: AshAgent.Tools.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
