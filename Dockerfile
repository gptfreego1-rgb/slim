FROM alpine:3.20

ENV DISPLAY=:1 \
    HOME=/root

RUN apk add --no-cache \
    firefox \
    xvfb \
    x11vnc \
    mesa-dri-gallium \
    ttf-dejavu \
    fontconfig \
    xkbcomp \
    dbus \
    dbus-x11 \
    su-exec

RUN adduser -D -h /home/browser browser && \
    mkdir -p /root/.vnc && \
    printf '%s\n' \
    '#!/bin/sh' \
    'set -eu' \
    'export DISPLAY=:1' \
    '' \
    'dbus-uuidgen --ensure=/etc/machine-id' \
    '' \
    '# Bersihkan lock/socket X11 yang mungkin tertinggal setelah restart' \
    'rm -f /tmp/.X1-lock /tmp/.X11-unix/X1' \
    '' \
    '# Password VNC: default 123456; ganti melalui env VNC_PASSWORD' \
    'x11vnc -storepasswd "${VNC_PASSWORD:-123456}" /root/.vnc/passwd >/dev/null' \
    '' \
    '# Jalankan Xvfb dan tunggu sampai display siap' \
    'Xvfb :1 -screen 0 1366x900x24 -nolisten tcp -ac &' \
    'i=0' \
    'while [ ! -S /tmp/.X11-unix/X1 ]; do' \
    '  i=$((i + 1))' \
    '  if [ "$i" -ge 30 ]; then' \
    '    echo "Xvfb gagal siap dalam 30 detik" >&2' \
    '    exit 1' \
    '  fi' \
    '  sleep 1' \
    'done' \
    '' \
    '# Jalankan Firefox sebagai user non-root; --no-sandbox dihapus' \
    'su-exec browser env DISPLAY=:1 HOME=/home/browser dbus-run-session -- firefox --no-remote &' \
    '' \
    '# Jalankan VNC di foreground agar container tetap hidup' \
    'exec x11vnc -display :1 -rfbport 5901 -rfbauth /root/.vnc/passwd -forever -shared -noxdamage' \
    > /startup.sh && \
    chmod +x /startup.sh

EXPOSE 5901

WORKDIR /home/browser

CMD ["/startup.sh"]
