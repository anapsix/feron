## this stage installs everything required to build the project
FROM crystallang/crystal:1.0.0-alpine as build
RUN apk add openssl-dev openssl-libs-static zlib-static upx
WORKDIR /tmp
COPY ./src/feron.cr /tmp
RUN \
    crystal build --static feron.cr && \
    upx /tmp/feron

## this stage created final docker image
FROM alpine:3.13 as release
COPY --from=build /tmp/feron /usr/local/bin/feron
USER nobody
ENTRYPOINT [ "/usr/local/bin/feron" ]
CMD [ "--help" ]

## this stage installs everything required to build the project
# FROM crystallang/crystal:1.0.0 as build
# RUN apt-get update && apt-get install zlib1g-dev upx
# WORKDIR /tmp
# COPY ./src/feron.cr /tmp
# RUN \
#     crystal build feron.cr && \
#     upx /tmp/feron

# ## this stage created final docker image
# FROM alpine:3.13 as release
# COPY --from=build /tmp/feron /usr/local/bin/feron
# USER nobody
# ENTRYPOINT [ "/usr/local/bin/feron" ]
# CMD [ "--help" ]

