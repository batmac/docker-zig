FROM --platform=$BUILDPLATFORM perl:slim AS getter-zig
WORKDIR /
ARG TARGETPLATFORM
RUN apt-get update && apt-get install --no-install-recommends -y wget xz-utils
COPY get.pl *.xz ./
# ADD http://worldclockapi.com/api/json/utc/now builddate
RUN ./get.pl $TARGETPLATFORM

FROM --platform=$BUILDPLATFORM alpine:edge AS getter
RUN apk add --no-cache git

FROM --platform=$BUILDPLATFORM getter AS getter-zig.vim
RUN  mkdir -p /tmp/.vim/pack/plugins/start/ \
		 && cd /tmp/.vim/pack/plugins/start/ \
		 && git clone https://github.com/ziglang/zig.vim

FROM --platform=$BUILDPLATFORM getter AS getter-gyro
RUN git clone https://github.com/mattnite/gyro

FROM --platform=$BUILDPLATFORM getter AS getter-zigmod
RUN git clone https://github.com/batmac/zigmod --recursive

FROM --platform=$BUILDPLATFORM getter AS getter-zls
RUN git clone --recurse-submodules https://github.com/zigtools/zls


FROM alpine:edge AS zig
COPY --from=getter-zig /tag/zig /usr/bin/zig
COPY --from=getter-zig /tag/lib /usr/lib/

FROM zig AS builder
RUN apk add --no-cache git


FROM builder AS gyro
COPY --from=getter-gyro /gyro /gyro
WORKDIR /gyro
RUN zig build -Drelease-safe

FROM builder AS zigmod
COPY --from=getter-zigmod /zigmod /zigmod
WORKDIR /zigmod
RUN zig build -Dbootstrap && ./zig-out/bin/zigmod fetch && zig build

FROM builder AS zls
COPY --from=getter-zls /zls /zls
WORKDIR /zls
RUN zig build -Drelease-safe

FROM zig
RUN apk add --no-cache vim
COPY --from=getter-zig.vim /tmp/.vim /root/.vim
COPY --from=gyro /gyro/zig-out/bin/gyro /usr/bin/gyro
COPY --from=zigmod /zigmod/zig-out/bin/zigmod /usr/bin/zigmod
COPY --from=zls /zls/zig-out/bin/zls /usr/bin/zls

