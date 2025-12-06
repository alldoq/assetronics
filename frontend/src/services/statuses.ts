import api from './api'

export interface Status {
  id: number
  name: string
  value: string
  description?: string
  color: string
  created_at: string
  updated_at: string
}

export interface CreateStatusData {
  name: string
  value: string
  description?: string
  color: string
}

export interface UpdateStatusData extends Partial<CreateStatusData> {}

export const statusesService = {
  // Get all statuses
  async getAll(): Promise<Status[]> {
    const response = await api.get('/statuses')
    return response.data.data
  },

  // Get single status
  async getById(id: number): Promise<Status> {
    const response = await api.get(`/statuses/${id}`)
    return response.data.data
  },

  // Create status
  async create(data: CreateStatusData): Promise<Status> {
    const response = await api.post('/statuses', { status: data })
    return response.data.data
  },

  // Update status
  async update(id: number, data: UpdateStatusData): Promise<Status> {
    const response = await api.put(`/statuses/${id}`, { status: data })
    return response.data.data
  },

  // Delete status
  async delete(id: number): Promise<void> {
    await api.delete(`/statuses/${id}`)
  },
}
