FROM golang:1.27.3 as build

RUN mkdir -p /go/src/go-exporter
WORKDIR /go/src/go-exporter

COPY go.mod .
COPY main.go .

RUN go get germanedge.com/go-exporter

RUN CGO_ENABLED=0 go build -a -installsuffix cgo --ldflags "-s -w" -o /usr/bin/go-exporter

# Final stage: ship only the static binary. The golang build stage inherits
# buildpack-deps (curl, openssh-client, git, ...) and is discarded here, so none
# of its OS-level CVEs reach the published image.
FROM scratch
COPY --from=build /usr/bin/go-exporter /usr/bin/go-exporter
