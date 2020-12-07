package mock

import (
	"fmt"

	nodes "github.com/lfittl/pg_query_go/nodes"
)

func (s Schema) createTable(create nodes.CreateStmt) (*nodes.CreateStmt, error) {
	_, exists := s.Tables[*create.Relation.Relname]
	if exists {
		var err error
		if !create.IfNotExists {
			err = fmt.Errorf("table '%s' already exists", *create.Relation.Relname)
		}
		return nil, err
	}
	return &create, nil
}

func (s Schema) alterTable(alter nodes.AlterTableStmt) (*nodes.CreateStmt, error) {
	tablename := *alter.Relation.Relname
	createStmt, exists := s.Tables[tablename]
	if !exists {
		var err error
		if !alter.MissingOk {
			err = fmt.Errorf("table '%s' does not exist", tablename)
		}
		return nil, err
	}

	for _, v := range alter.Cmds.Items {
		cmd, _ := v.(nodes.AlterTableCmd)

		switch cmd.Subtype {
		case nodes.AT_AddConstraint:
			constraint := cmd.Def.(nodes.Constraint)
			// If we are not using pg_dump provided schema, we should check whether the constraint already exists
			// idxConstr := s.findConstraint(tablename, *constraint.Conname)
			// if idxConstr < 0 {
			// 	s.Tables[tablename].Constraints.Items = append(s.Tables[tablename].Constraints.Items, constraint)
			// } else {
			// 	s.Tables[tablename].Constraints.Items[idxConstr] = constraint
			// }
			createStmt.Constraints.Items = append(createStmt.Constraints.Items, constraint)
			// 		// case nodes.AT_DropConstraint:
			// 		// 	idxConstr := s.findConstraint(idx, *cmd.Name)
			// 		// 	if idxConstr < 0 && cmd.MissingOk {
			// 		// 		return nil
			// 		// 	} else if idxConstr < 0 {
			// 		// 		return fmt.Errorf("could not find constraint")
			// 		// 	}
			// 		// 	constraints := s.Tables[idx].Constraints.Items
			// 		// 	s.Tables[idx].Constraints.Items = append(constraints[:idxConstr], constraints[idxConstr+1:]...)
			// 		// case nodes.AT_AddColumn:
			// 		// columns := s.Tables[tablename].TableElts.Items
			// 		// s.Tables[tablename].TableElts.Items = append(columns, def)
			// 		// case nodes.AT_DropColumn:
			// 		// 	columnIdx := s.findColumn(idx, *cmd.Name)
			// 		// 	if columnIdx < 0 && cmd.MissingOk {
			// 		// 		return nil
			// 		// 	} else if columnIdx < 0 {
			// 		// 		return fmt.Errorf("column to drop not found")
			// 		// 	}
			// 		// 	columns := s.Tables[idx].TableElts.Items
			// 		// 	s.Tables[idx].TableElts.Items = append(columns[:columnIdx], columns[columnIdx+1:]...)
			// 		// default:
			// 		// 	log.Printf("Alter table type not supported: %d (https://github.com/lfittl/pg_query_go/blob/master/nodes/alter_table_type.go)\n", cmd.Subtype)
		}
	}
	return &createStmt, nil
}

// func dropTable(tableName string) error {
// 	idx := s.findTable(tableName)
// 	if idx < 0 {
// 		return fmt.Errorf("table not found")
// 	}
// 	s.Tables = append(s.Tables[:idx], s.Tables[idx+1:]...)
// 	return nil
// }

// func createEnum(enum nodes.CreateEnumStmt) error {
// 	s.Enums = append(s.Enums, enum)
// 	return nil
// }

// func findEnum(name string) int {
// 	idx := -1
// 	for i, enum := range s.Enums {
// 		for _, v := range enus.TypeName.Items {
// 			str, ok := v.(nodes.String)
// 			if !ok {
// 				continue
// 			}
// 			if str.Str == name {
// 				idx = i
// 			}
// 		}
// 	}
// 	return idx
// }

// func findTable(tableName string) int {
// 	idx := -1
// 	for i, table := range s.Tables {
// 		if *table.Relation.Relname == tableName {
// 			idx = i
// 		}
// 	}
// 	return idx
// }

// func findColumn(tableIdx int, columnName string) int {
// 	idx := -1
// 	columns := s.Tables[tableIdx].TableElts.Items
// 	for i, item := range columns {
// 		column, ok := ites.(nodes.ColumnDef)
// 		if !ok { // is of type `nodes.Constraint`
// 			continue
// 		}
// 		if *column.Colname == columnName {
// 			idx = i
// 		}
// 	}
// 	return idx
// }

func (s *Schema) findConstraint(tablename, constrName string) int {
	idx := -1
	constraints := s.Tables[tablename].Constraints.Items
	for i, constr := range constraints {
		c := constr.(nodes.Constraint)
		if *c.Conname == constrName {
			idx = i
		}
	}
	return idx
}

// func dropEnum(name string) error {
// 	idx := s.findEnum(name)
// 	if idx < 0 {
// 		return fmt.Errorf("Could not find enum %s", name)
// 	} else {
// 		enums := s.Enums
// 		s.Enums = append(enums[:idx], enums[idx+1:]...)
// 	}
// 	return nil
// }
