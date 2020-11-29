defmodule Aoc.Scheduler do
  use Quantum, otp_app: :aoc

  def aocbot_today() do
    GenServer.cast(Process.whereis(:aocbot), :today)
  end

  def aocbot_heartbeat() do
    scrape_time = DateTime.to_iso8601(DateTime.utc_now())
    leaderboard = Aoc.Rank.Client.leaderboard("2018")
    Mongo.insert_one(
      :mongo, "leaderboard",
      Map.put(leaderboard, "scrape_time", scrape_time)
    )
    GenServer.cast(Process.whereis(:aocbot), :heartbeat)
  end
end
