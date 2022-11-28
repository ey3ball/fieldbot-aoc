defmodule Aoc.Cfg do
  def check() do
    true = Enum.all?(
      Application.fetch_env!(:aoc, Aoc.Server)
      |> Keyword.values()
    )
    true = Enum.all?(
      Application.fetch_env!(:aoc, Aoc.Mongod)
      |> Keyword.values()
    )
    true = Enum.all?(
      Application.fetch_env!(:aoc, Aoc.Client)
      |> Keyword.values()
    )
    true = Enum.all?(
      Application.fetch_env!(:aoc, Aoc.Rooms)
      |> Keyword.values()
    )
  end

  def matrix_url() do
    env = Application.fetch_env!(:aoc, Aoc.Server)
    protocol = env |> Keyword.get(:protocol)
    host = env |> Keyword.get(:host)
    port = env |> Keyword.get(:port)
    "#{protocol}://#{host}:#{port}"
  end

  def matrix_userid() do
    Application.fetch_env!(:aoc, Aoc.Server) |> Keyword.get(:userid)
  end

  def matrix_token() do
    Application.fetch_env!(:aoc, Aoc.Server) |> Keyword.get(:token)
  end

  def aoc_cookie() do
    Application.fetch_env!(:aoc, Aoc.Client) |> Keyword.get(:cookie)
  end

  def leaderboard() do
    Application.fetch_env!(:aoc, Aoc.Client) |> Keyword.get(:leaderboard)
  end

  def room_main() do
    Application.fetch_env!(:aoc, Aoc.Rooms) |> Keyword.get(:main)
  end

  def room_debug() do
    Application.fetch_env!(:aoc, Aoc.Rooms) |> Keyword.get(:spam)
  end

  def mongod() do
    env = Application.fetch_env!(:aoc, Aoc.Mongod)
    host = env |> Keyword.get(:host)
    port = env |> Keyword.get(:port)
    username = env |> Keyword.get(:username)
    password = env |> Keyword.get(:password)
    database = env |> Keyword.get(:database)
    "mongodb://#{username}:#{password}@#{host}:#{port}/#{database}"

  end
end

defmodule Aoc.Server do
  use Supervisor

  @moduledoc """
  """
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, %{}, opts)
  end

  def init(state) do
    Aoc.Cfg.check()

    IO.puts IO.ANSI.red() <> "Aoc.Server Starting"

    children = [
      Aoc.IrcBot.Aoc
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end

    :ok
  def terminate(_state) do
    IO.puts(IO.ANSI.green()
      <> "Aoc.Server Terminated" <> IO.ANSI.reset()
    )
  end
end
