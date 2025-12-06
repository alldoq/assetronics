//go:build windows

package collector

import (
	"bytes"
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"os/exec"
	"os/user"
	"runtime"
	"strings"
)

type WindowsCollector struct{}

func New() Collector {
	return &WindowsCollector{}
}

func (c *WindowsCollector) Collect() (*SystemInfo, error) {
	info := &SystemInfo{
		Platform: runtime.GOOS,
	}

	// 1. Hostname
	hostname, err := os.Hostname()
	if err != nil {
		return nil, fmt.Errorf("failed to get hostname: %w", err)
	}
	info.Hostname = hostname

	// 2. Username
	currentUser, err := user.Current()
	if err != nil {
		info.Username = os.Getenv("USERNAME")
	} else {
		info.Username = currentUser.Username
	}

	// 3. Serial Number (wmic)
	serial, err := getWindowsSerialNumber()
	if err != nil {
		fmt.Printf("Warning: failed to get serial number: %v\n", err)
		info.SerialNumber = "UNKNOWN"
	} else {
		info.SerialNumber = serial
	}

	// 4. OS Version (wmic or ver)
	osVer, err := getWindowsOSName()
	if err != nil {
		info.OS = "Windows (Unknown Version)"
	} else {
		info.OS = osVer
	}

	// 5. Network Info
	ip, mac, err := GetNetworkInfo()
	if err == nil {
		info.IPAddress = ip
		info.MACAddress = mac
	}

	// 6. Hardware Info
	// For Windows we stick to wmic for now to avoid cgo/syscall complexity for prototype
	info.Make = getWmic("csproduct", "vendor")
	info.Model = getWmic("csproduct", "name")
	info.CPUModel = getWmic("cpu", "name")
	info.CPUCores = getWmicInt("cpu", "NumberOfCores")
	
	// RAM (Capacity is in bytes)
	ramBytes := getWmicInt64("memorychip", "Capacity") 
	// Note: wmic memorychip returns multiple rows for multiple sticks. 
	// This simple helper only grabs the first one. For full total we need to sum.
	// Let's do a slightly better job for RAM:
	info.RAMGB = getWindowsTotalRAM()

	// Disk
	info.DiskTotalGB, info.DiskFreeGB = getWindowsDiskInfo()

	// 7. Installed Software
	info.InstalledSoftware = getWindowsInstalledSoftware()

	return info, nil
}

// getWindowsInstalledSoftware uses wmic to list installed software.
func getWindowsInstalledSoftware() []Software {
	cmd := exec.Command("wmic", "product", "get", "Name,Version,Vendor,InstallDate", "/format:csv")
	var out bytes.Buffer
	cmd.Stdout = &out
	err := cmd.Run()
	if err != nil {
		fmt.Printf("Warning: failed to get Windows software: %v\n", err)
		return []Software{}
	}

	softwareList := []Software{}
	reader := csv.NewReader(bytes.NewReader(out.Bytes()))
	records, err := reader.ReadAll()
	if err != nil {
		fmt.Printf("Warning: failed to parse Windows software CSV: %v\n", err)
		return []Software{}
	}

	if len(records) < 2 { // Expect header and at least one data row
		return []Software{}
	}
	
	header := records[0]
	nameIdx, versionIdx, vendorIdx, installDateIdx := -1, -1, -1, -1

	for i, col := range header {
		switchedCol := strings.TrimSpace(col)
		switch switchedCol {
		case "Name":
			nameIdx = i
		case "Version":
			versionIdx = i
		case "Vendor":
			vendorIdx = i
		case "InstallDate":
			installDateIdx = i
		}
	}

	for _, record := range records[1:] {
		if len(record) > int(math.Max(float64(nameIdx), math.Max(float64(versionIdx), math.Max(float64(vendorIdx), float64(installDateIdx))))) && nameIdx != -1 {
			name := strings.TrimSpace(record[nameIdx])
			if name == "" { continue }

			version := ""
			if versionIdx != -1 { version = strings.TrimSpace(record[versionIdx]) }

			vendor := ""
			if vendorIdx != -1 { vendor = strings.TrimSpace(record[vendorIdx]) }

			installDate := ""
			if installDateIdx != -1 { installDate = strings.TrimSpace(record[installDateIdx]) }

			softwareList = append(softwareList, Software{
				Name: name,
				Version: version,
				Vendor: vendor,
				InstallDate: installDate,
			})
		}
	}

	return softwareList
}

func getWmic(alias, property string) string {
	cmd := exec.Command("wmic", alias, "get", property)
	var out bytes.Buffer
	cmd.Stdout = &out
	err := cmd.Run()
	if err != nil {
		return ""
	}
	lines := strings.Split(out.String(), "\n")
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed != "" && !strings.Contains(strings.ToLower(trimmed), strings.ToLower(property)) {
			return trimmed
		}
	}
	return ""
}

func getWmicInt(alias, property string) int {
	valStr := getWmic(alias, property)
	var val int
	fmt.Sscanf(valStr, "%d", &val)
	return val
}

func getWmicInt64(alias, property string) int64 {
	valStr := getWmic(alias, property)
	var val int64
	fmt.Sscanf(valStr, "%d", &val)
	return val
}

func getWindowsTotalRAM() int {
	// wmic computersystem get TotalPhysicalMemory
	cmd := exec.Command("wmic", "computersystem", "get", "TotalPhysicalMemory")
	var out bytes.Buffer
	cmd.Stdout = &out
	err := cmd.Run()
	if err != nil { return 0 }
	
	lines := strings.Split(out.String(), "\n")
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed != "" && !strings.Contains(line, "TotalPhysicalMemory") {
			var bytes int64
			fmt.Sscanf(trimmed, "%d", &bytes)
			return int(bytes / (1024 * 1024 * 1024))
		}
	}
	return 0
}

func getWindowsDiskInfo() (int, int) {
	// wmic logicaldisk where "DeviceID='C:'" get Size,FreeSpace
	cmd := exec.Command("wmic", "logicaldisk", "where", "DeviceID='C:'", "get", "Size,FreeSpace")
	var out bytes.Buffer
	cmd.Stdout = &out
	err := cmd.Run()
	if err != nil { return 0, 0 }

	// Output:
	// FreeSpace     Size
	// 52702781440   255465201664
	lines := strings.Split(out.String(), "\n")
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed != "" && !strings.Contains(line, "FreeSpace") {
			parts := strings.Fields(trimmed)
			if len(parts) >= 2 {
				var free, size int64
				fmt.Sscanf(parts[0], "%d", &free)
				fmt.Sscanf(parts[1], "%d", &size)
				return int(size / (1024*1024*1024)), int(free / (1024*1024*1024))
			}
		}
	}
	return 0, 0
}

func getWindowsSerialNumber() (string, error) {
	// wmic bios get serialnumber
	cmd := exec.Command("wmic", "bios", "get", "serialnumber")
	var out bytes.Buffer
	cmd.Stdout = &out
	err := cmd.Run()
	if err != nil {
		return "", err
	}

	// Output format is usually:
	// SerialNumber
	// XXXXXXXX

	lines := strings.Split(out.String(), "\n")
	for _, line := range lines {
		rimmed := strings.TrimSpace(line)
		if trimmed != "" && !strings.Contains(strings.ToLower(trimmed), "serialnumber") {
			return trimmed, nil
		}
	}
	return "", fmt.Errorf("serial number not found")
}

func getWindowsOSName() (string, error) {
	// wmic os get caption
	cmd := exec.Command("wmic", "os", "get", "Caption")
	var out bytes.Buffer
	cmd.Stdout = &out
	err := cmd.Run()
	if err != nil {
		return "", err
	}

	lines := strings.Split(out.String(), "\n")
	for _, line := range lines {
		rimmed := strings.TrimSpace(line)
		if trimmed != "" && !strings.Contains(strings.ToLower(trimmed), "caption") {
			return trimmed, nil
		}
	}
	return "Windows", nil
}
