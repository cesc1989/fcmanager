# syntax=docker/dockerfile:1

# Debe coincidir con .ruby-version / mise.toml
ARG RUBY_VERSION=3.4.8
FROM ruby:${RUBY_VERSION}-slim AS base

WORKDIR /app

ENV HANAMI_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    DATABASE_URL=sqlite://db/fcmanager.sqlite \
    HANAMI_SERVE_ASSETS=true

# Debe coincidir con BUNDLED WITH de Gemfile.lock
RUN gem install bundler -v 4.1.0


# Etapa de construcción: gemas nativas + assets (Node solo vive aquí)
FROM base AS build

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends build-essential

# hanami-assets (npm) exige node >= 22
COPY --from=node:22-slim /usr/local/bin/node /usr/local/bin/node
COPY --from=node:22-slim /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf "${BUNDLE_PATH}"/ruby/*/cache

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN bundle exec hanami assets compile && \
    rm -rf node_modules


# Imagen final
FROM base

# hanami db prepare usa la CLI sqlite3 para cargar/volcar structure.sql
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends sqlite3 && \
    rm -rf /var/lib/apt/lists/*

# uid 1000 = primer usuario de Linux Mint, dueño de ./db en el host
RUN useradd --create-home --uid 1000 app

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=app:app /app /app

USER app

EXPOSE 2300

ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
