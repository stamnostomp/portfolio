# Stage 1: build a mix release
FROM elixir:1.18-alpine AS build

WORKDIR /app
ENV MIX_ENV=prod

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

COPY lib lib
RUN mix release

# Stage 2: run the release. Same base image as the build stage so the
# bundled ERTS finds matching musl/openssl libraries.
FROM elixir:1.18-alpine

WORKDIR /app
COPY --from=build /app/_build/prod/rel/leaderboard ./

ENV DATA_DIR=/data
VOLUME /data
EXPOSE 4000

CMD ["bin/leaderboard", "start"]
