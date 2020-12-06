package main

import (
	"fmt"
	"time"
)

func main() {
	insertChan := make(chan string)
	queryChan := make(chan string)
	resultChan := make(chan string)

	go mock(insertChan, queryChan, resultChan)
	go query(queryChan, resultChan)
	insert(insertChan)
}

// creates the mock records
func mock(insertChan, queryChan, resultChan chan string) {
	for i := 0; i < 10; i++ {
		queryChan <- fmt.Sprintf("query %d", i)
		results := <-resultChan
		fmt.Println("result", results)
		insertChan <- fmt.Sprintf("%d%s%d%s", i, "This is the ", i, " message")
		time.Sleep(1 * time.Second)
	}
}

// inserts records into the database and closes the chan when the requested amount is done being made
func insert(insertChan chan string) {
	for r := range insertChan {
		fmt.Println("insert", r[1:])
		i := int(r[0] - '0')
		if i == 2 {
			close(insertChan)
		}
	}
}

// keeps a local cache of results
func query(queryChan, resultChan chan string) {
	for q := range queryChan {
		fmt.Println("query", q)
		resultChan <- fmt.Sprintf("result for %s", q)
	}
}
