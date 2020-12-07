package cmd

import (
	"bytes"
	"database/sql"
	"flag"
	"fmt"
	"io"
	"log"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"

	_ "github.com/lib/pq" // sql driver

	"github.com/jmbaur/databuilder/config"
	"github.com/jmbaur/databuilder/mock"
)

// Execute is the entrypoint of the program
func Execute() {
	log.SetOutput(os.Stderr)

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
	if err != nil {
		log.Printf("continuing without config file: %v\n", err)
	}
	cfg := config.Parse(cfgFile)

	// get reader for SQL schema
	var reader io.Reader
	args := flag.Args()
	if len(args) == 0 {
		cmd := exec.Command("pg_dump", "-s", *connection)
		output, err := cmd.Output()
		if err != nil {
			log.Fatalf("failed to execute '%s': %v\n", cmd, err)
		}
		reader = bytes.NewReader(output)
	} else if flag.Args()[0] == "-" {
		reader = os.Stdin
	} else {
		schemaInputArg := flag.Args()[0]
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
		if err := os.Remove(fullPath); err != nil {
			log.Printf("failed to remove file %s: %v\n", fullPath, err)
		}
		file, err := os.Create(fullPath)
		if err != nil {
			log.Fatalf("unable to create file %s: %v\n", fullPath, err)
		}
		writer = file
	}
	defer func() {
		if err := writer.Close(); err != nil {
			log.Printf("failed to close writer: %v\n", err)
		}
	}()

	// get connection to database
	parsedURL, err := url.Parse(*connection)
	if err != nil {
		log.Fatalf("could not parse connection string %s: %v\n", *connection, err)
	}
	//////////////////////////////////////////////////////////////////////////////////////////////////////
	// pq defaults sslmode=require, should we explicitly add sslmode=disable to the connection string arg?
	// v := parsedURL.Query()
	// v.Set("sslmode", "disable")
	// parsedURL.RawQuery = v.Encode()
	//////////////////////////////////////////////////////////////////////////////////////////////////////
	connStr := fmt.Sprint(parsedURL)

	conn, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatalf("unable to connect to database at %s: %v\n", *connection, err)
	}
	defer func() {
		if err := conn.Close(); err != nil {
			log.Printf("failed to close database connection: %v\n", err)
		}
	}()

	// schema := mock.Parse(reader, &cfg)
	mock.Parse(reader, &cfg)

	// spew.Dump(schema)
	os.Exit(1)

	// queryChan := make(chan db.Query)
	// resultChan := make(chan db.Result)
	// insertChan := make(chan db.Record)

	// go mock.Mock(queryChan, resultChan, insertChan, schema)
	// go db.ListenForQueries(queryChan, resultChan)
	// db.Insert(insertChan, conn, writer)
}
