package cmd

import (
	"database/sql"
	"flag"
	"fmt"
	"io"
	"log"
	"net/url"
	"os"
	"path/filepath"

	_ "github.com/lib/pq"

	"github.com/jmbaur/databuilder/config"
)

// Execute is the entrypoint of the program
func Execute() {
	connection := flag.String("connection", "postgres://localhost:5432", "Connection string to database")
	configFile := flag.String("config", "mock.yml", "Path to config file")
	outFile := flag.String("out", "", "Path to output file")
	flag.Parse()

	// get config file
	cfgFullPath, err := filepath.Abs(*configFile)
	if err != nil {
		log.Fatalf("could not get full path to config file %s: %v\n", *configFile, err)
	}
	cfgFile, err := os.Open(cfgFullPath)
	cfg := config.Parse(cfgFile)

	// get reader for SQL schema
	args := flag.Args()
	if len(args) != 1 {
		log.Fatalln("did not specify where to read schema from")
	}
	schemaInputArg := flag.Args()[0]

	var reader io.Reader
	if schemaInputArg == "-" {
		reader = os.Stdin
	} else {
		fullPath, err := filepath.Abs(schemaInputArg)
		if err != nil {
			log.Fatalf("could not get full path to schema file %s: %v\n", schemaInputArg, err)
		}
		file, err := os.Open(fullPath)
		if err != nil {
			log.Fatalf("could not open schema file %s: %v\n", fullPath, err)
		}
		reader = file
	}

	// get writer for SQL statements
	var writer io.WriteCloser
	if outFile == nil {
		writer = os.Stdout
	} else {
		fullPath, err := filepath.Abs(*outFile)
		if err != nil {
			log.Fatalf("could not get full path for file %s: %v\n", *outFile, err)
		}
		os.Remove(fullPath)
		file, err := os.Create(fullPath)
		if err != nil {
			log.Fatalf("unable to create file %s: %v\n", fullPath, err)
		}
		writer = file
	}
	defer writer.Close()

	// get connection to database
	parsedURL, err := url.Parse(*connection)
	if err != nil {
		log.Fatalf("could not parse connection string %s: %v\n", *connection, err)
	}
	// pq defaults sslmode=require, should we explicitly add sslmode=disable to the connection string arg?
	// v := parsedURL.Query()
	// v.Set("sslmode", "disable")
	// parsedURL.RawQuery = v.Encode()
	connStr := fmt.Sprint(parsedURL)

	conn, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatalf("unable to connect to database at %s: %v\n", *connection, err)
	}
	defer conn.Close()

	rows, err := conn.Query("SELECT now()")
	if err != nil {
		log.Fatal("failed to query database: ", err)
	}
	defer rows.Close()
	for rows.Next() {
		var date string
		rows.Scan(&date)
		fmt.Printf("%+v\n", date)
	}

	fmt.Println("IGNORE")
	fmt.Println(cfg, reader)

	// insertChan := make(chan db.Record)
	// queryChan := make(chan string)
	// done := make(chan bool)

	// mock.Mock(reader, cfg)
	// go db.WriteRecords(conn)
	// go func() {
	// 	for {
	// 		<-done
	// 	}
	// }()

	// m.Mock(writer)
}
