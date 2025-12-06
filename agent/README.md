# Assetronics Agent

This is the lightweight agent for macOS and Windows that automatically discovers system information and reports it to the Assetronics backend.

## Building

### macOS
```bash
go build -o assetronics-agent-mac main.go
```

### Windows (Cross-compile from macOS/Linux)
```bash
GOOS=windows GOARCH=amd64 go build -o assetronics-agent.exe main.go
```

### Linux (Cross-compile from macOS/Windows)
```bash
GOOS=linux GOARCH=amd64 go build -o assetronics-agent-linux main.go
```

## Running

The agent requires a Tenant ID (the "slug" of the company) to report correctly.

### macOS
```bash
# Run once (good for testing)
./assetronics-agent-mac -tenant=acme -url=http://localhost:4000/api/v1

# Run in background (production-like)
export ASSETRONICS_TENANT=acme
./assetronics-agent-mac &
```

### Windows
```powershell
assetronics-agent.exe -tenant=acme -url=http://localhost:4000/api/v1
```

### Linux
```bash
# Run once (good for testing)
./assetronics-agent-linux -tenant=acme -url=http://localhost:4000/api/v1

# Run in background (production-like)
export ASSETRONICS_TENANT=acme
./assetronics-agent-linux &
```

**Note on Linux Serial Number Discovery:**
On some Linux systems (especially containers or environments without DMI access), the serial number might be reported as "UNKNOWN" if `/sys/class/dmi/id/product_serial` is not readable. Future enhancements could include `dmidecode` (requires root privileges) as a fallback.


## Configuration

Configuration can be provided via flags or environment variables:

| Flag | Env Var | Description | Default |
|------|---------|-------------|---------|
| `-tenant` | `ASSETRONICS_TENANT` | **Required.** The Tenant ID/Slug. | "" |
| `-url` | `ASSETRONICS_URL` | Base URL of the Assetronics API. | `http://localhost:4000/api/v1` |
| `-interval` | `_` | Check-in interval in seconds. | 3600 (1 hour) |
