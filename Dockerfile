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
 dbus-x11

RUN mkdir -p /root/.vnc && \
 printf '%s\n' \
 '#!/bin/sh' \
 'set -e' \
 'export DISPLAY=:1' \
 '' \
 '# Fix: machine-id buat D-Bus' \
 'dbus-uuidgen --ensure=/etc/machine-id' \
 '' \
 '# Fix: bersihin X lock sisa restart' \
 'rm -f /tmp/.X1-lock' \
 'rm -rf /tmp/.X11-unix/X1' \
 '' \
 '# Password VNC dari env VNC_PASSWORD (default 123456)' \
 'x11vnc -storepasswd "${VNC_PASSWORD:-123456}" /root/.vnc/passwd >/dev/null' \
 '' \
 '# Start Xvfb' \
 'Xvfb :1 -screen 0 1366x900x16 &' \
 'sleep 2' \
 '' \
 '# Firefox di dalam D-Bus session, --no-sandbox buat root' \
 'dbus-run-session -- firefox --no-sandbox &' \
 '' \
 '# VNC di foreground biar container tetap hidup' \
 'exec x11vnc -display :1 -rfbport 5901 -rfbauth /root/.vnc/passwd -forever -shared -noxdamage -nowf' \
 > /startup.sh && \
 chmod +x /startup.sh

EXPOSE 5901
WORKDIR /root
CMD ["/startup.sh"]
