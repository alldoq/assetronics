package config

import (
	"flag"
	"os"
)

type Config struct {
	APIURL     string
	APIKey     string
	TenantID   string
	Interval   int // Seconds between check-ins
	ScanRange  string // CIDR to scan (e.g. 192.168.1.0/24)
}

func Load() *Config {
	cfg := &Config{}

	flag.StringVar(&cfg.APIURL, "url", getEnv("ASSETRONICS_URL", "http://localhost:4000/api/v1"), "Assetronics API URL")
	flag.StringVar(&cfg.APIKey, "key", getEnv("ASSETRONICS_KEY", ""), "Agent API Key") // For future auth
	flag.StringVar(&cfg.TenantID, "tenant", getEnv("ASSETRONICS_TENANT", ""), "Tenant ID/Slug") 
	flag.IntVar(&cfg.Interval, "interval", 3600, "Check-in interval in seconds")
	flag.StringVar(&cfg.ScanRange, "scan", "", "Network Scan CIDR (e.g. 192.168.1.0/24). If set, runs in Scanner mode.")

	flag.Parse()

	return cfg
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}
