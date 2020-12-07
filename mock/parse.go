package mock

import (
	"io"
	"io/ioutil"
	"log"

	"github.com/jmbaur/databuilder/config"
	pg_query "github.com/lfittl/pg_query_go"
	nodes "github.com/lfittl/pg_query_go/nodes"
)

// Schema is the reduced pg_query_go AST
type Schema struct {
	Tables map[string]nodes.CreateStmt
	Enums  map[string]nodes.CreateEnumStmt
}

// Parse uses the io.Reader to parse SQL statements and make the AST
func Parse(input io.Reader, cfg *config.Config) *Schema {
	data, err := ioutil.ReadAll(input)
	if err != nil {
		log.Fatalf("could not read from stdin: %v\n", err)
	}

	root, err := pg_query.Parse(string(data))
	if err != nil {
		log.Fatalf("could not parse SQL: %v\n", err)
	}

	scm := &Schema{Tables: make(map[string]nodes.CreateStmt), Enums: make(map[string]nodes.CreateEnumStmt)}

	for _, v := range root.Statements {
		stmt, ok := v.(nodes.RawStmt)
		if !ok {
			log.Fatalf("could not parse statement %v\n", v)
		}

		switch stmt.Stmt.(type) {
		case nodes.CreateStmt:
			create := stmt.Stmt.(nodes.CreateStmt)
			tablename := *create.Relation.Relname
			createStmt, err := scm.createTable(create)
			if err != nil {
				log.Printf("could not add table '%s' to schema\n", tablename)
				continue
			}
			scm.Tables[tablename] = *createStmt
		case nodes.AlterTableStmt:
			alter := stmt.Stmt.(nodes.AlterTableStmt)
			tablename := *alter.Relation.Relname
			createStmtAltered, err := scm.alterTable(alter)
			if err != nil {
				log.Printf("could not alter table '%s' in schema: %v\n", tablename, err)
				continue
			}
			scm.Tables[tablename] = *createStmtAltered
		case nodes.InsertStmt:
			// table is being seeded, don't create any fake data for it
			insert := stmt.Stmt.(nodes.InsertStmt)
			tablename := *insert.Relation.Relname
			delete(scm.Tables, tablename)
			// 	case nodes.DropStmt:
			// 		drop := stmt.Stmt.(nodes.DropStmt)
			// 		switch drop.RemoveType {
			// 		case nodes.OBJECT_EXTENSION:
			// 			continue
			// 		case nodes.OBJECT_TABLE:
			// 			for _, v := range drop.Objects.Items {
			// 				list, ok := v.(nodes.List)
			// 				if !ok {
			// 					continue
			// 				}
			// 				for _, w := range list.Items {
			// 					str, ok := w.(nodes.String)
			// 					if !ok {
			// 						continue
			// 					}
			// 					if err := m.dropTable(str.Str); err != nil && !drop.MissingOk {
			// 						log.Printf("Could not drop table \"%s\": %v\n", str.Str, err)
			// 					}
			// 				}
			// 			}
			// 		case nodes.OBJECT_TYPE:
			// 			for _, item := range drop.Objects.Items {
			// 				typename, ok := item.(nodes.TypeName)
			// 				if !ok {
			// 					continue
			// 				}
			// 				for _, item := range typename.Names.Items {
			// 					str, ok := item.(nodes.String)
			// 					if !ok {
			// 						continue
			// 					}
			// 					if err := m.dropEnum(str.Str); err != nil && !drop.MissingOk {
			// 						log.Printf("Could not drop enum \"%s\": %v\n", str.Str, err)
			// 					}
			// 				}
			// 			}
			// 		default:
			// 			continue
			// 		}
			// 	case nodes.CreateEnumStmt:
			// 		enum := stmt.Stmt.(nodes.CreateEnumStmt)
			// 		if err := m.createEnum(enum); err != nil {
			// 			log.Printf("Could not create enum: %v\n", err)
			// 		}
			// 	default:
			// 		continue
		}
	}

	return scm
}
