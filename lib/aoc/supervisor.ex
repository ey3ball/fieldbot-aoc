defmodule Aoc do
  use Application

  def start(_type, _args) do
    Aoc.Supervisor.start_link(name: Aoc.Supervisor)
  end
end

defmodule Aoc.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      %{
        id: :mongo,
        start: {
          Mongo, :start_link,
          [[name: :mongo, url: Aoc.Cfg.mongod()]]
        }
      },
      Aoc.Scheduler,
      Aoc.Server,
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
