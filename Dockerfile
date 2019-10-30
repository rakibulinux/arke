FROM ruby:2.6.5

ARG RAILS_ENV=production
ARG UID=1000
ARG GID=1000

ENV RAILS_ENV=${RAILS_ENV} \
    APP_HOME=/home/app

ENV TZ=UTC

 # Create group "app" and user "app".
RUN groupadd -r --gid ${GID} app \
 && useradd --system --create-home --home ${APP_HOME} --shell /sbin/nologin --no-log-init \
      --gid ${GID} --uid ${UID} app

WORKDIR $APP_HOME
USER app

COPY --chown=app:app Gemfile Gemfile.lock $APP_HOME/

# Install dependencies
RUN gem install bundler
RUN bundle install --jobs=$(nproc)

# Copy the main application.
COPY --chown=app:app . $APP_HOME

# Initialize application configuration & assets.
# RUN ./bin/init_config

# Expose port 8081 to the Docker host, to be accessible outside
EXPOSE 8081

 # The main command to run when the container starts. Also
# tell the Rails dev server to bind to all interfaces by
# default.
CMD ["bundle", "exec", "puma", "--config", "config/puma.rb"]
