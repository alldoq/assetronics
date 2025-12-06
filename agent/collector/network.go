package collector

import (
	"fmt"
	"net"
)

// GetNetworkInfo returns the primary IP and MAC address
func GetNetworkInfo() (string, string, error) {
	interfaces, err := net.Interfaces()
	if err != nil {
		return "", "", err
	}

	for _, iface := range interfaces {
		// Skip loopback and down interfaces
		if iface.Flags&net.FlagLoopback != 0 || iface.Flags&net.FlagUp == 0 {
			continue
		}

		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}

		for _, addr := range addrs {
			// Check if it's an IP network
			if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
				if ipnet.IP.To4() != nil {
					// Found a valid IPv4 address
					return ipnet.IP.String(), iface.HardwareAddr.String(), nil
				}
			}
		}
	}
	return "", "", fmt.Errorf("no active network interface found")
}
