FROM alpine:latest

ENV DISPLAY=:1 \
    HOME=/root

# 1. GABUNG semua install & cleanup dalam SATU RUN (biar ga ada layer sampah)
# 2. Pakai --virtual buat bungkus dependency yang cuma dipakai saat build (kalo ada)
# 3. Install HANYA yang perlu Firefox + mesa-dri-gallium
RUN apk add --no-cache \
    firefox \
    xvfb \
    x11vnc \
    mesa-dri-gallium \
    ttf-dejavu \
    fontconfig \
    && rm -rf /var/cache/apk/*

# Setup VNC & startup script (langsung bikin di sini, ga usah pakai heredoc kepanjangan)
RUN mkdir -p /root/.vnc && \
    echo "123456" | x11vnc -storepasswd stdin /root/.vnc/passwd && \
    printf '%s\n' \
    '#!/bin/sh' \
    'export DISPLAY=:1' \
    'rm -f /tmp/.X1-lock /tmp/.X11-unix/X1' \
    'Xvfb :1 -screen 0 1366x900x16 &' \
    'sleep 2' \
    'firefox &' \
    'exec x11vnc -display :1 -rfbport 5901 -rfbauth /root/.vnc/passwd -forever -shared -noxdamage -nowf' \
    > /startup.sh && \
    chmod +x /startup.sh

EXPOSE 5901
WORKDIR /root
CMD ["/startup.sh"]
