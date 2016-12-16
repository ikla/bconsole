FROM php:7.0-alpine

## Add the files
RUN { \
    echo 'memory_limit = 128M'; \
    echo 'max_execution_time = 360'; \
  }	> /usr/local/etc/php/conf.d/php.ini

## Add Tini
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ tini
ENTRYPOINT ["/sbin/tini", "--"]

# get & install console
ADD https://github.com/ptrofimov/beanstalk_console/archive/master.tar.gz /tmp/beanstalk_console.tar.gz
RUN tar xvz -C /tmp/ -f /tmp/beanstalk_console.tar.gz \
    && mv /tmp/beanstalk_console-master /var/www \
    && chown www-data:www-data -R /var/www \
    && rm /tmp/beanstalk_console.tar.gz

## Expose the port
EXPOSE 80

# setup default beanstalkd server
RUN { echo '#!/bin/sh'; \
    echo $'if [[ -n "$BEANSTALKD_HOST" ]]; then'; \
    echo $'  if [[ -z "$BEANSTALKD_PORT" ]]; then'; \
	echo $'    BEANSTALKD_PORT=11300;'; \
    echo $'  fi;'; \
	echo $'  sed -ir "s/\'servers\'.*$/\'servers\'=> array(\'Default Beanstalkd\' => \'beanstalk:\/\/$BEANSTALKD_HOST:$BEANSTALKD_PORT\'),/g" /var/www/config.php'; \
	echo $'fi'; \
	echo $''; \
	echo $'php -S 0.0.0.0:80 -t /var/www/public/'; \
  } > /runcmd.sh
RUN chmod +x /runcmd.sh

CMD ["/runcmd.sh"]
