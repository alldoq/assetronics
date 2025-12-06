# Hardware Discovery Methods for Assetronics

This document outlines the three primary strategies ("The 3-Legged Stool") for discovering and inventorying hardware assets within an organization.

## 1. Endpoint Agents (The "Deep Dive")
**Best for:** Laptops, Desktops, Servers (Windows, macOS, Linux).

*   **Mechanism:** A lightweight binary (Go, Rust, etc.) runs directly on the operating system.
*   **Data Quality:** ⭐⭐⭐⭐⭐ (Highest). Can access file systems, hardware registers, and real-time status.
*   **Deployment:** Installed via script, GPO, or manually by the user.
*   **Pros:**
    *   Works independently of network location (WFH, Coffee Shop).
    *   Can execute logic (e.g., "Delete this file", "Update this config").
    *   Real-time check-ins.
*   **Cons:** Requires installation and maintenance.

## 2. MDM / IDP Integration (The "Sanctioned Truth")
**Best for:** Managed Fleets (Corporate MacBooks, Corporate Windows Laptops), Mobile Devices (iOS, Android), Chromebooks.

*   **Mechanism:** Connecting via API to existing management platforms like Jamf Pro, Microsoft Intune, Google Workspace, or Kandji.
*   **Data Quality:** ⭐⭐⭐⭐ (High). Authoritative data from the management system.
*   **Deployment:** Zero deployment on devices. Pure cloud-to-cloud integration.
*   **Pros:**
    *   Instant visibility of all managed assets.
    *   No agent to install (uses the MDM's existing agent).
    *   Includes ownership and compliance data.
*   **Cons:**
    *   Blind to "Shadow IT" (unmanaged devices).
    *   Dependent on the 3rd party API limits and costs.

## 3. Network Discovery (The "Wide Net")
**Best for:** Unmanaged Infrastructure, IoT, Printers, Routers, Switches, "Shadow IT".

*   **Mechanism:** A "Scanner" appliance or software probe sits on a specific network subnet (e.g., the office network) and actively probes IP addresses.
*   **Techniques:**
    *   **Ping/ICMP:** "Is anyone there?"
    *   **Port Scanning (Nmap):** "What services are you running?" (Port 9100 = Printer).
    *   **SNMP:** "Tell me your details." (Standard for network gear).
*   **Data Quality:** ⭐⭐ to ⭐⭐⭐. Good for identification, poor for detailed configuration.
*   **Pros:**
    *   Finds everything connected to the wire.
    *   Agentless.
*   **Cons:**
    *   Blocked by firewalls.
    *   Limited by VLANs/Subnets (scanner needs visibility).
    *   Useless for remote/WFH employees not on VPN.

## Summary Strategy
For total coverage, Assetronics employs a hybrid approach:
1.  **MDM Integrations** first for rapid, high-value coverage of the main fleet.
2.  **Agents** for deep visibility on servers or critical workstations requiring detailed telemetry.
3.  **Network Scanners** for on-premise offices to catch printers and unmanaged hardware.
