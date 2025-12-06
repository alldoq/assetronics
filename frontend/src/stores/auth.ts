import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { authApi, type LoginCredentials, type RegisterData, type User } from '@/services/api'

export const useAuthStore = defineStore('auth', () => {
  // State
  const user = ref<User | null>(null)
  const token = ref<string | null>(null)
  const refreshToken = ref<string | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  // Getters
  const isAuthenticated = computed(() => !!token.value && !!user.value)
  const userRole = computed(() => user.value?.role || null)
  const userName = computed(() => {
    if (!user.value) return null
    return `${user.value.first_name} ${user.value.last_name}`
  })

  // Actions
  const login = async (credentials: LoginCredentials) => {
    loading.value = true
    error.value = null

    try {
      const response = await authApi.login(credentials)
      token.value = response.access_token
      refreshToken.value = response.refresh_token
      user.value = response.user

      // Persist to localStorage
      localStorage.setItem('auth_token', response.access_token)
      localStorage.setItem('refresh_token', response.refresh_token)
      localStorage.setItem('user', JSON.stringify(response.user))

      return true
    } catch (err: any) {
      error.value = err.response?.data?.error || 'Login failed. Please try again.'
      return false
    } finally {
      loading.value = false
    }
  }

  const register = async (data: RegisterData) => {
    loading.value = true
    error.value = null

    try {
      const response = await authApi.register(data)
      token.value = response.access_token
      refreshToken.value = response.refresh_token
      user.value = response.user

      // Persist to localStorage
      localStorage.setItem('auth_token', response.access_token)
      localStorage.setItem('refresh_token', response.refresh_token)
      localStorage.setItem('user', JSON.stringify(response.user))

      return true
    } catch (err: any) {
      error.value = err.response?.data?.error || 'Registration failed. Please try again.'
      return false
    } finally {
      loading.value = false
    }
  }

  const logout = async () => {
    try {
      await authApi.logout()
    } catch (err) {
      console.error('Logout error:', err)
    } finally {
      // Clear state
      user.value = null
      token.value = null
      refreshToken.value = null
      error.value = null

      // Clear localStorage
      localStorage.removeItem('auth_token')
      localStorage.removeItem('refresh_token')
      localStorage.removeItem('user')
    }
  }

  const loadUserFromStorage = () => {
    const storedToken = localStorage.getItem('auth_token')
    const storedRefreshToken = localStorage.getItem('refresh_token')
    const storedUser = localStorage.getItem('user')

    if (storedToken && storedUser) {
      token.value = storedToken
      refreshToken.value = storedRefreshToken
      try {
        user.value = JSON.parse(storedUser)
      } catch (err) {
        console.error('Failed to parse stored user:', err)
        logout()
      }
    }
  }

  const refreshUser = async () => {
    if (!token.value) return

    try {
      const freshUser = await authApi.getCurrentUser()
      user.value = freshUser
      localStorage.setItem('user', JSON.stringify(freshUser))
    } catch (err) {
      console.error('Failed to refresh user:', err)
      logout()
    }
  }

  const clearError = () => {
    error.value = null
  }

  return {
    // State
    user,
    token,
    refreshToken,
    loading,
    error,

    // Getters
    isAuthenticated,
    userRole,
    userName,

    // Actions
    login,
    register,
    logout,
    loadUserFromStorage,
    refreshUser,
    clearError,
  }
})
