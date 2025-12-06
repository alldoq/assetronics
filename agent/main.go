package main

import (
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"assetronics-agent/api"
	"assetronics-agent/collector"
	"assetronics-agent/config"
	"assetronics-agent/scanner"
)

func main() {
	cfg := config.Load()
	apiClient := api.New(cfg)

	// Determine platform-specific collector
	sysCollector := collector.New()

	if cfg.TenantID == "" {
		log.Fatal("Error: Tenant ID is required. Please provide it via -tenant flag or ASSETRONICS_TENANT env var.")
	}

	log.Printf("Assetronics Agent starting...")
	log.Printf("Platform: %s", collector.GetPlatform())
	log.Printf("Tenant: %s", cfg.TenantID)
	log.Printf("API URL: %s", cfg.APIURL)

	if cfg.ScanRange != "" {
		log.Printf("Mode: Network Scanner")
		log.Printf("Target Range: %s", cfg.ScanRange)
		
		results, err := scanner.Scan(cfg.ScanRange)
		if err != nil {
			log.Fatalf("Scan failed: %v", err)
		}
		log.Printf("Scan complete. Found %d devices.", len(results.Devices))
		
		if err := apiClient.SendScanResults(results); err != nil {
			log.Fatalf("Failed to upload scan results: %v", err)
		}
		log.Printf("Results uploaded successfully.")
		return
	}

	log.Printf("Mode: Endpoint Agent")
	log.Printf("Check-in Interval: %d seconds", cfg.Interval)

	// Perform initial check-in
	if err := performCheckIn(sysCollector, apiClient); err != nil {
		log.Printf("Error during initial check-in: %v", err)
	} else {
		log.Printf("Initial check-in successful")
	}

	// Setup ticker for periodic check-ins
	ticker := time.NewTicker(time.Duration(cfg.Interval) * time.Second)
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	for {
		select {
		case <-ticker.C:
			if err := performCheckIn(sysCollector, apiClient); err != nil {
				log.Printf("Error during check-in: %v", err)
			} else {
				log.Printf("Check-in successful")
			}
		case <-quit:
			ticker.Stop()
			log.Println("Agent stopping...")
			return
		}
	}
}

func performCheckIn(c collector.Collector, client *api.Client) error {
	info, err := c.Collect()
	if err != nil {
		return fmt.Errorf("collection failed: %w", err)
	}

	// Log what we found (debug)
	// log.Printf("Collected: %+v", info)

	if err := client.CheckIn(info); err != nil {
		return fmt.Errorf("api check-in failed: %w", err)
	}

	return nil
}
