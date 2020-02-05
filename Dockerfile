FROM golang:latest as build

RUN mkdir -p /go/src/go-exporter
WORKDIR /go/src/go-exporter

RUN go get -d github.com/gorilla/mux && \
	go get -d github.com/prometheus/client_golang/prometheus

COPY main.go . 

RUN CGO_ENABLED=0 go build -a -installsuffix cgo --ldflags "-s -w" -o /usr/bin/go-exporter
