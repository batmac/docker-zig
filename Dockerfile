FROM --platform=$BUILDPLATFORM perl:slim AS getter
WORKDIR /
ARG TARGETPLATFORM
RUN apt-get update && apt-get install --no-install-recommends -y wget xz-utils
COPY get.pl *.xz ./
ADD http://worldclockapi.com/api/json/utc/now builddate
RUN ./get.pl $TARGETPLATFORM

FROM alpine:edge
COPY --from=getter /tag/zig /usr/bin/zig
COPY --from=getter /tag/lib /usr/lib/

#FROM zig AS builder
#RUN apk add --no-cache git wget

#FROM builder AS zigmod
#RUN git clone https://github.com/nektro/zigmod --recursive
#RUN cd zigmod && zig build -Dbootstrap && ./zig-out/bin/zigmod fetch

#FROM builder AS gyro
#RUN git clone https://github.com/mattnite/gyro.git && cd gyro && zig build -Drelease-safe
