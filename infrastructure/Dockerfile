# https://hub.docker.com/_/ruby/
FROM ruby:2.7.2-alpine3.12 as builder

# rails env
ARG buildtime_env=production
# region default
ARG buildtime_region=us-west-1
# ngrok or ssl
ARG buildtime_startup="ssl"

ENV LANG=en_US.utf8                                                     \
  LANGUAGE=en_US.utf8                                                   \
  LC_ALL=en_US.utf8                                                     \
  RAILS_ENV=$buildtime_env                                              \
  AWS_DEFAULT_REGION=$buildtime_region                                  \
  START_UP=$buildtime_startup                                           \
  RUBYGEMS_VERSION=3.1.4                                                \
  GEM_HOME=/usr/src/app/vendor/bundle/ruby/2.7.0

WORKDIR /usr/src/app

RUN apk add                                                             \
  linux-headers                                                         \
  gcc                                                                   \
  make                                                                  \
  libc-dev                                                              \
  mariadb-dev                                                           \
  g++                                                                   \
  git                                                                   \
  libxml2                                                               \
  libxslt-dev                                                           \
  shared-mime-info                                                      \
  && cd /usr/src/app

COPY Gemfile* ./
RUN gem update --system "$RUBYGEMS_VERSION"                            \
  && gem install bundler                                                \
  && echo "gems: $RUBYGEMS_VERSION"                                     \
  && echo "Bundle version: " "$(bundle --version)"                      \
  && bundle config set deployment 'true'                                \
  && bundle config set frozen 'true'                                    \
  && bundle config set no-cache 'true'                                  \
  && bundle config set without 'development test'                       \
  && bundle install --jobs 8 --retry 5                                  \
  # && echo "Cleaning up..."                                              \
  # && bundle exec cleanup_vendor --summary -e '**/password_strength*/*/common.txt'                               \
  && bundle clean --force                                               \
  && rm -rf vendor/bundle/ruby/2.7.0/cache/*.gem                        \
  && find vendor/bundle/ruby/2.7.0/gems/ -name "*.c" -delete            \
  && find vendor/bundle/ruby/2.7.0/gems/ -name "*.o" -delete            \
  && rm -rf /usr/src/app/vendor/bundle/ruby/2.7.0/cache                 \
  && echo "Builder stage complete!"

COPY . .

FROM ruby:2.7.2-alpine3.12

# rails env
ARG buildtime_env=production
# region default
ARG buildtime_region=us-west-1
# ngrok or ssl
ARG buildtime_startup="ssl"

ENV LANG=en_US.utf8                                                     \
  LANGUAGE=en_US.utf8                                                   \
  LC_ALL=en_US.utf8                                                     \
  RAILS_ENV=$buildtime_env                                              \
  AWS_DEFAULT_REGION=$buildtime_region                                  \
  START_UP=$buildtime_startup                                           \
  RUBYGEMS_VERSION=3.1.4                                                \
  GEM_HOME=/usr/src/app/vendor/bundle/ruby/2.7.0

WORKDIR /usr/src/app
COPY --from=builder /usr/src/app .

RUN apk add --no-cache                                                  \
  bash                                                                  \
  tzdata                                                                \
  imagemagick                                                          \
  libgomp                                                               \
  xz-dev                                                                \
  libxml2-dev                                                           \
  xz-libs                                                               \
  whois                                                                 \
  mariadb-connector-c                                                   \
  openssl                                                               \
  py-pip                                                                \
  tmux                                                                  \
  && gem update --system "$RUBYGEMS_VERSION"                            \
  && rm -r /root/.gem/                                                  \
  && gem install bundler                                                \
  && bundle config set deployment 'true'                                \
  && bundle config set frozen 'true'                                    \
  && bundle config set no-cache 'true'                                  \
  && bundle config set without 'development test build'                 \
  && rm -rf /usr/local/lib/ruby/gems/*/cache/*                          \
  && rm -rf /usr/src/app/vendor/bundle/ruby/*/cache/*                   \
  && pip install datadog

# move old public out of the way
# EFS will get mounted there and we will rsync it back later
RUN mv /usr/src/app/public /usr/src/app/public-orig

EXPOSE 3000

CMD ["./nclouds/start_app.sh"]
