# ------------------------------------------------------------------------------
# base
# ------------------------------------------------------------------------------

FROM ruby:2.6.2-alpine AS base

RUN apk add bash
RUN apk add postgresql-dev
RUN apk add tzdata
RUN apk add nodejs
RUN apk add curl
RUN apk add libc6-compat
RUN apk add shared-mime-info

ENV APP_HOME /app
ENV DEPS_HOME /deps

ARG RAILS_ENV
ENV RAILS_ENV ${RAILS_ENV:-production}
ENV NODE_ENV ${RAILS_ENV:-production}

# ------------------------------------------------------------------------------
# dependencies
# ------------------------------------------------------------------------------

FROM base AS dependencies

RUN apk add build-base
RUN apk add git
RUN apk add yarn

# Set up install environment
RUN mkdir -p ${DEPS_HOME}
WORKDIR ${DEPS_HOME}
# End

# Install Ruby dependencies
COPY Gemfile ${DEPS_HOME}/Gemfile
COPY Gemfile.lock ${DEPS_HOME}/Gemfile.lock

RUN gem install bundler
ENV BUNDLE_BUILD__SASSC=--disable-march-tune-native

RUN bundle config set frozen 'true'
RUN if [ ${RAILS_ENV} = "production" ]; then \
  bundle config set without 'development test'; \
  elif [ ${RAILS_ENV} = "test" ]; then \
  bundle config set without 'development'; \
  else \
  bundle config set without 'test'; \
  fi
# End
RUN bundle config

RUN bundle install --retry 3

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

# Set up install environment
RUN mkdir -p ${APP_HOME}
WORKDIR ${APP_HOME}
# End

# Download and install filebeat for sending logs to logstash
ENV FILEBEAT_VERSION=7.6.2
ENV FILEBEAT_DOWNLOAD_PATH=/tmp/filebeat.tar.gz
ENV FILEBEAT_CHECKSUM=482304509aed80db78ef63a0fed88e4453ebe7b11f6b4ab3168036a78f6a413e2f6a5c039f405e13984653b1a094c23f7637ac7daf3da75a032692d1c34a9b65
RUN curl https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${FILEBEAT_VERSION}-linux-x86_64.tar.gz -o ${FILEBEAT_DOWNLOAD_PATH} && \
    [ "$(sha512sum ${FILEBEAT_DOWNLOAD_PATH})" = "${FILEBEAT_CHECKSUM}  ${FILEBEAT_DOWNLOAD_PATH}" ] && \
    tar xzvf ${FILEBEAT_DOWNLOAD_PATH} && \
    rm ${FILEBEAT_DOWNLOAD_PATH} && \
    mv filebeat-${FILEBEAT_VERSION}-linux-x86_64 /filebeat && \
    rm -f /filebeat/filebeat.yml

# Copy our local filebeat config to the installation
COPY filebeat.yml /filebeat/filebeat.yml

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
  ADMIN_ALLOWED_IPS= \
  ENVIRONMENT_NAME= \
  bundle exec rake assets:precompile; \
  fi

EXPOSE 3000

ARG GIT_COMMIT_HASH
ENV GIT_COMMIT_HASH ${GIT_COMMIT_HASH}

CMD /filebeat/filebeat -c /filebeat/filebeat.yml & bundle exec rails server

# ------------------------------------------------------------------------------
# shellcheck
# ------------------------------------------------------------------------------

FROM koalaman/shellcheck:stable AS shellcheck

# ------------------------------------------------------------------------------
# test
# ------------------------------------------------------------------------------

FROM web AS test

RUN apk add chromium chromium-chromedriver

# Install ShellCheck
COPY --from=shellcheck / /opt/shellcheck/

ENV PATH /opt/shellcheck/bin:${PATH}
# End

# Copy all files
# This is only for the test target and ensures that all the files that could be linted locally are also linted on CI.
# We need to be mindful of files that get added to the project, if they are secrets or superfluous we should add them
# to the .dockerignore file.
COPY . ${APP_HOME}/
# End

CMD [ "bundle", "exec", "rake" ]
