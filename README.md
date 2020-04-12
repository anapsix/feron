# Feron

Tool to retrieve Cloudflare Access logs via [LogPull API][logpull].

## Usage

```
Usage: feron [arguments]
    -z ID, --zone-id=ID              Cloudflare Zone ID, defaults to CF_ZONE_ID env value, if present
    -e EMAIL, --auth-email=EMAIL     Cloudflare Auth Email, defaults to CF_AUTH_EMAIL env value, if present
    -k KEY, --auth-key=KEY           Cloudflare Auth Key, defaults to CF_AUTH_KEY env value, if present
    -s PERCENT, --sample=PERCENT     Sample percentage (1% = 0.01), defaults to 0.01
    -c NUM, --count=NUM              Number of log events to retrieve, unset by default
    -f FIELDS, --fields=FIELDS       Comma delimited list of log event fields to include, defaults to whatever API returns by default, set to "all" for all available fields
    --start EPOCH                    Timestamp (inclusive) formatted as UNIX EPOCH, must be no more than 7 days back, defaults to 6 minutes ago
    --end EPOCH                      Timestamp (exclusive) formatted as UNIX EPOCH, must be at least 1 minute old, and later than --start, defaults to 1 minute ago
    --exclude-empty                  Exclude empty log fields, defaults to false
    -h, --help                       Show this help
    -v, --version                    Display version
```


## Build

### Locally, for your platform/arch
```sh
crystal build -o ./releases/feron ./src/feron.cr
```

### Everything, including Docker image

When launched on macOS, the following builds binary for Darwin, as well as linux/amd64, placing binaries to `./releases`
```sh
make all
```

[ Link Reference ]::
[logpull]: https://developers.cloudflare.com/logs/logpull-api/

