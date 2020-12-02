import Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :aoc, Aoc.Scheduler,
  jobs: [
    {"0 6 * * *", &Aoc.Scheduler.aocbot_today/0},
    {"*/15 * * *", &Aoc.Scheduler.aocbot_heartbeat/0}
  ]

config :aoc, Aoc.Client,
  cookie: "AocWebsiteCookie"

config :aoc, Aoc.Server,
  username: "matrix-username",
  password: "matrix-password"
