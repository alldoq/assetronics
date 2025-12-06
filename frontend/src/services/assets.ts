import api from './api'

export interface Asset {
  id: string
  name: string
  serial_number?: string
  category: string
  status: 'on_order' | 'in_stock' | 'assigned' | 'in_transit' | 'in_repair' | 'retired' | 'lost' | 'stolen'
  description?: string
  purchase_date?: string
  purchase_price?: number
  vendor?: string
  department?: string
  location_id?: number
  location?: {
    id: number
    name: string
  }
  employee_id?: number
  employee?: {
    id: number
    first_name: string
    last_name: string
  }
  warranty_expiration?: string
  condition?: 'new' | 'excellent' | 'good' | 'fair' | 'poor'
  notes?: string
  custom_fields?: Record<string, any>
  tags?: string[]
  photo_url?: string
  image_url?: string
  created_at: string
  updated_at: string
}

export interface CreateAssetData {
  name: string
  serial_number?: string
  category: string
  status: string
  description?: string
  purchase_date?: string
  purchase_price?: number
  vendor?: string
  department?: string
  location_id?: number
  employee_id?: number
  warranty_expiration?: string
  condition?: string
  notes?: string
  custom_fields?: Record<string, any>
  photo?: File
}

export interface UpdateAssetData extends Partial<CreateAssetData> {}

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

export interface AssetFilters {
  page?: number
  per_page?: number
  status?: string
  category?: string
  employee_id?: string
  location_id?: string
  q?: string
}

export const assetsService = {
  // Get all assets with pagination and filters
  async getAll(filters?: AssetFilters): Promise<PaginatedResponse<Asset>> {
    const response = await api.get('/assets', {
      params: filters,
    })
    return response.data
  },

  // Get single asset
  async getById(id: string): Promise<Asset> {
    const response = await api.get(`/assets/${id}`)
    return response.data.data
  },

  // Create asset
  async create(data: CreateAssetData): Promise<Asset> {
    const formData = new FormData()

    // Append all fields to FormData
    Object.keys(data).forEach((key) => {
      const value = data[key as keyof CreateAssetData]
      if (value !== undefined && value !== null) {
        if (key === 'photo' && value instanceof File) {
          formData.append(key, value)
        } else if (key === 'custom_fields' && typeof value === 'object') {
          Object.keys(value).forEach((subKey) => {
            formData.append(`custom_fields[${subKey}]`, String((value as any)[subKey]))
          })
        } else {
          formData.append(key, String(value))
        }
      }
    })

    const response = await api.post('/assets', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    })
    return response.data.data
  },

  // Update asset
  async update(id: string, data: UpdateAssetData): Promise<Asset> {
    const formData = new FormData()

    Object.keys(data).forEach((key) => {
      const value = data[key as keyof UpdateAssetData]
      if (value !== undefined && value !== null) {
        if (key === 'photo' && value instanceof File) {
          formData.append(key, value)
        } else if (key === 'custom_fields' && typeof value === 'object') {
          Object.keys(value).forEach((subKey) => {
            formData.append(`custom_fields[${subKey}]`, String((value as any)[subKey]))
          })
        } else {
          formData.append(key, String(value))
        }
      }
    })

    const response = await api.put(`/assets/${id}`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    })
    return response.data.data
  },

  // Delete asset
  async delete(id: string): Promise<void> {
    await api.delete(`/assets/${id}`)
  },

  // Search assets with pagination
  async search(filters: AssetFilters): Promise<PaginatedResponse<Asset>> {
    const response = await api.get('/assets/search', {
      params: filters,
    })
    return response.data
  },

  // Assign asset to employee
  async assign(
    assetId: string,
    employeeId: string,
    assignmentType: 'permanent' | 'temporary' | 'loaner' = 'permanent',
    expectedReturnDate?: string
  ): Promise<Asset> {
    const response = await api.post(`/assets/${assetId}/assign`, {
      employee_id: employeeId,
      assignment_type: assignmentType,
      expected_return_date: expectedReturnDate,
    })
    return response.data.data
  },

  // Return asset from employee
  async return(assetId: string, employeeId?: string): Promise<Asset> {
    const response = await api.post(`/assets/${assetId}/return`, {
      employee_id: employeeId,
    })
    return response.data.data
  },

  // Transfer asset between employees
  async transfer(assetId: string, fromEmployeeId: string, toEmployeeId: string): Promise<Asset> {
    const response = await api.post(`/assets/${assetId}/transfer`, {
      from_employee_id: fromEmployeeId,
      to_employee_id: toEmployeeId,
    })
    return response.data.data
  },
}
