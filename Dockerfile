FROM alpine:3.16 AS builder
ARG THREADS="4"

WORKDIR /src

RUN apk add --no-cache git g++ build-base linux-headers cmake python3 \
    curl-dev rapidjson-dev pcre2-dev yaml-cpp-dev && \
    git clone https://github.com/ftk/quickjspp --depth=1 && \
    cd quickjspp && \
    git submodule update --init && \
    cmake -DCMAKE_BUILD_TYPE=Release . && \
    make quickjs -j $THREADS && \
    install -d /usr/lib/quickjs/ && \
    install -m644 quickjs/libquickjs.a /usr/lib/quickjs/ && \
    install -d /usr/include/quickjs/ && \
    install -m644 quickjs/quickjs.h quickjs/quickjs-libc.h /usr/include/quickjs/ && \
    install -m644 quickjspp.hpp /usr/include && \
    cd .. && \
    git clone https://github.com/PerMalmberg/libcron --depth=1 && \
    cd libcron && \
    git submodule update --init && \
    cmake -DCMAKE_BUILD_TYPE=Release . && \
    make libcron -j $THREADS && \
    install -m644 libcron/out/Release/liblibcron.a /usr/lib/ && \
    install -d /usr/include/libcron/ && \
    install -m644 libcron/include/libcron/* /usr/include/libcron/ && \
    install -d /usr/include/date/ && \
    install -m644 libcron/externals/date/include/date/* /usr/include/date/ && \
    cd .. && \
    git clone https://github.com/ToruNiina/toml11 --branch="v4.3.0" --depth=1 && \
    cd toml11 && \
    cmake -DCMAKE_CXX_STANDARD=11 . && \
    make install -j $THREADS && \
    cd ..

COPY . /src/subconverter
WORKDIR /src/subconverter

RUN cmake -DCMAKE_BUILD_TYPE=Release . && \
    make -j $THREADS

FROM alpine:3.16

RUN apk add --no-cache pcre2 libcurl yaml-cpp tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

COPY --from=builder /src/subconverter/subconverter /usr/bin/
COPY --from=builder /src/subconverter/base /base/

WORKDIR /base
VOLUME ["/base/custom"]
EXPOSE 25500/tcp

CMD ["subconverter"]
