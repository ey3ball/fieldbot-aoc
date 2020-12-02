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

  def today() do
    today = Date.utc_today()
    case {today.month, today.day} do
      {12, day} when day <= 25 ->
        day
      {_, _}
        -> 0
    end
  end

  def problem(year, day) do
    url = @aoc_url <> "#{year}/day/#{day}"
    {:ok, 200, _, ref} = :hackney.request(:get, url)
    {:ok, body} = :hackney.body(ref)
    parsed = Floki.parse_document!(body)
    parsed
  end

  def problem_title(parsed_problem) do
    parsed_problem
    |> Floki.find("article h2")
    |> Floki.text()
  end

  def global_scores(year, day) do
    url = @aoc_url <> "#{year}/leaderboard/day/#{day}"
    {:ok, 200, _, ref} = :hackney.request(:get, url)
    {:ok, body} = :hackney.body(ref)
    parsed = Floki.parse_document!(body)
    parsed
  end

  def global_stats(leaderboard) do
    find_ranked = fn(leaderboard, rank) ->
      leaderboard
      # Find Leaderboard HTML entities
      |> Floki.find(".leaderboard-entry")
      # Only keep those where position == rank
      |> Enum.filter(&(
        String.strip(
          Floki.find(&1, ".leaderboard-position") |> Floki.text
        ) == "#{rank})"
      ))
      # Extract Time from HTML
      |> Enum.map(fn (entry) ->
        entry
        |> Floki.find(".leaderboard-time")
        |> Floki.text
        |> String.slice(-8..-1)
      end)
      # Sort so that we have part1, part2 times in order
      |> Enum.sort()
    end

    slowest = find_ranked.(leaderboard, 100)
    fastest = find_ranked.(leaderboard, 1)
    {slowest, fastest}
  end
end

defmodule Aoc.Cache.Client do
  def last(year, datetime \\ DateTime.utc_now()) do
    iso_datetime = DateTime.to_iso8601(datetime)
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

  def daily() do
    now = DateTime.now!("EST")
    date = DateTime.to_date(now)
    start = DateTime.new!(date, ~T[00:00:00], "EST")
    {last("#{now.year}", DateTime.shift_zone!(now, "UTC")),
     last("#{now.year}", DateTime.shift_zone!(start, "UTC"))}
  end

  def today(date \\ Date.utc_today()) do
    Mongo.find_one(:mongo, "daystats",
      %{
        "$and" => [
          %{"day" => date.day},
          %{"year" => date.year}
        ]
      }
    )
  end


  def last_couple(year \\ "2020") do
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
