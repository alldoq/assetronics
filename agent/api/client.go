package api

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"assetronics-agent/collector"
	"assetronics-agent/config"
	"assetronics-agent/scanner"
)

type Client struct {
	Config *config.Config
	Client *http.Client
}

func New(cfg *config.Config) *Client {
	return &Client{
		Config: cfg,
		Client: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

type CheckInRequest struct {
	Hostname     string `json:"hostname"`
	Username     string `json:"username"`
	SerialNumber string `json:"serial_number"`
	OS           string `json:"os"`
	Platform     string `json:"platform"`
	IPAddress    string `json:"ip_address"`
	MACAddress   string `json:"mac_address"`
	Make         string `json:"make"`
	Model        string `json:"model"`
	CPUModel     string `json:"cpu_model"`
	CPUCores     int    `json:"cpu_cores"`
	RAMGB        int    `json:"ram_gb"`
	DiskTotalGB  int    `json:"disk_total_gb"`
	DiskFreeGB   int    `json:"disk_free_gb"`
	InstalledSoftware []collector.Software `json:"installed_software"`
}

func (c *Client) CheckIn(info *collector.SystemInfo) error {
	payload := CheckInRequest{
		Hostname:     info.Hostname,
		Username:     info.Username,
		SerialNumber: info.SerialNumber,
		OS:           info.OS,
		Platform:     info.Platform,
		IPAddress:    info.IPAddress,
		MACAddress:   info.MACAddress,
		Make:         info.Make,
		Model:        info.Model,
		CPUModel:     info.CPUModel,
		CPUCores:     info.CPUCores,
		RAMGB:        info.RAMGB,
		DiskTotalGB:  info.DiskTotalGB,
		DiskFreeGB:   info.DiskFreeGB,
		InstalledSoftware: info.InstalledSoftware,
	}

	jsonData, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %w", err)
	}

	url := fmt.Sprintf("%s/agent/checkin", c.Config.APIURL)
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	if c.Config.TenantID != "" {
		req.Header.Set("X-Tenant-ID", c.Config.TenantID)
	}
	// Add auth header if APIKey is present (future proofing)
	if c.Config.APIKey != "" {
		req.Header.Set("Authorization", "Bearer "+c.Config.APIKey)
	}

	resp, err := c.Client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send check-in request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("check-in failed with status: %d", resp.StatusCode)
	}

	return nil
}

func (c *Client) SendScanResults(result *scanner.ScanResult) error {
	jsonData, err := json.Marshal(result)
	if err != nil {
		return fmt.Errorf("failed to marshal scan result: %w", err)
	}

	url := fmt.Sprintf("%s/agent/scan", c.Config.APIURL)
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	if c.Config.TenantID != "" {
		req.Header.Set("X-Tenant-ID", c.Config.TenantID)
	}
	if c.Config.APIKey != "" {
		req.Header.Set("Authorization", "Bearer "+c.Config.APIKey)
	}

	resp, err := c.Client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send scan results: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("scan upload failed with status: %d", resp.StatusCode)
	}

	return nil
}
