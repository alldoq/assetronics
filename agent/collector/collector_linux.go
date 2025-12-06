//go:build linux

package collector

import (
	"bufio"
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"os/user"
	"runtime"
	"strconv"
	"strings"
	"syscall"
	"time"
)

type LinuxCollector struct{}

func New() Collector {
	return &LinuxCollector{}
}

func (c *LinuxCollector) Collect() (*SystemInfo, error) {
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
		info.Username = os.Getenv("USER")
	} else {
		info.Username = currentUser.Username
	}

	// 3. Serial Number
	// Try /sys/class/dmi/id/product_serial first (cleanest, no external bin)
	serial, err := getLinuxSerialNumber()
	if err != nil {
		// If that fails (e.g. permissions), we could try dmidecode if running as root,
		// but usually if /sys is unreadable, dmidecode will be too.
		// For VMs/Containers, this often returns empty or error.
		info.SerialNumber = "UNKNOWN"
	} else {
		info.SerialNumber = serial
	}

	// 4. OS Version
	info.OS = getLinuxOSName()

	// 5. Network Info
	ip, mac, err := GetNetworkInfo()
	if err == nil {
		info.IPAddress = ip
		info.MACAddress = mac
	}

	// 6. Hardware Info
	info.Make = getFileContent("/sys/devices/virtual/dmi/id/sys_vendor")
	info.Model = getFileContent("/sys/devices/virtual/dmi/id/product_name")
	
	// CPU
	info.CPUModel, info.CPUCores = getLinuxCPUInfo()
	
	// RAM
	info.RAMGB = getLinuxRAMGB()

	// Disk
	diskTotal, diskFree, err := getDiskUsage("/")
	if err == nil {
		info.DiskTotalGB = int(diskTotal / (1024 * 1024 * 1024))
		info.DiskFreeGB = int(diskFree / (1024 * 1024 * 1024))
	}

	// 7. Installed Software
	info.InstalledSoftware = getLinuxInstalledSoftware()

	return info, nil
}

// getLinuxInstalledSoftware uses dpkg or rpm to list installed packages.
func getLinuxInstalledSoftware() []Software {
	softwareList := []Software{}

	// Try dpkg first (Debian/Ubuntu)
	cmd := exec.Command("dpkg", "-l")
	var out bytes.Buffer
	cmd.Stdout = &out
	err := cmd.Run()
	if err == nil {
		scanner := bufio.NewScanner(bytes.NewReader(out.Bytes()))
		for scanner.Scan() {
			line := scanner.Text()
			// Example: "ii  apache2  2.4.41-4ubuntu3.1  amd64  Apache HTTP Server"
			// We are looking for lines starting with "ii" or "hi" (installed)
			if strings.HasPrefix(line, "ii ") || strings.HasPrefix(line, "hi ") {
				fields := strings.Fields(line)
				if len(fields) >= 3 {
					name := fields[1]
					version := fields[2]
					softwareList = append(softwareList, Software{Name: name, Version: version})
				}
			}
		}
		return softwareList
	}

	// Fallback to rpm (RHEL/CentOS/Fedora)
	cmd = exec.Command("rpm", "-qa", "--queryformat", "%{NAME}|%{VERSION}|%{VENDOR}|%{INSTALLTIME}
")
	out.Reset()
	cmd.Stdout = &out
	err = cmd.Run()
	if err == nil {
		scanner := bufio.NewScanner(bytes.NewReader(out.Bytes()))
		for scanner.Scan() {
			line := scanner.Text()
			parts := strings.Split(line, "|")
			if len(parts) >= 4 {
				name := parts[0]
				version := parts[1]
				vendor := parts[2]
				installTime := parts[3] // Unix timestamp

				// Convert Unix timestamp to YYYY-MM-DD
				date := ""
				if ts, err := strconv.ParseInt(installTime, 10, 64); err == nil {
					date = time.Unix(ts, 0).Format("2006-01-02")
				}
				
				softwareList = append(softwareList, Software{Name: name, Version: version, Vendor: vendor, InstallDate: date})
			}
		}
		return softwareList
	}

	fmt.Printf("Warning: failed to get Linux software inventory: %v\n", err)
	return []Software{}
}

func getFileContent(path string) string {
	content, err := os.ReadFile(path)
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(content))
}

func getLinuxCPUInfo() (string, int) {
	f, err := os.Open("/proc/cpuinfo")
	if err != nil {
		return "Unknown", 1
	}
	defer f.Close()

	var modelName string
	cores := 0
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "model name") {
			parts := strings.Split(line, ":")
			if len(parts) > 1 {
				modelName = strings.TrimSpace(parts[1])
			}
			cores++
		}
	}
	if cores == 0 { cores = 1 }
	return modelName, cores
}

func getLinuxRAMGB() int {
	f, err := os.Open("/proc/meminfo")
	if err != nil {
		return 0
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "MemTotal:") {
			parts := strings.Fields(line)
			if len(parts) >= 2 {
				var kb int64
				fmt.Sscanf(parts[1], "%d", &kb)
				return int(kb / (1024 * 1024))
			}
		}
	}
	return 0
}

func getDiskUsage(path string) (uint64, uint64, error) {
	var stat syscall.Statfs_t
	err := syscall.Statfs(path, &stat)
	if err != nil {
		return 0, 0, err
	}
	total := stat.Blocks * uint64(stat.Bsize)
	free := stat.Bavail * uint64(stat.Bsize)
	return total, free, nil
}

func getLinuxSerialNumber() (string, error) {
	// Standard location for DMI data on Linux
	content, err := os.ReadFile("/sys/class/dmi/id/product_serial")
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(content)), nil
}

func getLinuxOSName() string {
	// Try /etc/os-release
	f, err := os.Open("/etc/os-release")
	if err != nil {
		return "Linux (Unknown Distro)"
	}
	defer f.Close()

	var prettyName, name string
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "PRETTY_NAME=") {
			prettyName = parseOsReleaseField(line)
		} else if strings.HasPrefix(line, "NAME=") {
			name = parseOsReleaseField(line)
		}
	}

	if prettyName != "" {
		return prettyName
	}
	if name != "" {
		return name
	}
	return "Linux"
}

func parseOsReleaseField(line string) string {
	parts := strings.SplitN(line, "=", 2)
	if len(parts) != 2 {
		return ""
	}
	// Remove quotes
	val := parts[1]
	val = strings.Trim(val, "\"")
	val = strings.Trim(val, "'")
	return val
}