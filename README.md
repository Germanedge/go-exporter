# id-exporter

# Dockerfile
```
RUN curl -s https://api.github.com/repos/Germanedge/id-exporter/releases/latest \
    | grep "browser_download_url.*\.tar\.gz" \
    | cut -d ":" -f 2,3 \
    | tr -d \" \
    | tr -d " " \
    | xargs -I{} curl {} -Lo id-exporter.tar.gz \
    && tar -xzf id-exporter.tar.gz -C /usr/bin/ \
    && chmod +x /usr/bin/id-exporter \
    && rm -f id-exporter.tar.gz
```

# entrypointwrapper
```
id-exporter -port 8080 & #Choose a port of your liking
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

