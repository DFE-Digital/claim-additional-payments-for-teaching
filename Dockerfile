# ------------------------------------------------------------------------------
# base
# ------------------------------------------------------------------------------

FROM ruby:2.6.2-alpine AS base

RUN apk add build-base
RUN apk add tzdata
RUN apk add postgresql-dev
RUN apk add yarn

# ------------------------------------------------------------------------------
# dependencies
# ------------------------------------------------------------------------------

FROM base AS dependencies

# Set up install environment
ENV DEPS_HOME /deps

RUN mkdir -p ${DEPS_HOME}
WORKDIR ${DEPS_HOME}
# End

# Install JavaScript dependencies
COPY package.json ${DEPS_HOME}/package.json
COPY yarn.lock ${DEPS_HOME}/yarn.lock

RUN yarn install --frozen-lockfile --production
# End

# ------------------------------------------------------------------------------
# web
# ------------------------------------------------------------------------------

FROM base AS web

# Set up install environment
ENV APP_HOME /app

RUN mkdir -p ${APP_HOME}
WORKDIR ${APP_HOME}

ARG RAILS_ENV
ENV RAILS_ENV ${RAILS_ENV:-production}
ENV NODE_ENV ${RAILS_ENV:-production}

RUN echo "Building with RAILS_ENV=${RAILS_ENV}"
# End

# Install Ruby dependencies
COPY Gemfile ${APP_HOME}/Gemfile
COPY Gemfile.lock ${APP_HOME}/Gemfile.lock

RUN gem install bundler
RUN bundle install --frozen --retry 3 --without development test
# End

# Copy JavaScript dependencies
COPY --from=dependencies /deps/node_modules ${APP_HOME}/node_modules
# End

# Copy app code (sorted by vague frequency of change for caching)
RUN mkdir -p ${APP_HOME}/log
RUN mkdir -p ${APP_HOME}/tmp

COPY config.ru ${APP_HOME}/config.ru
COPY Rakefile ${APP_HOME}/Rakefile

COPY public ${APP_HOME}/public
COPY vendor ${APP_HOME}/vendor
COPY bin ${APP_HOME}/bin
COPY lib ${APP_HOME}/lib
COPY config ${APP_HOME}/config
COPY db ${APP_HOME}/db
COPY app ${APP_HOME}/app
# End

RUN RAILS_ENV=production DFE_SIGN_IN_ISSUER= DFE_SIGN_IN_REDIRECT_URL= DFE_SIGN_IN_IDENTIFIER= DFE_SIGN_IN_SECRET= bundle exec rake assets:precompile

EXPOSE 3000

CMD [ "rails", "server" ]
