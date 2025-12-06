import axios, { type AxiosInstance, type AxiosError } from 'axios'

// API Configuration
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:4000/api/v1'
const DEFAULT_TENANT = import.meta.env.VITE_DEFAULT_TENANT || 'acme'

// Create axios instance
const apiClient: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
    'X-Tenant-ID': DEFAULT_TENANT,
  },
  timeout: 10000,
})

// Request interceptor to add auth token
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('auth_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor for error handling
apiClient.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    if (error.response?.status === 401) {
      // Clear auth data and redirect to login
      localStorage.removeItem('auth_token')
      localStorage.removeItem('user')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

// API Types
export interface LoginCredentials {
  email: string
  password: string
}

export interface RegisterData {
  email: string
  password: string
  first_name: string
  last_name: string
  phone?: string
}

export interface User {
  id: string
  email: string
  first_name: string
  last_name: string
  role: string
  status: string
  phone?: string
  avatar_url?: string
  email_verified_at?: string
  tenant_id?: string  // Tenant slug (e.g., "acme")
}

export interface AuthResponse {
  access_token: string
  refresh_token: string
  user: User
}

export interface ForgotPasswordData {
  email: string
}

export interface ResetPasswordData {
  token: string
  password: string
  password_confirmation: string
}

export interface MessageResponse {
  message: string
}

// Auth API
export const authApi = {
  login: async (credentials: LoginCredentials): Promise<AuthResponse> => {
    const response = await apiClient.post<{ data: AuthResponse }>('/auth/login', credentials)
    return response.data.data
  },

  register: async (data: RegisterData): Promise<AuthResponse> => {
    const response = await apiClient.post<{ data: AuthResponse }>('/auth/register', data)
    return response.data.data
  },

  logout: async (): Promise<void> => {
    await apiClient.post('/auth/logout')
  },

  getCurrentUser: async (): Promise<User> => {
    const response = await apiClient.get<{ data: { user: User; tenant: string } }>('/auth/me')
    return response.data.data.user
  },

  forgotPassword: async (data: ForgotPasswordData): Promise<MessageResponse> => {
    const response = await apiClient.post<MessageResponse>('/auth/forgot-password', data)
    return response.data
  },

  resetPassword: async (data: ResetPasswordData): Promise<MessageResponse> => {
    const response = await apiClient.post<MessageResponse>('/auth/reset-password', data)
    return response.data
  },

  validateResetToken: async (token: string): Promise<MessageResponse> => {
    const response = await apiClient.get<MessageResponse>(`/auth/validate-reset-token/${token}`)
    return response.data
  },
}

// Settings API Types
export interface NotificationPreference {
  id: string
  user_id: string
  notification_type: string
  channels: {
    email: boolean
    in_app: boolean
    sms: boolean
    push: boolean
  }
  frequency: 'immediate' | 'daily_digest' | 'weekly_digest' | 'off'
  respect_quiet_hours: boolean
  inserted_at: string
  updated_at: string
}

export interface TenantSettings {
  id: string
  email: {
    from_address?: string
    from_name?: string
    reply_to?: string
    bcc_admin: boolean
  }
  quiet_hours: {
    enabled: boolean
    start?: string
    end?: string
    timezone: string
  }
  workflow: {
    auto_create_onboarding: boolean
    auto_create_offboarding: boolean
    default_priority: string
    default_due_days: number
    auto_escalate_days: number
    notify_manager_overdue: boolean
  }
  integration: {
    sync_frequency_minutes: number
    max_retries: number
    retry_backoff_minutes: number
    conflict_resolution: string
    notify_on_failure: boolean
  }
  asset: {
    depreciation_method: string
    depreciation_months: number
    warranty_alert_days: number
    audit_frequency_months: number
    tag_prefix?: string
    auto_generate_tags: boolean
    require_serial: boolean
    enforce_serial_unique: boolean
  }
  employee: {
    auto_terminate_on_hris_delete: boolean
    termination_asset_return_days: number
    require_return_confirmation: boolean
    sync_frequency_minutes: number
  }
  security: {
    require_2fa: boolean
    session_timeout_minutes: number
    failed_login_lockout_count: number
    lockout_duration_minutes: number
    password_expiration_days?: number
    require_strong_passwords: boolean
    api_key_expiration_days: number
  }
  audit: {
    enable_detailed_logging: boolean
    log_retention_days: number
    require_change_approval: boolean
    approval_threshold_amount?: number
    compliance_framework: string
  }
  reporting: {
    auto_generate: boolean
    frequency: string
    default_format: string
    include_sensitive_data: boolean
  }
  inserted_at: string
  updated_at: string
}

// Settings API
export const settingsApi = {
  // Get tenant settings
  getTenantSettings: async (): Promise<TenantSettings> => {
    const response = await apiClient.get<{ data: TenantSettings }>('/settings')
    return response.data.data
  },

  // Update tenant settings
  updateTenantSettings: async (settings: Partial<TenantSettings>): Promise<TenantSettings> => {
    const response = await apiClient.patch<{ data: TenantSettings }>('/settings', { settings })
    return response.data.data
  },

  // Get all user notification preferences
  getUserNotificationPreferences: async (): Promise<NotificationPreference[]> => {
    const response = await apiClient.get<{ data: NotificationPreference[] }>('/preferences/notifications')
    return response.data.data
  },

  // Get a specific notification preference
  getUserNotificationPreference: async (notificationType: string): Promise<NotificationPreference> => {
    const response = await apiClient.get<{ data: NotificationPreference }>(`/preferences/notifications/${notificationType}`)
    return response.data.data
  },

  // Update a specific notification preference
  updateUserNotificationPreference: async (
    notificationType: string,
    preference: Partial<NotificationPreference>
  ): Promise<NotificationPreference> => {
    const response = await apiClient.patch<{ data: NotificationPreference }>(
      `/preferences/notifications/${notificationType}`,
      { preference }
    )
    return response.data.data
  },
}

export default apiClient
