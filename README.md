# go-exporter
Export generic GO metrics to monitor any container in Prometheus via Consul. Useful to monitor container health for services without native Prometheus support.

It also offers the /service-name endpoint used in custom consul health checks
It's default port is set to 9132 via a env variable in the ge-ubuntu-base image. It can be overridden by setting the GO_EXPORTER_PORT environment variable in the dockerfile of you application.

Maintainer: Christoph Heuwieser, Julian Daweke, Ferdinand Ritter

# Usage in Dockerfile

Insert go-exporter via multistage build

```
FROM germanedge-docker.artifactory.new-solutions.com/edge-one/go-exporter:0.5.0 AS go-exporter

FROM  ...

COPY --from=go-exporter /usr/bin/go-exporter /usr/bin/
RUN chmod +x /usr/bin/go-exporter
```

# entrypointwrapper
```
go-exporter -port 8080 & #Choose a port of your liking
```

# consul.json
```
{
    "service": {
        "meta": {
            "scrape_path": "/metrics",
            "scrape_port": "8080",
        }
    }
}
```

