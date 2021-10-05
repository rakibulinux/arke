FROM ruby:2.6

ARG UID=1000
ARG GID=1000

ENV APP_HOME=/home/app \
    TZ=UTC

 # Create group "app" and user "app".
RUN groupadd -r --gid ${GID} app \
 && useradd --system --create-home --home ${APP_HOME} --shell /sbin/nologin --no-log-init \
      --gid ${GID} --uid ${UID} app

WORKDIR $APP_HOME
USER app

COPY --chown=app:app Gemfile Gemfile.lock $APP_HOME/

# Install dependencies
RUN gem install bundler
RUN bundle install --jobs=$(nproc) --without test development

# Copy the main application.
COPY --chown=app:app . $APP_HOME
