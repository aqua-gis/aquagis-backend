#!/usr/bin/env bash

# abort on error
set -e

# set locale to UTF-8 compatible. apologies to non-english speakers...
locale-gen en_GB.utf8
update-locale LANG=en_GB.utf8 LC_ALL=en_GB.utf8
export LANG=en_GB.utf8
export LC_ALL=en_GB.utf8

# make sure we have up-to-date packages
apt-get update

# upgrade all packages
apt-get upgrade -y

# install packages as explained in INSTALL.md
apt-get install -y ruby2.7 libruby2.7 ruby2.7-dev \
                     libmagickwand-dev libxml2-dev libxslt1-dev nodejs yarnpkg \
                     apache2 apache2-dev build-essential git-core firefox-geckodriver \
                     libsasl2-dev imagemagick libffi-dev libgd-dev libarchive-dev libbz2-dev libpq-dev postgresql postgresql-contrib
gem2.7 install rake
gem2.7 install --version "~> 2.1.4" bundler

## install the bundle necessary for aquagis-api
pushd /srv/aquagis-api
# do bundle install as a convenience
bundle install --retry=10 --jobs=2
# do yarn install as a convenience
bundle exec rake yarn:install
# create user and database for aquagis-api
#db_user_exists=`sudo -u postgres psql postgres -tAc "select 1 from pg_roles where rolname='vagrant'"`
#if [ "$db_user_exists" != "1" ]; then
#    sudo -u postgres createuser -s vagrant
#    sudo -u vagrant createdb -E UTF-8 -O vagrant aquagis_db
#    sudo -u vagrant createdb -E UTF-8 -O vagrant aquagis_test
    # add btree_gist extension
#    sudo -u vagrant psql -c "create extension btree_gist" aquagis_db
#    sudo -u vagrant psql -c "create extension btree_gist" aquagis_test
#fi


# install PostgreSQL functions
#sudo -u vagrant psql -d aquagis_db -f db/functions/functions.sql
################################################################################
# *IF* you want a vagrant image which supports replication (or perhaps you're
# using this script to provision some other server and want replication), then
# uncomment the following lines (until popd) and comment out the one above
# (functions.sql).
################################################################################
#pushd db/functions
#sudo -u vagrant make
#sudo -u vagrant psql aquagis_db -c "CREATE OR REPLACE FUNCTION tile_for_point(int4, int4) RETURNS int8 AS '/srv/openstreetmap-website/db/functions/libpgosm.so', 'tile_for_point' LANGUAGE C STRICT"
#sudo -u vagrant psql aquagis_db -c "CREATE OR REPLACE FUNCTION xid_to_int4(xid) RETURNS int4 AS '/srv/openstreetmap-website/db/functions/libpgosm.so', 'xid_to_int4' LANGUAGE C STRICT"
#popd


# set up sample configs
if [ ! -f config/database.yml ]; then
    sudo -u vagrant cp config/example.database.yml config/database.yml
fi
touch config/settings.local.yml
# migrate the database to the latest version
sudo -u vagrant bundle exec rake db:migrate
popd
