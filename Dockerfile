FROM elixir:latest

COPY ./ /logflare
WORKDIR /logflare

ENV MIX_ENV staging
ENV PORT 80

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt-get install -y nodejs

RUN mix local.rebar --force
RUN mix local.hex --force
RUN mix deps.get
RUN mix compile

RUN cd /logflare/assets \
    && npm install \
    && ./node_modules/webpack/bin/webpack.js --mode production 

WORKDIR /logflare

RUN mix phx.digest
# RUN mix ecto.migrate
RUN mix release --force --overwrite

ENTRYPOINT ["/logflare/_build/staging/rel/logflare/bin/logflare", "start"]
CMD ["/logflare/_build/staging/rel/logflare/bin/logflare", "start"]