FROM golang:1.20.4 as build

RUN mkdir -p /go/src/go-exporter
WORKDIR /go/src/go-exporter

COPY go.mod .
COPY main.go .

RUN go get germanedge.com/go-exporter

RUN CGO_ENABLED=0 go build -a -installsuffix cgo --ldflags "-s -w" -o /usr/bin/go-exporter

