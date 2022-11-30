import Config

config :aoc, Aoc.Mongod,
  host: System.get_env("FIELDBOT_MONGOD_SERVICE_HOST", nil),
  port: System.get_env("FIELDBOT_MONGOD_SERVICE_PORT", nil),
  username: System.get_env("FIELDBOT_MONGOD_USERNAME", nil),
  password: System.get_env("FIELDBOT_MONGOD_PASSWORD", nil),
  database: System.get_env("FIELDBOT_MONGOD_DATABASE", "aoc")

config :aoc, Aoc.Server,
  host: System.get_env("FIELDBOT_MATRIX_SERVICE_HOST", nil),
  port: System.get_env("FIELDBOT_MATRIX_SERVICE_PORT", nil),
  protocol: System.get_env("FIELDBOT_MATRIX_SERVICE_SCHEME", "http"),
  userid: System.get_env("FIELDBOT_MATRIX_USERID", nil),
  token: System.get_env("FIELDBOT_MATRIX_TOKEN", nil)

config :aoc, Aoc.Client,
  cookie: System.get_env("FIELDBOT_AOC_COOKIE", nil),
  leaderboard: System.get_env("FIELDBOT_AOC_LEADERBOARD", nil)

config :aoc, Aoc.Rooms,
  main: System.get_env("FIELDBOT_ROOM_MAIN", nil),
  spam: System.get_env("FIELDBOT_ROOM_DEBUG", nil),
  monitor: System.get_env("FIELDBOT_ROOM_MONITOR", "0")
