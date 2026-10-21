FROM golang:1.27.3 as build

WORKDIR /go/src/go-exporter

# Resolve dependencies from the reviewed lockfile only. -mod=readonly makes the
# build fail when go.mod/go.sum are out of date instead of silently rewriting
# them, so the shipped binary is built from the dependency set that was reviewed.
ENV GOFLAGS=-mod=readonly

COPY go.mod go.sum ./
RUN go mod download

COPY main.go .

RUN CGO_ENABLED=0 go build -a -installsuffix cgo --ldflags "-s -w" -o /usr/bin/go-exporter

# Final stage: ship only the static binary. The golang build stage inherits
# buildpack-deps (curl, openssh-client, git, ...) and is discarded here, so none
# of its OS-level CVEs reach the published image.
FROM scratch
COPY --from=build /usr/bin/go-exporter /usr/bin/go-exporter
