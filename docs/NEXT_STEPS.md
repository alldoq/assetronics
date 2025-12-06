# GAP Analysis & Implementation Plan

Based on the analysis of `SPEC.md`, `API_SPECIFICATION.md`, and the current codebase state (Backend v0.1.0, Frontend v0.0.0).

## 1. Current State Overview

*   **Backend (Elixir/Phoenix):** ~98% complete regarding *Core Management* features.
    *   **Implemented:** Multi-tenancy (Triplex), Encryption (Cloak), Background Jobs (Oban), REST API (Assets, Employees, Locations, Workflows, Integrations), and Integration Adapters.
    *   **Missing:** User Authentication (JWT/Guardian), Real-time WebSockets, and "Discovery" modules (Agents/Scanners).
*   **Frontend (Vue 3/Vite):** ~80% complete regarding *UI/UX Structure*.
    *   **Implemented:** Full view structure (Assets, Employees, Dashboard), Pinia stores, Service layer (API clients), and Routing.
    *   **Missing:** Integration with real-time features and working Backend Authentication.

## 2. GAP Analysis: IATM Spec vs. Implementation

The "IATM" (IT Asset Management) specification lists **Automated Inventory** (Agents & Scanners) as the foundation. The current implementation focuses on **Administrative Management** (Manual entry + Cloud Integrations).

| Feature / Component | Status | Missing / Gap |
| :--- | :--- | :--- |
| **I. Data Discovery (Agents)** | 🔴 **Missing** | No backend context for "Endpoint Agents" to check in. No agent software binary/script. |
| **I. Network Scanner** | 🔴 **Missing** | No scanning logic to discover unmanaged devices on the network. |
| **II. Core Asset DB** | 🟢 **Implemented** | `Assets` context with encryption and history is fully built. |
| **III. Authentication** | 🟡 **Partial** | Frontend has `auth.ts` store; Backend lacks `User` schema and `Guardian` JWT implementation. |
| **IV. Real-Time Updates** | 🟡 **Partial** | Backend has `PubSub`; Frontend lacks WebSocket (`Phoenix.Socket`) integration. |
| **V. Integrations** | 🟢 **Implemented** | Adapters for BambooHR, Workday, NetSuite, etc., are present. |
| **VI. Testing** | 🔴 **Missing** | Tests are currently "To be created". |

## 3. Implementation Plan

To align the repository with the MVP specification, we must bridge the gap between the "Admin Console" and "Automated Discovery" while finalizing critical Auth infrastructure.

### Phase 1: Critical Infrastructure (Auth & Reliability)
**Goal:** Secure the platform and ensure data integrity.
1.  **Backend Auth:** Implement `Guardian` for JWT.
    *   Create `User` schema (distinct from `Employee`).
    *   Implement `AuthController` (`login`, `register`, `me`).
    *   Add Auth Plugs/Pipelines to `router.ex`.
2.  **Frontend Auth Connection:** Verify and update `frontend/src/services/api.ts` to point to new backend auth endpoints.
3.  **Tests:** Initialize backend test suite (`mix test`). Write unit tests for `Assets` and `Integrations` contexts.

### Phase 2: The "IATM" Core (Discovery)
**Goal:** Automate data collection per `SPEC.md`.
4.  **Agent Context (Backend):** Create a new context `Assetronics.Discovery.Agent`.
    *   Add API endpoints for agents to "check-in" (`POST /api/v1/agent/checkin`).
    *   Logic to upsert assets based on `serial_number`.
5.  **Agent Prototype (Client):** Create a simple CLI agent (Go/Rust/Python) that collects OS info and calls the backend API.
6.  **Network Scanner:** Implement simple scanning logic (e.g., Nmap wrapper) to populate "Unmanaged Assets".

### Phase 3: Real-Time Polish
**Goal:** Improve UX with live updates.
7.  **Backend Channels:** Create `AssetChannel` and `WorkflowChannel`.
8.  **Frontend WebSockets:** Integrate `phoenix` JS client into `frontend/src/services/socket.ts` and update Stores.

## Immediate Next Step
**Implement Backend Authentication:**
1.  Configure `Guardian`.
2.  Create `User` schema with password hashing (`Argon2`).
3.  Implement Login/Register controllers.
