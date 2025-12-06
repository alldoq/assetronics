import api from './api'

export interface Transaction {
  id: string
  transaction_type: string
  asset_id: string
  employee_id?: string
  from_status?: string
  to_status?: string
  from_location_id?: string
  to_location_id?: string
  from_employee_id?: string
  to_employee_id?: string
  description?: string
  notes?: string
  performed_by?: string
  performed_at: string
  transaction_amount?: number
  metadata?: Record<string, any>
  ip_address?: string
  user_agent?: string
  inserted_at: string
  updated_at: string

  // Associations
  asset?: {
    id: string
    name: string
    asset_tag?: string
    serial_number?: string
  }
  employee?: {
    id: string
    first_name: string
    last_name: string
    email: string
  }
  from_employee?: {
    id: string
    first_name: string
    last_name: string
    email: string
  }
  to_employee?: {
    id: string
    first_name: string
    last_name: string
    email: string
  }
}

export interface TransactionsQueryParams {
  transaction_type?: string
  limit?: number
}

export const transactionsService = {
  // Get all transactions
  async getAll(params?: TransactionsQueryParams): Promise<Transaction[]> {
    const queryParams = new URLSearchParams()
    if (params?.transaction_type) {
      queryParams.append('transaction_type', params.transaction_type)
    }
    if (params?.limit) {
      queryParams.append('limit', params.limit.toString())
    }

    const url = `/transactions${queryParams.toString() ? '?' + queryParams.toString() : ''}`
    const response = await api.get(url)
    return response.data.data
  },

  // Get single transaction
  async getById(id: string): Promise<Transaction> {
    const response = await api.get(`/transactions/${id}`)
    return response.data.data
  },

  // Get transactions for a specific asset
  async getByAsset(assetId: string): Promise<Transaction[]> {
    const response = await api.get(`/assets/${assetId}/transactions`)
    return response.data.data
  },

  // Get transactions for a specific employee
  async getByEmployee(employeeId: string): Promise<Transaction[]> {
    const response = await api.get(`/employees/${employeeId}/transactions`)
    return response.data.data
  }
}
