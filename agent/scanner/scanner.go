package scanner

import (
	"fmt"
	"net"
	"os/exec"
	"runtime"
	"strings"
	"sync"
	"time"
)

type Device struct {
	IP       string   `json:"ip"`
	Hostname string   `json:"hostname"`
	Mac      string   `json:"mac"` // MAC is hard to get without ARP table access or root, might skip for now or use ARP cli
	Ports    []int    `json:"open_ports"`
	Vendor   string   `json:"vendor"` // Can be inferred from MAC OUI if we had it
	Status   string   `json:"status"` // "online"
}

type ScanResult struct {
	Range   string   `json:"range"`
	Devices []Device `json:"devices"`
}

// Scan performs a network scan on the given CIDR
func Scan(cidr string) (*ScanResult, error) {
	ip, ipnet, err := net.ParseCIDR(cidr)
	if err != nil {
		return nil, fmt.Errorf("invalid CIDR: %v", err)
	}

	var ips []string
	for ip := ip.Mask(ipnet.Mask); ipnet.Contains(ip); inc(ip) {
		ips = append(ips, ip.String())
	}

	// Remove network and broadcast addresses (simple heuristic: first and last)
	if len(ips) > 2 {
		ips = ips[1 : len(ips)-1]
	}

	results := make(chan Device, len(ips))
	var wg sync.WaitGroup

	// Worker pool pattern could be better, but for /24 (254 IPs), straight goroutines are "okay" in Go.
	// Limiting concurrency is safer.
	semaphore := make(chan struct{}, 50) // Max 50 concurrent scans

	for _, targetIP := range ips {
		wg.Add(1)
		go func(ip string) {
			defer wg.Done()
			semaphore <- struct{}{} // Acquire
			defer func() { <-semaphore }() // Release

			if isReachable(ip) {
				d := Device{
					IP:     ip,
					Status: "online",
				}
				
				// Resolve Hostname
				names, _ := net.LookupAddr(ip)
				if len(names) > 0 {
					d.Hostname = strings.TrimSuffix(names[0], ".")
				}

				// Scan common ports to guess type
				d.Ports = scanPorts(ip)
				
				results <- d
			}
		}(targetIP)
	}

	go func() {
		wg.Wait()
		close(results)
	}()

	foundDevices := []Device{}
	for d := range results {
		foundDevices = append(foundDevices, d)
	}

	return &ScanResult{
		Range:   cidr,
		Devices: foundDevices,
	}, nil
}

func inc(ip net.IP) {
	for j := len(ip) - 1; j >= 0; j-- {
		ip[j]++
		if ip[j] > 0 {
			break
		}
	}
}

func isReachable(ip string) bool {
	// 1. Try simple Ping
	if ping(ip) {
		return true
	}
	// 2. Fallback: Try a quick TCP connect to common ports (80, 443, 135, 445)
	// Some firewalls block ICMP but allow SMB/HTTP
	ports := []int{80, 443, 135, 445, 22}
	for _, p := range ports {
		if checkPort(ip, p) {
			return true
		}
	}
	return false
}

func ping(ip string) bool {
	var cmd *exec.Cmd
	
	switch runtime.GOOS {
	case "windows":
		cmd = exec.Command("ping", "-n", "1", "-w", "500", ip)
	case "darwin":
		cmd = exec.Command("ping", "-c", "1", "-W", "500", ip) // -W is in ms on some macOS pings? No, usually ms. wait.. macOS ping -W is ms? man ping says -W wait time in ms.
		// Actually macOS ping -W is milliseconds? Let's check. man says: -W waittime. "Time in milliseconds to wait for a reply".
		// But BSD ping -W is usually in ms. Linux ping -W is seconds. 
		// To be safe, standard timeout 1 second.
		cmd = exec.Command("ping", "-c", "1", "-t", "1", ip) 
	default: // Linux
		cmd = exec.Command("ping", "-c", "1", "-W", "1", ip) // -W in seconds
	}

	err := cmd.Run()
	return err == nil
}

func scanPorts(ip string) []int {
	var open []int
	// Common ports for fingerprinting
	targets := []int{21, 22, 23, 80, 443, 445, 3389, 8080, 9100} // 9100 = printer
	
	for _, p := range targets {
		if checkPort(ip, p) {
			open = append(open, p)
		}
	}
	return open
}

func checkPort(ip string, port int) bool {
	address := fmt.Sprintf("%s:%d", ip, port)
	conn, err := net.DialTimeout("tcp", address, 500*time.Millisecond)
	if err != nil {
		return false
	}
	conn.Close()
	return true
}
