FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system packages then clean up to minimize image size
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install --no-install-recommends -y \
      build-essential \
      curl \
      default-jre-headless \
      file \
      firefox-geckodriver \
      imagemagick \
      libarchive-dev \
      libffi-dev \
      libgd-dev \
      libmagickwand-dev \
      libpq-dev \
      libsasl2-dev \
      libxml2-dev \
      libxslt1-dev \
      locales \
      nodejs \
      postgresql-client \
      ruby2.7 \
      libruby2.7 \
      ruby2.7-dev \
      tzdata \
      unzip \
      libbz2-dev \
      yarnpkg \
      nginx \
      cron

 # Set up for produciton
 #   Install our PGP key and add HTTPS support for APT
RUN apt-get install -y dirmngr gnupg
# RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
COPY docker/passenger-ubuntu-key.txt /app/passenger-ubuntu-key.txt
RUN apt-key add /app/passenger-ubuntu-key.txt
RUN apt-get install -y apt-transport-https ca-certificates

# Add our APT repository
RUN sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger focal main > /etc/apt/sources.list.d/passenger.list'
RUN apt-get update

# Install Passenger + Nginx module
RUN apt-get install -y libnginx-mod-http-passenger

# Clean apt chach
RUN apt-get clean \
 && rm -rf /var/lib/apt/lists/*


# Setup NGINX and Passinger
RUN if [ ! -f /etc/nginx/modules-enabled/50-mod-http-passenger.conf ]; then ln -s /usr/share/nginx/modules-available/mod-http-passenger.load /etc/nginx/modules-enabled/50-mod-http-passenger.conf ; fi
RUN ls /etc/nginx/conf.d/mod-http-passenger.conf
COPY docker/nginx.conf /etc/nginx/nginx.conf
RUN systemctl enable nginx
RUN mkdir /var/run/passenger-instreg


# Install bundler
RUN gem2.7 install bundler

ENV DEBIAN_FRONTEND=dialog

# Setup app location
RUN mkdir -p /app
WORKDIR /app

# Install Ruby packages
ADD Gemfile Gemfile.lock /app/
RUN bundle install

# Install NodeJS packages using yarnpkg
# `bundle exec rake yarn:install` will not work
ADD package.json yarn.lock Rakefile /app/
COPY config/ app/
RUN yarnpkg install

RUN set RAILS_ENV=production

# Add the script to the Docker Image
COPY docker/onboot.sh /root/onboot.sh

# Give execution rights on the cron scripts
RUN chmod +x /root/onboot.sh

# Expose the port for access
EXPOSE 3000/tcp