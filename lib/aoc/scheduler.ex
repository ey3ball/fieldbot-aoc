defmodule Aoc.Scheduler do
  use Quantum, otp_app: :aoc
  @start_hour 5

  def aocbot_stats() do
    {_, today} = Aoc.Rank.Client.today()
    aocbot_stats(today)
  end

  def aocbot_stats(0) do
    :ok
  end

  def aocbot_stats(_) do
    GenServer.cast(Process.whereis(:aocbot), :stats)
  end

  def aocbot_solutions() do
    {_, today} = Aoc.Rank.Client.today()
    aocbot_solutions(today)
  end

  def aocbot_solutions(0) do
    :ok
  end

  def aocbot_solutions(_) do
    GenServer.cast(Process.whereis(:aocbot), :solutions)
  end

  def aocbot_today() do
    {_, today} = Aoc.Rank.Client.today()
    aocbot_today(today)
  end

  def aocbot_today(0) do
    :ok
  end

  def aocbot_today(_) do
    date = Date.utc_today()
    Mongo.insert_one(
      :mongo, "daystats",
      %{
        "day" => date.day,
        "year" => date.year,
        "global_stats" => %{
          "complete" => :false,
          "fastest" => [],
          "slowest" => []
        },
        "finishers" => []
      }
    )
    GenServer.cast(Process.whereis(:aocbot), :today)
  end

  def aocbot_heartbeat() do
    date = Date.utc_today()
    {year, _} = Aoc.Rank.Client.today()
    scrape_time = DateTime.utc_now()
    iso_time = DateTime.to_iso8601(scrape_time)

    # Update leaderboard cache
    leaderboard = Aoc.Rank.Client.leaderboard("#{year}")
    Mongo.insert_one(
      :mongo, "leaderboard",
      Map.put(leaderboard, "scrape_time", iso_time)
    )

    # If necessary update global stats
    if scrape_time.hour >= @start_hour do
      daydata = Aoc.Cache.Client.today()
      IO.inspect daydata
      if daydata["global_stats"]["complete"] == :false do
        global = Aoc.Rank.Client.global_scores(date.year, date.day)
        {slowest, fastest} = Aoc.Rank.Client.global_stats(global)
        complete = ((length(slowest) + length(fastest)) == 4)
        IO.inspect complete
        IO.inspect slowest

        new_stats = %{
          "global_stats" => %{
              "complete" => complete,
              "fastest" => fastest,
              "slowest" => slowest,
          }
        }

        Mongo.update_one!(
          :mongo, "daystats",
          %{ "_id" => daydata["_id"] },
          %{ "$set": new_stats }
        )

        if complete or new_stats != daydata["global_stats"] do
          GenServer.cast(Process.whereis(:aocbot), :global_update)
        end
      end
    end

    GenServer.cast(Process.whereis(:aocbot), :heartbeat)
  end

  def aocbot_updates() do
    scrape_time = DateTime.to_iso8601(DateTime.utc_now())
    leaderboard = Aoc.Rank.Client.leaderboard("2018")
    Mongo.insert_one(
      :mongo, "leaderboard",
      Map.put(leaderboard, "scrape_time", scrape_time)
    )
    leaderboard = Aoc.Rank.Client.leaderboard("2019")
    Mongo.insert_one(
      :mongo, "leaderboard",
      Map.put(leaderboard, "scrape_time", scrape_time)
    )
  end
end
