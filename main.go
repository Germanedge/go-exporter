package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"

	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func init() {
	//Metrics have to be registered to be exposed:
	//Example:
	//prometheus.MustRegister(cpuTemp)
	//prometheus.MustRegister(hdFailures)
}

func main() {
	portPtr := flag.Int("port", 8080, "Port Number")
	flag.Parse()
	// The Handler function provides a default handler to expose metrics
	// via an HTTP server. "/metrics" is the usual endpoint for that.
	http.Handle("/metrics", promhttp.Handler())
	log.Fatal(http.ListenAndServe(fmt.Sprintf("%s%d", ":", *portPtr), nil))
}
