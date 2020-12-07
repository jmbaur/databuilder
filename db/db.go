package db

import (
	"database/sql"
	"fmt"
	"io"
)

// Query defines a database call for foreign key references
type Query struct {
	Table  string
	Column string
}

// Result gets returned from a query
type Result []interface{}

// Record gets passed from the Mocker to the Inserter
type Record struct {
	Table        string
	Amount       int
	ColumnValues map[string]interface{}
}

func (q *Query) String() string {
	return fmt.Sprintf("SELECT %s FROM %s ORDER BY random() LIMIT 1;", q.Column, q.Table)
}

func (r *Record) String() (str string) {
	str += ";"
	return
}

// ListenForQueries receives queries and sends results for foreign key references
func ListenForQueries(queryChan <-chan Query, resultChan chan<- Result) {

}

// Insert makes database calls, keeps track of when record insertion fails or
// succeeds, writes successful insertions to the writer, and closes the
// insertion channel when the requested amount of records is reached.
func Insert(insertChan chan Record, conn *sql.DB, writer io.Writer) {

}
