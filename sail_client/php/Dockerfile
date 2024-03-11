FROM sail:php82 as php

ARG  ACCEPT_EULA=Y
ARG  DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq

# Prepere custom script
# COPY ./scripts/start.sh /start.sh
# RUN chmod +x /start.sh

# Add or Remove packages/files
# ...

#
# docker client
#
ENV DOCKERVERSION=20.10.5
RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKERVERSION}.tgz \
  && tar xzvf docker-${DOCKERVERSION}.tgz --strip 1 \
                 -C /usr/local/bin docker/docker \
  && rm docker-${DOCKERVERSION}.tgz
  
# Remove useless packages/files (when, sqlserver Dockerfile)
#RUN pear clear-cache

RUN apt-get purge -qq --autoremove -y && \
    # Clean
    apt-get autoremove -qq -y && \
    apt-get autoclean -qq && \
    apt-get clean -qq

# Empty some directories from all files and hidden files
RUN rm -rf /build /tmp/* && \
    find /root /var/lib/apt/lists /usr/share/man /usr/share/doc /var/cache /var/log -type f -delete

# (when, php-fpm Dockerfile)
# USER sail
EXPOSE 80 443 6001