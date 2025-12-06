import api from './api'

import type { Employee } from './employees'

export interface User {
  id: string
  email: string
  first_name: string
  last_name: string
  role: 'super_admin' | 'admin' | 'manager' | 'employee' | 'viewer'
  status: 'active' | 'inactive' | 'locked'
  phone?: string
  avatar_url?: string
  timezone: string
  locale: string
  email_verified: boolean
  last_login_at?: string
  locked: boolean
  employee_id?: string
  employee?: Employee
  inserted_at: string
  updated_at: string
}

export interface CreateUserData {
  email: string
  password: string
  first_name: string
  last_name: string
  role?: string
  phone?: string
  timezone?: string
  locale?: string
  employee_id?: string
}

export interface UpdateUserData {
  first_name?: string
  last_name?: string
  phone?: string
  avatar_url?: string
  timezone?: string
  locale?: string
}

export interface UserFilters {
  role?: string
  status?: string
  email?: string
}

export const usersService = {
  // Get all users
  async getAll(filters?: UserFilters): Promise<User[]> {
    const response = await api.get('/users', { params: filters })
    return response.data.data
  },

  // Get single user
  async getById(id: string): Promise<User> {
    const response = await api.get(`/users/${id}`)
    return response.data.data
  },

  // Create user
  async create(data: CreateUserData): Promise<User> {
    const response = await api.post('/users', { user: data })
    return response.data.data
  },

  // Update user
  async update(id: string, data: UpdateUserData): Promise<User> {
    const response = await api.patch(`/users/${id}`, { user: data })
    return response.data.data
  },

  // Delete user
  async delete(id: string): Promise<void> {
    await api.delete(`/users/${id}`)
  },

  // Update user role
  async updateRole(id: string, role: string): Promise<User> {
    const response = await api.patch(`/users/${id}/role`, { role })
    return response.data.data
  },

  // Update user status
  async updateStatus(id: string, status: string): Promise<User> {
    const response = await api.patch(`/users/${id}/status`, { status })
    return response.data.data
  },

  // Unlock user account
  async unlock(id: string): Promise<User> {
    const response = await api.post(`/users/${id}/unlock`)
    return response.data.data
  },
}
