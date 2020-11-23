defmodule Aoc.Server do
  use GenServer

  defmodule State do
    defstruct host: "127.0.0.1",
              port: 5999,
              nick: "",
              pass: "",
              user: "fieldbot",
              name: "fieldbot",
              client: nil,
              handlers: []
    end

  @moduledoc """
  """
  def start_link(_) do
    env = Application.fetch_env!(:aoc, Aoc.Server)
    GenServer.start_link(__MODULE__, %State{
      nick: Keyword.get(env, :username),
      pass: Keyword.get(env, :password)
    }, [])
  end

  def init(state) do
    {:ok, client} = ExIRC.start_link!()

    {:ok, network} = Aoc.IrcBot.Network.start_link(client, state)
    {:ok, aoc} = Aoc.IrcBot.Aoc.start_link(client)

    {:ok, %{state | :client => client, :handlers => [network, aoc]}}
  end

    :ok
  def terminate(_state) do
    IO.puts(IO.ANSI.green()
      <> "Terminated ?" <> IO.ANSI.reset()
    )
  end
end
