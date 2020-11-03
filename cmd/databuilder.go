package cmd

import (
	"fmt"
	"os"

	"github.com/jmbaur/databuilder/mocker"
)

func Execute() {
	m := mocker.New("tmp")
	m.Parse(os.Stdin)
	fmt.Println(len(m.Tables))
	fmt.Println(len(m.Enums))
}
