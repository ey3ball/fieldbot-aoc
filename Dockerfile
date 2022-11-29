FROM docker.io/elixir:1.14

RUN useradd -d /app -u 1000 fieldbot
ADD . /app/
RUN chown -R fieldbot:fieldbot /app

USER fieldbot
RUN cd /app \
    && mix local.hex --force \
    && mix clean --deps \
        && mix local.rebar --force \
        && mix deps.get \
    && mix release

ENTRYPOINT [ "/app/_build/dev/rel/aoc/bin/aoc", "start" ]
