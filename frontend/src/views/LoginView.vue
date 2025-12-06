<template>
  <div class="min-h-screen flex items-center justify-center px-4 py-8 bg-light-bg relative">
    <div class="w-full max-w-md relative z-10">
      <!-- Logo/Brand -->
      <div class="flex flex-col items-center mb-8">
        <div class="flex items-center gap-3 mb-4">
          <img src="/logo.png" alt="Assetronics Logo" class="h-12 w-auto" style="background-color: white;">
          <h1 class="text-3xl font-light font-poppins text-accent-blue">Assetronics</h1>
        </div>
        <p class="text-text-light text-sm">Intelligent Hardware Lifecycle</p>
      </div>

      <!-- Login Card -->
      <div class="bg-white border border-border-light rounded-4xl shadow-subtle p-6 sm:p-8">
        <h2 class="text-2xl font-bold text-primary-dark mb-6">Sign In</h2>

        <!-- Error Message -->
        <div
          v-if="authStore.error"
          class="mb-6 p-4 rounded-lg bg-red-50 border border-red-200 text-red-800 text-sm"
        >
          {{ authStore.error }}
        </div>

        <form @submit.prevent="handleLogin" class="space-y-5">
          <!-- Email Field -->
          <div>
            <label for="email" class="block text-sm font-bold text-primary-dark mb-2">
              Email address
            </label>
            <input
              id="email"
              v-model="form.email"
              type="email"
              required
              autocomplete="email"
              class="input-refined"
              :class="{ 'border-red-500': errors.email }"
              placeholder="you@example.com"
              @focus="clearFieldError('email')"
            />
            <p v-if="errors.email" class="mt-2 text-sm text-red-600">
              {{ errors.email }}
            </p>
          </div>

          <!-- Password Field -->
          <div>
            <label for="password" class="block text-sm font-bold text-primary-dark mb-2">
              Password
            </label>
            <div class="relative">
              <input
                id="password"
                v-model="form.password"
                :type="showPassword ? 'text' : 'password'"
                required
                autocomplete="current-password"
                class="input-refined pr-12"
                :class="{ 'border-red-500': errors.password }"
                placeholder="••••••••"
                @focus="clearFieldError('password')"
              />
              <button
                type="button"
                @click="showPassword = !showPassword"
                class="absolute right-3 top-1/2 -translate-y-1/2 text-text-light hover:text-primary-dark touch-target"
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
          </div>

          <!-- Remember Me & Forgot Password -->
          <div class="flex items-center justify-between text-sm">
            <label class="flex items-center space-x-2 cursor-pointer">
              <input
                v-model="form.remember"
                type="checkbox"
                class="w-4 h-4 rounded border-slate-300 text-accent-blue focus:ring-2 focus:ring-accent-blue/20"
              />
              <span class="text-slate-600">Remember me</span>
            </label>
            <router-link to="/forgot-password" class="text-blue-600 hover:text-blue-700 underline font-medium">
              Forgot password?
            </router-link>
          </div>

          <!-- Submit Button -->
          <button
            type="submit"
            :disabled="authStore.loading"
            class="w-full px-8 py-4 btn-brand-primary"
          >
            <span v-if="!authStore.loading">Sign In</span>
            <span v-else class="flex items-center justify-center">
              <svg class="animate-spin -ml-1 mr-2 h-5 w-5" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Signing in...
            </span>
          </button>
        </form>

        <!-- Divider -->
        <div class="relative my-6">
          <div class="absolute inset-0 flex items-center">
            <div class="w-full border-t border-slate-200"></div>
          </div>
          <div class="relative flex justify-center text-sm">
            <span class="px-4 bg-white/80 text-slate-600">Don't have an account?</span>
          </div>
        </div>

        <!-- Register Link -->
        <router-link
          to="/register"
          class="block w-full text-center px-8 py-4 btn-brand-secondary"
        >
          Create Account
        </router-link>
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
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

// Form state
const form = reactive({
  email: '',
  password: '',
  remember: false,
})

// UI state
const showPassword = ref(false)
const errors = reactive<Record<string, string>>({})

// Clear specific field error
const clearFieldError = (field: string) => {
  delete errors[field]
  authStore.clearError()
}

// Validate form
const validateForm = (): boolean => {
  const newErrors: Record<string, string> = {}

  if (!form.email) {
    newErrors.email = 'Email is required'
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
    newErrors.email = 'Please enter a valid email address'
  }

  if (!form.password) {
    newErrors.password = 'Password is required'
  } else if (form.password.length < 6) {
    newErrors.password = 'Password must be at least 6 characters'
  }

  Object.assign(errors, newErrors)
  return Object.keys(newErrors).length === 0
}

// Handle login
const handleLogin = async () => {
  // Clear previous errors
  Object.keys(errors).forEach((key) => delete errors[key])

  // Validate
  if (!validateForm()) {
    return
  }

  // Attempt login
  const success = await authStore.login({
    email: form.email,
    password: form.password,
  })

  if (success) {
    // Redirect to dashboard
    router.push('/dashboard')
  }
}

// Check if already authenticated
onMounted(() => {
  authStore.loadUserFromStorage()
  if (authStore.isAuthenticated) {
    router.push('/dashboard')
  }
})
</script>
