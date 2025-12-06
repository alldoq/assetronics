import api from './api'
import type { Organization } from './organizations'
import type { Department } from './departments'
import type { Location } from './locations'

export interface EmployeeAsset {
  id: string
  asset_tag?: string
  name: string
  category: string
  make?: string
  model?: string
  status: string
  condition?: string
  assigned_at?: string
}

export interface Employee {
  id: string
  employee_id?: string
  hris_id?: string
  first_name: string
  last_name: string
  email: string
  phone?: string
  job_title?: string
  avatar_url?: string
  department?: string  // Legacy field from HRIS
  organization_id?: number
  organization?: Organization
  department_id?: number
  department_info?: Department
  manager_id?: string
  manager?: Employee
  hire_date?: string
  termination_date?: string
  employment_status: 'active' | 'on_leave' | 'terminated'
  office_location_id?: string
  office_location?: Location
  work_location_type?: 'office' | 'remote' | 'hybrid'
  home_address?: Record<string, any>
  date_of_birth?: string
  ssn?: string
  national_id?: string
  notes?: string
  custom_fields?: Record<string, any>
  assets?: EmployeeAsset[]
  assets_count?: number
  inserted_at?: string
  created_at?: string
  updated_at: string
}

export interface CreateEmployeeData {
  employee_id?: string
  hris_id?: string
  first_name: string
  last_name: string
  email: string
  phone?: string
  job_title?: string
  department?: string
  organization_id?: number
  department_id?: number
  manager_id?: string
  hire_date?: string
  termination_date?: string
  employment_status: string
  office_location_id?: string
  work_location_type?: string
  home_address?: Record<string, any>
  date_of_birth?: string
  ssn?: string
  national_id?: string
  notes?: string
  custom_fields?: Record<string, any>
  photo?: File
}

export interface UpdateEmployeeData extends Partial<CreateEmployeeData> {}

export const employeesService = {
  // Get all employees
  async getAll(): Promise<Employee[]> {
    const response = await api.get('/employees')
    return response.data.data
  },

  // Get single employee
  async getById(id: string): Promise<Employee> {
    const response = await api.get(`/employees/${id}`)
    return response.data.data
  },

  // Create employee
  async create(data: CreateEmployeeData): Promise<Employee> {
    const formData = new FormData()

    Object.keys(data).forEach((key) => {
      const value = data[key as keyof CreateEmployeeData]
      if (value !== undefined && value !== null) {
        if (key === 'photo' && value instanceof File) {
          formData.append('employee[photo]', value)
        } else if (key === 'custom_fields' && typeof value === 'object') {
          Object.keys(value).forEach((subKey) => {
            formData.append(`employee[custom_fields][${subKey}]`, String((value as any)[subKey]))
          })
        } else {
          formData.append(`employee[${key}]`, String(value))
        }
      }
    })

    const response = await api.post('/employees', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    })
    return response.data.data
  },

  // Update employee
  async update(id: string, data: UpdateEmployeeData): Promise<Employee> {
    const formData = new FormData()

    Object.keys(data).forEach((key) => {
      const value = data[key as keyof UpdateEmployeeData]
      if (value !== undefined && value !== null) {
        if (key === 'photo' && value instanceof File) {
          formData.append('employee[photo]', value)
        } else if (key === 'custom_fields' && typeof value === 'object') {
          Object.keys(value).forEach((subKey) => {
            formData.append(`employee[custom_fields][${subKey}]`, String((value as any)[subKey]))
          })
        } else {
          formData.append(`employee[${key}]`, String(value))
        }
      }
    })

    const response = await api.put(`/employees/${id}`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    })
    return response.data.data
  },

  // Delete employee
  async delete(id: string): Promise<void> {
    await api.delete(`/employees/${id}`)
  },

  // Terminate employee
  async terminate(id: string, data: { termination_date: string; reason: string; notes?: string }): Promise<Employee> {
    const response = await api.post(`/employees/${id}/terminate`, data)
    return response.data.data
  },

  // Reactivate employee
  async reactivate(id: string): Promise<Employee> {
    const response = await api.post(`/employees/${id}/reactivate`, {})
    return response.data.data
  },

  // Get employee assets
  async getAssets(id: string): Promise<EmployeeAsset[]> {
    const response = await api.get(`/employees/${id}/assets`)
    return response.data.data.assets
  }
}
