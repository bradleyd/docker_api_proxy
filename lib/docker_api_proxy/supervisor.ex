defmodule DockerApiProxy.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [
      worker(DockerApiProxy.Registry, [:registry])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
