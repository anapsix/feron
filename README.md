# Feron

Tool to retrieve Cloudflare Access logs via [LogPull API][logpull].

## Usage

```
Usage: ./feron [arguments]
    -z ID, --zone-id=ID              Cloudflare Zone ID, defaults to CF_ZONE_ID env value, if present
    -e EMAIL, --auth-email=EMAIL     Cloudflare Auth Email, defaults to CF_AUTH_EMAIL env value, if present
    -k KEY, --auth-key=KEY           Cloudflare Auth Key, defaults to CF_AUTH_KEY env value, if present
    -r RAYID, --rayid=RAYID          RayID to retrieve log event for. When present, percent, count, and start/end time are ignored
    -s PERCENT, --sample=PERCENT     Sample percentage (1% = 0.01), defaults to 0.01
    -c NUM, --count=NUM              Number of log events to retrieve, unset by default
    -f FIELDS, --fields=FIELDS       Comma delimited list of log event fields to include, defaults to whatever API returns by default, set to "all" for all available fields
    --start EPOCH                    Timestamp (inclusive) formatted as UNIX EPOCH, must be no more than 7 days back, defaults to 6 minutes ago
    --end EPOCH                      Timestamp (exclusive) formatted as UNIX EPOCH, must be at least 1 minute old, and later than --start, defaults to 1 minute ago
    --exclude-empty                  Exclude empty log fields, defaults to false
    -h, --help                       Show this help
    -v, --version                    Display version
    -d, --debug                      Enables debug output
```

> NOTE: when `-r RAYID, --rayid=RAYID` argument is used, `--start / --end`,
> `--count`. and `-s PERCENT, --sample=PERCENT` are ignored.

### Continuously retrieving logs

One can schedule continuous log retrieval, and store them in Elasticsearch for further analysis.
Or even deploy such process onto K8s cluster.
The [get-cloudflare-logs][get-cloudflare-logs] repo includes Docker image, and
Helm chart to do just that.


## Build

### Using Shards
```sh
shards build --releases
```

Compiled binary should be available in `./bin/feron`

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
[get-cloudflare-logs]: https://github.com/anapsix/get-cloudflare-logs

