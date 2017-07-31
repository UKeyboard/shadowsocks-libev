FROM alpine

MAINTAINER jun <hyj.hfut.mail@gmail.com>

ENV TZ 'Asia/Shanghai'
ENV SS_LIBEV_VERSION 3.0.7
ENV KCP_VERSION 20170525
ENV COW_VERSION 0.9.8
ENV POLIPO_VERSION 1.1.1

RUN set -ex \
    && apk upgrade --no-cache \
    && apk add --no-cache libsodium \
                          bash \
                          tzdata \
                          libcrypto1.0 \
                          libev \
                          libsodium \
                          mbedtls \
                          pcre \
                          udns \
                          wget \
    && apk add --no-cache \
               --virtual .build-deps autoconf \
                                     automake \
                                     build-base \
                                     curl \
                                     gettext-dev \
                                     libev-dev \
                                     libsodium-dev \
                                     libtool \
                                     linux-headers \
                                     mbedtls-dev \
                                     openssl-dev \
                                     pcre-dev \
                                     tar \
                                     udns-dev \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo $TZ > /etc/timezone \
    && mkdir workspace \
    && cd workspace \
    && curl -sSLO https://github.com/shadowsocks/shadowsocks-libev/releases/download/v$SS_LIBEV_VERSION/shadowsocks-libev-$SS_LIBEV_VERSION.tar.gz \
    && tar -zxf shadowsocks-libev-$SS_LIBEV_VERSION.tar.gz \
    && cd shadowsocks-libev-$SS_LIBEV_VERSION \
    && ./configure --prefix=/usr --disable-documentation \
    && make -j${NPROC} install \
    && cd .. \
    && rm -rf shadowsocks-libev* \
    && curl -sSLO https://github.com/xtaci/kcptun/releases/download/v$KCP_VERSION/kcptun-linux-amd64-$KCP_VERSION.tar.gz \
    && mkdir kcptun-linux-amd64-$KCP_VERSION \
    && tar -zxf kcptun-linux-amd64-$KCP_VERSION.tar.gz -C kcptun-linux-amd64-$KCP_VERSION \
    && cp kcptun-linux-amd64-$KCP_VERSION/server_linux_amd64 /usr/local/bin/kcp-server \
    && cp kcptun-linux-amd64-$KCP_VERSION/client_linux_amd64 /usr/local/bin/kcp-client \
    && rm -rf kcptun-linux-amd64* \
    && curl -sSLO https://github.com/jech/polipo/archive/polipo-$POLIPO_VERSION.tar.gz \
    && tar -zxf polipo-$POLIPO_VERSION.tar.gz \
    && cd polipo-polipo-$POLIPO_VERSION \
    && make -j${NPROC} \
    && cp polipo /usr/local/bin/polipo \
    && mkdir -p /usr/share/polipo/www /var/cache/polipo \
    && mkdir -p /etc/polipo && cp config.sample /etc/polipo/config.sample \
    && cd .. \
    && rm -rf polipo* \
    && curl -sSL https://github.com/cyfdecyf/cow/releases/download/$COW_VERSION/cow-linux64-$COW_VERSION.gz | gzip -d > cow \
    && cp cow /usr/local/bin/cow && chmod a+x /usr/local/bin/cow \
    && mkdir -p /etc/cow \
    && curl -sSL https://raw.githubusercontent.com/cyfdecyf/cow/master/doc/sample-config/rc > rc \
    && cp rc /etc/cow/rc \
    && rm cow rc \
    && { find /usr/local/bin  -type f -regex ".[^\.]*" -exec strip --strip-all '{}' + || true; } \
    && apk del .build-deps \
    && cd / && rm -rf workspace /var/cache/apk/* \
    && addgroup -S xproxy \
    && adduser -S -h /home/xproxy -s /bin/bash -G xproxy xproxy

ENV WORKSPACE /home/xproxy
WORKDIR $WORKSPACE
ADD entrypoint.sh entrypoint.sh
RUN set -ex \
    && chmod a+x entrypoint.sh


USER xproxy

ENV POLIPO_PORT 8123
ENV COW_PORT 7777
EXPOSE $POLIPO_PORT $COW_PORT


ENTRYPOINT ["./entrypoint.sh"]