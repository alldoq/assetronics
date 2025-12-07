import api from './api'

export interface SoftwareLicense {
  id: string
  name: string
  vendor: string
  description?: string
  total_seats: number
  available_seats?: number
  used_seats?: number
  utilization_rate?: number
  annual_cost?: number
  cost_per_seat?: number
  purchase_date?: string
  expiration_date?: string
  status: 'active' | 'expired' | 'cancelled' | 'future'
  license_key?: string
  sso_app_id?: string
  integration_id?: string
  integration?: {
    id: string
    name: string
    provider: string
  }
  created_at: string
  updated_at: string
}

export interface SoftwareAssignment {
  id: string
  employee_id: string
  software_license_id: string
  assigned_at: string
  last_used_at?: string
  status: 'active' | 'revoked'
  employee?: {
    id: string
    first_name: string
    last_name: string
    email: string
  }
  software_license?: SoftwareLicense
  created_at: string
  updated_at: string
}

export interface CreateSoftwareLicenseData {
  name: string
  vendor: string
  description?: string
  total_seats: number
  annual_cost?: number
  cost_per_seat?: number
  purchase_date?: string
  expiration_date?: string
  status: string
  license_key?: string
  sso_app_id?: string
  integration_id?: string
}

export interface UpdateSoftwareLicenseData extends Partial<CreateSoftwareLicenseData> {}

export interface PaginationMeta {
  total: number
  page: number
  per_page: number
  total_pages: number
}

export interface PaginatedResponse<T> {
  data: T[]
  meta: PaginationMeta
}

export interface SoftwareFilters {
  page?: number
  per_page?: number
  status?: string
  vendor?: string
  q?: string
}

export interface AssignSoftwareData {
  employee_id: string
  assigned_at?: string
  status?: string
}

export const softwareService = {
  // Get all licenses with pagination and filters
  async getAll(filters?: SoftwareFilters): Promise<PaginatedResponse<SoftwareLicense>> {
    const response = await api.get('/software', {
      params: filters,
    })
    return response.data
  },

  // Get single license
  async getById(id: string): Promise<SoftwareLicense> {
    const response = await api.get(`/software/${id}`)
    return response.data.data
  },

  // Get license stats
  async getStats(id: string): Promise<any> {
    const response = await api.get(`/software/${id}/stats`)
    return response.data.data
  },

  // Get license assignments
  async getAssignments(id: string): Promise<SoftwareAssignment[]> {
    const response = await api.get(`/software/${id}/assignments`)
    return response.data.data
  },

  // Get employee's software licenses
  async getEmployeeLicenses(employeeId: string): Promise<SoftwareAssignment[]> {
    const response = await api.get(`/employees/${employeeId}/software`)
    return response.data.data
  },

  // Create license
  async create(data: CreateSoftwareLicenseData): Promise<SoftwareLicense> {
    const response = await api.post('/software', { software: data })
    return response.data.data
  },

  // Update license
  async update(id: string, data: UpdateSoftwareLicenseData): Promise<SoftwareLicense> {
    const response = await api.put(`/software/${id}`, { software: data })
    return response.data.data
  },

  // Delete license
  async delete(id: string): Promise<void> {
    await api.delete(`/software/${id}`)
  },

  // Assign license to employee
  async assign(licenseId: string, data: AssignSoftwareData): Promise<SoftwareAssignment> {
    const response = await api.post(`/software/${licenseId}/assign`, data)
    return response.data.data
  },

  // Revoke assignment
  async revokeAssignment(licenseId: string, assignmentId: string): Promise<void> {
    await api.post(`/software/${licenseId}/revoke`, { assignment_id: assignmentId })
  },

  // Get expiring licenses
  async getExpiring(days: number = 30): Promise<SoftwareLicense[]> {
    const response = await api.get('/software/expiring', {
      params: { days }
    })
    return response.data.data
  },

  // Get underutilized licenses
  async getUnderutilized(threshold: number = 50): Promise<SoftwareLicense[]> {
    const response = await api.get('/software/underutilized', {
      params: { threshold }
    })
    return response.data.data
  }
}
