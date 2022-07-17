FROM alpine:20220715 as build
WORKDIR /
RUN apk add --no-cache git build-base cmake python3 \
    && git clone https://github.com/ziglang/zig-bootstrap
RUN cd /zig-bootstrap && ./build -j4 native-linux-musl baseline
RUN find out