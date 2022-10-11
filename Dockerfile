FROM golang:1.19.2 as build

RUN mkdir -p /go/src/go-exporter
WORKDIR /go/src/go-exporter

#RUN go get -u github.com/gorilla/mux && \
#RUN	go install github.com/prometheus/client_golang/prometheus@latest

COPY go.mod .
COPY main.go .

RUN go get germanedge.com/go-exporter
#RUN     go install github.com/prometheus/client_golang/prometheus@latest

RUN CGO_ENABLED=0 go build -a -installsuffix cgo --ldflags "-s -w" -o /usr/bin/go-exporter

