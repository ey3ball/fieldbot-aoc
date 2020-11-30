defmodule Aoc.Rank.Client do
  @aoc_url "https://adventofcode.com/"
  @leaderboard_path "/leaderboard/private/view/635901.json"

  def leaderboard(year) do
    cookie = Keyword.get(
      Application.fetch_env!(:aoc, Aoc.Client),
      :cookie
    )
    url = @aoc_url <> year <> @leaderboard_path
    IO.puts "#{url}"
    {:ok, 200, _, ref} = :hackney.request(:get,
      @aoc_url <> year <> @leaderboard_path,
      [], <<>>, [{:cookie, cookie}]
    )
    {:ok, body} = :hackney.body(ref)
    {:ok, result} = Jason.decode(body)
    result
  end
end

defmodule Aoc.Cache.Client do
  def last(year, datetime \\ DateTime.utc_now()) do
    iso_datetime = DateTime.to_iso8601(datetime)
    IO.inspect iso_datetime
    cursor = Mongo.find(:mongo, "leaderboard",
      %{
        "$and" => [
          %{"event" => year},
          %{"scrape_time" =>
            %{"$lte" => iso_datetime}
          }
        ]
      },
      sort: %{scrape_time: -1},
      limit: 1
    )
    [last|_] = cursor |> Enum.to_list()
    last
  end

  def daily(year) do
    now = DateTime.utc_now()
    yesterday = DateTime.add(now, -24*3600)
    {last(year, now), last(year, yesterday)}
  end

  def last_couple(year \\ "2018") do
    cursor = Mongo.find(:mongo, "leaderboard",
      %{"event" => year},
      sort: %{scrape_time: -1},
      limit: 2
    )
    [n,n_1|_] = cursor |> Enum.to_list()
    {n, n_1}
  end

  # Test Document diff : fvallee +1 star +8 points
  def test_last_couple(year \\ "2018") do
    cursor = Mongo.find(:mongo, "leaderboard",
      %{
        "$and" => [
          %{"event" => year},
          %{"scrape_time" =>
            %{"$lte" => "2020-11-29T22:45:00.461371Z"}
          }
        ]
      },
      sort: %{scrape_time: -1},
      limit: 2
    )
    [n,n_1|_] = cursor |> Enum.to_list()
    {n, n_1}
  end
end
