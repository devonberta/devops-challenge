package main

import (
	"fmt"
	"flag"
	"log"
	"net/http"
	"strconv"
	"time"
)
// struct to represent configuration options and final values from flag options and defaults
type Server struct {
	port              		int
	host					string
	startupTime         	time.Time
	message           		string
	startupDelaySeconds   	time.Duration
	livenessDelaySeconds	time.Duration
	jobDuration       		time.Duration
}

func main() {
	// Flag statements with defaults for the application
	portPtr 				:= flag.Int("port", 8000, "Integer representing listening port of the service")
	hostPtr 				:= flag.String("host", "0.0.0.0", "string representing listening address of the service")
	messagePtr				:= flag.String("message", "Hello, World!", "string representing response on / page")
	startupDelaySecondsPtr	:= flag.Int("startupDelay", 15, "Integer representing seconds to wait for startup")
	livenessDelaySecondsPtr := flag.Int("livenessDelay", 15, "Integer representing seconds to wait for liveness")
	flag.Parse()
	// initialize serverConfig with defaults and values from the flags
	var serverConfig = &Server{
		port: *portPtr,
		host: *hostPtr,
		startupTime: time.Now(),
		message: *messagePtr,
		startupDelaySeconds: time.Duration(*startupDelaySecondsPtr) * time.Second,
		livenessDelaySeconds: time.Duration(*livenessDelaySecondsPtr) * time.Second,
	}
	// http path handlers, added startupProbe and livenessProbe for kubernetes health probes in helm chart
	http.HandleFunc("/startupProbe", serverConfig.startupProbe)
	http.HandleFunc("/livenessProbe", serverConfig.livenessProbe)
	http.HandleFunc("/", serverConfig.root)
	// Setting some timeouts for the server object to be started
	srv := &http.Server{
		Addr:         fmt.Sprintf("%s:%d", serverConfig.host, serverConfig.port),
		WriteTimeout: 15 * time.Second,
		ReadTimeout:  15 * time.Second,
	}
	// posting the listening interface
	fmt.Println((time.Now().Format("02/09/2006 15:04:05")) + " - [my-web-server] - [INFO]: Webserver listening: http://" + serverConfig.host + ":" + strconv.Itoa(serverConfig.port)+ "\n")
	log.Fatal(srv.ListenAndServe())
}

func (s *Server) startupProbe(w http.ResponseWriter, r *http.Request) {
	if time.Since(s.startupTime) > s.startupDelaySeconds {
		w.Header().Set("status", "200")
		fmt.Println(s.host + " - - [ " + (time.Now().Format("02/09/2006 15:04:05")) + " ] \"" + string(r.Method) + " / HTTP/1.1\" " + w.Header().Get("status") + " -")
	} else {
		w.Header().Set("status", "503")
		fmt.Println(s.host + " - - [ " + (time.Now().Format("02/09/2006 15:04:05")) + " ] \"" + string(r.Method) + " / HTTP/1.1\" " + w.Header().Get("status") + " -")
	}
}

func (s *Server) livenessProbe(w http.ResponseWriter, r *http.Request) {
	if time.Since(s.startupTime) > s.livenessDelaySeconds {
		w.Header().Set("status", "200")
		fmt.Println(s.host + " - - [ " + (time.Now().Format("02/09/2006 15:04:05")) + " ] \"" + string(r.Method) + " / HTTP/1.1\" " + w.Header().Get("status") + " -")
	} else {
		w.Header().Set("status", "503")
		fmt.Println(s.host + " - - [ " + (time.Now().Format("02/09/2006 15:04:05")) + " ] \"" + string(r.Method) + " / HTTP/1.1\" " + w.Header().Get("status") + " -")
	}
}

func (s *Server) root(w http.ResponseWriter, r *http.Request) {
	if time.Since(s.startupTime) > s.startupDelaySeconds {
		switch r.Method {
		case http.MethodGet:
			w.Header().Set("status", "200")
			w.Header().Set("Content-Type", "text/plain")
			fmt.Fprintf(w, s.message)
			fmt.Println(s.host + " - - [ " + (time.Now().Format("02/09/2006 15:04:05")) + " ] \"" + string(r.Method) + " / HTTP/1.1\" " + w.Header().Get("status") + " -")
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			fmt.Println(s.host + " - - [ " + (time.Now().Format("02/09/2006 15:04:05")) + " ] \"" + string(r.Method) + " / HTTP/1.1\" " + w.Header().Get("status") + " -")
		}
	} else {
		w.Header().Set("status", "503")
		fmt.Println(s.host + " - - [ " + (time.Now().Format("02/09/2006 15:04:05")) + " ] \"" + string(r.Method) + " / HTTP/1.1\" " + w.Header().Get("status") + " -")
	}
}