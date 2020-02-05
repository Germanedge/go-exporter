# go-exporter
Export generic GO metrics to monitor container

# Dockerfile
```
RUN curl -s https://api.github.com/repos/Germanedge/go-exporter/releases/latest \
    | grep "browser_download_url.*\.tar\.gz" \
    | cut -d ":" -f 2,3 \
    | tr -d \" \
    | wget -qi - \
    && tar -xf go-exporter.tar.gz -C /usr/bin/ \
    && chmod +x /usr/bin/go-exporter \
    && rm -f go-exporter.tar.gz
```

# entrypointwrapper
```
go-exporter -port 8080 #Choose a port of your liking
```
