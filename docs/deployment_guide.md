# Assetronics Deployment & Configuration Guide

Complete guide for deploying Assetronics ITAM platform to production.

## Table of Contents

1. [System Requirements](#1-system-requirements)
2. [AI Inference - Ollama Setup](#2-ai-inference---ollama-setup)
3. [PDF Processing Tools](#3-pdf-processing-tools)
4. [Environment Configuration](#4-environment-configuration)
5. [Integration Credentials](#5-integration-credentials)
6. [Worker Configuration](#6-worker-configuration)
7. [Deployment Options](#7-deployment-options)
8. [Security & Best Practices](#8-security--best-practices)
9. [Monitoring & Troubleshooting](#9-monitoring--troubleshooting)

---

## 1. System Requirements

### Backend Server

- **OS**: Ubuntu 22.04 LTS or macOS (for development)
- **RAM**: Minimum 4GB (8GB+ recommended for Ollama)
- **CPU**: 2+ cores (4+ recommended for Ollama)
- **Disk**: 20GB+ free space (additional 10GB+ for Ollama models)
- **Network**: Outbound HTTPS access to integration APIs

### Database

- **PostgreSQL**: 14.0 or higher
- **RAM**: 2GB+ dedicated
- **Disk**: 50GB+ with auto-scaling

### Required Software

- Elixir 1.15+ & Erlang/OTP 26+
- PostgreSQL 14+
- Node.js 18+ & npm (for frontend)
- Docker (optional, recommended)

---

## 2. AI Inference - Ollama Setup

Ollama is required for AI-powered invoice parsing. It runs a local LLM (llama3) to extract structured data from invoice PDFs.

### Installation

**Docker (Recommended)**:
```bash
docker run -d \
  --name ollama \
  --restart unless-stopped \
  -p 11434:11434 \
  -v ollama_models:/root/.ollama \
  ollama/ollama:latest
```

**Native Installation (Linux)**:
```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Start Ollama service
sudo systemctl start ollama
sudo systemctl enable ollama

# Verify
curl http://localhost:11434/api/version
```

**macOS**:
```bash
# Download from https://ollama.com/download
# Or via Homebrew:
brew install ollama

# Start Ollama
brew services start ollama
```

### Download llama3 Model

```bash
# Pull the llama3 model (approx 4.7GB)
ollama pull llama3

# Verify the model is available
ollama list
# Should show:
# NAME            ID              SIZE
# llama3:latest   365c0bd3c000    4.7 GB
```

### Test Ollama

```bash
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3",
    "prompt": "Extract vendor name from: Invoice from Dell Inc.",
    "stream": false
  }'
```

### Environment Configuration

```bash
export OLLAMA_URL="http://localhost:11434"  # or http://ollama:11434 for Docker
export OLLAMA_MODEL="llama3"
```

### GPU Acceleration (Optional)

For 10-100x faster inference:

```bash
# NVIDIA GPU (requires nvidia-docker)
docker run -d --gpus all \
  --name ollama \
  -p 11434:11434 \
  -v ollama_models:/root/.ollama \
  ollama/ollama:latest

# Verify GPU usage
docker exec ollama nvidia-smi
```

---

## 3. PDF Processing Tools

Assetronics extracts text from PDF invoices before sending to Ollama.

### Linux: Install pdftotext

```bash
# Ubuntu/Debian
sudo apt-get install -y poppler-utils

# CentOS/RHEL
sudo yum install -y poppler-utils

# Verify
pdftotext -v
# Should output: pdftotext version 22.02.0
```

### macOS: Use textutil (Pre-installed)

```bash
# textutil is included in macOS by default
which textutil
# Should output: /usr/bin/textutil
```

Assetronics automatically detects the platform and uses the appropriate tool.

### Docker: Include in Dockerfile

```dockerfile
# backend/Dockerfile
FROM hexpm/elixir:1.15-erlang-26-alpine-3.18

# Install pdftotext
RUN apk add --no-cache poppler-utils

# ... rest of Dockerfile
```

### Test PDF Extraction

```bash
# Create a test PDF
echo "Invoice #12345" | ps2pdf - test.pdf

# Extract text
pdftotext test.pdf -  # Linux
textutil -convert txt test.pdf -stdout  # macOS
```

---

## 4. Environment Configuration

### Generate Secrets

```bash
# Navigate to backend directory
cd backend

# Generate Phoenix secret (64 characters)
mix phx.gen.secret

# Generate Guardian JWT secret
mix guardian.gen.secret

# Generate Cloak encryption key (32 bytes, base64 encoded)
mix phx.gen.secret 32 | base64
```

### Create .env File

Create `backend/.env.production`:

```bash
# =============================================================================
# DATABASE
# =============================================================================
DATABASE_URL=ecto://assetronics:password@localhost/assetronics_prod
POOL_SIZE=20

# =============================================================================
# PHOENIX
# =============================================================================
PHX_HOST=yourdomain.com
PHX_SERVER=true
PORT=4000
SECRET_KEY_BASE=<generated_from_mix_phx_gen_secret>

# =============================================================================
# AUTHENTICATION & SECURITY
# =============================================================================
GUARDIAN_SECRET_KEY=<generated_from_mix_guardian_gen_secret>
CLOAK_KEY=<generated_base64_key>

# =============================================================================
# APPLICATION URLS
# =============================================================================
FRONTEND_URL=https://yourdomain.com
OAUTH_REDIRECT_URI=https://yourdomain.com/api/v1/oauth/callback

# =============================================================================
# AI / INVOICE PROCESSING
# =============================================================================
OLLAMA_URL=http://localhost:11434
OLLAMA_MODEL=llama3

# =============================================================================
# FILE STORAGE (AWS S3 - OPTIONAL)
# =============================================================================
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_S3_BUCKET=assetronics-uploads
AWS_REGION=us-east-1

# =============================================================================
# EMAIL (RESEND - OPTIONAL)
# =============================================================================
RESEND_API_KEY=re_your_api_key
FROM_EMAIL=noreply@yourdomain.com
```

---

## 5. Integration Credentials

### Google Workspace / Gmail

See `docs/google_workspace_setup_guide.md` for detailed instructions.

**Quick Summary**:
1. Create a Project in Google Cloud Console
2. Enable Admin SDK API and Gmail API
3. Create a Service Account with Domain-Wide Delegation
4. Grant scopes:
   - `https://www.googleapis.com/auth/admin.directory.device.chromeos`
   - `https://www.googleapis.com/auth/admin.directory.device.mobile`
   - `https://www.googleapis.com/auth/gmail.readonly`
   - `https://www.googleapis.com/auth/gmail.modify`
5. Download JSON key and store in integration `auth_config.service_account_json`
6. Set `auth_config.target_email` to the mailbox to scan

### Microsoft Intune & Graph (OAuth)

See `docs/OAUTH_SETUP.md` for detailed instructions.

**Quick Summary**:
1. Register App in Azure Portal
2. Create Client Secret
3. Grant Application Permissions:
   - `DeviceManagementManagedDevices.Read.All` (Intune)
   - `Mail.ReadWrite` (Graph Mail)
   - `User.Read.All`
4. Each tenant provides their own OAuth credentials via UI
5. Credentials stored encrypted in `integrations.auth_config`

### Jamf Pro (Basic Auth)

1. Create API user in Jamf Pro console
2. Grant appropriate permissions (read devices)
3. Configure integration:
   - `base_url`: `https://your-instance.jamfcloud.com`
   - `api_key`: Username
   - `api_secret`: Password

### CDW (API Key)

1. Contact CDW to request API access
2. Receive API Key and Secret
3. Configure integration:
   - `api_key`: Your CDW API Key
   - `api_secret`: Your CDW API Secret

---

## 6. Worker Configuration

Assetronics uses **Oban** for background job processing.

### Current Configuration

Located in `backend/config/config.exs`:

```elixir
config :assetronics, Oban,
  repo: Assetronics.Repo,
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},  # Keep jobs for 7 days
    {Oban.Plugins.Cron, crontab: [
      {"*/15 * * * *", Assetronics.Workers.InvoicePoller}  # Every 15 minutes
    ]}
  ],
  queues: [
    default: 10,         # General tasks (10 concurrent jobs)
    integrations: 20,    # Integration syncs (20 concurrent)
    notifications: 5,    # Email/Slack alerts
    reports: 3           # Report generation
  ]
```

### Worker Types

1. **InvoicePoller** (`lib/assetronics/workers/invoice_poller.ex`)
   - **Schedule**: Every 15 minutes (Oban cron)
   - **Purpose**: Polls Gmail and Microsoft Graph for invoice emails
   - **Actions**: Triggers invoice processing pipeline

2. **SyncIntegrationWorker** (`lib/assetronics/workers/sync_integration_worker.ex`)
   - **Queue**: `integrations`
   - **Purpose**: Sync individual integrations (MDM, HRIS, etc.)
   - **Retry**: Max 3 attempts with exponential backoff

3. **ScheduledSyncWorker** (`lib/assetronics/workers/scheduled_sync_worker.ex`)
   - **Purpose**: Periodic scheduler for all tenant integrations
   - **Actions**: Enqueues SyncIntegrationWorker jobs

### Monitoring Workers

```bash
# View Oban dashboard (if enabled)
# Navigate to: https://yourdomain.com/admin/oban

# Or query via IEx
iex> Oban.Job |> Assetronics.Repo.all() |> length()

# Check queue status
iex> Oban.check_queue(queue: :integrations)
```

---

## 7. Deployment Options

### Option A: Docker Compose (Recommended)

Create `docker-compose.yml`:

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: assetronics
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: assetronics_prod
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  backend:
    build: ./backend
    depends_on:
      - postgres
      - ollama
    env_file: .env.production
    ports:
      - "4000:4000"
    restart: unless-stopped

  ollama:
    image: ollama/ollama:latest
    volumes:
      - ollama_models:/root/.ollama
    ports:
      - "11434:11434"
    restart: unless-stopped

volumes:
  postgres_data:
  ollama_models:
```

Deploy:
```bash
docker-compose up -d
docker exec backend mix ecto.migrate
```

### Option B: Systemd Service

Create `/etc/systemd/system/assetronics.service`:

```ini
[Unit]
Description=Assetronics ITAM Platform
After=network.target postgresql.service

[Service]
Type=forking
User=assetronics
WorkingDirectory=/opt/assetronics
EnvironmentFile=/etc/assetronics.env
ExecStart=/opt/assetronics/_build/prod/rel/assetronics/bin/assetronics daemon
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Deploy:
```bash
sudo systemctl enable assetronics
sudo systemctl start assetronics
```

---

## 8. Security & Best Practices

### 1. Secure Credentials

- All OAuth credentials stored encrypted (AES-256-GCM)
- Never commit `.env` files to version control
- Use environment variables for all secrets
- Rotate secrets every 6-12 months

### 2. Database Security

```sql
-- Restrict database user permissions
GRANT USAGE ON SCHEMA public TO assetronics;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- Enable SSL connections
ALTER SYSTEM SET ssl = on;
```

### 3. Firewall Configuration

```bash
# Allow only necessary ports
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 443/tcp  # HTTPS
sudo ufw deny 11434/tcp # Block external Ollama access
sudo ufw enable
```

### 4. Multi-Tenant Isolation

- Each tenant has separate PostgreSQL schema (Triplex)
- Complete data isolation between tenants
- Credentials never shared across tenants

---

## 9. Monitoring & Troubleshooting

### Common Issues

**Issue**: Ollama connection failed
```bash
# Check Ollama is running
curl http://localhost:11434/api/version

# Restart Ollama
docker restart ollama  # or
sudo systemctl restart ollama
```

**Issue**: PDF extraction fails
```bash
# Verify pdftotext is installed
which pdftotext

# Reinstall if missing
sudo apt-get install --reinstall poppler-utils
```

**Issue**: Email marking fails
- **Gmail**: Ensure `gmail.modify` scope is granted
- **Microsoft Graph**: Ensure `Mail.ReadWrite` permission is granted

### Logging

```bash
# View application logs
sudo journalctl -u assetronics -f

# View Ollama logs
docker logs ollama -f
```

### Health Checks

```bash
# Application health
curl https://yourdomain.com/api/health

# Database connectivity
curl https://yourdomain.com/api/health/db
```

---

## Next Steps

After deployment:

1. Create admin user in IEx console
2. Set up first tenant and OAuth integrations
3. Configure Sentry or other monitoring
4. Set up automated database backups
5. Load test with realistic data volumes

---

## Support

- **Documentation**: [docs.assetronics.com](https://docs.assetronics.com)
- **OAuth Setup**: See `docs/OAUTH_SETUP.md`
- **Google Workspace**: See `docs/google_workspace_setup_guide.md`
- **Issues**: [github.com/assetronics/assetronics/issues](https://github.com/assetronics/assetronics/issues)

---

**Last Updated**: 2025-01-XX
