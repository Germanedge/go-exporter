package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"encoding/json"
)

func init() {
	//Metrics have to be registered to be exposed:
	//Example:
	//prometheus.MustRegister(cpuTemp)
	//prometheus.MustRegister(hdFailures)
}

func handleRequest(w http.ResponseWriter, r *http.Request) {
	response := map[string]string{"name": "myname"}
	json.NewEncoder(w).Encode(response)
}

func main() {
	portPtr := flag.Int("port", 9131, "Port Number")
	flag.Parse()
	// The Handler function provides a default handler to expose metrics
	// via an HTTP server. "/metrics" is the usual endpoint for that.
	http.Handle("/service-name", handleRequest)
	log.Fatal(http.ListenAndServe(fmt.Sprintf("%s%d", ":", *portPtr), nil))
}
