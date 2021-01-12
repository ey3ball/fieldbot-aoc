# Fieldbot-Aoc

This is an IRC bot that announces new AoC problems, global leaderboard times
and private leaderboard updates / stats.

It is intended to be used with the <https://github.com/matrix-org/matrix-ircd> project.
Messages contain HTML formatting and probably won't be of much use with an
actual IRCd.

Ultimately this bot is currently used to publish updates to slack, because why
not ?

> Bot <-> matrix-ircd <-> synapse <-> mx-puppet-slack

It works suprisingly well. You could probably use the bot with other bridges or
directly with matrix, but message formatting has been specifically tailored to
look good on slack.

## Building

A Dockerfile is provided to build the main app, there's nothing particular
here, it's a fairly standard Elixir app, just run mix.

```
mix deps.get
mix compile
```

## Starting

First of all you should head up to `config/config.exs` and setup a few
variables there. You'll need :

* `Aoc.Client.cookie` content of a valid cookie grabbed from the AoC website
* `Aoc.Server.username` matrix username we'll use to authenticate with matrix-ircd
* `Aoc.Server.password` matrix password
* `Aoc.IrcBot.channel` target IRC channel for announces
* `Aoc.IrcBot.spam` target IRC channel for monitoring announces

After that you can go ahead and start the stack :
```
MATRIX_URL=https://matrix.server.url docker-compose -p aoc up
```

This will start all of the necessary services but not fieldbot itself.

At that point you should login into MongoDB and make sure you create an `aoc`
account (password: `root`) which has administrative rights over the `aoc`
database. This isn't done automatically and these credentials are hardcoded in
the Elixir app for now. (PRs welcome ;))

Finally once this is all done you can start the Elixir app
```
$ docker-compose -p aoc exec aoc /bin/bash
$ iex -S mix # Start the app and open an Elixir shell
```

## First run

Once your bot is up you'll have to wait a bit before it populates the internal
database and can produce usefull stats.

Basically we're fetching fresh data from AoC's servers once every 15 minutes
(as suggested by the AoC API usage rules)
and storing that locally in a Mongo database. Most of the announces are based on
diff computed between consecutive fetches, so you may need to wait up to 30
minutes before the bot can pick up anything usefull.

Some announces (daily stats mostly) are based on the initial leaderboard state
at the beginning of the day, so you'll have to wait up to 24 hours before we
have enough history for these to work properly.

Some commands (such as global leaderboard stats) interrogate AoC servers
directly each time.
