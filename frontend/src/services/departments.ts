import api from './api'

export type DepartmentType =
  | 'division'
  | 'department'
  | 'team'
  | 'unit'
  | 'group'
  | 'other'

export interface Department {
  id: number
  name: string
  type?: DepartmentType
  description?: string
  parent_id?: number
  parent?: Department
  children?: Department[]
  level?: number
  path?: string[]
  created_at: string
  updated_at: string
}

export interface CreateDepartmentData {
  name: string
  type?: DepartmentType
  description?: string
  parent_id?: number
}

export interface UpdateDepartmentData extends Partial<CreateDepartmentData> {}

export const departmentsService = {
  // Get all departments
  async getAll(): Promise<Department[]> {
    const response = await api.get('/departments')
    return response.data.data
  },

  // Get single department
  async getById(id: number): Promise<Department> {
    const response = await api.get(`/departments/${id}`)
    return response.data.data
  },

  // Create department
  async create(data: CreateDepartmentData): Promise<Department> {
    const response = await api.post('/departments', { department: data })
    return response.data.data
  },

  // Update department
  async update(id: number, data: UpdateDepartmentData): Promise<Department> {
    const response = await api.put(`/departments/${id}`, { department: data })
    return response.data.data
  },

  // Delete department
  async delete(id: number): Promise<void> {
    await api.delete(`/departments/${id}`)
  },
}
