# ------------------------------------------------------------------------------
# base
# ------------------------------------------------------------------------------
FROM ruby:3.4.4-alpine AS base

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

ENV APP_HOME=/app
ENV DEPS_HOME=/deps
ENV RAILS_ENV=production

RUN apk update
RUN apk add postgresql16=~16.9-r0
RUN apk add bash postgresql-dev tzdata nodejs curl libc6-compat shared-mime-info

# ------------------------------------------------------------------------------
# dependencies
# ------------------------------------------------------------------------------
FROM base AS dependencies

RUN apk update
RUN apk add build-base git yarn yaml-dev libffi-dev

# Set up install environment
RUN mkdir -p ${DEPS_HOME}
WORKDIR ${DEPS_HOME}

# Install Ruby dependencies
COPY Gemfile ${DEPS_HOME}/Gemfile
COPY Gemfile.lock ${DEPS_HOME}/Gemfile.lock
RUN gem install bundler
ENV BUNDLE_BUILD__SASSC=--disable-march-tune-native
RUN bundle config set frozen 'true'
RUN bundle config set without 'development';
# End

RUN bundle config
RUN bundle install --retry 3

# Install JavaScript dependencies
COPY package.json ${DEPS_HOME}/package.json
COPY yarn.lock ${DEPS_HOME}/yarn.lock
RUN yarn install --frozen-lockfile

# ------------------------------------------------------------------------------
# web
# ------------------------------------------------------------------------------

FROM base AS web

# Set up install environment
RUN mkdir -p ${APP_HOME}
WORKDIR ${APP_HOME}

EXPOSE 3000

CMD ["sh", "-c", "bundle exec rails db:migrate:ignore_concurrent_migration_exceptions && bundle exec rails server"]

# Copy dependencies (relying on dependencies using the same base image as this)
COPY --from=dependencies ${DEPS_HOME}/Gemfile ${APP_HOME}/Gemfile
COPY --from=dependencies ${DEPS_HOME}/Gemfile.lock ${APP_HOME}/Gemfile.lock
COPY --from=dependencies ${GEM_HOME} ${GEM_HOME}
COPY --from=dependencies ${DEPS_HOME}/node_modules ${APP_HOME}/node_modules

# Copy app code (sorted by vague frequency of change for caching)
COPY config.ru ${APP_HOME}/config.ru
COPY Rakefile ${APP_HOME}/Rakefile
COPY public ${APP_HOME}/public
COPY vendor ${APP_HOME}/vendor
COPY bin ${APP_HOME}/bin
COPY lib ${APP_HOME}/lib
COPY config ${APP_HOME}/config
COPY db ${APP_HOME}/db
COPY app ${APP_HOME}/app
COPY spec ${APP_HOME}/spec

RUN DFE_SIGN_IN_API_CLIENT_ID= \
  DFE_SIGN_IN_API_SECRET= \
  DFE_SIGN_IN_API_ENDPOINT= \
  ADMIN_ALLOWED_IPS= \
  ENVIRONMENT_NAME= \
  SUPPRESS_DFE_ANALYTICS_INIT= \
  GOVUK_APP_DOMAIN= \
  GOVUK_WEBSITE_ROOT= \
  SECRET_KEY_BASE_DUMMY=1 \
  bundle exec rake assets:precompile

RUN chown -hR appuser:appgroup ${APP_HOME}

USER appuser

ARG COMMIT_SHA
ENV GIT_COMMIT_HASH=${COMMIT_SHA}

# ------------------------------------------------------------------------------
# shellcheck
# ------------------------------------------------------------------------------

FROM koalaman/shellcheck:stable AS shellcheck

# ------------------------------------------------------------------------------
# test
# ------------------------------------------------------------------------------
FROM base AS test

USER root
WORKDIR ${APP_HOME}

ENV RAILS_ENV=test
ENV NODE_ENV=test
CMD [ "bundle", "exec", "rake" ]

RUN apk add chromium

# Install ShellCheck
COPY --from=shellcheck / /opt/shellcheck/
ENV PATH /opt/shellcheck/bin:${PATH}

COPY --from=dependencies ${GEM_HOME} ${GEM_HOME}

# Copy from web to include generated assets
COPY --from=web ${APP_HOME} ${APP_HOME}

# Copy all files
# This is only for the test target and ensures that all the files that could be linted locally are also linted on CI.
# We need to be mindful of files that get added to the project, if they are secrets or superfluous we should add them
# to the .dockerignore file.
COPY . ${APP_HOME}/

RUN chown -hR appuser:appgroup ${APP_HOME}

USER appuser
