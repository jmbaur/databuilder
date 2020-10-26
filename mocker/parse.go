package mocker

import (
	"fmt"
	"io"
	"io/ioutil"
	"log"

	pg_query "github.com/lfittl/pg_query_go"
	nodes "github.com/lfittl/pg_query_go/nodes"
)

// Parse uses the io.Reader to parse SQL statements and make the AST
func (m *Mocker) Parse(input io.Reader) {
	data, err := ioutil.ReadAll(input)
	if err != nil {
		log.Fatalf("Could not read from stdin: %v\n", err)
	}
	tree, err := pg_query.Parse(string(data))
	if err != nil {
		log.Fatalf("Could not parse SQL: %v\n", err)
	}

	for _, v := range tree.Statements {
		stmt, ok := v.(nodes.RawStmt)
		if !ok {
			log.Fatal(fmt.Errorf("Could not parse statement: %s", v))
		}
		switch stmt.Stmt.(type) {
		case nodes.CreateStmt:
			create := stmt.Stmt.(nodes.CreateStmt)
			m.createTable(create, create.IfNotExists)
		case nodes.CreateEnumStmt:
			enum := stmt.Stmt.(nodes.CreateEnumStmt)
			var name string
			for _, v := range enum.TypeName.Items {
				enumName, ok := v.(nodes.String)
				if !ok {
					log.Printf("Could not use type assertion for pg_query.String, actual type: %T\n", v)
				}
				name = enumName.Str
			}
			var vals []string
			for _, v := range enum.Vals.Items {
				enumVal, ok := v.(nodes.String)
				if !ok {
					log.Printf("Could not use type assertion for pg_query.String, actual type: %T\n", v)
				}
				vals = append(vals, enumVal.Str)
			}
			err := m.createEnums(name, vals)
			if err != nil {
				log.Printf("Could not create enum %s: %v\n", name, err)
			}
		case nodes.InsertStmt:
			insert := stmt.Stmt.(nodes.InsertStmt)
			err := m.dropTable(*insert.Relation.Relname, false)
			if err != nil {
				log.Printf("Could not drop table \"%s\": %v\n", *insert.Relation.Relname, err)
			}
		case nodes.DropStmt:
			drop := stmt.Stmt.(nodes.DropStmt)
			for _, v := range drop.Objects.Items {
				list, ok := v.(nodes.List)
				if !ok {
					// TODO implement
					// log.Printf("Could not use type assertion for pg_query.List, actual type: %T\n", v)
					continue
				}
				for _, w := range list.Items {
					dropName, ok := w.(nodes.String)
					if !ok {
						// TODO implement
						// log.Printf("Could not use type assertion for pg_query.String, actual type: %T\n", w)
						continue
					}
					err := m.dropTable(dropName.Str, drop.MissingOk)
					if err != nil {
						log.Printf("Could not drop table \"%s\": %v\n", dropName.Str, err)
					}
				}
			}
		case nodes.AlterTableStmt:
			alter := stmt.Stmt.(nodes.AlterTableStmt)
			fmt.Println("alter", *alter.Relation.Relname)
		default:
			continue
		}
	}
}
