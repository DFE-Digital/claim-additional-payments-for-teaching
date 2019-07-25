# ------------------------------------------------------------------------------
# base
# ------------------------------------------------------------------------------

FROM ruby:2.6.2-alpine AS base

RUN apk --no-cache add bash
RUN apk --no-cache add postgresql-dev
RUN apk --no-cache add tzdata
RUN apk --no-cache add nodejs

ENV APP_HOME /app
ENV DEPS_HOME /deps

ARG RAILS_ENV
ENV RAILS_ENV ${RAILS_ENV:-production}
ENV NODE_ENV ${RAILS_ENV:-production}

# ------------------------------------------------------------------------------
# dependencies
# ------------------------------------------------------------------------------

FROM base AS dependencies

RUN echo "Building with RAILS_ENV=${RAILS_ENV}, NODE_ENV=${NODE_ENV}"

RUN apk --no-cache add build-base
RUN apk --no-cache add yarn

# Set up install environment
RUN mkdir -p ${DEPS_HOME}
WORKDIR ${DEPS_HOME}
# End

# Install Ruby dependencies
COPY Gemfile ${DEPS_HOME}/Gemfile
COPY Gemfile.lock ${DEPS_HOME}/Gemfile.lock

RUN gem install bundler

RUN if [ ${RAILS_ENV} = "production" ]; then \
  bundle install --frozen --retry 3 --without development test; \
  elif [ ${RAILS_ENV} = "test" ]; then \
  bundle install --frozen --retry 3 --without development; \
  else \
  bundle install --frozen --retry 3 --without test; \
  fi
# End

# Install JavaScript dependencies
COPY package.json ${DEPS_HOME}/package.json
COPY yarn.lock ${DEPS_HOME}/yarn.lock

RUN if [ ${RAILS_ENV} = "production" ]; then \
  yarn install --frozen-lockfile --production; \
  else \
  yarn install --frozen-lockfile; \
  fi
# End

# ------------------------------------------------------------------------------
# web
# ------------------------------------------------------------------------------

FROM base AS web

RUN echo "Building with RAILS_ENV=${RAILS_ENV}, NODE_ENV=${NODE_ENV}"

# Set up install environment
RUN mkdir -p ${APP_HOME}
WORKDIR ${APP_HOME}
# End

# Copy dependencies (relying on dependencies using the same base image as this)
COPY --from=dependencies ${DEPS_HOME}/Gemfile ${APP_HOME}/Gemfile
COPY --from=dependencies ${DEPS_HOME}/Gemfile.lock ${APP_HOME}/Gemfile.lock
COPY --from=dependencies ${GEM_HOME} ${GEM_HOME}

COPY --from=dependencies ${DEPS_HOME}/node_modules ${APP_HOME}/node_modules
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

RUN if [ ${RAILS_ENV} = "production" ]; then \
  DFE_SIGN_IN_API_CLIENT_ID= \
  DFE_SIGN_IN_API_SECRET= \
  DFE_SIGN_IN_API_ENDPOINT= \
  bundle exec rake assets:precompile; \
  fi

EXPOSE 3000

ENTRYPOINT [ "bin/docker-entrypoint" ]
CMD [ "rails", "server" ]

# ------------------------------------------------------------------------------
# test
# ------------------------------------------------------------------------------

FROM web AS test

RUN echo "Building with RAILS_ENV=${RAILS_ENV}, NODE_ENV=${NODE_ENV}"

RUN apk --no-cache add chromium chromium-chromedriver

# Copy test code (sorted by vague frequency of change for caching)
COPY .prettierignore ${APP_HOME}/.prettierignore
COPY .prettierrc ${APP_HOME}/.prettierrc
COPY .rspec ${APP_HOME}/.rspec

COPY spec ${APP_HOME}/spec
# End
