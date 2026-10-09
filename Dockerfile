FROM alpine:3.20

ENV DISPLAY=:1 \
    HOME=/root \
    LIBGL_ALWAYS_SOFTWARE=1

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
    su-exec && \
    adduser -D -h /home/browser browser && \
    mkdir -p /home/browser/firefox-profile /root/.vnc && \
    printf '%s\n' \
      'user_pref("browser.tabs.unloadOnLowMemory", false);' \
      'user_pref("browser.cache.memory.capacity", 16384);' \
      'user_pref("gfx.webrender.enabled", false);' \
      'user_pref("layers.acceleration.disabled", true);' \
      'user_pref("media.hardware-video-decoding.enabled", false);' \
      'user_pref("browser.startup.page", 0);' \
      'user_pref("browser.shell.checkDefaultBrowser", false);' \
      > /home/browser/firefox-profile/user.js && \
    chown -R browser:browser /home/browser && \
    printf '%s\n' \
      '#!/bin/sh' \
      'set -eu' \
      'export DISPLAY=:1' \
      'dbus-uuidgen --ensure=/etc/machine-id' \
      'rm -f /tmp/.X1-lock /tmp/.X11-unix/X1' \
      'x11vnc -storepasswd "${VNC_PASSWORD:-123456}" /root/.vnc/passwd >/dev/null' \
      'Xvfb :1 -screen 0 1368x900x16 -nolisten tcp -ac &' \
      'i=0' \
      'while [ ! -S /tmp/.X11-unix/X1 ]; do' \
      '  i=$((i + 1))' \
      '  if [ "$i" -ge 30 ]; then' \
      '    echo "Xvfb gagal siap dalam 30 detik" >&2' \
      '    exit 1' \
      '  fi' \
      '  sleep 1' \
      'done' \
      '(' \
      '  while :; do' \
      '    echo "Menjalankan Firefox..."' \
      '    if su-exec browser env DISPLAY=:1 HOME=/home/browser LIBGL_ALWAYS_SOFTWARE=1 dbus-run-session -- firefox --profile /home/browser/firefox-profile --no-remote; then' \
      '      status=0' \
      '    else' \
      '      status=$?' \
      '    fi' \
      '    echo "Firefox berhenti dengan status ${status}; mencoba lagi dalam 3 detik." >&2' \
      '    sleep 3' \
      '  done' \
      ') &' \
      'exec x11vnc -display :1 -rfbport 5901 -rfbauth /root/.vnc/passwd -forever -shared -noxdamage -nowf' \
      > /startup.sh && \
    chmod +x /startup.sh

EXPOSE 5901

WORKDIR /home/browser

CMD ["/startup.sh"]
