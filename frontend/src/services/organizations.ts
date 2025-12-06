import api from './api'

export type OrganizationType =
  | 'holding_company'
  | 'parent_company'
  | 'subsidiary'
  | 'division'
  | 'business_unit'
  | 'branch'
  | 'other'

export interface Organization {
  id: number
  name: string
  type?: OrganizationType
  description?: string
  parent_id?: number
  parent?: Organization
  children?: Organization[]
  level?: number
  path?: string[]
  created_at: string
  updated_at: string
}

export interface CreateOrganizationData {
  name: string
  type?: OrganizationType
  description?: string
  parent_id?: number
}

export interface UpdateOrganizationData extends Partial<CreateOrganizationData> {}

export const organizationsService = {
  // Get all organizations
  async getAll(): Promise<Organization[]> {
    const response = await api.get('/organizations')
    return response.data.data
  },

  // Get single organization
  async getById(id: number): Promise<Organization> {
    const response = await api.get(`/organizations/${id}`)
    return response.data.data
  },

  // Create organization
  async create(data: CreateOrganizationData): Promise<Organization> {
    const response = await api.post('/organizations', { organization: data })
    return response.data.data
  },

  // Update organization
  async update(id: number, data: UpdateOrganizationData): Promise<Organization> {
    const response = await api.put(`/organizations/${id}`, { organization: data })
    return response.data.data
  },

  // Delete organization
  async delete(id: number): Promise<void> {
    await api.delete(`/organizations/${id}`)
  },
}
