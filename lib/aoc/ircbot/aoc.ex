defmodule Aoc.IrcBot.Aoc do
  use GenServer

  alias Aoc.Cache.Client, as: Cache
  alias Aoc.IrcBot.Formatter, as: Formatter

  @five_seconds 5000
  @bot_prefix "🤖 "
  @moduledoc """
  """
  def start! do
    start_link([])
  end

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: :aocbot)
  end

  def init(_args) do
    {:ok, pid} =
      Polyjuice.Client.start_link(
        Aoc.Cfg.matrix_url(),
        access_token: Aoc.Cfg.matrix_token(),
        user_id: Aoc.Cfg.matrix_userid(),
        handler: self(),
        storage: Polyjuice.Client.Storage.Ets.open()
      )

    IO.puts(IO.ANSI.red() <> "Aoc.IrcBot Starting - client #{inspect(pid)}")
    client = Polyjuice.Client.get_client(pid)

    {:ok,
     %{
       :client => client,
       :init => false,
       :room => nil,
       :room_spam => nil,
       :channel => Aoc.Cfg.room_main(),
       :spam => Aoc.Cfg.room_debug()
     }}
  end

  def handle_cast(:stats, state) do
    date = DateTime.now!("EST")
    Aoc.IrcBot.Commands.daily(state)
    Aoc.IrcBot.Commands.fast(state, "#{date.day}", "#{date.year}")
    {:noreply, state}
  end

  def handle_cast(:solutions, state) do
    date = DateTime.now!("EST")

    Aoc.IrcBot.Commands.send_message(
      state,
      @bot_prefix <>
        "Day #{date.day} 🎁 Solution discussion thread" <>
        "<BLOCKQUOTE>Be nice and don't open until part 2 completion" <>
        "<BR>⚠️ <STRONG>Spoilers Ahead</STRONG>" <>
        "</BLOCKQUOTE>"
    )

    {:noreply, state}
  end

  def handle_cast(:today, state) do
    today = Date.utc_today()

    problem = Aoc.Rank.Client.problem(today.year, today.day)
    title = Aoc.Rank.Client.problem_title(problem)

    Aoc.IrcBot.Commands.send_message(
      state,
      @bot_prefix <>
        "Wake up early 🐦🐦🐦 ! <BLOCKQUOTE>" <>
        "🎅  " <>
        "Today's problem :" <>
        "<BR>🎅 <STRONG>" <>
        title <>
        "</STRONG>" <>
        "<BR>⏲️  " <> "</BLOCKQUOTE>"
    )

    {:noreply, state}
  end

  def handle_cast(:heartbeat, state) do
    scrape_time = DateTime.to_iso8601(DateTime.utc_now())

    Aoc.IrcBot.Commands.send_message(
      state,
      @bot_prefix <> "Refreshed leaderboard stats !" <> scrape_time,
      state[:room_spam]
    )

    diff = Aoc.Rank.Announces.find_updates()

    cond do
      diff == [] ->
        :ok

      true ->
        updates = Formatter.updates(diff)
        Aoc.IrcBot.Commands.send_message(state, updates)
    end

    {:noreply, state}
  end

  def handle_cast(:global_update, state) do
    stats = Aoc.Cache.Client.today()
    fastest = stats["global_stats"]["fastest"]
    slowest = stats["global_stats"]["slowest"]

    complete =
      cond do
        stats["global_stats"]["complete"] == true ->
          "<BR>🌍 Global leaderboard is complete for the day ! 100 people have solved the two challenges already."

        true ->
          ""
      end

    Aoc.IrcBot.Commands.send_message(
      state,
      @bot_prefix <>
        "Global leaderboard update !" <>
        Formatter.reference_times(slowest, fastest) <>
        complete
    )

    {:noreply, state}
  end

  def handle_info({:polyjuice_client, :initial_sync_completed}, state) do
    IO.puts(IO.ANSI.red() <> "Matrix client ready !!")
    {:ok, {room_id, _}} = Polyjuice.Client.Room.get_alias(state[:client], Aoc.Cfg.room_main())

    {:ok, {debug_room_id, _}} =
      Polyjuice.Client.Room.get_alias(state[:client], Aoc.Cfg.room_debug())

    IO.puts("Room ? #{inspect(room_id)}")
    IO.puts("Debug Room ? #{inspect(debug_room_id)}")
    {:noreply, %{state | :init => true, :room => room_id, :room_spam => debug_room_id}}
  end

  def handle_info(
        {:polyjuice_client, :message,
         {channel, %{"content" => %{"msgtype" => "m.text"} = message}} = data},
        # , :channel => channel}
        state = %{:init => true, :room => channel}
      ) do
    from = message["sender"]
    message = message["body"]

    IO.puts("#{from} sent a message to #{channel}: #{message}")

    cond do
      String.starts_with?(message, "!crashtest") ->
        1 = 0

      String.starts_with?(message, "!formattest") ->
        Aoc.IrcBot.Commands.send_message(
          state,
          @bot_prefix <>
            "Test <strong>*fsdfsfd*</strong>" <>
            "<pre>fsdf</pre><table><td>dsfsdf</td><td>dsfsdf</td></table>"
        )

      String.starts_with?(message, "!selftest") ->
        problem = Aoc.Rank.Client.problem("2021", "5")
        leaderboard = Aoc.Rank.Client.leaderboard("2021")
        IO.inspect(leaderboard)

        Aoc.IrcBot.Commands.send_message(
          state,
          @bot_prefix <>
            "Test API client<BR>" <>
            "Problem 2021/05 " <>
            Aoc.Rank.Client.problem_title(problem) <>
            "<BR>" <>
            "Leaderboard 2021" <> "<BR>" <> Aoc.IrcBot.Formatter.leaderboard(leaderboard)
        )

      String.starts_with?(message, "!updatetest") ->
        GenServer.cast(Process.whereis(:aocbot), :heartbeat)

      String.starts_with?(message, "!2018") ->
        Aoc.IrcBot.Commands.top5(state, "2018")

      String.starts_with?(message, "!2019") ->
        Aoc.IrcBot.Commands.top5(state, "2019")

      String.starts_with?(message, "!2020") ->
        Aoc.IrcBot.Commands.top5(state, "2020")

      String.starts_with?(message, "!2021") ->
        Aoc.IrcBot.Commands.top5(state, "2021")

      String.starts_with?(message, "!daily") ->
        {_, today} = Aoc.Rank.Client.today()

        case today do
          0 ->
            Aoc.IrcBot.Commands.send_message(
              state,
              @bot_prefix <>
                "No AoC today :( " <>
                "Come back during advent season 🧦 !"
            )

          _ ->
            Aoc.IrcBot.Commands.daily(state)
        end

      String.starts_with?(message, "!fast") ->
        date = DateTime.now!("EST")

        {day, year} =
          case Regex.run(~r/!fast ([0-9]+).?([0-9]{4})?$/, message) do
            nil ->
              {"#{date.day}", "#{date.year}"}

            [_, arg_day] ->
              {arg_day, "#{date.year}"}

            [_, arg_day, arg_year] ->
              {arg_day, arg_year}
          end

        Aoc.IrcBot.Commands.fast(state, day, year)

      String.starts_with?(message, "!global") ->
        case Regex.run(~r/!global (20[1-2][0-9]) ([0-9][0-9]*)/, message) do
          nil ->
            date = DateTime.now!("EST")
            Aoc.IrcBot.Commands.global(state, "#{date.year}", "#{date.day}")

          [_, year, day] ->
            Aoc.IrcBot.Commands.global(state, year, day)
        end

      String.starts_with?(message, "!help") ->
        Aoc.IrcBot.Commands.send_message(
          state,
          @bot_prefix <>
            "I live to serve<BR>" <>
            @bot_prefix <>
            "<strong>!help</strong>: read this<BR>" <>
            @bot_prefix <>
            "<strong>![year]</strong>: show top5<BR>" <>
            @bot_prefix <>
            "<strong>!daily</strong>: today's stats<BR>" <>
            @bot_prefix <>
            "<strong>!fast [day] [year]</strong>: fastest part2 solvers<BR>" <>
            @bot_prefix <>
            "<strong>!global [year] [day]</strong>: global leaderboard statistics<BR>"
        )

      String.starts_with?(message, "!") ->
        Aoc.IrcBot.Commands.send_message(
          state,
          @bot_prefix <> " Come again ?"
        )

      true ->
        :ok
    end

    {:noreply, state}
  end

  def handle_info({:received, message, sender, channel}, state) do
    from = sender.nick
    IO.puts("#{from} sent a message to #{channel}: #{message}")
    {:noreply, state}
  end

  # Catch-all for messages you don't care about
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end

defmodule Aoc.IrcBot.Commands do
  alias Aoc.IrcBot.Formatter, as: Formatter
  alias Aoc.Cache.Client, as: Cache
  alias Polyjuice.Client, as: Matrix
  @bot_prefix "🤖 "

  def send_message(state, message) do
    send_message(state, message, state[:room])
  end

  def send_message(state, message, room) do
    Matrix.Room.send_message(
      state[:client],
      room,
      {Floki.text(message), message}
    )
  end

  def daily(state) do
    {day, diff} = Aoc.Rank.Announces.daily_stats()

    cond do
      diff == [] ->
        send_message(
          state,
          @bot_prefix <> "No ⭐found recently :("
        )

      true ->
        updates = Formatter.ranking("#{day}", diff)

        send_message(
          state,
          @bot_prefix <>
            "Today's leaders ! Who woke up first ? ☕" <>
            updates
        )
    end

    :ok
  end

  def top5(state, year) do
    leaderboard = Cache.last(year)

    send_message(
      state,
      @bot_prefix <> Formatter.leaderboard(leaderboard)
    )
  end

  def fast(state, day, year) do
    # date = Date.new!(
    #  elem(Integer.parse(year), 0),
    #  12,
    #  elem(Integer.parse(day) + 1, 0)
    # )
    # time = DateTime.new!(date, ~T[00:00:00.000], "EST")
    leaderboard = Aoc.Cache.Client.last(year)
    solve_stats = Aoc.Rank.Stats.by_time(leaderboard, day)

    send_message(
      state,
      @bot_prefix <>
        "Fastest 🦌 in the pack ? (best part 2 solve times for #{year}-#{day})" <>
        Formatter.part2_times(solve_stats)
    )

    :ok
  end

  def global(state, year, day) do
    global = Aoc.Rank.Client.global_scores(year, day)
    stats = Aoc.Rank.Client.global_stats(global)

    send_message(
      state,
      @bot_prefix <> Formatter.global(stats, year, day)
    )

    :ok
  end
end

defmodule Aoc.IrcBot.Formatter do
  def ranked_member(rank, member) do
    ~s(#{rank} ⭐ #{member["stars"]} ... ) <>
      ~s(<strong>#{member["name"]} </strong>#{member["local_score"]} pts)
  end

  def user_update(user_diff) do
    "#{user_diff.name} #{user_diff.new_badge}" <>
      (user_diff.new_times
       |> Map.to_list()
       |> Enum.map(fn
         {day, ""} -> "<STRONG>J#{day}</STRONG> "
         {day, time} -> "<STRONG>J#{day}</STRONG> #{time} "
       end)
       |> Enum.join(" ")) <>
      "[+#{user_diff.new_points} pts]" <>
      " gets #{:rand.uniform(div(user_diff.new_points, 10) + 1)} 🍬 "
  end

  def updates(diff) do
    updates =
      diff
      |> Enum.map(&user_update(&1))
      |> Enum.take(10)

    "🚨 " <> Enum.join(updates, "<BR>🚨 ")
  end

  def ranking(day, diff) do
    updates =
      diff
      |> Enum.sort(
        &(&1[:new_points] > &2[:new_points] ||
            (&1[:new_points] == &2[:new_points] &&
               &1[:p2_time] <= &2[:p2_time]))
      )
      |> Enum.take(5)
      |> beautify_rank()
      |> Enum.map(fn {user, i} ->
        "#{i}<strong>#{user.name}</strong> #{user.new_points} pts #{day_badge(day, user)} #{user.p2_time}"
      end)

    "<BLOCKQUOTE>" <> Enum.join(updates, "<BR>") <> "</BLOCKQUOTE>"
  end

  def day_badge(day, user) do
    case Map.get(user.day_stars, day, 0) do
      2 -> "🤩 "
      1 -> "⭐ "
      0 -> "🌛"
    end
  end

  def leaderboard(leaderboard) do
    message = "Naughty or Nice ? Introducing 🎅's favorites<BR><BLOCKQUOTE>"

    members =
      for {{_, s}, i} <-
            Aoc.Rank.Stats.by_rank(leaderboard)
            |> beautify_rank
            |> Enum.take(5),
          do: ranked_member(i, s)

    message <> Enum.join(members, "<BR>") <> "</BLOCKQUOTE>"
  end

  def global({slow, fast}, year, day) do
    "Global stats for #{year}/#{day}:<BR>" <>
      reference_times(slow, fast)
  end

  def reference_times(slow, fast) do
    "<BLOCKQUOTE>" <>
      "🔥 Fastest: part 1 - #{Enum.at(fast, 0)} " <>
      "⭐ part 2 - #{Enum.at(fast, 1)} 🤩<BR>" <>
      "❄️ Slowest: part 1 - #{Enum.at(slow, 0)} " <>
      "⭐ part 2 - #{Enum.at(slow, 1)} 🤩<BR>" <>
      "</BLOCKQUOTE>"
  end

  def part2_times(timed_stats) do
    rankings =
      timed_stats
      |> beautify_rank()
      |> Enum.map(fn {{time, username}, rank} ->
        "#{rank} in #{Time.to_iso8601(Time.from_seconds_after_midnight(time))} ⏱️ <STRONG>#{username}</STRONG>"
      end)
      |> Enum.join("<BR>")

    "<BLOCKQUOTE>" <> rankings <> "</BLOCKQUOTE>"
  end

  def beautify_rank(enumerable) do
    enumerable
    |> Enum.with_index()
    |> Enum.map(fn
      {v, 0} -> {v, "🥇"}
      {v, 1} -> {v, "🥈"}
      {v, 2} -> {v, "🥉"}
      {v, i} when i < 9 -> {v, "  #{i + 1}  "}
      {v, i} -> {v, " #{i + 1} "}
    end)
  end
end
