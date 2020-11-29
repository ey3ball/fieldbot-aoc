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
    new_stars = m2["stars"] - m1["stars"]
    new_points = m2["local_score"] - m1["local_score"]
    %{
      :id => m2["id"],
      :name => m2["name"],
      :new_stars => new_stars,
      :new_points => new_points
    }
  end

  def diff(l1, l2) do
    l1 = l1["members"]
    l2 = l2["members"]

    l2
    |> Map.to_list()
    |> Enum.map(&(diff_member(elem(&1, 1), l1[elem(&1, 0)])))
  end

  def members_stats(leaderboard) do
    leaderboard["members"]
    |> Map.to_list()
    |> Enum.map(fn {id, data}
      -> {id, data["completion_day_level"]} end)
  end
end

defmodule Aoc.Rank.Announces do
  def find_updates() do
    {n, n_1} = Aoc.Cache.Client.last_couple()
    #{n, n_1} = Aoc.Cache.Client.test_last_couple()
    diff = Aoc.Rank.Stats.diff(n, n_1)
    Enum.filter(
      diff, fn(%{:new_points => p}) -> p != 0 end
    )
  end
end
