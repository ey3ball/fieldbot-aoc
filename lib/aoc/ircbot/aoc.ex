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
    {:ok, %{:client => client, :init => false}}
  end

  def handle_cast(:today, state) do
    {:noreply, state}
  end

  def handle_cast(:heartbeat, state) do
    diff = Aoc.Rank.Announces.find_updates()

    cond do
      diff == "" ->
        :ok
      true ->
        updates = Aoc.IrcBot.Formatter.updates(diff)
        ExIRC.Client.msg(
          state[:client], :privmsg, @channel,
          updates
        )
    end

    scrape_time = DateTime.to_iso8601(DateTime.utc_now())
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
      String.starts_with?(message, "!crashtest") ->
        1 = 0
      String.starts_with?(message, "!formattest") ->
        ExIRC.Client.msg(
            state[:client], :privmsg, @channel,
            "Test <strong>*fsdfsfd*</strong> <pre>fsdf</pre><table><td>dsfsdf</td><td>dsfsdf</td></table>"
        )
      String.starts_with?(message, "!updatetest") ->
        GenServer.cast(Process.whereis(:aocbot), :heartbeat)
      String.starts_with?(message, "!2018") ->
        leaderboard = Aoc.Rank.Client.leaderboard("2018")
        ExIRC.Client.msg(
            state[:client], :privmsg, @channel,
            "Leaderboard :"
        )
        for {{_, s}, i} <- Aoc.Rank.Stats.by_rank(leaderboard)
            |> Enum.with_index()
            |> Enum.take(5), do: (
          IO.puts "#{inspect s}"
          ExIRC.Client.msg(
              state[:client], :privmsg, @channel,
              Aoc.IrcBot.Formatter.ranked_member(i, s)
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


defmodule Aoc.IrcBot.Formatter do
  def ranked_member(rank, member) do
    ~s(##{rank}. ⭐#{member["stars"]} ... )
    <> ~s(<strong>#{member["name"]}</strong>)
  end

  def updates(diff) do
    updates = diff
    |> Enum.map(&(
      "#{&1.name} grabs #{&1.new_stars} ⭐(+#{&1.new_points})"
    ))
    "Candies ! " <> Enum.join(updates, ", ")
  end
end
