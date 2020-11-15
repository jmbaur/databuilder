package mocker

import (
	"fmt"

	nodes "github.com/lfittl/pg_query_go/nodes"
)

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
			columns := m.Tables[idx].TableElts.Items
			m.Tables[idx].TableElts.Items = append(columns, def)
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

func (m *Mocker) dropTable(tableName string) error {
	idx := m.findTable(tableName)
	if idx < 0 {
		return fmt.Errorf("table not found")
	}
	m.Tables = append(m.Tables[:idx], m.Tables[idx+1:]...)
	return nil
}

func (m *Mocker) createEnum(enum nodes.CreateEnumStmt) error {
	m.Enums = append(m.Enums, enum)
	return nil
}

func (m *Mocker) findEnum(name string) int {
	idx := -1
	for i, enum := range m.Enums {
		for _, v := range enum.TypeName.Items {
			str, ok := v.(nodes.String)
			if !ok {
				continue
			}
			if str.Str == name {
				idx = i
			}
		}
	}
	return idx
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
		if !ok { // is of type `nodes.Constraint`
			continue
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

func (m *Mocker) dropEnum(name string) error {
	idx := m.findEnum(name)
	if idx < 0 {
		return fmt.Errorf("Could not find enum %s", name)
	} else {
		enums := m.Enums
		m.Enums = append(enums[:idx], enums[idx+1:]...)
	}
	return nil
}
