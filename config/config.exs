import Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :aoc, Aoc.Scheduler,
  jobs: [
    {"0 4 * * *", &Aoc.Scheduler.aocbot_updates/0},
    {"0 1,12,18 * * *", &Aoc.Scheduler.aocbot_stats/0},
    {"1 5 * * *", &Aoc.Scheduler.aocbot_today/0},
    {"5,20,35,50 * * *", &Aoc.Scheduler.aocbot_heartbeat/0}
  ]

config :aoc, Aoc.Client,
  cookie: "AocWebsiteCookie"

config :aoc, Aoc.Server,
  username: "matrix-username",
  password: "matrix-password"
