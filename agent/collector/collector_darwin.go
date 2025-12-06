//go:build darwin

package collector

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"os/user"
	"runtime"
	"strings"
	"syscall"
)

type DarwinCollector struct{}

func New() Collector {
	return &DarwinCollector{}
}

func (c *DarwinCollector) Collect() (*SystemInfo, error) {
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
		// Fallback to env var if user.Current fails
		info.Username = os.Getenv("USER")
	} else {
		info.Username = currentUser.Username
	}

	// 3. Serial Number (ioreg)
	serial, err := getMacOSSerialNumber()
	if err != nil {
		fmt.Printf("Warning: failed to get serial number: %v\n", err)
		info.SerialNumber = "UNKNOWN"
	} else {
		info.SerialNumber = serial
	}

	// 4. OS Version (sw_vers)
	osVer, err := getMacOSVersion()
	if err != nil {
		info.OS = "macOS (Unknown Version)"
	} else {
		info.OS = "macOS " + osVer
	}

	// 5. Network Info
	ip, mac, err := GetNetworkInfo()
	if err == nil {
		info.IPAddress = ip
		info.MACAddress = mac
	}

	// 6. Hardware Info
	info.Make = "Apple"
	info.Model = getSysctl("hw.model")
	info.CPUModel = getSysctl("machdep.cpu.brand_string")
	info.CPUCores = getSysctlInt("hw.ncpu")
	
	memBytes := getSysctlInt64("hw.memsize")
	info.RAMGB = int(memBytes / (1024 * 1024 * 1024))

	// Disk info (root volume)
	diskTotal, diskFree, err := getDiskUsage("/")
	if err == nil {
		info.DiskTotalGB = int(diskTotal / (1024 * 1024 * 1024))
		info.DiskFreeGB = int(diskFree / (1024 * 1024 * 1024))
	}

	// 7. Installed Software
	info.InstalledSoftware = getMacOSInstalledSoftware()

	return info, nil
}

// getMacOSInstalledSoftware uses system_profiler to list applications.
func getMacOSInstalledSoftware() []Software {
	cmd := exec.Command("system_profiler", "SPApplicationsDataType", "-json")
	var out bytes.Buffer
	cmd.Stdout = &out
	err := cmd.Run()
	if err != nil {
		fmt.Printf("Warning: failed to get macOS software: %v\n", err)
		return []Software{}
	}

	var result struct {
		SPApplicationsDataType []struct {
			Path        string `json:"_path"`
			Version     string `json:"version"`
			LastModified string `json:"lastModified,omitempty"`
			Name        string `json:"info"` // This field usually contains the human-readable name
			// Other fields like 'obtained_from', 'kind' can be added if needed
		}
	}

	if err := json.Unmarshal(out.Bytes(), &result); err != nil {
		fmt.Printf("Warning: failed to parse macOS software JSON: %v\n", err)
		return []Software{}
	}

	softwareList := []Software{}
	for _, app := range result.SPApplicationsDataType {
		// Extract a cleaner name from the path if 'info' is not ideal
		name := app.Name
		if name == "" {
			// Fallback: extract from path, e.g., "/Applications/Firefox.app" -> "Firefox"
			parts := strings.Split(app.Path, "/")
			if len(parts) > 0 {
				lastPart := parts[len(parts)-1]
				name = strings.TrimSuffix(lastPart, ".app")
			}
		}
		if name == "" { continue }

		softwareList = append(softwareList, Software{
			Name: name,
			Version: app.Version,
			// Vendor is not directly available via system_profiler in a consistent field
			// InstallDate could be mapped from LastModified if desired
		})
	}
	return softwareList
}

func getSysctl(key string) string {
	cmd := exec.Command("sysctl", "-n", key)
	out, err := cmd.Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out))
}

func getSysctlInt(key string) int {
	valStr := getSysctl(key)
	var val int
	fmt.Sscanf(valStr, "%d", &val)
	return val
}

func getSysctlInt64(key string) int64 {
	valStr := getSysctl(key)
	var val int64
	fmt.Sscanf(valStr, "%d", &val)
	return val
}

func getDiskUsage(path string) (uint64, uint64, error) {
	var stat syscall.Statfs_t
	err := syscall.Statfs(path, &stat)
	if err != nil {
		return 0, 0, err
	}
	// Available blocks * size per block = available space in bytes
	// Note: Bsize on Darwin is strictly usually correct, but Bavail is blocks available to non-root
	total := stat.Blocks * uint64(stat.Bsize)
	free := stat.Bavail * uint64(stat.Bsize)
	return total, free, nil
}

func getMacOSSerialNumber() (string, error) {
	// ioreg -l | grep IOPlatformSerialNumber
	cmd := exec.Command("ioreg", "-c", "IOPlatformExpertDevice", "-d", "2")
	var out bytes.Buffer
	cmd.Stdout = &out
	err := cmd.Run()
	if err != nil {
		return "", err
	}

	output := out.String()
	lines := strings.Split(output, "\n")
	for _, line := range lines {
		if strings.Contains(line, "IOPlatformSerialNumber") {
			parts := strings.Split(line, "=")
			if len(parts) >= 2 {
				serial := strings.TrimSpace(parts[1])
				serial = strings.Trim(serial, "\"")
				return serial, nil
			}
		}
	}
	return "", fmt.Errorf("serial number not found in ioreg output")
}

func getMacOSVersion() (string, error) {
	cmd := exec.Command("sw_vers", "-productVersion")
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(output)), nil
}
