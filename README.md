# go-exporter
Export generic GO metrics to monitor any container in Prometheus via Consul. Useful to monitor container health for services without native Prometheus support.

It also offers the /service-name endpoint used in custom consul health checks
It's default port is set to 9132 via a env variable in the ge-ubuntu-base image. It can be overridden by setting the GO_EXPORTER_PORT environment variable in the dockerfile of you application.


Maintainer: Christoph Heuwieser, Julian Daweke, Niels Oldenburg

# Dockerfile
```
RUN curl -s https://api.github.com/repos/Germanedge/go-exporter/releases/latest \
    | grep "browser_download_url.*\.tar\.gz" \
    | cut -d ":" -f 2,3 \
    | tr -d \" \
    | tr -d " " \
    | xargs -I{} curl {} -Lo go-exporter.tar.gz \
    && tar -xzf go-exporter.tar.gz -C /usr/bin/ \
    && chmod +x /usr/bin/go-exporter \
    && rm -f go-exporter.tar.gz
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

