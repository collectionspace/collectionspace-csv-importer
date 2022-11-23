FROM ruby:2.7.4

# Setup std production defaults
ENV LANG=en_US.UTF-8 \
    RACK_ENV=production \
    RAILS_ENV=production \
    RAILS_FORCE_SSL=true \
    RAILS_LOG_TO_STDOUT=true \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_STORAGE_SERVICE=amazon

RUN curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get update && apt-get install -y nodejs yarn

RUN mkdir -p /usr/app/
WORKDIR /usr/app

COPY Gemfile* /usr/app/
RUN bundle install --without development test && rails webpacker:install

COPY . /usr/app/
# Optimize container startup times by precompiling assets ahead of deployment
# We need to satisfy the initializers with dummy values
RUN DATABASE_URL=nulldb://user:pass@127.0.0.1/dbname \
    LOCKBOX_MASTER_KEY=0000000000000000000000000000000000000000000000000000000000000000 \
    SECRET_KEY_BASE=123456 \
    ./bin/rails assets:precompile && \
    chmod u+x docker-entrypoint.sh

ENTRYPOINT [ "./docker-entrypoint.sh" ]
CMD ["./bin/rails", "s", "-b", "0.0.0.0"]
EXPOSE 3000
