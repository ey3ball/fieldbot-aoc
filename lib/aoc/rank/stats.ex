defmodule Aoc.Rank.Stats do
  def test_stats() do
    [leaderboard|_] = Enum.to_list(
      Mongo.find(:mongo, "leaderboard", %{}))
  end

  def by_rank(leaderboard) do
    members = leaderboard["members"]
    |> Enum.sort(&(
      elem(&1, 1)["local_score"]
      >= elem(&2, 1)["local_score"]
    ))
    members
  end

  def by_stars(leaderboard) do
    leaderboard["members"]
    |> Enum.sort(&(
      elem(&1, 1)["stars"]
      >= elem(&2, 1)["stars"]
    ))
  end

  def members(leaderboard) do
    leaderboard["members"]
    |> Map.to_list()
    |> Enum.sort()
    |> Enum.map(&(elem(&1, 1)))
  end

  def diff_member(m1, m2) do
    %{
      :id => m2["id"],
      :name => m2["name"],
      :new_stars => m2["stars"] - m1["stars"],
      :new_points => m2["local_score"] - m1["local_score"]
    }
  end

  def diff(l1, l2) do
    l1 = l1["members"]
    l2 = l2["members"]

    l2
    |> Map.to_list()
    |> Enum.map(&(diff_member(elem(&1, 1), l2[elem(&1, 0)])))
  end

  def members_stats(leaderboard) do
    leaderboard["members"]
    |> Map.to_list()
    |> Enum.map(fn {id, data}
      -> {id, data["completion_day_level"]} end)
  end
end
