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
