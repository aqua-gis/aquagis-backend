chmod -R 0777 /app/tmp;
touch /root/cronrun
set RAILS_ENV=production
cd /app && bundle exec rake i18n:js:export assets:precompile;
cron;
/usr/sbin/nginx -g "daemon off;"