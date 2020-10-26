package mocker

import (
	"fmt"

	nodes "github.com/lfittl/pg_query_go/nodes"
)

type enum struct {
	name string
	vals []string
}

// Mocker is used for parsing SQL statements as well as mocking data
type Mocker struct {
	DBConStr string
	Tables   []nodes.CreateStmt
	Enums    []enum
}

var tables []nodes.CreateStmt
var enums []enum

// New initializes a Mocker object for use with parsing SQL statements
func New(conStr string) *Mocker {
	return &Mocker{
		DBConStr: conStr,
	}
}

// CreateTable adds a table to the mocker slice that will be mocked after all
// table definitions have been initialized and after all table alterations
// have been read.
func (m *Mocker) createTable(table nodes.CreateStmt, ifNotExists bool) error {
	idx := m.findTable(*table.Relation.Relname)
	if idx >= 0 && ifNotExists {
		return nil
	}
	if idx >= 0 && !ifNotExists {
		return fmt.Errorf("table already exists")
	}
	m.Tables = append(m.Tables, table)
	return nil
}

// DropTable removes the table from the tables slice. It should be used when
// the "DROP" statement is made or when an "INSERT INTO" statement is made.
func (m *Mocker) dropTable(tableName string, missingOk bool) error {
	idx := m.findTable(tableName)
	if idx < 0 && missingOk {
		return nil
	}
	if idx < 0 {
		return fmt.Errorf("table not found")
	}
	m.Tables = append(m.Tables[:idx], m.Tables[idx+1:]...)
	return nil
}

// CreateEnums adds an enum type to the mocker slice that will be mocked after
// all SQL definitions have been read.
func (m *Mocker) createEnums(enumName string, enumVals []string) error {
	newEnum := enum{name: enumName, vals: enumVals}
	idx := m.findEnum(enumName)
	if idx < 0 {
		m.Enums = append(m.Enums, newEnum)
	} else {
		m.Enums[idx] = newEnum
	}
	return nil
}

func (m *Mocker) findTable(tableName string) int {
	idx := -1
	for i, table := range m.Tables {
		if *table.Relation.Relname == tableName {
			idx = i
		}
	}
	return idx
}

func (m *Mocker) findEnum(enumName string) int {
	idx := -1
	for i, enum := range m.Enums {
		if enum.name == enumName {
			idx = i
		}
	}
	return idx
}