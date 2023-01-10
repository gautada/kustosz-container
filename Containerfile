ARG ALPINE_VERSION="3.17.0"

FROM gautada/alpine:$ALPINE_VERSION

# ╭――――――――――――――――――――╮
# │ METADATA           │
# ╰――――――――――――――――――――╯
LABEL source="https://github.com/gautada/kustosz-container.git"
LABEL maintainer="Adam Gautier <adam@gautier.org>"
LABEL description="A container for a kustosz feed reader"

# ╭――――――――――――――――――――╮
# │ STANDARD CONFIG    │
# ╰――――――――――――――――――――╯

# USER:
ARG USER=kustosz

ARG UID=1001
ARG GID=1001
RUN /usr/sbin/addgroup -g $GID $USER \
 && /usr/sbin/adduser -D -G $USER -s /bin/ash -u $UID $USER \
 && /usr/sbin/usermod -aG wheel $USER \
 && /bin/echo "$USER:$USER" | chpasswd

# PRIVILEGE:
COPY wheel  /etc/container/wheel

# BACKUP:
COPY backup /etc/container/backup

# VERSION:
# COPY version /usr/bin/version

# ENTRYPOINT:
RUN rm -v /etc/container/entrypoint
COPY entrypoint /etc/container/entrypoint

# FOLDERS
RUN /bin/chown -R $USER:$USER /mnt/volumes/container \
 && /bin/chown -R $USER:$USER /mnt/volumes/backup \
 && /bin/chown -R $USER:$USER /var/backup \
 && /bin/chown -R $USER:$USER /tmp/backup


# ╭――――――――――――――――――――╮
# │ APPLICATION        │
# ╰――――――――――――――――――――╯
# RUN /sbin/apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing rabbitmq-server
RUN apk add --no-cache build-base python3-dev py3-pip py3-wheel py3-redis py3-psycopg

RUN pip install kustosz
RUN pip install gunicorn

RUN /bin/ln -svf /etc/container/settings.yaml /home/$USER/settings.yaml \
 && curl https://raw.githubusercontent.com/KustoszApp/server/main/settings/settings.yaml > /etc/container/settings.yaml

RUN /bin/ln -svf /etc/container/settings.local.yaml /home/$USER/settings.local.yaml \
 && /bin/ln -svf /mnt/volumes/configmaps/settings.local.yaml /etc/container/settings.local.yaml \
 && /bin/ln -svf /mnt/volumes/container/settings.local.yaml /mnt/volumes/configmaps/settings.local.yaml

# RUN mkdir -p /etc/rabbitmq/conf.d
# RUN /bin/ln -svf /etc/container/default.conf /etc/rabbitmq/conf.d/default.conf \
#  && /bin/ln -svf /mnt/volumes/configmaps/default.conf /etc/container/default.conf \
#  && /bin/ln -svf /mnt/volumes/container/default.conf /mnt/volumes/configmaps/default.conf
# RUN /bin/touch /home/$USER/.erlang.cookie \
#  && chown $USER:$USER /home/$USER/.erlang.cookie
# RUN sed "s/default_password/$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 64 | shasum | shasum | base64 | head -c 20)/" /etc/rabbitmq/conf.d/default.conf >
# RUN /bin/ln -svf /etc/container/rabbitmq.conf /etc/rabbitmq/rabbitmq.conf \
#   && /bin/ln -svf /mnt/volumes/configmaps/rabbitmq.conf /etc/container/rabbitmq.conf \
#   && /bin/ln -svf /mnt/volumes/container/rabbitmq.conf /mnt/volumes/configmaps/rabbitmq.conf
#
# RUN /bin/ln -svf /etc/container/rabbitmq-env.conf /etc/rabbitmq/rabbitmq-env.conf \
#  && /bin/ln -svf /mnt/volumes/configmaps/rabbitmq-env.conf /etc/container/rabbitmq-env.conf \
#  && /bin/ln -svf /mnt/volumes/container/rabbitmq-env.conf /mnt/volumes/configmaps/rabbitmq-env.conf
#
# Note: This command enable RMQ management plugin
# RUN /usr/sbin/rabbitmq-plugins enable --offline rabbitmq_management
# RUN pip3 install pika
# RUN ln -s /mnt/volumes/container/scripts /home/$USER/scripts
# RUN /bin/mkdir -p /opt/rabbit/mnesia \
# && /bin/chown $USER:$USER /opt/rabbit/mnesia
 
# ╭――――――――――――――――――――╮
# │ CONTAINER          │
# ╰――――――――――――――――――――╯
USER $USER
VOLUME /mnt/volumes/backup
VOLUME /mnt/volumes/configmaps
VOLUME /mnt/volumes/container
EXPOSE 5672/tcp 15672/tcp
WORKDIR /home/$USER
