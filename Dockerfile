FROM alpine:latest

ENV DISPLAY=:1 \
    HOME=/root

# Install semua dependency dalam SATU layer, langsung cleanup cache
RUN apk add --no-cache \
    firefox \
    xvfb \
    x11vnc \
    mesa-dri-gallium \
    ttf-dejavu \
    fontconfig \
    && rm -rf /var/cache/apk/*

# Buat startup script + setup VNC password default dalam satu layer
RUN mkdir -p /root/.vnc && \
    x11vnc -storepasswd 123456 /root/.vnc/passwd >/dev/null && \
    printf '%s\n' \
    '#!/bin/sh' \
    'export DISPLAY=:1' \
    '' \
    '# Fix: Firefox butuh machine-id buat D-Bus' \
    'if [ ! -s /etc/machine-id ]; then' \
    '    echo "01234567890123456789012345678901" > /etc/machine-id' \
    'fi' \
    '' \
    '# Fix: bersihin X lock sisa restart' \
    'rm -f /tmp/.X1-lock' \
    'rm -rf /tmp/.X11-unix/X1' \
    '' \
    '# Start Xvfb' \
    'Xvfb :1 -screen 0 1366x900x16 &' \
    'sleep 2' \
    '' \
    '# Fix: --no-sandbox buat atasi EACCES CanCreateUserNamespace' \
    'firefox --no-sandbox &' \
    '' \
    '# Start VNC (foreground, biar container tetep hidup)' \
    'exec x11vnc -display :1 -rfbport 5901 -rfbauth /root/.vnc/passwd -forever -shared -noxdamage -nowf' \
    > /startup.sh && \
    chmod +x /startup.sh

EXPOSE 5901
WORKDIR /root
CMD ["/startup.sh"]
