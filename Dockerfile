# generate gemfile.lock
#   docker-compose run app bundle install
# uncomment and rebuild image
#   docker-compose build app
# boostrap rails app (select no when asked Overwrite /usr/src/app/Gemfile?)
#   docker-compose run --user "1000:$(id -g)" app rails new --skip-bundle .
# reconfigure database.yml settings
#   chanage sqlite3 to postgresql
#   host:     <%= ENV['SAMPLE_APP_DB_HOST'] || 'localhost' %>
#   port:     <%= ENV['SAMPLE_APP_DB_PORT'] || '5432' %>
#   database: <%= ENV['SAMPLE_APP_DB_NAME'] %>
#   username: <%= ENV['SAMPLE_APP_DB_USER'] %>
#   password: <%= ENV['SAMPLE_APP_DB_PASSWORD'] %>
#   remove database options for sqlite3 in all environments
# rename docker-compose.yml environment settings
#   e.g. TOY_APP_DB_HOST: --> SAMPLE_APP_DB_HOST:
# docker-compose up

# base image
FROM ruby:2.3

# install some requirements
RUN set -ex \
  && apt-get update \
  && apt-get install -y \
    nodejs

#  throw errors if Gemfile has been modified since Gemfile.lock
# comment out while bootstrapping app
RUN bundle config --global frozen 0

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# install required gems from gemfile
# comment out while bootstrapping app
COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/
RUN bundle install

# copy the code
COPY . /usr/src/app

# default command
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["bin/rails", "server", "-b", "0.0.0.0"]

# install gosu
ENV GOSU_VERSION '1.9'
ENV GOSU_GPG_KEY 'B42F6819007F00F88E364FD4036A9C25BF357DD4'
RUN set -ex \
    && wget -O /usr/local/bin/gosu \
        "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
    && wget -O /usr/local/bin/gosu.asc \
        "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GOSU_GPG_KEY" \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

RUN set -ex \
    && groupadd --gid 118 --system worker \
    && useradd --uid 118 --gid 118 --shell /bin/false --home-dir /nonexistent --system worker
