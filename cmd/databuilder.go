package cmd

import (
	"os"

	"github.com/jmbaur/databuilder/mocker"
)

func Execute() {
	m := mocker.New("tmp")
	m.Parse(os.Stdin)
}
