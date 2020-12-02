defmodule Aoc.IrcBot.Aoc do
  use GenServer

  alias Aoc.Cache.Client, as: Cache
  alias Aoc.IrcBot.Formatter, as: Formatter
  alias ExIRC.Client, as: Irc

  @five_seconds 5000
  @bot_prefix "🤖 "
  @moduledoc """
  """
  def start! do
    start_link([])
  end

  def start_link(client) do
    GenServer.start_link(__MODULE__, client, name: :aocbot)
  end

  def init(client) do
    Irc.add_handler(client, self())
    Process.send_after(self(), :started, @five_seconds)
    {:ok, %{
      :client => client,
      :init => false,
      :channel => Application.fetch_env!(:aoc, Aoc.IrcBot)
        |> Keyword.get(:channel),
      :spam => Application.fetch_env!(:aoc, Aoc.IrcBot)
        |> Keyword.get(:spam)
    }}
  end

  def handle_cast(:today, state) do
    today = Date.utc_today()

    problem = Aoc.Rank.Client.problem(today.year, today.day)
    title = Aoc.Rank.Client.problem_title(problem)

    Irc.msg(
        state[:client], :privmsg, state[:channel],
        @bot_prefix <> "The Game is ON ! <BLOCKQUOTE>"
        <> "🎅  " <> "Today's problem :"
        <> "<BR>🎅 <STRONG>" <> title <>"</STRONG>"
        <> "<BR>⏲️  " <> "</BLOCKQUOTE>"
    )

    {:noreply, state}
  end

  def handle_cast(:heartbeat, state) do
    scrape_time = DateTime.to_iso8601(DateTime.utc_now())
    Irc.msg(
        state[:client], :privmsg, state[:spam],
        @bot_prefix <> "Refreshed leaderboard stats !"
        <> scrape_time
    )

    diff = Aoc.Rank.Announces.find_updates()
    cond do
      diff == [] ->
        :ok
      true ->
        updates = Formatter.updates(diff)
        Irc.msg(
          state[:client], :privmsg, state[:channel],
          updates
        )
    end

    {:noreply, state}
  end

  def handle_cast(:global_update, state) do
    stats = Aoc.Cache.Client.today()
    fastest = stats["global_stats"]["fastest"]
    slowest = stats["global_stats"]["slowest"]

    complete = cond do
      stats["global_stats"]["complete"] == :true ->
        "<BR>🌍 leaderboard is complete for the day !"
      :true ->
        ""
    end

    Irc.msg(
        state[:client], :privmsg, state[:channel],
        @bot_prefix <> "Global leaderboard update !"
        <> Formatter.reference_times(slowest, fastest)
        <> complete
    )

    {:noreply, state}
  end


  def handle_info(:started, state) do
    {:noreply, %{state | :init => true}}
  end

  def handle_info(
      {:received, message, sender, channel},
      state = %{:init => true, :channel => channel}
  ) do
    from = sender.nick

    IO.puts "#{from} sent a message to #{channel}: #{message}"
    cond do
      String.starts_with?(message, "!crashtest") ->
        1 = 0
      String.starts_with?(message, "!formattest") ->
        Irc.msg(
            state[:client], :privmsg, state[:channel],
            @bot_prefix <> "Test <strong>*fsdfsfd*</strong>"
            <> "<pre>fsdf</pre><table><td>dsfsdf</td><td>dsfsdf</td></table>"
        )
      String.starts_with?(message, "!updatetest") ->
        GenServer.cast(Process.whereis(:aocbot), :heartbeat)
      String.starts_with?(message, "!2018") ->
        leaderboard = Cache.last("2018")
        Irc.msg(
            state[:client], :privmsg, state[:channel],
            @bot_prefix <> Formatter.leaderboard(leaderboard)
        )
      String.starts_with?(message, "!2019") ->
        leaderboard = Cache.last("2019")
        Irc.msg(
            state[:client], :privmsg, state[:channel],
            @bot_prefix <> Formatter.leaderboard(leaderboard)
        )
      String.starts_with?(message, "!2020") ->
        leaderboard = Cache.last("2020")
        Irc.msg(
            state[:client], :privmsg, state[:channel],
            @bot_prefix <> Formatter.leaderboard(leaderboard)
        )
      String.starts_with?(message, "!daily") ->
        diff = Aoc.Rank.Announces.daily_stats()
        cond do
          diff == [] ->
            Irc.msg(
              state[:client], :privmsg, state[:channel],
              @bot_prefix <> "No ⭐found recently :("
            )
          true ->
            updates = Formatter.ranking(diff)
            Irc.msg(
              state[:client], :privmsg, state[:channel],
              @bot_prefix <> "Today's ranking " <> updates
            )
        end
        :ok
      String.starts_with?(message, "!global") ->
        case Regex.run(~r/!global (20[1-2][0-9]) ([0-9][0-9]*)/, message) do
          nil ->
            :ok
          [_, year, day] ->
            global = Aoc.Rank.Client.global_scores(year, day)
            stats = Aoc.Rank.Client.global_stats(global)
            Irc.msg(state[:client], :privmsg, channel,
              @bot_prefix <> Formatter.global(stats, year, day)
            )
        end
      String.starts_with?(message, "!help") ->
        Irc.msg(
          state[:client], :privmsg, state[:channel],
          @bot_prefix <> "I live to serve<BR>"
          <> @bot_prefix <> "<strong>!help</strong>: read this<BR>"
          <> @bot_prefix <> "<strong>![year]</strong>: show top5<BR>"
          <> @bot_prefix <> "<strong>!daily</strong>: 24 hours stats<BR>"
          <> @bot_prefix <> "<strong>!crashtest</strong>: crash the bot (on purpose)<BR>"
        )
      String.starts_with?(message, "!") ->
        Irc.msg(state[:client], :privmsg, channel,
          @bot_prefix <> " Come again ?"
        )
      true ->
        :ok
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
    ~s(##{rank+1}. ⭐ #{member["stars"]} ... )
    <> ~s(<strong>#{member["name"]}</strong>)
  end

  def updates(diff) do
    updates = diff
    |> Enum.map(&(
      "#{&1.name} grabs #{&1.new_stars} ⭐ (+#{&1.new_points} pts)"
    ))
    "🚨🍬 " <> Enum.join(updates, ", ")
  end

  def ranking(diff) do
    IO.inspect diff
    updates = diff
      |> Enum.sort(&(&1[:new_points] >= &2[:new_points]))
      |> Enum.with_index()
      |> Enum.map(fn {user, i} ->
        "#{i+1}. #{user.new_points} <strong>#{user.name}</strong> (+#{user.new_stars} ⭐)"
      end)
    "<BLOCKQUOTE>" <> Enum.join(updates, "<BR>") <> "</BLOCKQUOTE>"
  end

  def leaderboard(leaderboard) do
    message = "Leaderboard :<BR><BLOCKQUOTE>"
    members = for {{_, s}, i} <- Aoc.Rank.Stats.by_rank(leaderboard)
        |> Enum.with_index()
        |> Enum.take(10), do: (
      ranked_member(i, s)
    )
    message <> Enum.join(members, "<BR>") <> "</BLOCKQUOTE>"
  end

  def global({slow, fast}, year, day) do
    "Global stats for #{year}/#{day}:<BR>"
    <> reference_times(slow, fast)
  end

  def reference_times(slow, fast) do
    "<BLOCKQUOTE>"
    <> "🔥 Fastest: #{Enum.join(fast, " 🌟 ")}<BR>"
    <> "❄️ Slowest: #{Enum.join(slow, " 🌟 ")}<BR>"
    <> "</BLOCKQUOTE>"
  end
end
