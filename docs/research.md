# IT Asset Management (ITAM) Micro SaaS Research Document

## Executive Summary

This document provides comprehensive market research, competitive analysis, and technical feasibility assessment for building an **"Import-First" ITAM solution** targeting SMBs. The core differentiator is automated multi-source import from vendor portals, MDM platforms, email/invoice parsing, and license management systems.

---

## Implementation Status

### Phase 1 & 2: ✅ MOSTLY COMPLETED (January 2025)

**Completed Components:**
- **Google Workspace Integration** ✅ (ChromeOS, Mobile, Licenses, Auth)
- **Email Invoice Parsing** ✅ (Gmail & Microsoft Graph adapters, Ollama integration)
- **Intune Integration** ✅ (Device sync + **OAuth flow complete**)
- **Dell Integration** ✅ (Premier API + **OAuth flow complete**)
- **OAuth Connect Flows** ✅ (Full end-to-end implementation for Intune & Dell)
- **Oban Workers** ✅ (InvoicePoller configured with 15-min cron)
- **CDW Integration** ✅ (B2B API with API key authentication)
- **Jamf Integration** ✅ (Apple MDM with Basic Auth)

**Documentation:**
- `docs/google_workspace_api_research.md` - Google Workspace API documentation
- `docs/google_workspace_setup_guide.md` - Google Workspace setup instructions
- `docs/OAUTH_SETUP.md` - **NEW**: Complete OAuth setup guide for Intune & Dell

**OAuth Implementation Details (NEW):**
- ✅ Per-tenant OAuth credentials stored encrypted in `integrations.auth_config`
- ✅ Frontend UI collects client_id/client_secret from users
- ✅ Backend OAuth flow: authorization → token exchange → automatic refresh
- ✅ CSRF protection using Phoenix.Token
- ✅ Multi-tenant isolation with schema-based storage
- ✅ Comprehensive setup documentation with troubleshooting guides

**Recently Completed (2025-01-XX):**
- ✅ **Email Processing Improvements**: Gmail now creates custom "Assetronics/Processed" label
- ✅ **Microsoft Graph Improvements**: Adds "Assetronics Processed" category to emails
- ✅ **Comprehensive Error Handling**: Full exception handling with structured logging in both adapters
- ✅ **Production Deployment Guide**: Complete `docs/DEPLOYMENT_GUIDE.md` with Ollama, PDF tools, Docker, systemd
- ✅ **Worker Documentation**: Oban configuration fully documented (InvoicePoller runs every 15 min)
- ✅ **CDW & Jamf Auth Documentation**: Included in deployment guide

**Remaining Tasks:**
- Comprehensive test suite (currently <10% coverage)
- Enhanced monitoring and alerting (Sentry integration exists)
- Performance optimization and load testing
- Additional integration adapters (Workday, NetSuite detailed implementations)

---

## Table of Contents

1. [Market Opportunity](#1-market-opportunity)
2. [Competitive Landscape](#2-competitive-landscape)
3. [Technical Feasibility](#3-technical-feasibility)
4. [Hybrid Architecture Strategy](#4-hybrid-architecture-strategy)
5. [System Requirements](#5-system-requirements)
6. [Value Proposition](#6-value-proposition)
7. [Feature Comparison Matrix](#7-feature-comparison-matrix)
8. [Recommended MVP Scope](#8-recommended-mvp-scope)
9. [Go-to-Market Validation](#9-go-to-market-validation)

---

## 1. Market Opportunity

### The Gap in Current ITAM Solutions

Existing players like Snipe-IT, Lansweeper, ServiceNow have significant limitations:

- **Snipe-IT** is open-source and popular but import is mostly manual or requires custom scripting
- **Enterprise tools** (ServiceNow, Ivanti) are expensive and overkill for SMBs
- **Most tools focus on storing asset data**, not automatically collecting it

### The Pain Point

IT admins spend hours reconciling data from:
- Procurement emails
- Vendor portals
- MDM platforms
- Spreadsheets from finance
- Network scans

Licenses especially get lost in email threads and PDF invoices.

### Market Shift

The modern ITAM approach for SMBs focuses more on hardware asset management and is driven by security audits and automation. This shift means that ITAM no longer requires experts in the field but can be easily managed by regular IT teams. The systems are designed to be simple, user-friendly, and accessible.

---

## 2. Competitive Landscape

### Tier 1: Enterprise Giants (Overkill for SMBs)

| Tool | Strengths | Weaknesses |
|------|-----------|------------|
| **ServiceNow HAM** | Deep integrations (Jamf, SCCM, Intune), workflow automation | Premium pricing not feasible for SMBs, complex implementation |
| **Flexera** | 2.1 million software use rights library, 5,500 templates | Enterprise-only pricing |
| **Ivanti Neurons** | Active/passive scanning, third-party connectors, Google partner | Enterprise complexity |

### Tier 2: Mid-Market Players (Main Competition)

| Tool | Strengths | Weaknesses | Pricing |
|------|-----------|------------|---------|
| **Lansweeper** | SCCM/Intune sync, lightweight agents for Win/Mac/Linux | Network-discovery focused, less procurement automation | ~$2-4/asset/year |
| **Oomnitza** | Extensive integration list, powerful API workflows | Dated UI, one of the most expensive ITAMs | Custom (expensive) |
| **InvGate** | AWS/Azure/Chromebook/mobile sync, agent + agentless | Less focused on procurement-to-asset pipeline | ~$19/agent/month |
| **Setyl** | MDM/RMM/IAM auto-import, HR system integration | Newer player, less procurement depth | ~$4/user/month |

### Tier 3: Open Source & Budget Options

| Tool | Strengths | Weaknesses |
|------|-----------|------------|
| **Snipe-IT** | Free, customizable, great audit logs | No built-in network scanning, manual data entry, limited reporting/analytics |

### Key Findings from Reviews

**Snipe-IT limitations:**
- "No built-in network scanning. You have to input them manually or via import."
- "Reporting and analytics are limited."
- "A recurring theme in user feedback points to its reliance on manual data entry and potential scalability issues."

**Oomnitza feedback:**
- "Extensive integration list. Most common MDM and software titles have integrations."
- "The UI still feels dated. It's also one of the most expensive ITAM's out there."

---

## 3. Technical Feasibility

### 3.1 Vendor API Availability

#### Dell Premier APIs ✅ Strong

Dell Premier offers comprehensive APIs:
- **Catalog API**: Retrieve catalog data and pricing
- **Quote API**: Retrieve quote details including SKU descriptions, pricing
- **Purchase Order API**: Submit purchase orders
- **Order Status API**: Look up or receive dynamic order status updates
- **POA API**: Receive automated purchase order acknowledgement

Dell sends real-time notifications during the entire procurement process via push APIs.

**Integration Complexity:** Medium
- Requires Dell Premier account
- OAuth/API key authentication
- REST API with JSON responses

#### CDW APIs ✅ Strong

The Customer Order API provides CDW's Customer community with the ability to send customer order data in real time.

CDW already has an Oomnitza integration that sends asset information including Model, Manufacturer, Serial Number, Purchase Date, and PO Number directly when products are ordered. Over 130 different Item Classes available.

**Key insight:** CDW-Oomnitza integration proves this is technically feasible.

#### HP APIs ⚠️ Partial

HP provides:
- HP TechPulse Analytics API
- HP Incident Integration API
- Hardware management capabilities

**Limitation:** HP's APIs focus on device management/support, NOT procurement. No direct order history API. Would need email parsing for HP purchases.

#### Lenovo APIs ⚠️ Limited

Lenovo provides warranty lookup API key to customers who request it via Sales or Support Account Representatives. Required to be a large enterprise customer.

**Limitation:** Primarily warranty lookup, not procurement data. Enterprise-only access.

#### Warranty Data Aggregation ✅ Possible

PowerShell scripts exist that automate warranty information reporting from multiple vendors (HP, Dell, Lenovo, Microsoft) by identifying vendor via serial number length patterns.

### 3.2 Invoice/Email Parsing Technology

#### Direct Inbox Access (Gmail & Microsoft)
Currently, the plan is to use email forwarding. However, for a more robust solution, direct integration with Gmail and Microsoft 365 inboxes via their respective APIs (Gmail API, Microsoft Graph API) should be explored to enable automatic scanning and ingestion of emails containing invoices.

#### Ollama Client for AI Processing
Consider integrating an Ollama client for local or self-hosted AI processing of PDF invoices. This would allow for on-premise extraction of asset information, potentially offering cost savings and enhanced data privacy compared to cloud-based solutions.

#### Microsoft Azure Document Intelligence ✅ Production-Ready

The Document Intelligence invoice model uses powerful OCR capabilities to analyze and extract key fields and line items from sales invoices. Extracts customer name, billing address, due date, amount due. Returns structured JSON. Supports 27 languages.

**Pricing:** ~$1.50 per 1,000 pages (S0 tier)

#### Third-Party Solutions

| Solution | Capabilities |
|----------|--------------|
| **Parseur** | AI invoice processing reduces processing time by 80%. Predefined mailboxes. Benchmark shows ~150 hours saved and ~$6,413/month saved per customer |
| **Affinda** | End-to-end invoice extraction. Email, drag-drop, or API. Auto splits/classifies files |
| **Parsio** | Pre-built models for invoices, business cards, ID documents |
| **Google Document AI** | FibroGen case study: $150/month run cost, 40x ROI, 25% AP team bandwidth freed |

### 3.3 Microsoft 365 License API Integration

Fully supported via Microsoft Graph API:

```
GET https://graph.microsoft.com/v1.0/subscribedSkus
```

**Returns:**
- SKU ID and Part Number
- Consumed units vs. prepaid units
- Service plans
- Subscription status

**PowerShell Example:**
```powershell
Get-MgSubscribedSku | Select -Property Sku*, ConsumedUnits -ExpandProperty PrepaidUnits
```

**What you can pull:**
- License counts (owned vs. consumed)
- Per-user license assignments
- Service plan details
- Subscription status

### 3.4 MDM API Integration

#### Microsoft Intune
- Hardware inventory (model, serial, RAM, storage)
- OS version
- Compliance status
- Last check-in time
- Primary user

#### Jamf
- Full hardware specs
- Installed apps
- User assignment

#### Google Workspace (Chrome Enterprise)
- Device info, OS version, last sync

---

## 4. Hybrid Architecture Strategy

### Why Hybrid? (Agentless + Agent)

While an "Import-First" (Agentless) strategy remains the core differentiator for rapid onboarding, a **lightweight agent** is necessary for specific deep-dive capabilities that APIs cannot provide.

**Agentless (API-driven):**
- **Primary Data Source:** Imports 80% of asset data (Purchase date, Cost, Warranty, License assignment).
- **Pros:** Zero deployment friction, instant value.

**Agent (Go-based):**
- **Secondary Data Source:** fills the "Last 20%" gap.
- **Capabilities:**
    - Real-time location tracking (IP/Geo)
    - Detailed software metering (usage frequency)
    - Granular hardware health (battery cycles, disk SMART status)
- **Deployment:** Optional. Customers can start agentless and deploy agents only to critical devices.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     DATA COLLECTION LAYER                        │
├─────────────┬─────────────┬─────────────┬─────────────┬─────────┤
│   Email     │   Vendor    │    MDM      │   Network   │  Agent  │
│   Inbox     │   APIs      │   Sync      │   Scanner   │ (Go Bin)│
│  (Invoice   │ (Dell,CDW)  │(Intune,Jamf)│  (SNMP,     │ (Linux, │
│   Parser)   │             │             │   Nmap)     │  Mac)   │
└──────┬──────┴──────┬──────┴──────┬──────┴──────┬──────┴────┬────┘
       │             │             │             │           │
       ▼             ▼             ▼             ▼           ▼
┌─────────────────────────────────────────────────────────────────┐
│              DEDUPLICATION & MATCHING ENGINE                     │
│  • Serial number matching (Primary Key)                          │
│  • Fuzzy model name matching                                     │
│  • PO → Asset linking                                            │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    UNIFIED ASSET DATABASE                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. System Requirements

To support the local AI processing capabilities, the backend infrastructure has specific dependencies:

### 1. AI Inference Engine
- **Service:** [Ollama](https://ollama.com)
- **Model:** `llama3` (or `mistral`)
- **Port:** Default `11434`
- **Role:** Extracts structured JSON data from unstructured PDF invoice text.

### 2. PDF Processing Utilities
- **Linux:** `pdftotext` (part of `poppler-utils`)
- **macOS:** `textutil` (native) or `pdftotext`
- **Role:** Converts PDF attachments to raw text before AI processing.

### 3. Database
- **PostgreSQL:** with `pgcrypto` extension enabled (for Cloak encryption).

---

## 6. Value Proposition

### MDM vs Your ITAM: Different Problems

| Question | MDM Answers | Your ITAM Answers |
|----------|-------------|-------------------|
| "How many laptops did we buy this year?" | ❌ | ✅ |
| "When does the warranty expire?" | ❌ | ✅ |
| "Do we own more M365 licenses than we use?" | ❌ | ✅ |
| "Which devices are unassigned in storage?" | ❌ | ✅ |
| "What did we pay for this laptop?" | ❌ | ✅ |
| "Who had this laptop before current user?" | ❌ | ✅ |
| "Have all ordered laptops arrived?" | ❌ | ✅ |
| "What's our total IT spend?" | ❌ | ✅ |
| "What assets does this departing employee have?" | ⚠️ Partial | ✅ |
| "Are we audit-ready (SOC 2/ISO 27001)?" | ❌ | ✅ |

### The Real-World Data Fragmentation

Typical 200-person company asset data lives in:

```
Microsoft Intune         →  Windows laptops enrolled
Jamf                     →  MacBooks enrolled
Google Admin             →  Chromebooks, Google licenses
Microsoft 365 Admin      →  M365 license assignments
Dell Premier Portal      →  Order history, invoices
CDW Account              →  Other hardware purchases
Amazon Business          →  Monitors, keyboards, misc
QuickBooks               →  What finance thinks we bought
IT Manager's Spreadsheet →  "The real list" (outdated)
Email threads            →  POs, tracking numbers, receipts
Closet in the office     →  Spare laptops nobody tracks
```

**MDM sees maybe 60% of this picture.** Zero context on cost, procurement, or lifecycle.

### Key Use Cases MDM Can't Handle

#### 1. Procurement → Deployment Tracking

> "We ordered 15 laptops from Dell. Have they shipped? Been enrolled? Any sitting in a box?"

- **Dell API**: ordered, shipped, delivered
- **Intune API**: enrolled or not
- **Your product**: "3 laptops delivered but not yet enrolled"

#### 2. License Compliance

> "We're paying for 200 M365 E3 licenses. Using them all?"

- **M365 Admin**: 200 licenses, 187 assigned
- **Intune**: 150 active devices
- **Your product**: "13 licenses assigned to users with no active device in 90 days"

#### 3. Offboarding

> "Sarah is leaving. What equipment does she have?"

- **Intune**: Surface Pro enrolled
- **Jamf**: MacBook enrolled
- **Your product**: Surface Pro, MacBook, 27" monitor, keyboard, YubiKey, iPhone — full list with serials, purchase dates, cost

#### 4. Audit Prep

> "Auditor wants complete inventory with proof of ownership"

- **MDM**: device list (enrolled only)
- **Your product**: complete asset register with purchase records, assignment history, disposal documentation

#### 5. Budget Planning

> "CFO wants IT hardware spend for last 12 months"

- **MDM**: zero financial data
- **Your product**: "$340K spent. 47 laptops approaching 4 years. Projected refresh: $85K"

### Positioning Statement

**Don't say:** "We're an ITAM that integrates with your MDM"

**Say:** "Your MDM manages devices. We manage your entire IT asset lifecycle — from purchase order to disposal."

**Or:** "We turn your scattered IT data into one source of truth."

---

## 7. Feature Comparison Matrix

| Feature | Snipe-IT | Lansweeper | Setyl | Oomnitza | **Your Product** |
|---------|----------|------------|-------|----------|------------------|
| **Free/Open Source** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Network Discovery** | ❌ | ✅ | Via integrations | ✅ | ✅ |
| **MDM Import (Intune/Jamf)** | ❌ (manual) | ✅ | ✅ | ✅ | ✅ |
| **Vendor Portal Sync (Dell/CDW)** | ❌ | ❌ | ❌ | ✅ (CDW only) | ✅ ⭐ |
| **Email/Invoice Parsing** | ❌ | ❌ | ❌ | ❌ | ✅ ⭐ |
| **M365 License Sync** | ❌ | Partial | ✅ | ✅ | ✅ |
| **Intelligent Deduplication** | ❌ | Basic | Basic | ✅ | ✅ |
| **Procurement-to-Asset Pipeline** | ❌ | ❌ | Partial | Partial | ✅ ⭐ |
| **SMB Pricing (<$5/user)** | Free | ~$2-4/asset | ~$4/user | Enterprise | ✅ |
| **Self-Hosted Option** | ✅ | ❌ | ❌ | ❌ | Optional |

**⭐ = Unique differentiators**

---

## 8. Recommended MVP Scope (Revised)

### Phase 1: Core Data Foundation (✅ COMPLETED)
1. **Google Workspace Sync**: Devices, Users, Licenses.
2. **Email Invoice Parsing**: Gmail/Graph + Ollama for AI extraction.
3. **Agent Implementation**: Basic Go agent for Linux/Mac telemetry.

### Phase 2: MDM & Procurement Integration (IN PROGRESS)
1. **Microsoft Intune**: Device sync logic ready, pending OAuth UI.
2. **Dell Premier**: Order history sync ready, pending OAuth UI.
3. **CDW Integration**: Adapter development required.
4. **Jamf Integration**: Adapter development required.

### Phase 3: Advanced Features (PLANNED)
1. **Network Scanner**: Agent-based Nmap/SNMP scanning.
2. **Fuzzy Deduplication**: Intelligent matching of "MacBook Pro" vs "MBP 14".
3. **Accounting Sync**: QuickBooks/Xero/NetSuite adapters.
4. **Audit Reports**: SOC2/ISO27001 compliance templates.

---

## 9. Go-to-Market Validation

### Target Customer Segments

| Customer Type | Why They Need You |
|---------------|-------------------|
| **SMBs (50-500 employees)** | Outgrown spreadsheets, can't afford ServiceNow |
| **Mixed environments** | Windows + Mac + Chromebook = 3 different consoles |
| **MSPs** | Need unified view across all client assets |
| **Audit-prep companies** | SOC 2 / ISO 27001 requires documentation |
| **Finance/IT alignment** | CFO wants cost visibility |
| **Fast-growing startups** | Hiring 10 people/month, onboarding chaos |

### Validation Questions to Ask IT Managers

1. "Where do you currently track IT assets?"
2. "How long does it take to get a complete inventory for an audit?"
3. "Do you know how many software licenses you own vs. use?"
4. "What happens when an employee leaves — how do you know what to collect?"
5. "How do you track warranties and refresh cycles?"
6. "Would you pay $3-5/user/month for a unified asset view?"

### The Litmus Test

> "If I showed you a dashboard with every IT asset your company owns — hardware, licenses, who has what, warranties, and spend — pulled automatically from Intune, Jamf, Dell, and email invoices... would that be useful?"

If most say "yes, I'd pay for that" — you have a product.

### Pre-Build Validation Steps

1. **Talk to 10 MSPs** — They manage assets for multiple clients
2. **Talk to 10 IT managers (50-500 employees)** — Are they outgrowing spreadsheets?
3. **Test email parsing** — Get sample PO emails from Dell/HP/CDW, test extraction accuracy
4. **Verify vendor APIs** — Apply for Dell Premier API access, test CDW endpoints

---

## Appendix: API Endpoints Reference

### Microsoft Graph - License Management

```http
# Get all subscribed SKUs
GET https://graph.microsoft.com/v1.0/subscribedSkus

# Get user license details
GET https://graph.microsoft.com/v1.0/users/{id}/licenseDetails
```

### Dell Premier APIs

- Catalog: `GET /catalog`
- Quote: `GET /quotes/{quoteId}`
- Order Status: `GET /orders/{orderId}/status`
- Order Status Push: Webhook registration

### Invoice Parsing Services

| Service | Endpoint | Pricing |
|---------|----------|---------|
| Azure Document Intelligence | `POST /documentModels/prebuilt-invoice:analyze` | ~$1.50/1000 pages |
| Parseur | Email forwarding + REST API | Per-document |
| Google Document AI | `POST /v1/projects/{project}/locations/{location}/processors/{processor}:process` | Pay-per-use |

---

## Document Information

- **Created:** November 2025
- **Purpose:** Market research and feasibility analysis for ITAM Micro SaaS
- **Status:** Research complete, ready for validation phase

---

*End of Document*
