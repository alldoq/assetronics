<template>
  <MainLayout>
    <div class="max-w-7xl mx-auto">
      <!-- Header -->
      <div class="mb-6">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-3xl font-bold text-primary-dark">Edit software license</h1>
            <p class="text-slate-500 mt-1">Update license information</p>
          </div>
          <button @click="handleCancel" class="px-6 py-3 btn-brand-secondary">
            <svg class="w-5 h-5 mr-2 inline-block" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
            Cancel
          </button>
        </div>
      </div>

      <!-- Loading state -->
      <div v-if="isLoadingLicense" class="bg-white border border-border-light rounded-2xl p-8 text-center">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-accent-blue mx-auto mb-4"></div>
        <p class="text-slate-600">Loading license...</p>
      </div>

      <!-- Success message -->
      <div v-if="successMessage" class="alert-success mb-6">
        {{ successMessage }}
      </div>

      <!-- Main Content -->
      <div v-if="!isLoadingLicense" class="grid grid-cols-1 lg:grid-cols-4 gap-6">
        <!-- Vertical Tabs Navigation -->
        <div class="lg:col-span-1">
          <nav class="space-y-1 sticky top-6">
            <button
              v-for="tab in tabs"
              :key="tab.id"
              @click="activeTab = tab.id"
              class="w-full flex items-start px-4 py-3 text-sm font-medium rounded-md transition-colors text-left border-l-4"
              :class="
                activeTab === tab.id
                  ? 'bg-accent-blue/10 text-primary-dark border-teal-600'
                  : 'text-slate-600 hover:bg-light-bg hover:text-primary-dark border-transparent'
              "
            >
              <component
                :is="tab.icon"
                class="w-5 h-5 mr-3 flex-shrink-0 mt-0.5"
                :class="activeTab === tab.id ? 'text-teal-600' : ''"
              />
              <div class="flex-1">
                <div class="flex items-center justify-between">
                  <span class="font-bold">{{ tab.label }}</span>
                  <span
                    v-if="hasErrors(tab.fields)"
                    class="w-2 h-2 rounded-full bg-red-500 ml-2"
                    aria-label="Has errors"
                  ></span>
                </div>
                <p class="text-xs text-slate-500 mt-0.5">{{ tab.description }}</p>
              </div>
            </button>
          </nav>
        </div>

        <!-- Tab Content -->
        <div class="lg:col-span-3">
          <form @submit.prevent="handleSubmit">
            <!-- Tab 1: License Information -->
            <div v-show="activeTab === 'license-info'" class="bg-white border border-border-light rounded-2xl p-6">
              <h2 class="text-lg font-bold text-primary-dark mb-6">License information</h2>
              <div class="space-y-6">
                <!-- License name -->
                <div>
                  <label for="license-name" class="block text-sm font-medium text-slate-600 mb-2">
                    License name <span class="text-red-500">*</span>
                  </label>
                  <input
                    id="license-name"
                    v-model="form.name"
                    type="text"
                    required
                    class="input-refined"
                    placeholder="e.g., Microsoft 365 Business"
                    @focus="clearError('name')"
                  />
                  <p v-if="errors.name" class="mt-2 text-sm text-red-600">{{ errors.name }}</p>
                </div>

                <!-- Vendor and Status row -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
                  <div>
                    <label for="vendor" class="block text-sm font-medium text-slate-600 mb-2">
                      Vendor <span class="text-red-500">*</span>
                    </label>
                    <input
                      id="vendor"
                      v-model="form.vendor"
                      type="text"
                      required
                      class="input-refined"
                      placeholder="e.g., Microsoft"
                      @focus="clearError('vendor')"
                    />
                    <p v-if="errors.vendor" class="mt-2 text-sm text-red-600">
                      {{ errors.vendor }}
                    </p>
                  </div>

                  <div>
                    <label for="status" class="block text-sm font-medium text-slate-600 mb-2">
                      Status <span class="text-red-500">*</span>
                    </label>
                    <select
                      id="status"
                      v-model="form.status"
                      required
                      class="input-refined"
                      @focus="clearError('status')"
                    >
                      <option value="">Select status</option>
                      <option value="active">Active</option>
                      <option value="expired">Expired</option>
                      <option value="cancelled">Cancelled</option>
                      <option value="future">Future</option>
                    </select>
                    <p v-if="errors.status" class="mt-2 text-sm text-red-600">{{ errors.status }}</p>
                  </div>
                </div>

                <!-- Description -->
                <div>
                  <label for="description" class="block text-sm font-medium text-slate-600 mb-2">
                    Description
                  </label>
                  <textarea
                    id="description"
                    v-model="form.description"
                    rows="4"
                    class="input-refined resize-none"
                    placeholder="Add any additional details about this license..."
                  ></textarea>
                </div>
              </div>
            </div>

            <!-- Tab 2: Seat Management -->
            <div v-show="activeTab === 'seat-management'" class="bg-white border border-border-light rounded-2xl p-6">
              <h2 class="text-lg font-bold text-primary-dark mb-6">Seat management</h2>
              <div class="space-y-6">
                <!-- Total seats -->
                <div>
                  <label for="total-seats" class="block text-sm font-medium text-slate-600 mb-2">
                    Total seats <span class="text-red-500">*</span>
                  </label>
                  <input
                    id="total-seats"
                    v-model="form.total_seats"
                    type="number"
                    required
                    min="1"
                    class="input-refined"
                    placeholder="e.g., 100"
                    @focus="clearError('total_seats')"
                  />
                  <p v-if="errors.total_seats" class="mt-2 text-sm text-red-600">
                    {{ errors.total_seats }}
                  </p>
                  <p class="mt-1 text-xs text-slate-500">
                    Number of licenses available
                  </p>
                </div>

                <!-- Annual cost and Cost per seat -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
                  <div>
                    <label for="annual-cost" class="block text-sm font-medium text-slate-600 mb-2">
                      Annual cost
                    </label>
                    <div class="relative">
                      <span class="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 text-sm">
                        $
                      </span>
                      <input
                        id="annual-cost"
                        v-model="form.annual_cost"
                        type="number"
                        step="0.01"
                        min="0"
                        class="input-refined pl-7"
                        placeholder="0.00"
                      />
                    </div>
                    <p class="mt-1 text-xs text-slate-500">
                      Total annual license cost
                    </p>
                  </div>

                  <div>
                    <label for="cost-per-seat" class="block text-sm font-medium text-slate-600 mb-2">
                      Cost per seat
                    </label>
                    <div class="relative">
                      <span class="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 text-sm">
                        $
                      </span>
                      <input
                        id="cost-per-seat"
                        v-model="form.cost_per_seat"
                        type="number"
                        step="0.01"
                        min="0"
                        class="input-refined pl-7"
                        placeholder="0.00"
                      />
                    </div>
                    <p class="mt-1 text-xs text-slate-500">
                      Cost per individual license
                    </p>
                  </div>
                </div>
              </div>
            </div>

            <!-- Tab 3: Dates & Keys -->
            <div v-show="activeTab === 'dates-keys'" class="bg-white border border-border-light rounded-2xl p-6">
              <h2 class="text-lg font-bold text-primary-dark mb-6">Dates and license keys</h2>
              <div class="space-y-6">
                <!-- Purchase date and Expiration date -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
                  <div>
                    <label for="purchase-date" class="block text-sm font-medium text-slate-600 mb-2">
                      Purchase date
                    </label>
                    <input
                      id="purchase-date"
                      v-model="form.purchase_date"
                      type="date"
                      class="input-refined"
                    />
                  </div>

                  <div>
                    <label for="expiration-date" class="block text-sm font-medium text-slate-600 mb-2">
                      Expiration date
                    </label>
                    <input
                      id="expiration-date"
                      v-model="form.expiration_date"
                      type="date"
                      class="input-refined"
                    />
                    <p class="mt-1 text-xs text-slate-500">
                      When the license expires
                    </p>
                  </div>
                </div>

                <!-- License key -->
                <div>
                  <label for="license-key" class="block text-sm font-medium text-slate-600 mb-2">
                    License key
                  </label>
                  <textarea
                    id="license-key"
                    v-model="form.license_key"
                    rows="3"
                    class="input-refined resize-none font-mono text-sm"
                    placeholder="Enter license key or activation code..."
                  ></textarea>
                  <p class="mt-1 text-xs text-slate-500">
                    Store the license key securely
                  </p>
                </div>
              </div>
            </div>

            <!-- Tab 4: Integration -->
            <div v-show="activeTab === 'integration'" class="bg-white border border-border-light rounded-2xl p-6">
              <h2 class="text-lg font-bold text-primary-dark mb-6">Integration settings</h2>
              <div class="space-y-6">
                <!-- SSO App ID -->
                <div>
                  <label for="sso-app-id" class="block text-sm font-medium text-slate-600 mb-2">
                    SSO app ID
                  </label>
                  <input
                    id="sso-app-id"
                    v-model="form.sso_app_id"
                    type="text"
                    class="input-refined"
                    placeholder="e.g., app_12345"
                  />
                  <p class="mt-1 text-xs text-slate-500">
                    Single sign-on application identifier
                  </p>
                </div>

                <!-- Integration info box -->
                <div class="bg-slate-50 border border-slate-200 rounded-lg p-4">
                  <div class="flex items-start">
                    <svg class="w-5 h-5 text-blue-500 mr-3 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <div>
                      <h4 class="text-sm font-medium text-slate-700 mb-1">SSO integration</h4>
                      <p class="text-xs text-slate-600">
                        The SSO app ID is optional and used when integrating with single sign-on providers. It helps identify this license in your SSO system for automated user provisioning.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Action Buttons -->
            <div class="mt-6 flex justify-end gap-3">
              <button type="button" @click="handleCancel" class="px-6 py-3 btn-brand-secondary">
                Cancel
              </button>
              <button
                type="submit"
                :disabled="isSubmitting"
                class="px-8 py-3 btn-brand-primary"
              >
                <span v-if="!isSubmitting">Update license</span>
                <span v-else class="flex items-center justify-center">
                  <svg
                    class="animate-spin -ml-1 mr-2 h-5 w-5"
                    fill="none"
                    viewBox="0 0 24 24"
                  >
                    <circle
                      class="opacity-25"
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      stroke-width="4"
                    ></circle>
                    <path
                      class="opacity-75"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                    ></path>
                  </svg>
                  Updating...
                </span>
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </MainLayout>
</template>

<script setup lang="ts">
import { ref, reactive, h, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import MainLayout from '@/components/MainLayout.vue'
import { softwareService, type UpdateSoftwareLicenseData } from '@/services/software'

const router = useRouter()
const route = useRoute()

const licenseId = route.params.id as string
const activeTab = ref<string>('license-info')
const isLoadingLicense = ref(true)
const isSubmitting = ref(false)
const successMessage = ref('')

interface Tab {
  id: string
  label: string
  description: string
  icon: () => any
  fields: string[]
}

// Tab definitions
const tabs: Tab[] = [
  {
    id: 'license-info',
    label: 'License information',
    description: 'Basic details',
    icon: () =>
      h(
        'svg',
        { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
        h('path', {
          'stroke-linecap': 'round',
          'stroke-linejoin': 'round',
          'stroke-width': '2',
          d: 'M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z',
        })
      ),
    fields: ['name', 'vendor', 'status'],
  },
  {
    id: 'seat-management',
    label: 'Seat management',
    description: 'Seats and pricing',
    icon: () =>
      h(
        'svg',
        { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
        h('path', {
          'stroke-linecap': 'round',
          'stroke-linejoin': 'round',
          'stroke-width': '2',
          d: 'M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z',
        })
      ),
    fields: ['total_seats'],
  },
  {
    id: 'dates-keys',
    label: 'Dates and keys',
    description: 'License details',
    icon: () =>
      h(
        'svg',
        { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
        h('path', {
          'stroke-linecap': 'round',
          'stroke-linejoin': 'round',
          'stroke-width': '2',
          d: 'M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z',
        })
      ),
    fields: [],
  },
  {
    id: 'integration',
    label: 'Integration',
    description: 'SSO and external systems',
    icon: () =>
      h(
        'svg',
        { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
        h('path', {
          'stroke-linecap': 'round',
          'stroke-linejoin': 'round',
          'stroke-width': '2',
          d: 'M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z',
        })
      ),
    fields: [],
  },
]

// Form data
const form = reactive({
  name: '',
  vendor: '',
  description: '',
  total_seats: null as number | null,
  annual_cost: null as number | null,
  cost_per_seat: null as number | null,
  purchase_date: '',
  expiration_date: '',
  status: 'active',
  license_key: '',
  sso_app_id: '',
})

// Form errors
const errors = reactive<Record<string, string>>({})

const clearError = (field: string) => {
  delete errors[field]
}

const validateForm = (): boolean => {
  const newErrors: Record<string, string> = {}

  if (!form.name.trim()) {
    newErrors.name = 'License name is required'
  }

  if (!form.vendor.trim()) {
    newErrors.vendor = 'Vendor is required'
  }

  if (!form.status) {
    newErrors.status = 'Status is required'
  }

  if (!form.total_seats || form.total_seats < 1) {
    newErrors.total_seats = 'Total seats must be at least 1'
  }

  Object.assign(errors, newErrors)
  return Object.keys(newErrors).length === 0
}

// Load existing license data
const loadLicense = async () => {
  isLoadingLicense.value = true

  try {
    const license = await softwareService.getById(licenseId)

    // Populate form with existing data
    form.name = license.name
    form.vendor = license.vendor
    form.description = license.description || ''
    form.total_seats = license.total_seats
    form.annual_cost = license.annual_cost || null
    form.cost_per_seat = license.cost_per_seat || null
    form.purchase_date = license.purchase_date || ''
    form.expiration_date = license.expiration_date || ''
    form.status = license.status
    form.license_key = license.license_key || ''
    form.sso_app_id = license.sso_app_id || ''
  } catch (error: any) {
    console.error('Failed to load license:', error)
    alert('Failed to load license details. Please try again.')
    router.push('/software')
  } finally {
    isLoadingLicense.value = false
  }
}

const handleSubmit = async () => {
  // Clear previous errors
  Object.keys(errors).forEach((key) => delete errors[key])

  // Validate
  if (!validateForm()) {
    // Switch to the first tab with errors
    for (const tab of tabs) {
      if (hasErrors(tab.fields)) {
        activeTab.value = tab.id
        break
      }
    }
    return
  }

  isSubmitting.value = true

  try {
    // Prepare license data
    const licenseData: UpdateSoftwareLicenseData = {
      name: form.name,
      vendor: form.vendor,
      description: form.description || undefined,
      total_seats: form.total_seats!,
      annual_cost: form.annual_cost || undefined,
      cost_per_seat: form.cost_per_seat || undefined,
      purchase_date: form.purchase_date || undefined,
      expiration_date: form.expiration_date || undefined,
      status: form.status as 'active' | 'expired' | 'cancelled' | 'future',
      license_key: form.license_key || undefined,
      sso_app_id: form.sso_app_id || undefined,
    }

    // Update license via API
    await softwareService.update(licenseId, licenseData)

    successMessage.value = `License "${form.name}" has been updated successfully.`

    // Redirect to software page after 2 seconds
    setTimeout(() => {
      router.push('/software')
    }, 2000)
  } catch (error: any) {
    console.error('Error submitting form:', error)

    // Handle validation errors from API
    if (error.response?.data?.errors) {
      Object.assign(errors, error.response.data.errors)
    } else {
      alert('Failed to update license. Please try again.')
    }
  } finally {
    isSubmitting.value = false
  }
}

const handleCancel = () => {
  if (confirm('Are you sure you want to cancel? Any unsaved changes will be lost.')) {
    router.push('/software')
  }
}

// Check if a tab has errors
const hasErrors = (fields: string[]): boolean => {
  return fields.some((field) => errors[field])
}

onMounted(() => {
  loadLicense()
})
</script>
