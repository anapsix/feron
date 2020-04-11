## this stage installs everything required to build the project
FROM alpine:3.11 as build
RUN apk add alpine-sdk crystal shards zlib-static libressl-dev upx
WORKDIR /tmp
COPY ./src/feron.cr /tmp
RUN \
    crystal build --static feron.cr && \
    upx /tmp/feron

## this stage created final docker image
FROM alpine:3.11 as release
COPY --from=build /tmp/feron /feron
USER nobody
ENTRYPOINT [ "/feron" ]
CMD [ "--help" ]
