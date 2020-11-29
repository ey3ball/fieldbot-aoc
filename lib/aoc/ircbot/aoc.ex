defmodule Aoc.IrcBot.Aoc do
  use GenServer

  @channel "#adventofcode-bootcamp-Fieldbox.ai"
  @five_seconds 5000
  @moduledoc """
  """
  def start! do
    start_link([])
  end

  def start_link(client) do
    GenServer.start_link(__MODULE__, client, name: :aocbot)
  end

  def init(client) do
    ExIRC.Client.add_handler(client, self())
    Process.send_after(self(), :started, @five_seconds)
    {:ok, conn} = Mongo.start_link(
      name: :mongo,
      url: "mongodb://aoc:root@localhost:27017/aoc"
    )
    {:ok, %{:client => client, :init => false}}
  end

  def handle_cast(:today, state) do
    {:noreply, state}
  end

  def handle_cast(:heartbeat, state) do
    scrape_time = DateTime.to_iso8601(DateTime.utc_now())
    leaderboard = Aoc.Rank.Client.leaderboard("2018")
    Mongo.insert_one(
      :mongo, "leaderboard",
      Map.put(leaderboard, "scrape_time", scrape_time)
    )
    ExIRC.Client.msg(
        state[:client], :privmsg, @channel,
      "Scraped 2018 leaderboard at " <> scrape_time
    )
    {:noreply, state}
  end

  def command_help(state) do
    commands = [
      "!help",
    ]

    IO.puts "Hello ?"
    for c <- commands, do:
      ExIRC.Client.msg(
          state[:client], :privmsg, @channel,
          c
      )
    :ok
  end

  def handle_info(:started, state) do
    {:noreply, %{state | :init => true}}
  end

  def handle_info(
      {:received, message, sender, channel = @channel},
      state = %{:init => true}) do
    from = sender.nick
    IO.puts "#{inspect state} -"
    IO.puts "#{from} sent a message to #{channel}: #{message}"
    cond do
      String.starts_with?(message, "!crash") ->
        1 = 0
      String.starts_with?(message, "!test") ->
        ExIRC.Client.msg(
            state[:client], :privmsg, @channel,
            "fsdf <strong>*fsdfsfd*</strong>"
        )
      String.starts_with?(message, "!2018") ->
        info = Aoc.Rank.Client.leaderboard("2018")
        for {{_, s}, i} <- Enum.with_index(info["members"])
            |> Enum.take(5), do: (
          IO.puts "#{inspect s}"
          ExIRC.Client.msg(
              state[:client], :privmsg, @channel,
              ~s(#{i+1}. <strong>#{s["name"]}</strong>\t\t #{s["stars"]}⭐)
          )
        )
      String.starts_with?(message, "!") ->
        ExIRC.Client.msg(state[:client], :privmsg, channel,
            "🤖 hello :)"
        )
      true ->
        :ok
        #ExIRC.Client.msg(state[:client], :privmsg, channel,
        #    "Come again ?"
        #)
    end

    {:noreply, state}
  end

  def handle_info({:received, message, sender, channel}, state) do
    from = sender.nick
    IO.puts "#{from} sent a message to #{channel}: #{message}"
    {:noreply, state}
  end

  # Catch-all for messages you don't care about
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
