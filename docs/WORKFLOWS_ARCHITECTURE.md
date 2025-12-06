# Workflows System Architecture

This document provides detailed technical architecture diagrams for the Assetronics workflow system.

---

## System Component Diagram

```mermaid
graph TB
    subgraph Client["Client Layer"]
        Browser[Web Browser]
        Mobile[Mobile App Future]
    end

    subgraph Frontend["Frontend Application (Vue 3 + TypeScript)"]
        Router[Vue Router]
        WorkflowsView[WorkflowsView.vue]
        WorkflowDetail[WorkflowDetailView.vue]
        CreateModal[CreateWorkflowModal.vue]
        WorkflowCard[WorkflowCard.vue]
        Store[Auth Store]
    end

    subgraph API["API Layer (Phoenix Framework)"]
        APIRouter[Router]
        WorkflowController[WorkflowController]
        WorkflowJSON[WorkflowJSON View]
        Auth[Authentication Plug]
        Tenant[Multi-Tenant Plug]
    end

    subgraph Business["Business Logic Layer"]
        WorkflowsContext[Workflows Context]
        Templates[Templates Module]
        WorkflowSchema[Workflow Schema]
        Changeset[Ecto Changeset]
    end

    subgraph Data["Data Layer"]
        Repo[Ecto Repo]
        Triplex[Triplex Multi-Tenant]
        DB[(PostgreSQL<br/>Schema-per-Tenant)]
    end

    subgraph Jobs["Background Jobs (Oban)"]
        OverdueWorker[Overdue Reminder Worker]
        AutoStartWorker[Auto-Start Worker]
        HRISWorker[HRIS Sync Worker]
    end

    subgraph Events["Event System"]
        PubSub[Phoenix PubSub]
        Broadcast[Event Broadcaster]
        Channel[WebSocket Channel]
    end

    subgraph External["External Integrations"]
        HRIS[HRIS Systems]
        Email[SMTP Email]
        MDM[MDM Systems]
    end

    Browser --> Router
    Router --> WorkflowsView
    Router --> WorkflowDetail
    WorkflowsView --> CreateModal
    WorkflowsView --> WorkflowCard

    CreateModal --> |HTTP Request| APIRouter
    WorkflowDetail --> |HTTP Request| APIRouter

    APIRouter --> Auth
    Auth --> Tenant
    Tenant --> WorkflowController

    WorkflowController --> WorkflowsContext
    WorkflowsContext --> Templates
    WorkflowsContext --> WorkflowSchema
    WorkflowSchema --> Changeset

    WorkflowsContext --> Repo
    Repo --> Triplex
    Triplex --> DB

    WorkflowsContext --> Broadcast
    Broadcast --> PubSub
    PubSub --> Channel
    Channel -.-> Browser

    Jobs --> WorkflowsContext
    Jobs --> Email

    HRIS -.->|Webhook| APIRouter
    WorkflowsContext -.->|Send Email| Email

    WorkflowController --> WorkflowJSON
    WorkflowJSON -.->|JSON Response| Browser
```

---

## Data Flow: Creating a Workflow from Template

```mermaid
sequenceDiagram
    autonumber
    participant User
    participant Browser
    participant VueRouter
    participant CreateModal
    participant API
    participant Controller
    participant Context
    participant Templates
    participant Repo
    participant DB
    participant PubSub
    participant Email

    User->>Browser: Navigate to /workflows
    Browser->>VueRouter: Route to WorkflowsView
    VueRouter-->>Browser: Render view

    User->>Browser: Click "Create Workflow"
    Browser->>CreateModal: Open modal (step 1)

    Note over CreateModal: Initialize with fallback templates
    CreateModal->>CreateModal: Load getFallbackTemplates()
    CreateModal-->>User: Show 4 templates immediately

    CreateModal->>API: GET /api/v1/workflows/templates
    API->>Controller: templates(conn, params)
    Controller->>Context: list_available_templates()
    Context->>Templates: list_templates()
    Templates-->>Context: Template metadata
    Context-->>Controller: Templates array
    Controller-->>API: JSON response
    API-->>CreateModal: Template data (or use fallback)

    User->>CreateModal: Select "Incoming Hardware"
    CreateModal->>CreateModal: Move to step 2
    CreateModal->>API: GET /api/v1/assets
    API-->>CreateModal: Assets list
    CreateModal->>API: GET /api/v1/employees
    API-->>CreateModal: Employees list

    User->>CreateModal: Fill form & submit
    CreateModal->>API: POST /api/v1/workflows/from-template
    Note over API: Body: {<br/>  template_key: "incoming_hardware",<br/>  asset_id: "uuid",<br/>  assigned_to: "it@company.com"<br/>}

    API->>Controller: create_from_template(conn, params)
    Controller->>Context: create_from_template(tenant, :incoming_hardware, attrs)
    Context->>Templates: from_template(:incoming_hardware, attrs)

    Note over Templates: Build complete workflow with:<br/>- 8 steps<br/>- Instructions<br/>- Asset ID<br/>- Due date

    Templates-->>Context: Workflow attributes map
    Context->>Context: create_workflow(tenant, attrs)
    Context->>Repo: insert(changeset, prefix: tenant_schema)
    Repo->>DB: INSERT INTO tenant_acme.workflows
    DB-->>Repo: Workflow record created
    Repo-->>Context: {:ok, workflow}

    Context->>PubSub: broadcast("workflows:tenant", "workflow_created")
    PubSub-->>Browser: WebSocket event

    Context->>Email: workflow_assigned(workflow, assigned_to)
    Email-->>User: Email notification

    Context-->>Controller: {:ok, workflow}
    Controller-->>API: JSON workflow response
    API-->>CreateModal: Workflow created
    CreateModal->>VueRouter: Navigate to /workflows/{id}
    VueRouter-->>User: Show workflow detail view
```

---

## Workflow State Machine

```mermaid
stateDiagram-v2
    [*] --> Pending: Created from<br/>Template or API

    state Pending {
        [*] --> AwaitingStart
        AwaitingStart --> AwaitingStart: Update metadata
    }

    Pending --> InProgress: POST /workflows/{id}/start

    state InProgress {
        [*] --> Step1
        Step1 --> Step2: Advance
        Step2 --> Step3: Advance
        Step3 --> StepN: Advance
        StepN --> ReadyToComplete: All steps done
    }

    InProgress --> InProgress: POST /workflows/{id}/advance
    InProgress --> Completed: POST /workflows/{id}/complete
    InProgress --> Cancelled: POST /workflows/{id}/cancel

    Pending --> Cancelled: POST /workflows/{id}/cancel

    state Completed {
        [*] --> Finalized
        Finalized --> Archived: After 90 days
    }

    state Cancelled {
        [*] --> WithReason
        WithReason: Cancellation reason required
    }

    Completed --> [*]
    Cancelled --> [*]

    note right of Pending
        Status: "pending"
        current_step: 0
        started_at: null
    end note

    note right of InProgress
        Status: "in_progress"
        current_step: 1..N
        started_at: timestamp
    end note

    note right of Completed
        Status: "completed"
        current_step: total_steps
        completed_at: timestamp
    end note

    note right of Cancelled
        Status: "cancelled"
        cancelled_at: timestamp
        metadata.cancellation_reason
    end note
```

---

## Template Processing Flow

```mermaid
flowchart TD
    Start([User Selects Template]) --> CheckType{Template Type?}

    CheckType -->|incoming_hardware| HW[Load Hardware Template]
    CheckType -->|new_employee| EMP[Load Employee Template]
    CheckType -->|equipment_return| RET[Load Return Template]
    CheckType -->|emergency_replacement| EMG[Load Emergency Template]

    HW --> BaseHW[Base Template:<br/>8 steps<br/>3 day duration<br/>Type: procurement]
    EMP --> BaseEMP[Base Template:<br/>9 steps<br/>7 day duration<br/>Type: onboarding]
    RET --> BaseRET[Base Template:<br/>6 steps<br/>2 day duration<br/>Type: offboarding]
    EMG --> BaseEMG[Base Template:<br/>5 steps<br/>1 day duration<br/>Type: repair]

    BaseHW --> Merge[Merge with User Attributes]
    BaseEMP --> Merge
    BaseRET --> Merge
    BaseEMG --> Merge

    Merge --> Attrs{User Provided<br/>Attributes}
    Attrs -->|asset_id| AddAsset[Link to Asset]
    Attrs -->|employee_id| AddEmp[Link to Employee]
    Attrs -->|assigned_to| AddAssign[Set Assignment]
    Attrs -->|due_date| AddDue[Set Due Date]
    Attrs -->|priority| AddPrio[Set Priority]

    AddAsset --> Build[Build Complete Workflow Object]
    AddEmp --> Build
    AddAssign --> Build
    AddDue --> Build
    AddPrio --> Build

    Build --> Validate{Validation}
    Validate -->|Valid| Insert[Insert to Database]
    Validate -->|Invalid| Error[Return Error]

    Insert --> Broadcast[Broadcast Event]
    Broadcast --> Notify[Send Email Notification]
    Notify --> Return([Return Workflow to Client])

    Error --> Return

    style Start fill:#e1f5e1
    style Return fill:#e1f5e1
    style Error fill:#ffe1e1
    style Validate fill:#fff3cd
```

---

## Multi-Tenant Data Isolation

```mermaid
graph TB
    subgraph Request["HTTP Request"]
        Headers[Headers:<br/>Authorization: Bearer token<br/>X-Tenant-ID: acme]
    end

    subgraph AuthLayer["Authentication Layer"]
        AuthPlug[Auth Plug]
        JWTVerify[Verify JWT Token]
        ExtractTenant[Extract Tenant from Token]
    end

    subgraph TenantLayer["Multi-Tenant Layer"]
        TenantPlug[Triplex Plug]
        ValidateTenant{Tenant<br/>Exists?}
        SetPrefix[Set Schema Prefix]
    end

    subgraph Database["PostgreSQL Database"]
        PublicSchema[(public schema<br/>tenants table)]
        TenantAcme[(tenant_acme schema<br/>workflows<br/>employees<br/>assets)]
        TenantFoo[(tenant_foo schema<br/>workflows<br/>employees<br/>assets)]
        TenantBar[(tenant_bar schema<br/>workflows<br/>employees<br/>assets)]
    end

    subgraph Query["Ecto Query Execution"]
        Repo[Repo.all/insert/update]
        Prefix[prefix: tenant_acme]
        Execute[Execute SQL with<br/>SET search_path TO tenant_acme]
    end

    Headers --> AuthPlug
    AuthPlug --> JWTVerify
    JWTVerify --> ExtractTenant
    ExtractTenant --> TenantPlug

    TenantPlug --> ValidateTenant
    ValidateTenant -->|Yes| SetPrefix
    ValidateTenant -->|No| Reject[401 Unauthorized]

    SetPrefix --> Repo
    Repo --> Prefix
    Prefix --> Execute

    Execute -->|Acme Request| TenantAcme
    Execute -->|Foo Request| TenantFoo
    Execute -->|Bar Request| TenantBar

    ValidateTenant -.->|Lookup| PublicSchema

    style Reject fill:#ffe1e1
    style TenantAcme fill:#e1f5e1
    style TenantFoo fill:#e1e5f5
    style TenantBar fill:#f5e1f5
```

---

## Integration Triggers: Auto-Creating Workflows

```mermaid
graph LR
    subgraph HRIS["HRIS System (BambooHR)"]
        NewHire[New Employee<br/>Added]
        Terminated[Employee<br/>Terminated]
    end

    subgraph Webhook["Webhook Handler"]
        Receiver[POST /api/v1/webhooks/hris]
        Verify[Verify Signature]
        Parse[Parse Payload]
    end

    subgraph Logic["Business Logic"]
        CheckEvent{Event Type?}
        CreateOnboard[Create Onboarding<br/>Workflow]
        CreateOffboard[Create Offboarding<br/>Workflow]
    end

    subgraph Workflow["Workflow System"]
        OnboardTemplate[New Employee Template<br/>9 steps, 7 days]
        OffboardTemplate[Equipment Return Template<br/>6 steps, 2 days]
        InsertDB[(Insert Workflow)]
    end

    subgraph Notify["Notifications"]
        EmailIT[Email IT Team]
        SlackMsg[Slack Message]
    end

    NewHire -->|Webhook POST| Receiver
    Terminated -->|Webhook POST| Receiver

    Receiver --> Verify
    Verify --> Parse
    Parse --> CheckEvent

    CheckEvent -->|employee.created| CreateOnboard
    CheckEvent -->|employee.terminated| CreateOffboard

    CreateOnboard --> OnboardTemplate
    CreateOffboard --> OffboardTemplate

    OnboardTemplate --> InsertDB
    OffboardTemplate --> InsertDB

    InsertDB --> EmailIT
    InsertDB --> SlackMsg

    style NewHire fill:#e1f5e1
    style Terminated fill:#ffe1e1
```

---

## Background Job Architecture

```mermaid
graph TB
    subgraph Scheduler["Oban Cron Scheduler"]
        Cron1[Every 15 min:<br/>HRIS Sync]
        Cron2[Daily 9 AM:<br/>Overdue Reminders]
        Cron3[Daily 6 AM:<br/>Auto-Start Onboarding]
    end

    subgraph Queue["Oban Job Queues"]
        IntQueue[integrations queue<br/>20 workers]
        DefaultQueue[default queue<br/>10 workers]
        NotifQueue[notifications queue<br/>5 workers]
    end

    subgraph Workers["Oban Workers"]
        HRISWorker[HRIS Sync Worker]
        OverdueWorker[Overdue Reminder Worker]
        AutoStartWorker[Auto-Start Worker]
        EmailWorker[Email Worker]
    end

    subgraph Processing["Job Processing"]
        FetchData[Fetch HRIS Data]
        FindOverdue[Find Overdue Workflows]
        FindToStart[Find Workflows<br/>Due Today]
        SendEmail[Send Email via SMTP]
    end

    subgraph Database["Database Operations"]
        CreateWorkflows[Create Workflows]
        UpdateStatus[Update Statuses]
        LogHistory[Log Job History]
    end

    Cron1 --> IntQueue
    Cron2 --> NotifQueue
    Cron3 --> DefaultQueue

    IntQueue --> HRISWorker
    NotifQueue --> OverdueWorker
    NotifQueue --> EmailWorker
    DefaultQueue --> AutoStartWorker

    HRISWorker --> FetchData
    OverdueWorker --> FindOverdue
    AutoStartWorker --> FindToStart

    FetchData --> CreateWorkflows
    FindOverdue --> SendEmail
    FindToStart --> UpdateStatus

    CreateWorkflows --> LogHistory
    SendEmail --> LogHistory
    UpdateStatus --> LogHistory

    style LogHistory fill:#e1f5e1
```

---

## Real-Time Event Broadcasting

```mermaid
sequenceDiagram
    participant User1 as User 1 (Browser)
    participant User2 as User 2 (Browser)
    participant Phoenix as Phoenix Server
    participant PubSub as Phoenix PubSub
    participant Context as Workflows Context
    participant DB as Database

    User1->>Phoenix: WebSocket Connect
    Phoenix->>PubSub: Join channel "workflows:tenant_acme"
    PubSub-->>Phoenix: Subscribed
    Phoenix-->>User1: Connected

    User2->>Phoenix: WebSocket Connect
    Phoenix->>PubSub: Join channel "workflows:tenant_acme"
    PubSub-->>Phoenix: Subscribed
    Phoenix-->>User2: Connected

    Note over User1,User2: Both users subscribed to same tenant channel

    User1->>Phoenix: POST /workflows/{id}/advance
    Phoenix->>Context: advance_workflow_step(tenant, workflow)
    Context->>DB: UPDATE workflow SET current_step = 2
    DB-->>Context: Updated

    Context->>PubSub: broadcast("workflows:tenant_acme", "workflow_step_advanced")

    PubSub-->>Phoenix: Event to User1
    PubSub-->>Phoenix: Event to User2

    Phoenix-->>User1: workflow_step_advanced event
    Phoenix-->>User2: workflow_step_advanced event

    User1->>User1: Update UI (current step highlighted)
    User2->>User2: Update UI (real-time refresh)

    Note over User1,User2: Both users see the same updated workflow in real-time
```

---

## Template Step Structure

```mermaid
classDiagram
    class WorkflowTemplate {
        +String title
        +String workflow_type
        +String priority
        +String description
        +Array~Step~ steps
        +Integer estimated_duration_days
        +Integer step_count
    }

    class Step {
        +Integer order
        +String name
        +String description
        +String instructions
        +Boolean completed
        +String assigned_to
        +DateTime completed_at
    }

    class WorkflowInstance {
        +UUID id
        +String tenant_id
        +String title
        +String workflow_type
        +String status
        +String priority
        +Integer current_step
        +Integer total_steps
        +Array~Step~ steps
        +Date due_date
        +String assigned_to
        +DateTime started_at
        +DateTime completed_at
        +UUID employee_id
        +UUID asset_id
        +String triggered_by
        +Map metadata
    }

    class IncomingHardware {
        +step1: "Receive Shipment"
        +step2: "Initial Inspection"
        +step3: "Asset Registration"
        +step4: "Configuration & Setup"
        +step5: "Quality Assurance Testing"
        +step6: "Assignment & Deployment"
        +step7: "User Onboarding"
        +step8: "Follow-up & Documentation"
    }

    class NewEmployee {
        +step1: "Pre-Onboarding Preparation"
        +step2: "Account Provisioning"
        +step3: "Software License Assignment"
        +step4: "Hardware Setup"
        +step5: "Day 1 - Welcome & Access"
        +step6: "Day 1 - IT Orientation"
        +step7: "Week 1 - Application Access"
        +step8: "Week 1 - Training"
        +step9: "Week 1 - Follow-up"
    }

    WorkflowTemplate *-- Step : contains
    WorkflowInstance *-- Step : contains
    IncomingHardware --|> WorkflowTemplate
    NewEmployee --|> WorkflowTemplate
    WorkflowTemplate ..> WorkflowInstance : instantiates
```

---

## Security & Authorization Flow

```mermaid
graph TB
    Request[HTTP Request] --> CheckAuth{Has Valid<br/>JWT Token?}

    CheckAuth -->|No| Reject401[401 Unauthorized]
    CheckAuth -->|Yes| ExtractTenant[Extract Tenant ID]

    ExtractTenant --> ValidateTenant{User Belongs<br/>to Tenant?}
    ValidateTenant -->|No| Reject403[403 Forbidden]
    ValidateTenant -->|Yes| CheckRole{User Role?}

    CheckRole -->|Admin| FullAccess[Full Access to<br/>All Workflows]
    CheckRole -->|Manager| TeamAccess[Access to Team<br/>Workflows Only]
    CheckRole -->|User| LimitedAccess[View Own<br/>Workflows Only]

    FullAccess --> ExecuteQuery[Execute Query<br/>with Tenant Prefix]
    TeamAccess --> ExecuteQuery
    LimitedAccess --> ExecuteQuery

    ExecuteQuery --> EncryptData{Contains<br/>Sensitive Data?}

    EncryptData -->|Yes| Encrypt[Encrypt with<br/>Cloak AES-256-GCM]
    EncryptData -->|No| Return[Return Response]

    Encrypt --> Return

    Return --> AuditLog[Log to Audit Trail]
    AuditLog --> Success[200 OK]

    style Reject401 fill:#ffe1e1
    style Reject403 fill:#ffe1e1
    style Success fill:#e1f5e1
```

---

## Performance Optimization Strategy

```mermaid
graph LR
    subgraph Client["Client Optimizations"]
        LazyLoad[Lazy Load<br/>Workflow Steps]
        Pagination[Paginated Lists<br/>20 per page]
        Cache[Browser Cache<br/>Templates]
    end

    subgraph API["API Optimizations"]
        Index[Database Indexes<br/>on status, type, due_date]
        Preload[Ecto Preload<br/>employee, asset]
        Limit[LIMIT queries<br/>No N+1]
    end

    subgraph Database["Database Optimizations"]
        PartialIndex[Partial Index:<br/>WHERE status IN pending, in_progress]
        JSONB[JSONB GIN Index<br/>on steps array]
        Vacuum[Auto-Vacuum<br/>Dead Tuple Cleanup]
    end

    subgraph Caching["Caching Layer"]
        ETS[ETS In-Memory<br/>Template Cache]
        Redis[Redis Optional:<br/>Workflow Summaries]
    end

    Client --> API
    API --> Caching
    Caching --> Database

    LazyLoad -.-> Pagination
    Index -.-> Preload
    PartialIndex -.-> JSONB

    style ETS fill:#e1f5e1
    style Index fill:#e1f5e1
```

---

## Monitoring & Observability

```mermaid
graph TB
    subgraph Application["Application Metrics"]
        WorkflowCount[Total Workflows<br/>by Status]
        AvgDuration[Average Completion<br/>Time by Type]
        OverdueRate[Overdue Rate<br/>Percentage]
        StepTime[Time per Step<br/>Average]
    end

    subgraph Logs["Centralized Logging"]
        StructLog[Structured Logs<br/>JSON Format]
        LogLevel[Log Levels:<br/>info, warn, error]
        Context[Contextual Data:<br/>tenant, workflow_id, step]
    end

    subgraph Alerts["Alerting Rules"]
        OverdueAlert[Alert if >20%<br/>workflows overdue]
        FailureAlert[Alert on workflow<br/>creation failure]
        SLAAlert[Alert if step time<br/>> 2x estimated]
    end

    subgraph Tools["Monitoring Tools"]
        Phoenix[Phoenix LiveDashboard]
        Sentry[Sentry Error Tracking]
        DataDog[DataDog APM Optional]
    end

    WorkflowCount --> Phoenix
    AvgDuration --> Phoenix
    OverdueRate --> Phoenix
    StepTime --> Phoenix

    StructLog --> Sentry
    LogLevel --> Sentry
    Context --> Sentry

    OverdueAlert --> Sentry
    FailureAlert --> Sentry
    SLAAlert --> Sentry

    Phoenix -.->|Export| DataDog
    Sentry -.->|Export| DataDog

    style OverdueAlert fill:#ffe1e1
    style FailureAlert fill:#ffe1e1
    style SLAAlert fill:#ffe1e1
```

---

## Deployment Architecture

```mermaid
graph TB
    subgraph Internet["Internet"]
        Users[End Users]
    end

    subgraph LoadBalancer["Load Balancer"]
        LB[Nginx / HAProxy<br/>SSL Termination]
    end

    subgraph AppServers["Application Servers (2+ instances)"]
        App1[Phoenix Server 1<br/>Port 4000]
        App2[Phoenix Server 2<br/>Port 4000]
    end

    subgraph Database["Database Cluster"]
        Primary[(PostgreSQL Primary<br/>Read/Write)]
        Replica[(PostgreSQL Replica<br/>Read Only)]
    end

    subgraph Jobs["Background Jobs"]
        Oban1[Oban Worker Pool 1]
        Oban2[Oban Worker Pool 2]
    end

    subgraph Cache["Caching & Queue"]
        Redis[(Redis<br/>Session/Cache)]
        PGQueue[(PostgreSQL<br/>Oban Jobs Table)]
    end

    subgraph Storage["File Storage"]
        S3[(S3-Compatible<br/>Workflow Attachments)]
    end

    subgraph Monitoring["Monitoring Stack"]
        Metrics[Prometheus]
        Viz[Grafana]
        Errors[Sentry]
    end

    Users --> LB
    LB --> App1
    LB --> App2

    App1 --> Primary
    App1 --> Replica
    App2 --> Primary
    App2 --> Replica

    App1 --> Redis
    App2 --> Redis

    App1 --> S3
    App2 --> S3

    Oban1 --> PGQueue
    Oban2 --> PGQueue
    PGQueue --> Primary

    App1 --> Metrics
    App2 --> Metrics
    Metrics --> Viz

    App1 --> Errors
    App2 --> Errors

    style Primary fill:#e1f5e1
    style LB fill:#e1e5f5
```

---

**Last Updated**: 2025-11-30
**Version**: 1.0.0
