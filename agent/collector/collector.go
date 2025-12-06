package collector

import (
	"runtime"
)

type SystemInfo struct {
	Hostname        string `json:"hostname"`
	Username        string `json:"username"`
	SerialNumber    string `json:"serial_number"`
	OS              string `json:"os"`
	Platform        string `json:"platform"`
	IPAddress       string `json:"ip_address"`
	MACAddress      string `json:"mac_address"`
	Make            string `json:"make"`
	Model           string `json:"model"`
	CPUModel        string `json:"cpu_model"`
	CPUCores        int    `json:"cpu_cores"`
	RAMGB           int    `json:"ram_gb"`
	DiskTotalGB     int    `json:"disk_total_gb"`
	DiskFreeGB      int    `json:"disk_free_gb"`
	InstalledSoftware []Software `json:"installed_software"`
}

type Software struct {
	Name         string `json:"name"`
	Version      string `json:"version,omitempty"`
	Vendor       string `json:"vendor,omitempty"`
	InstallDate  string `json:"install_date,omitempty"`
}

type Collector interface {
	Collect() (*SystemInfo, error)
}

func GetPlatform() string {
	return runtime.GOOS
}
