import api from './api'

export type LocationType =
  | 'region'
  | 'country'
  | 'state'
  | 'city'
  | 'office'
  | 'building'
  | 'floor'
  | 'warehouse'
  | 'datacenter'
  | 'store'
  | 'other'

export interface Location {
  id: number
  name: string
  location_type?: LocationType
  is_active?: boolean
  address_line1?: string
  address_line2?: string
  city?: string
  state_province?: string
  postal_code?: string
  country?: string
  contact_name?: string
  contact_email?: string
  contact_phone?: string
  notes?: string
  custom_fields?: Record<string, any>
  parent_id?: number
  parent?: Location
  children?: Location[]
  level?: number
  path?: string[]
  inserted_at: string
  updated_at: string
  // Legacy aliases for backward compatibility
  address?: string
  state?: string
  created_at?: string
}

export interface CreateLocationData {
  name: string
  location_type?: LocationType
  is_active?: boolean
  address_line1?: string
  address_line2?: string
  city?: string
  state_province?: string
  postal_code?: string
  country?: string
  contact_name?: string
  contact_email?: string
  contact_phone?: string
  notes?: string
  custom_fields?: Record<string, any>
  parent_id?: number
}

export interface UpdateLocationData extends Partial<CreateLocationData> {}

export const locationsService = {
  // Get all locations
  async getAll(): Promise<Location[]> {
    const response = await api.get('/locations')
    return response.data.data
  },

  // Get single location
  async getById(id: number): Promise<Location> {
    const response = await api.get(`/locations/${id}`)
    return response.data.data
  },

  // Create location
  async create(data: CreateLocationData): Promise<Location> {
    const response = await api.post('/locations', { location: data })
    return response.data.data
  },

  // Update location
  async update(id: number, data: UpdateLocationData): Promise<Location> {
    const response = await api.put(`/locations/${id}`, { location: data })
    return response.data.data
  },

  // Delete location
  async delete(id: number): Promise<void> {
    await api.delete(`/locations/${id}`)
  },
}
