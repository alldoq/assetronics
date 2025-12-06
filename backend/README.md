# Assetronics Backend API

**Hardware Asset Lifecycle Management Platform - Phoenix/Elixir Backend**

API-only backend with multi-tenancy (Triplex) and field-level encryption (Cloak).

---

## 🚀 Quick Start

### Prerequisites
- Elixir 1.15+
- PostgreSQL 14+
- Mix

### Setup

```bash
# 1. Install dependencies
mix deps.get

# 2. Copy environment variables template
cp .env.example .env

# 3. Edit .env and set required variables:
#    - CLOAK_KEY (for encryption)
#    - DATABASE_URL (optional, defaults provided)
#    - GUARDIAN_SECRET_KEY (run: mix guardian.gen.secret)
#    - RESEND_API_KEY (for email notifications)
#    - AWS credentials (for S3 file storage in production)

# 4. Create database
mix ecto.create

# 5. Run migrations (public schema)
mix ecto.migrate

# 6. Create tenant and run tenant migrations
# Note: Seed script will create "acme" tenant automatically

# 7. Load test data
mix run priv/repo/seeds.exs

# 8. Start server
mix phx.server
```

Server runs on `http://localhost:4000`

### API Testing with Insomnia

Import the API collection for testing:

1. Open Insomnia REST client
2. Import `insomnia_collection.json`
3. The collection includes pre-configured:
   - Base URL: `http://localhost:4000/api/v1`
   - Tenant: `acme`
   - Test credentials for all user roles

**Test User Credentials:**
- **Admin:** admin@acme.com / Admin123!
- **Manager:** manager@acme.com / Manager123!
- **Employee:** employee@acme.com / Employee123!
- **Viewer:** viewer@acme.com / Viewer123!

**Quick Start:**
1. Use "Login (Admin)" request to authenticate
2. Copy `access_token` from response
3. Set `access_token` environment variable in Insomnia
4. All authenticated requests will now work

---

## 📋 What's Built

### ✅ Core Features
- **Multi-Tenancy** - Schema-based isolation with Triplex
- **Encryption** - AES-256-GCM for all sensitive data (Cloak)
- **Authentication & Authorization** - JWT tokens with Guardian, RBAC with Bodyguard (5 roles)
- **File Management** - S3 (production) + Local (development) storage with validation
- **Email Notifications** - Transactional emails via Resend (HTML + text templates)
- **Background Jobs** - PostgreSQL-backed queues with Oban
- **Audit Trail** - Complete transaction history
- **Real-Time** - Phoenix PubSub broadcasting

### ✅ Authentication & Security
- **JWT Authentication** - Access tokens (1h) + refresh tokens (30d) via Guardian
- **Role-Based Access Control** - 5 roles: super_admin, admin, manager, employee, viewer
- **Password Security** - Argon2 hashing with configurable complexity
- **Email Verification** - Secure email verification with time-limited tokens
- **Password Reset** - Secure password reset flow with tokens
- **Account Locking** - Auto-lock after failed login attempts

### ✅ Database Schemas
- `tenants` - Company/organization metadata (public schema)
- `users` - User accounts with encrypted PII and authentication
- `assets` - Hardware items with encrypted serial numbers, costs
- `employees` - Employee records with encrypted PII
- `locations` - Office/warehouse locations with encrypted addresses
- `workflows` - Automated processes (onboarding, offboarding, etc.)
- `integrations` - External systems with encrypted credentials
- `files` - File uploads (avatars, asset photos, workflow attachments)
- `transactions` - Complete audit trail

### ✅ REST API Endpoints
- **Authentication** - Login, logout, refresh, register, password reset, email verification
- **Users** - CRUD + role/status management, account locking
- **Assets** - CRUD + assign, return, transfer, history, search
- **Employees** - CRUD + terminate, reactivate, asset listing
- **Locations** - CRUD + activate/deactivate, asset/employee listing
- **Workflows** - CRUD + start, advance, complete, cancel, overdue tracking
- **Integrations** - CRUD + test connection, manual sync, auto-sync management
- **Files** - Upload, download, delete with category-specific validation
- **Tenants** - View/update settings, usage stats, feature management, subscriptions

### ✅ Business Logic (Contexts)
- `Assetronics.Accounts` - User management, authentication, tenants
- `Assetronics.Assets` - Full asset management with CRUD, assignment, returns, transfers
- `Assetronics.Employees` - Employee management with HRIS sync support
- `Assetronics.Locations` - Location management
- `Assetronics.Workflows` - Workflow templates and execution
- `Assetronics.Integrations` - Third-party integrations
- `Assetronics.Files` - File upload/storage with S3 and local adapters
- `Assetronics.Emails` - Email templates for users, assets, workflows

### ✅ Email Notifications
- **User Emails** - Welcome, email verification, password reset, password changed
- **Asset Emails** - Asset assigned, return reminders
- **Workflow Emails** - Assigned, completed, overdue, step reminders

See [PROJECT_STATUS.md](PROJECT_STATUS.md) for complete details.

---

## 🔐 Security

All sensitive data is encrypted at rest:
- Employee PII (names, SSN, addresses, phone)
- Asset data (serial numbers, purchase costs, PO numbers)
- Integration credentials (API keys, OAuth tokens)
- Financial data (transaction amounts, depreciation)

**Encryption:** AES-256-GCM via Cloak
**Isolation:** PostgreSQL schema per tenant via Triplex

---

## 🏢 Multi-Tenancy

Each company gets their own PostgreSQL schema:

```elixir
# Create tenant
Triplex.create("acme")        # Creates schema: tenant_acme
Triplex.migrate("acme")       # Runs tenant migrations

# Query tenant data
Assetronics.Assets.list_assets("acme")
```

---

## 📚 Learn More

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Triplex Multi-Tenancy](https://github.com/ateliware/triplex)
- [Cloak Encryption](https://github.com/danielberkompas/cloak)
- [Oban Background Jobs](https://getoban.pro/)

---

## 📝 Development

### Email Preview (Development)

In development, emails are captured locally and can be viewed at:
- **Mailbox Preview:** http://localhost:4000/dev/mailbox

All sent emails appear here instead of being delivered to real addresses.

### File Storage

**Development:** Files stored in `priv/static/uploads/`
**Production:** Files stored in AWS S3 (configure in `.env`)

Create upload directory:
```bash
mkdir -p priv/static/uploads
```

### Database Migrations

**Public schema migrations** (tenants table, shared data):
```bash
mix ecto.migrate
```

**Tenant migrations** (per-tenant data):
```bash
# Migrations run automatically when tenant is created
# Or manually:
Triplex.migrate("acme")
```

---

## 🧪 Testing

### Manual API Testing
1. Start server: `mix phx.server`
2. Load seed data: `mix run priv/repo/seeds.exs`
3. Import Insomnia collection: `insomnia_collection.json`
4. Test all endpoints with different user roles

### Automated Tests
```bash
# Run tests (TODO: Add test suite)
mix test
```

---

## 📝 Next Steps

1. ✅ ~~Create REST API controllers~~
2. ✅ ~~Implement authentication (Guardian + JWT)~~
3. ✅ ~~Add file upload support~~
4. ✅ ~~Implement email notifications~~
5. Add Phoenix Channels for real-time updates
6. Build integration workers (HRIS sync, Slack notifications)
7. Write comprehensive test suite
8. Add API rate limiting
9. Implement advanced search and filtering
10. Add data export functionality (CSV, Excel)

See [PROJECT_STATUS.md](PROJECT_STATUS.md) for detailed roadmap.
