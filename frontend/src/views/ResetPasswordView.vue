<template>
  <div class="min-h-screen flex items-center justify-center px-4 py-8 bg-light-bg">
    <div class="w-full max-w-md">
      <!-- Logo/Brand -->
      <div class="text-center mb-8">
        <div class="flex items-center justify-center gap-3 mb-4">
          <img src="/logo.png" alt="Assetronics Logo" class="h-12 w-auto" style="background-color: white;">
          <h1 class="text-3xl font-light font-poppins text-accent-blue">Assetronics</h1>
        </div>
        <p class="text-text-light">Create a new password</p>
      </div>

      <!-- Reset Password Card -->
      <div class="bg-white rounded-3xl border border-slate-200 shadow-subtle p-6 sm:p-8">
        <!-- Loading State (Validating Token) -->
        <div v-if="validatingToken" class="text-center py-8">
          <svg class="animate-spin h-12 w-12 text-teal-600 mx-auto mb-4" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <p class="text-slate-700">Validating reset link...</p>
        </div>

        <!-- Invalid Token State -->
        <div v-else-if="invalidToken" class="text-center">
          <div class="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4 border border-red-300">
            <svg class="w-8 h-8 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <h2 class="text-2xl font-bold text-primary-dark mb-3">Invalid or expired link</h2>
          <p class="text-slate-700 mb-6">
            This password reset link is invalid or has expired. Please request a new one.
          </p>
          <router-link
            to="/forgot-password"
            class="inline-block w-full btn-brand-primary text-center"
          >
            Request new link
          </router-link>
        </div>

        <!-- Success State -->
        <div v-else-if="passwordReset" class="text-center">
          <div class="w-16 h-16 bg-accent-blue/10 rounded-full flex items-center justify-center mx-auto mb-4 border border-accent-blue/20">
            <svg class="w-8 h-8 text-teal-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <h2 class="text-2xl font-bold text-primary-dark mb-3">Password reset successful!</h2>
          <p class="text-slate-700 mb-6">
            Your password has been updated. You can now sign in with your new password.
          </p>
          <router-link
            to="/login"
            class="inline-block w-full btn-brand-primary text-center"
          >
            Go to login
          </router-link>
        </div>

        <!-- Form State -->
        <div v-else>
          <h2 class="text-2xl font-bold text-primary-dark mb-2">Set new password</h2>
          <p class="text-slate-700 mb-6">
            Choose a strong password for your account.
          </p>

          <!-- Error Message -->
          <div
            v-if="error"
            class="mb-6 p-4 rounded-xl bg-red-50 border border-red-200 text-red-800 text-sm"
          >
            {{ error }}
          </div>

          <form @submit.prevent="handleSubmit" class="space-y-5">
            <!-- Password Field -->
            <div>
              <label for="password" class="block text-sm font-medium text-slate-700 mb-2">
                New password
              </label>
              <div class="relative">
                <input
                  id="password"
                  v-model="form.password"
                  :type="showPassword ? 'text' : 'password'"
                  required
                  autocomplete="new-password"
                  class="input-refined w-full"
                  :class="{ 'border-red-500': errors.password }"
                  placeholder="••••••••"
                  @focus="clearFieldError('password')"
                />
                <button
                  type="button"
                  @click="showPassword = !showPassword"
                  class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-700 touch-target"
                >
                  <svg
                    v-if="!showPassword"
                    class="w-5 h-5"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                    />
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                    />
                  </svg>
                  <svg v-else class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21"
                    />
                  </svg>
                </button>
              </div>
              <p v-if="errors.password" class="mt-2 text-sm text-red-600">
                {{ errors.password }}
              </p>
              <p class="mt-2 text-xs text-slate-600">
                Must be at least 8 characters with uppercase, lowercase, and number
              </p>
            </div>

            <!-- Confirm Password Field -->
            <div>
              <label for="password_confirmation" class="block text-sm font-medium text-slate-700 mb-2">
                Confirm new password
              </label>
              <div class="relative">
                <input
                  id="password_confirmation"
                  v-model="form.password_confirmation"
                  :type="showPasswordConfirm ? 'text' : 'password'"
                  required
                  autocomplete="new-password"
                  class="input-refined w-full"
                  :class="{ 'border-red-500': errors.password_confirmation }"
                  placeholder="••••••••"
                  @focus="clearFieldError('password_confirmation')"
                />
                <button
                  type="button"
                  @click="showPasswordConfirm = !showPasswordConfirm"
                  class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-700 touch-target"
                >
                  <svg
                    v-if="!showPasswordConfirm"
                    class="w-5 h-5"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                    />
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                    />
                  </svg>
                  <svg v-else class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21"
                    />
                  </svg>
                </button>
              </div>
              <p v-if="errors.password_confirmation" class="mt-2 text-sm text-red-600">
                {{ errors.password_confirmation }}
              </p>
            </div>

            <!-- Submit Button -->
            <button
              type="submit"
              :disabled="loading"
              class="w-full btn-brand-primary disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <span v-if="!loading">Reset password</span>
              <span v-else class="flex items-center justify-center">
                <svg class="animate-spin -ml-1 mr-2 h-5 w-5 text-primary-dark" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                Resetting password...
              </span>
            </button>
          </form>
        </div>
      </div>

      <!-- Footer -->
      <p class="text-center text-sm text-slate-600 mt-8">
        © 2025 Assetronics. All rights reserved.
      </p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { authApi } from '@/services/api'

const route = useRoute()

// Form state
const form = reactive({
  password: '',
  password_confirmation: '',
})

// UI state
const loading = ref(false)
const validatingToken = ref(true)
const invalidToken = ref(false)
const passwordReset = ref(false)
const error = ref<string | null>(null)
const errors = reactive<Record<string, string>>({})
const showPassword = ref(false)
const showPasswordConfirm = ref(false)

// Get token from URL
const token = ref<string>('')

// Clear specific field error
const clearFieldError = (field: string) => {
  delete errors[field]
  error.value = null
}

// Validate token on mount
onMounted(async () => {
  token.value = route.params.token as string

  if (!token.value) {
    invalidToken.value = true
    validatingToken.value = false
    return
  }

  try {
    await authApi.validateResetToken(token.value)
    validatingToken.value = false
  } catch (err) {
    invalidToken.value = true
    validatingToken.value = false
  }
})

// Validate form
const validateForm = (): boolean => {
  const newErrors: Record<string, string> = {}

  // Password
  if (!form.password) {
    newErrors.password = 'Password is required'
  } else if (form.password.length < 8) {
    newErrors.password = 'Password must be at least 8 characters'
  } else if (!/(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/.test(form.password)) {
    newErrors.password = 'Password must contain uppercase, lowercase, and number'
  }

  // Password confirmation
  if (!form.password_confirmation) {
    newErrors.password_confirmation = 'Please confirm your password'
  } else if (form.password !== form.password_confirmation) {
    newErrors.password_confirmation = 'Passwords do not match'
  }

  Object.assign(errors, newErrors)
  return Object.keys(newErrors).length === 0
}

// Handle form submission
const handleSubmit = async () => {
  // Clear previous errors
  Object.keys(errors).forEach((key) => delete errors[key])
  error.value = null

  // Validate
  if (!validateForm()) {
    return
  }

  loading.value = true

  try {
    await authApi.resetPassword({
      token: token.value,
      password: form.password,
      password_confirmation: form.password_confirmation,
    })

    // Show success message
    passwordReset.value = true
  } catch (err: any) {
    error.value = err.response?.data?.error || 'Failed to reset password. Please try again.'
  } finally {
    loading.value = false
  }
}
</script>
