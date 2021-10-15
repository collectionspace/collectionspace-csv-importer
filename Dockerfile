FROM ruby:2.7.4

RUN curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get update && apt-get install -y nodejs yarn

RUN mkdir -p /usr/app/
WORKDIR /usr/app

COPY Gemfile* /usr/app/
RUN bundle install --without development test && yarn install

COPY . /usr/app/
RUN chmod u+x docker-entrypoint.sh

ENTRYPOINT [ "./docker-entrypoint.sh" ]
CMD ["./bin/rails", "s", "-b", "0.0.0.0"]
EXPOSE 3000
