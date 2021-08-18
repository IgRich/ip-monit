FROM ruby:3.0.2

RUN apt-get update -qq
# for ping command
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends apt-utils
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y iputils-ping
# for wait database
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-client

RUN mkdir /ip-monit
COPY ./app /ip-monit/app
COPY ./bin /ip-monit/bin
COPY ./config /ip-monit/config
COPY ./lib /ip-monit/lib
COPY ./migrations /ip-monit/migrations
COPY .rvmrc boot.rb boot.rb Gemfile Gemfile.lock Rakefile ./ip-monit/

WORKDIR /ip-monit
RUN bundle config set --local without 'test'
RUN gem install bundler
RUN bundle install
