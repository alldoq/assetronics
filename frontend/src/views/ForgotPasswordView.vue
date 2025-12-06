<template>
  <div class="min-h-screen flex items-center justify-center px-4 py-8 bg-light-bg">
    <div class="w-full max-w-md">
      <!-- Logo/Brand -->
      <div class="text-center mb-8">
        <div class="flex items-center justify-center gap-3 mb-4">
          <img src="/logo.png" alt="Assetronics Logo" class="h-12 w-auto" style="background-color: white;">
          <h1 class="text-3xl font-light font-poppins text-accent-blue">Assetronics</h1>
        </div>
        <p class="text-text-light">Reset your password</p>
      </div>

      <!-- Forgot Password Card -->
      <div class="bg-white rounded-3xl border border-slate-200 shadow-subtle p-6 sm:p-8">
        <!-- Success State -->
        <div v-if="emailSent" class="text-center">
          <div class="w-16 h-16 bg-accent-blue/10 rounded-full flex items-center justify-center mx-auto mb-4 border border-accent-blue/20">
            <svg class="w-8 h-8 text-teal-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
            </svg>
          </div>
          <h2 class="text-2xl font-bold text-primary-dark mb-3">Check your email</h2>
          <p class="text-slate-700 mb-6">
            We've sent password reset instructions to <strong class="text-primary-dark">{{ form.email }}</strong>
          </p>
          <p class="text-sm text-slate-600 mb-6">
            Didn't receive the email? Check your spam folder or try again.
          </p>
          <button
            @click="resetForm"
            class="w-full btn-brand-secondary"
          >
            Try another email
          </button>
        </div>

        <!-- Form State -->
        <div v-else>
          <h2 class="text-2xl font-bold text-primary-dark mb-2">Forgot password?</h2>
          <p class="text-slate-700 mb-6">
            No worries! Enter your email and we'll send you reset instructions.
          </p>

          <!-- Error Message -->
          <div
            v-if="error"
            class="mb-6 p-4 rounded-xl bg-red-50 border border-red-200 text-red-800 text-sm"
          >
            {{ error }}
          </div>

          <form @submit.prevent="handleSubmit" class="space-y-5">
            <!-- Email Field -->
            <div>
              <label for="email" class="block text-sm font-medium text-slate-700 mb-2">
                Email address
              </label>
              <input
                id="email"
                v-model="form.email"
                type="email"
                required
                autocomplete="email"
                class="input-refined w-full"
                :class="{ 'border-red-500': fieldError }"
                placeholder="you@example.com"
                @focus="clearError"
              />
              <p v-if="fieldError" class="mt-2 text-sm text-red-600">
                {{ fieldError }}
              </p>
            </div>

            <!-- Submit Button -->
            <button
              type="submit"
              :disabled="loading"
              class="w-full btn-brand-primary disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <span v-if="!loading">Send reset instructions</span>
              <span v-else class="flex items-center justify-center">
                <svg class="animate-spin -ml-1 mr-2 h-5 w-5 text-primary-dark" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                Sending...
              </span>
            </button>
          </form>
        </div>

        <!-- Back to Login -->
        <div class="mt-6 text-center">
          <router-link
            to="/login"
            class="inline-flex items-center text-sm text-blue-600 hover:text-blue-700 underline font-medium transition-colors"
          >
            <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
            Back to login
          </router-link>
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
import { ref, reactive } from 'vue'
import { authApi } from '@/services/api'

// Form state
const form = reactive({
  email: '',
})

// UI state
const loading = ref(false)
const error = ref<string | null>(null)
const fieldError = ref<string | null>(null)
const emailSent = ref(false)

// Clear errors
const clearError = () => {
  error.value = null
  fieldError.value = null
}

// Reset form to initial state
const resetForm = () => {
  form.email = ''
  emailSent.value = false
  error.value = null
  fieldError.value = null
}

// Validate form
const validateForm = (): boolean => {
  if (!form.email) {
    fieldError.value = 'Email is required'
    return false
  }

  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
    fieldError.value = 'Please enter a valid email address'
    return false
  }

  return true
}

// Handle form submission
const handleSubmit = async () => {
  // Clear previous errors
  clearError()

  // Validate
  if (!validateForm()) {
    return
  }

  loading.value = true

  try {
    await authApi.forgotPassword({
      email: form.email,
    })

    // Show success message
    emailSent.value = true
  } catch (err: any) {
    error.value = err.response?.data?.error || 'Failed to send reset email. Please try again.'
  } finally {
    loading.value = false
  }
}
</script>
