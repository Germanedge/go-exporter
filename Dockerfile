FROM golang:1.20.5 as build

RUN mkdir -p /go/src/id-exporter
WORKDIR /go/src/id-exporter

COPY go.mod .
COPY main.go .

RUN go get germanedge.com/id-exporter

RUN CGO_ENABLED=0 go build -a -installsuffix cgo --ldflags "-s -w" -o /usr/bin/id-exporter

