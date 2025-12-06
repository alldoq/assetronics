<template>
  <div class="min-h-screen flex items-center justify-center px-4 py-8 bg-light-bg relative">
    <div class="w-full max-w-md">
      <div class="flex flex-col items-center mb-8">
        <div class="flex items-center gap-3 mb-4">
          <img src="/logo.png" alt="Assetronics Logo" class="h-12 w-auto" style="background-color: white;">
          <h1 class="text-3xl font-light font-poppins text-accent-blue">Assetronics</h1>
        </div>
        <p class="text-text-light text-sm">Create your account</p>
      </div>
      <div class="bg-white border border-border-light rounded-4xl shadow-subtle p-6 sm:p-8">
        <h2 class="text-2xl font-bold text-primary-dark mb-6">Sign Up</h2>
        <div v-if="authStore.error" class="mb-6 p-4 rounded-lg bg-red-50 border border-red-200 text-red-800 text-sm">{{ authStore.error }}</div>

        <form @submit.prevent="handleRegister" class="space-y-5">
          <!-- Name Fields -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <!-- First Name -->
            <div>
              <label for="first_name" class="block text-sm font-bold text-primary-dark mb-2">
                First name
              </label>
              <input
                id="first_name"
                v-model="form.first_name"
                type="text"
                required
                autocomplete="given-name"
                class="input-refined"
                :class="{ 'border-red-500': errors.first_name }"
                placeholder="John"
                @focus="clearFieldError('first_name')"
              />
              <p v-if="errors.first_name" class="mt-2 text-sm text-red-600">
                {{ errors.first_name }}
              </p>
            </div>

            <!-- Last Name -->
            <div>
              <label for="last_name" class="block text-sm font-bold text-primary-dark mb-2">
                Last name
              </label>
              <input
                id="last_name"
                v-model="form.last_name"
                type="text"
                required
                autocomplete="family-name"
                class="input-refined"
                :class="{ 'border-red-500': errors.last_name }"
                placeholder="Doe"
                @focus="clearFieldError('last_name')"
              />
              <p v-if="errors.last_name" class="mt-2 text-sm text-red-600">
                {{ errors.last_name }}
              </p>
            </div>
          </div>

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

          <!-- Phone Field (Optional) -->
          <div>
            <label for="phone" class="block text-sm font-bold text-primary-dark mb-2">
              Phone number <span class="text-slate-600 text-xs">(optional)</span>
            </label>
            <input
              id="phone"
              v-model="form.phone"
              type="tel"
              autocomplete="tel"
              class="input-refined"
              :class="{ 'border-red-500': errors.phone }"
              placeholder="+1-555-0000"
              @focus="clearFieldError('phone')"
            />
            <p v-if="errors.phone" class="mt-2 text-sm text-red-600">
              {{ errors.phone }}
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
                autocomplete="new-password"
                class="input-refined pr-12"
                :class="{ 'border-red-500': errors.password }"
                placeholder="••••••••"
                @focus="clearFieldError('password')"
              />
              <button
                type="button"
                @click="showPassword = !showPassword"
                class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-600 hover:text-primary-dark touch-target"
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
            <label for="password_confirm" class="block text-sm font-bold text-primary-dark mb-2">
              Confirm password
            </label>
            <div class="relative">
              <input
                id="password_confirm"
                v-model="form.password_confirm"
                :type="showPasswordConfirm ? 'text' : 'password'"
                required
                autocomplete="new-password"
                class="input-refined pr-12"
                :class="{ 'border-red-500': errors.password_confirm }"
                placeholder="••••••••"
                @focus="clearFieldError('password_confirm')"
              />
              <button
                type="button"
                @click="showPasswordConfirm = !showPasswordConfirm"
                class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-600 hover:text-primary-dark touch-target"
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
            <p v-if="errors.password_confirm" class="mt-2 text-sm text-red-600">
              {{ errors.password_confirm }}
            </p>
          </div>

          <!-- Terms & Conditions -->
          <div class="flex items-start">
            <input
              id="terms"
              v-model="form.terms"
              type="checkbox"
              required
              class="mt-1 w-4 h-4 rounded-2xl border-slate-300 text-accent-blue focus:ring-2 focus:ring-accent-blue/20"
            />
            <label for="terms" class="ml-2 text-sm text-primary-dark">
              I agree to the
              <a href="#" class="text-blue-600 hover:text-blue-700 underline font-medium">
                Terms of Service
              </a>
              and
              <a href="#" class="text-blue-600 hover:text-blue-700 underline font-medium">
                Privacy Policy
              </a>
            </label>
          </div>

          <!-- Submit Button -->
          <button
            type="submit"
            :disabled="authStore.loading"
            class="w-full px-8 py-4 btn-brand-primary"
          >
            <span v-if="!authStore.loading">Create Account</span>
            <span v-else class="flex items-center justify-center">
              <svg class="animate-spin -ml-1 mr-2 h-5 w-5" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Creating account...
            </span>
          </button>
        </form>

        <!-- Divider -->
        <div class="relative my-6">
          <div class="absolute inset-0 flex items-center">
            <div class="w-full border-t border-slate-200"></div>
          </div>
          <div class="relative flex justify-center text-sm">
            <span class="px-4 bg-white text-slate-600">Already have an account?</span>
          </div>
        </div>

        <!-- Login Link -->
        <router-link
          to="/login"
          class="block w-full text-center px-8 py-4 btn-brand-secondary"
        >
          Sign In
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
  first_name: '',
  last_name: '',
  email: '',
  phone: '',
  password: '',
  password_confirm: '',
  terms: false,
})

// UI state
const showPassword = ref(false)
const showPasswordConfirm = ref(false)
const errors = reactive<Record<string, string>>({})

// Clear specific field error
const clearFieldError = (field: string) => {
  delete errors[field]
  authStore.clearError()
}

// Validate form
const validateForm = (): boolean => {
  const newErrors: Record<string, string> = {}

  // First name
  if (!form.first_name.trim()) {
    newErrors.first_name = 'First name is required'
  }

  // Last name
  if (!form.last_name.trim()) {
    newErrors.last_name = 'Last name is required'
  }

  // Email
  if (!form.email) {
    newErrors.email = 'Email is required'
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
    newErrors.email = 'Please enter a valid email address'
  }

  // Phone (optional, but validate if provided)
  if (form.phone && !/^[+]?[\d\s\-()]+$/.test(form.phone)) {
    newErrors.phone = 'Please enter a valid phone number'
  }

  // Password
  if (!form.password) {
    newErrors.password = 'Password is required'
  } else if (form.password.length < 8) {
    newErrors.password = 'Password must be at least 8 characters'
  } else if (!/(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/.test(form.password)) {
    newErrors.password = 'Password must contain uppercase, lowercase, and number'
  }

  // Password confirmation
  if (!form.password_confirm) {
    newErrors.password_confirm = 'Please confirm your password'
  } else if (form.password !== form.password_confirm) {
    newErrors.password_confirm = 'Passwords do not match'
  }

  // Terms
  if (!form.terms) {
    newErrors.terms = 'You must agree to the terms and conditions'
  }

  Object.assign(errors, newErrors)
  return Object.keys(newErrors).length === 0
}

// Handle registration
const handleRegister = async () => {
  // Clear previous errors
  Object.keys(errors).forEach((key) => delete errors[key])

  // Validate
  if (!validateForm()) {
    return
  }

  // Attempt registration
  const success = await authStore.register({
    first_name: form.first_name,
    last_name: form.last_name,
    email: form.email,
    phone: form.phone || undefined,
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
