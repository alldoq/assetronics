import api from './api'

export interface Category {
  id: number
  name: string
  description?: string
  created_at: string
  updated_at: string
}

export interface CreateCategoryData {
  name: string
  description?: string
}

export interface UpdateCategoryData extends Partial<CreateCategoryData> {}

export const categoriesService = {
  // Get all categories
  async getAll(): Promise<Category[]> {
    const response = await api.get('/categories')
    return response.data.data
  },

  // Get single category
  async getById(id: number): Promise<Category> {
    const response = await api.get(`/categories/${id}`)
    return response.data.data
  },

  // Create category
  async create(data: CreateCategoryData): Promise<Category> {
    const response = await api.post('/categories', { category: data })
    return response.data.data
  },

  // Update category
  async update(id: number, data: UpdateCategoryData): Promise<Category> {
    const response = await api.put(`/categories/${id}`, { category: data })
    return response.data.data
  },

  // Delete category
  async delete(id: number): Promise<void> {
    await api.delete(`/categories/${id}`)
  },
}
