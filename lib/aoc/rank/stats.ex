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

  def by_time(leaderboard, day) do
    Map.to_list(leaderboard["members"])
    |> Enum.map(&(elem(&1, 1)))
    |> Enum.map(
      fn
        %{
          "name" => name,
          "completion_day_level" => %{
            ^day => %{
              "1" => %{ "get_star_ts" => part1_ts },
              "2" => %{ "get_star_ts" => part2_ts }
            }
          }
        } ->
          {String.to_integer(part2_ts) - String.to_integer(part1_ts), name} 
        _ ->
          :false
    end)
    |> Enum.filter(&(&1 != :false))
    |> Enum.sort
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

  def diff_member(m1, nil) do
    nil
  end
  def diff_member(m1, m2) do
    new_stars = m2["stars"] - m1["stars"]
    new_points = m2["local_score"] - m1["local_score"]
    today = DateTime.now!("EST").day
    today_stars = Map.get(m1["completion_day_level"], "#{today}", %{})
                  |> Map.to_list() |> Enum.count()
    new_today_stars = Map.get(m2["completion_day_level"], "#{today}", %{})
                  |> Map.to_list() |> Enum.count()
    new_badge = case {today_stars, new_today_stars} do
      {2,2} -> ""
      {1,1} -> ""
      {_,2} -> "🤩 " # part2 completed
      {_,1} -> "⭐ " # part1 completed
      _ -> ""
    end
    day_stars = m2["completion_day_level"]
                |> Map.to_list
                |> Enum.map(fn {i, v} -> {i, v |> Enum.to_list() |> Enum.count()} end)
                |> Map.new
    %{
      :id => m2["id"],
      :name => m2["name"],
      :new_stars => new_stars,
      :new_points => new_points,
      :new_badge => new_badge,
      :day_stars => day_stars,
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
      diff, fn
        %{:new_stars => p} ->
          p != 0
        nil ->
          :false
      end
    )
  end

  def daily_stats() do
    {day, n, n_1} = Aoc.Cache.Client.daily()
    diff = Aoc.Rank.Stats.diff(n, n_1)
    {day, Enum.filter(
      diff, fn
        %{:new_stars => p} ->
          p != 0
        nil ->
          :false
      end
    )}
  end
end
