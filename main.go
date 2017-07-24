package main

import (
	"flag"
	"log"
	"net/http"

	"github.com/swade1987/fotia/pkg"

	"github.com/prometheus/client_golang/prometheus"
)

var addr = flag.String("addr", ":8080", "The address to listen on for HTTP requests.")

func main() {
	flag.Parse()
	http.Handle("/metrics", prometheus.Handler())
	http.HandleFunc("/sleep", pkg.Sleep)
	http.HandleFunc("/down/", pkg.Down)
	http.HandleFunc("/up/", pkg.Up)
	log.Fatal(http.ListenAndServe(*addr, nil))
}
