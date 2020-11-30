defmodule Aoc.Server do
  use Supervisor

  defmodule State do
    defstruct host: "ircd",
              port: 5999,
              nick: Application.fetch_env!(:aoc, Aoc.Server) |> Keyword.get(:username),
              pass: Application.fetch_env!(:aoc, Aoc.Server) |> Keyword.get(:password),
              user: "fieldbot",
              name: "fieldbot",
              client: nil,
              handlers: []
    end

  @moduledoc """
  """
  def start_link(_) do
    env = Application.fetch_env!(:aoc, Aoc.Server)
    GenServer.start_link(__MODULE__, %State{}, [])
  end

  def init(state) do
    {:ok, client} = ExIRC.start_link!()

    children = [
      %{
        id: Aoc.IrcBot.Network,
        start: {Aoc.IrcBot.Network, :start_link, [client, state]}
      },
      %{
        id: Aoc.IrcBot.Aoc,
        start: {Aoc.IrcBot.Aoc, :start_link, [client]}
      }
    ]

    IO.puts IO.ANSI.red() <> "Starting ??"
    Supervisor.start_link(children, strategy: :one_for_one)
  end

    :ok
  def terminate(_state) do
    IO.puts(IO.ANSI.green()
      <> "Terminated ?" <> IO.ANSI.reset()
    )
  end
end
