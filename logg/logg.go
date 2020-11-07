package logg

import (
	"fmt"

	"github.com/fatih/color"
)

func main() {
	fmt.Println("vim-go")
}

const (
	Info = iota
	Warn
	Fatal
)

func Printf(level int, format string, v ...interface{}) {
	var col color.Attribute
	var prefix string
	switch level {
	case Info:
		col = color.FgBlue
		prefix = "INFO"
	case Warn:
		col = color.FgYellow
		prefix = "WARN"
	case Fatal:
		col = color.FgRed
		prefix = "FAIL"
	default:
		col = color.FgWhite
	}
	color.Set(col)
	fmt.Printf(prefix + " ")
	color.Unset()
	fmt.Printf(format, v...)
}
