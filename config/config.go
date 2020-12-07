package config

import (
	"io"
	"io/ioutil"
	"log"

	"gopkg.in/yaml.v2"
)

// Config contains tables
type Config struct {
	Tables []Table `yaml:"tables"`
}

// Table contains configurable options on how to create the mock data
type Table struct {
	Name          string   `yaml:"name"`
	Ignore        bool     `yaml:"ignore"`
	Amount        int      `yaml:"amount"`
	MajorEntities []string `yaml:"major_entities"`
	Columns       []Column `yaml:"columns"`
}

// Column contains mock-specific data for a given column
type Column struct {
	Name     string   `yaml:"name"`
	MockType string   `yaml:"mock_type"`
	Prefix   []string `yaml:"prefix"`
	Suffix   []string `yaml:"suffix"`
	Min      int      `yaml:"min"`
	Max      int      `yaml:"max"`
}

// Parse returns a Config struct to be used in the mocking process
func Parse(reader io.Reader) Config {
	var cfg Config
	data, err := ioutil.ReadAll(reader)
	if err != nil {
		log.Fatalf("failed to read config data: %v\n", err)
	}
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		log.Fatalf("failed to unmarshal config file: %v\n", err)
	}
	return cfg
}
