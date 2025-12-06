import apiClient from './api'

// Dashboard Types
export interface DashboardResponse {
  data: EmployeeDashboard | ManagerDashboard | AdminDashboard
  role: 'employee' | 'manager' | 'admin' | 'super_admin'
}

// Employee Dashboard Types
export interface EmployeeDashboard {
  employee: {
    id: string
    name: string
    email: string
    department: string
    job_title: string
  }
  my_assets: Asset[]
  my_workflows: Workflow[]
  recent_activity: Activity[]
  stats: {
    total_assets: number
    active_workflows: number
    pending_tasks: number
  }
}

export interface Asset {
  id: string
  name: string
  asset_tag: string
  serial_number: string
  category: string
  assigned_at: string
  expected_return_date: string | null
  assignment_type: string
}

export interface Workflow {
  id: string
  title: string
  workflow_type: string
  status: string
  progress: number
  due_date: string | null
  total_steps: number
  completed_steps: number
}

export interface Activity {
  id: string
  transaction_type: string
  performed_at: string
  asset_name: string | null
  employee_name: string | null
}

// Manager Dashboard Types
export interface ManagerDashboard {
  manager: {
    id: string
    name: string
    department: string
  }
  team_overview: {
    team_size: number
    total_assets: number
    active_workflows: number
  }
  asset_distribution: Array<{
    category: string
    count: number
  }>
  workflow_status: Array<{
    workflow_type: string
    count: number
  }>
  key_metrics: {
    team_utilization: number
    onboarding_completion_rate: number
    avg_time_to_equipment: number
    assets_per_employee: number
  }
}

// Admin Dashboard Types
export interface AdminDashboard {
  asset_inventory: {
    total: number
    by_status: {
      in_stock: number
      assigned: number
      in_repair: number
      retired: number
      on_order: number
      in_transit: number
      lost: number
      stolen: number
    }
    utilization_rate: number
    warranty_expiring_soon: number
  }
  workflow_metrics: {
    active_by_type: {
      onboarding: number
      offboarding: number
      repair: number
      maintenance: number
      procurement: number
    }
    overdue: number
    avg_completion_time: Record<string, number>
  }
  integration_health: {
    integrations: Integration[]
    success_rate_24h: number
    failed_syncs: number
  }
  employee_status: {
    total: number
    active: number
    new_hires: number
    terminations: number
  }
  recent_activity: Activity[]
  alerts: Alert[]
}

export interface Integration {
  id: string
  provider: string
  name: string
  last_sync_at: string | null
  last_sync_status: string | null
  last_sync_error: string | null
  last_sync_records_count?: number
}

export interface Alert {
  severity: 'error' | 'warning' | 'info'
  type: string
  message: string
  count: number
}

// Dashboard API Service
export const dashboardService = {
  /**
   * Get dashboard data for the current user
   * Returns role-specific dashboard data
   */
  async getDashboard(): Promise<DashboardResponse> {
    const response = await apiClient.get<DashboardResponse>('/dashboard')
    return response.data
  },
}
