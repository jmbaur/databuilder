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
	// spew.Dump(table)
	m.Tables = append(m.Tables, table)
	return nil
}

// TODO: split this method out into different pieces
func (m *Mocker) alterTable(alterStmt nodes.AlterTableStmt) error {
	idx := m.findTable(*alterStmt.Relation.Relname)
	if idx < 0 {
		return fmt.Errorf("table not found")
	}

	for _, v := range alterStmt.Cmds.Items {
		cmd, ok := v.(nodes.AlterTableCmd)
		if !ok {
			return fmt.Errorf("type assertion went bad to get alter table command")
		}

		switch cmd.Subtype {
		case nodes.AT_AddColumn:
			def := cmd.Def.(nodes.ColumnDef)
			m.Tables[idx].TableElts.Items = append(m.Tables[idx].TableElts.Items, def)
		case nodes.AT_DropColumn:
			columnIdx := m.findColumn(idx, *cmd.Name)
			if columnIdx < 0 && cmd.MissingOk {
				return nil
			} else if columnIdx < 0 {
				return fmt.Errorf("column to drop not found")
			}
			columns := m.Tables[idx].TableElts.Items
			m.Tables[idx].TableElts.Items = append(columns[:columnIdx], columns[columnIdx+1:]...)
		case nodes.AT_AddConstraint:
			constraint := cmd.Def.(nodes.Constraint)
			idxConstr := m.findConstraint(idx, *constraint.Conname)
			if idxConstr < 0 {
				m.Tables[idx].Constraints.Items = append(m.Tables[idx].Constraints.Items, constraint)
			} else {
				m.Tables[idx].Constraints.Items[idxConstr] = constraint
			}
		case nodes.AT_DropConstraint:
			idxConstr := m.findConstraint(idx, *cmd.Name)
			if idxConstr < 0 && cmd.MissingOk {
				return nil
			} else if idxConstr < 0 {
				return fmt.Errorf("could not find constraint")
			}
			constraints := m.Tables[idx].Constraints.Items
			m.Tables[idx].Constraints.Items = append(constraints[:idxConstr], constraints[idxConstr+1:]...)
		default:
			return fmt.Errorf("Alter table type not supported: %d\n", cmd.Subtype) // https://github.com/lfittl/pg_query_go/blob/master/nodes/alter_table_type.go
		}

	}

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

func (m *Mocker) findColumn(tableIdx int, columnName string) int {
	idx := -1
	columns := m.Tables[tableIdx].TableElts.Items
	for i, item := range columns {
		column, ok := item.(nodes.ColumnDef)
		if !ok {
			// might be a constraint `nodes.Constraint`
			return -1
		}
		if *column.Colname == columnName {
			idx = i
		}
	}
	return idx
}

func (m *Mocker) findConstraint(tableIdx int, conName string) int {
	idx := -1
	constraints := m.Tables[tableIdx].Constraints.Items
	for i, constr := range constraints {
		c := constr.(nodes.Constraint)
		if *c.Conname == conName {
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
