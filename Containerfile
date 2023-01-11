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
RUN apk add --no-cache build-base git nginx python3-dev py3-pip py3-wheel py3-redis py3-psycopg

RUN pip install kustosz
RUN pip install gunicorn

RUN /bin/mkdir -p /home/$USER/settings \
 && /bin/ln -svf /etc/container/settings.yaml /home/$USER/settings/settings.yaml \
 && curl https://raw.githubusercontent.com/KustoszApp/server/main/settings/settings.yaml > /etc/container/settings.yaml

RUN /bin/ln -svf /etc/container/settings.local.yaml /home/$USER/settings/settings.local.yaml \
 && /bin/ln -svf /mnt/volumes/configmaps/settings.local.yaml /etc/container/settings.local.yaml \
 && /bin/ln -svf /mnt/volumes/container/settings.local.yaml /mnt/volumes/configmaps/settings.local.yaml

RUN /bin/ln -svf /mnt/volumes/container/db.sqlite3 /home/$USER/db.sqlite3

COPY kustosz-profile.sh /etc/container/kustosz-profile.sh
RUN /bin/ln -fsv /etc/container/kustosz-profile.sh /etc/profile.d/kustosz-profile.sh

RUN mkdir -p /home/$USER/frontend \
 && cd /home/$USER/frontend \
 && curl -L https://github.com/KustoszApp/web-ui/releases/download/22.08.0/kustosz.tar.xz -o kustosz.tar.xz \
 && tar xf  kustosz.tar.xz \
 && rm kustosz.tar.xz \
 && cd .. \
 && chown $USER:$USER -R /home/$USER/frontend
# RUN git clone --branch 22.08.0 https://github.com/KustoszApp/web-ui.git /home/$USER/web-ui

# RUN chown $USER:$USER -R /var/lib/nginx 
RUN mv /etc/nginx/http.d/default.conf /etc/nginx/http.d/default.conf~
COPY kustosz-nginx.conf /etc/nginx/http.d/kustosz-nginx.conf
 
# ╭――――――――――――――――――――╮
# │ CONTAINER          │
# ╰――――――――――――――――――――╯
USER $USER
VOLUME /mnt/volumes/backup
VOLUME /mnt/volumes/configmaps
VOLUME /mnt/volumes/container
EXPOSE 5672/tcp 15672/tcp
WORKDIR /home/$USER

RUN mkdir -p ~/.celery/queue
# RUN source /etc/container/kustosz-profile.sh && /usr/bin/kustosz-manager migrate \
#  && /usr/bin/kustosz-manager createcachetable
#  && /usr/bin/kustosz-manager createcachetable
