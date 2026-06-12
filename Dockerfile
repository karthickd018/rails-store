ARG RUBY_VERSION=3.2.2
FROM public.ecr.aws/docker/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl libjemalloc2 libvips libpq5 nginx && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential git pkg-config libpq-dev && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ \
    "${BUNDLE_PATH}"/ruby/*/cache \
    "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY . .
RUN bundle exec bootsnap precompile app/ lib/
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY start.sh /rails/start.sh

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 \
    --create-home --shell /bin/bash && \
    mkdir -p /var/log/nginx && \
    chown -R rails:rails /rails /var/log/nginx

RUN chmod +x /rails/start.sh

# No USER rails — nginx needs root to bind port 80

EXPOSE 80

CMD ["/rails/start.sh"]