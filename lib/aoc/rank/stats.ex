defmodule Aoc.Rank.Stats do
  def test_stats() do
    [leaderboard|_] = Enum.to_list(
      Mongo.find(:mongo, "leaderboard", %{}))
  end

  def local_rank(leaderboard) do
    leaderboard["members"]
    |> Enum.sort(&(&1["local_score"]))
  end

  def members_stats(leaderboard) do
    leaderboard["members"]
    |> Map.to_list()
    |> Enum.map(fn {id, data}
      -> {id, data["completion_day_level"]} end)
  end
end
