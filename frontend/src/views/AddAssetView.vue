<template>
  <MainLayout>
    <div class="max-w-7xl mx-auto">
      <!-- Header -->
      <div class="mb-6">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-3xl font-bold text-primary-dark">Add new asset</h1>
            <p class="text-slate-500 mt-1">Fill in the details to add a new asset to your inventory</p>
          </div>
          <button @click="handleCancel" class="px-6 py-3 btn-brand-secondary">
            <svg class="w-5 h-5 mr-2 inline-block" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
            Cancel
          </button>
        </div>
      </div>

      <!-- Success message -->
      <div v-if="successMessage" class="alert-success mb-6">
        {{ successMessage }}
      </div>

      <!-- QR Code Scanner -->
      <div v-if="showScanner" class="bg-white border border-border-light rounded-2xl p-6 mb-6 shadow-subtle">
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-lg font-bold text-primary-dark">Scan QR code</h2>
          <button @click="showScanner = false" class="text-slate-500 hover:text-primary-dark">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
        <div class="bg-light-bg border-2 border-dashed border-slate-200 rounded-lg p-8 text-center">
          <svg class="w-16 h-16 mx-auto mb-4 text-teal-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z" />
          </svg>
          <p class="text-slate-600 mb-4">Position the QR code within the frame to scan</p>
          <p class="text-sm text-slate-500">Camera access required for QR code scanning</p>
        </div>
      </div>

      <!-- Main Content -->
      <div class="grid grid-cols-1 lg:grid-cols-4 gap-6">
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

            <!-- QR Code Scanner Button -->
            <button
              @click="toggleScanner"
              class="w-full flex items-center px-4 py-3 text-sm font-medium rounded-lg transition-colors text-left text-slate-600 hover:bg-light-bg hover:text-primary-dark border-l-4 border-transparent mt-4"
            >
              <svg class="w-5 h-5 mr-3 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z" />
              </svg>
              <div>
                <span class="font-bold">Scan QR Code</span>
                <p class="text-xs text-slate-500 mt-0.5">Auto-fill from QR</p>
              </div>
            </button>
          </nav>
        </div>

        <!-- Tab Content -->
        <div class="lg:col-span-3">
          <form @submit.prevent="handleSubmit">
            <!-- Tab 1: Asset Information -->
            <div v-show="activeTab === 'asset-info'" class="bg-white border border-border-light rounded-2xl p-6">
              <h2 class="text-lg font-bold text-primary-dark mb-6">Asset information</h2>
              <div class="space-y-6">
                <!-- Photo Upload -->
                <div>
                  <label class="block text-sm font-medium text-slate-600 mb-2">
                    Asset photo (optional)
                  </label>

                  <!-- Toggle Source -->
                  <div class="flex items-center gap-4 mb-3">
                    <label class="inline-flex items-center">
                      <input type="radio" v-model="photoSource" value="upload" class="form-radio text-accent-blue">
                      <span class="ml-2 text-sm text-slate-700">Upload file</span>
                    </label>
                    <label class="inline-flex items-center">
                      <input type="radio" v-model="photoSource" value="url" class="form-radio text-accent-blue">
                      <span class="ml-2 text-sm text-slate-700">Remote URL</span>
                    </label>
                  </div>

                  <div v-if="photoSource === 'upload'">
                    <div
                      v-if="!photoPreview"
                      @click="triggerPhotoUpload"
                      @dragover.prevent="handleDragOver"
                      @dragleave.prevent="handleDragLeave"
                      @drop.prevent="handleDrop"
                      class="border-2 border-dashed border-slate-200 rounded-lg p-8 text-center cursor-pointer hover:border-accent-blue transition-colors"
                      :class="{ 'border-accent-blue bg-brand-greenDim': isDragging }"
                    >
                      <svg class="w-12 h-12 mx-auto mb-4 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                      </svg>
                      <p class="text-sm text-slate-600 mb-2">
                        <span class="text-teal-600 font-medium">Click to upload</span> or drag and drop
                      </p>
                      <p class="text-xs text-slate-500">PNG, JPG, GIF up to 10MB</p>
                    </div>

                    <!-- Photo Preview -->
                    <div v-else class="relative">
                      <img :src="photoPreview" alt="Asset preview" class="w-full h-64 object-cover rounded-lg border border-slate-200" />
                      <button
                        @click.prevent="removePhoto"
                        class="absolute top-2 right-2 p-2 bg-red-600 text-white rounded-lg border border-slate-200 hover:bg-red-700 transition-colors"
                      >
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                      </button>
                    </div>
                    <input
                      ref="photoInput"
                      type="file"
                      accept="image/*"
                      class="hidden"
                      @change="handlePhotoSelect"
                    />
                  </div>

                  <!-- Remote URL Input -->
                  <div v-else>
                    <input
                      v-model="form.photo_url"
                      type="url"
                      placeholder="https://example.com/image.jpg"
                      class="input-refined w-full mb-2"
                    />
                    <div v-if="form.photo_url" class="relative mt-2">
                      <img 
                        :src="form.photo_url" 
                        alt="Preview" 
                        class="w-full h-64 object-cover rounded-lg border border-slate-200" 
                      />
                    </div>
                  </div>
                </div>

                <!-- Asset name -->
                <div>
                  <label for="asset-name" class="block text-sm font-medium text-slate-600 mb-2">
                    Asset name <span class="text-red-500">*</span>
                  </label>
                  <input
                    id="asset-name"
                    v-model="form.name"
                    type="text"
                    required
                    class="input-refined"
                    placeholder="e.g., MacBook Pro 16&quot;"
                    @focus="clearError('name')"
                  />
                  <p v-if="errors.name" class="mt-2 text-sm text-red-600">{{ errors.name }}</p>
                </div>

                <!-- Serial number -->
                <div>
                  <label for="serial-number" class="block text-sm font-medium text-slate-600 mb-2">
                    Serial number
                  </label>
                  <input
                    id="serial-number"
                    v-model="form.serial_number"
                    type="text"
                    class="input-refined"
                    placeholder="e.g., ABC123456789"
                    @focus="clearError('serial_number')"
                  />
                  <p v-if="errors.serial_number" class="mt-2 text-sm text-red-600">
                    {{ errors.serial_number }}
                  </p>
                </div>

                <!-- Category and Status row -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
                  <div>
                    <label for="category" class="block text-sm font-medium text-slate-600 mb-2">
                      Category <span class="text-red-500">*</span>
                    </label>
                    <select
                      id="category"
                      v-model="form.category"
                      required
                      class="input-refined"
                      @focus="clearError('category')"
                    >
                      <option value="">Select category</option>
                      <option v-for="cat in categories" :key="cat" :value="cat">
                        {{ formatCategory(cat) }}
                      </option>
                    </select>
                    <p v-if="errors.category" class="mt-2 text-sm text-red-600">
                      {{ errors.category }}
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
                      <option value="available">Available</option>
                      <option value="assigned">Assigned</option>
                      <option value="maintenance">In maintenance</option>
                      <option value="retired">Retired</option>
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
                    placeholder="Add any additional details about this asset..."
                  ></textarea>
                </div>
              </div>
            </div>

            <!-- Tab 2: Purchase Information -->
            <div v-show="activeTab === 'purchase-info'" class="bg-white border border-border-light rounded-2xl p-6">
              <h2 class="text-lg font-bold text-primary-dark mb-6">Purchase information</h2>
              <div class="space-y-6">
                <!-- Purchase date and price -->
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
                    <label for="purchase-price" class="block text-sm font-medium text-slate-600 mb-2">
                      Purchase price
                    </label>
                    <div class="relative">
                      <span class="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 text-sm">
                        $
                      </span>
                      <input
                        id="purchase-price"
                        v-model="form.purchase_price"
                        type="number"
                        step="0.01"
                        min="0"
                        class="input-refined pl-7"
                        placeholder="0.00"
                      />
                    </div>
                  </div>
                </div>

                <!-- Vendor -->
                <div>
                  <label for="vendor" class="block text-sm font-medium text-slate-600 mb-2">
                    Vendor
                  </label>
                  <select id="vendor" v-model="form.vendor_id" class="input-refined">
                    <option value="">Select vendor</option>
                    <option value="1">Apple</option>
                    <option value="2">Dell</option>
                    <option value="3">HP</option>
                    <option value="4">Lenovo</option>
                    <option value="5">Amazon</option>
                  </select>
                </div>
              </div>
            </div>

            <!-- Tab 3: Location & Assignment -->
            <div v-show="activeTab === 'location-assignment'" class="bg-white border border-border-light rounded-2xl p-6">
              <h2 class="text-lg font-bold text-primary-dark mb-6">Location & assignment</h2>
              <div class="space-y-6">
                <!-- Department and Location -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
                  <div>
                    <label for="department" class="block text-sm font-medium text-slate-600 mb-2">
                      Department
                    </label>
                    <select id="department" v-model="form.department_id" class="input-refined">
                      <option value="">Select department</option>
                      <option value="1">Engineering</option>
                      <option value="2">Sales</option>
                      <option value="3">Marketing</option>
                      <option value="4">HR</option>
                      <option value="5">Finance</option>
                    </select>
                  </div>

                  <div>
                    <label for="location" class="block text-sm font-medium text-slate-600 mb-2">
                      Location
                    </label>
                    <select id="location" v-model="form.location_id" class="input-refined">
                      <option value="">Select location</option>
                      <option value="1">Main Office</option>
                      <option value="2">Warehouse</option>
                      <option value="3">Remote</option>
                      <option value="4">Branch Office A</option>
                      <option value="5">Branch Office B</option>
                    </select>
                  </div>
                </div>

                <!-- Assigned to -->
                <div>
                  <label for="assigned-to" class="block text-sm font-medium text-slate-600 mb-2">
                    Assigned to employee
                  </label>
                  <select id="assigned-to" v-model="form.employee_id" class="input-refined">
                    <option value="">Not assigned</option>
                    <option value="1">John Smith</option>
                    <option value="2">Jane Doe</option>
                    <option value="3">Mike Johnson</option>
                    <option value="4">Sarah Williams</option>
                  </select>
                  <p class="mt-1 text-xs text-slate-500">
                    Leave empty to keep the asset unassigned
                  </p>
                </div>
              </div>
            </div>

            <!-- Tab 4: Additional Information -->
            <div v-show="activeTab === 'additional-info'" class="bg-white border border-border-light rounded-2xl p-6">
              <h2 class="text-lg font-bold text-primary-dark mb-6">Additional information</h2>
              <div class="space-y-6">
                <!-- Warranty expiration and Condition -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
                  <div>
                    <label
                      for="warranty-expiration"
                      class="block text-sm font-medium text-slate-600 mb-2"
                    >
                      Warranty expiration
                    </label>
                    <input
                      id="warranty-expiration"
                      v-model="form.warranty_expiration"
                      type="date"
                      class="input-refined"
                    />
                  </div>

                  <div>
                    <label for="condition" class="block text-sm font-medium text-slate-600 mb-2">
                      Condition
                    </label>
                    <select id="condition" v-model="form.condition" class="input-refined">
                      <option value="">Select condition</option>
                      <option value="new">New</option>
                      <option value="excellent">Excellent</option>
                      <option value="good">Good</option>
                      <option value="fair">Fair</option>
                      <option value="poor">Poor</option>
                    </select>
                  </div>
                </div>

                <!-- Notes -->
                <div>
                  <label for="notes" class="block text-sm font-medium text-slate-600 mb-2">
                    Notes
                  </label>
                  <textarea
                    id="notes"
                    v-model="form.notes"
                    rows="4"
                    class="input-refined resize-none"
                    placeholder="Add any internal notes or comments..."
                  ></textarea>
                </div>
              </div>
            </div>

            <!-- Tab 5: Metadata -->
            <div v-show="activeTab === 'metadata'" class="bg-white border border-border-light rounded-2xl p-6">
              <h2 class="text-lg font-bold text-primary-dark mb-6">Metadata</h2>
              <div class="space-y-6">
                <!-- Existing Custom Fields -->
                <div v-if="form.custom_fields && Object.keys(form.custom_fields).length > 0">
                  <label class="block text-sm font-medium text-slate-600 mb-2">
                    Custom fields
                  </label>
                  <div class="space-y-3">
                    <div
                      v-for="(value, key) in form.custom_fields"
                      :key="key"
                      class="flex items-center gap-3 bg-white p-3 rounded-lg border border-slate-200"
                    >
                      <div class="flex-1 font-medium text-slate-700">{{ key }}</div>
                      <div class="flex-1 text-slate-600">{{ value }}</div>
                      <button
                        type="button"
                        @click="removeCustomField(String(key))"
                        class="text-red-500 hover:text-red-700"
                        title="Remove field"
                      >
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                          />
                        </svg>
                      </button>
                    </div>
                  </div>
                </div>

                <!-- Add New Custom Field -->
                <div class="bg-slate-50 p-4 rounded-lg border border-slate-200">
                  <h3 class="text-sm font-medium text-primary-dark mb-3">Add new field</h3>
                  <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 mb-3">
                    <div>
                      <input
                        v-model="newCustomFieldKey"
                        type="text"
                        placeholder="Field name (e.g. OS Version)"
                        class="input-refined bg-white"
                      />
                    </div>
                    <div>
                      <input
                        v-model="newCustomFieldValue"
                        type="text"
                        placeholder="Value"
                        class="input-refined bg-white"
                      />
                    </div>
                  </div>
                  <button
                    type="button"
                    @click="addCustomField"
                    :disabled="!newCustomFieldKey || !newCustomFieldValue"
                    class="btn-brand-secondary w-full sm:w-auto text-sm py-2"
                  >
                    Add field
                  </button>
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
                <span v-if="!isSubmitting">Add Asset</span>
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
                  Adding...
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
import { useRouter } from 'vue-router'
import MainLayout from '@/components/MainLayout.vue'
import { assetsService, type CreateAssetData } from '@/services/assets'

const router = useRouter()

const activeTab = ref<string>('asset-info')
const isSubmitting = ref(false)
const successMessage = ref('')
const showScanner = ref(false)
const isDragging = ref(false)
const photoPreview = ref<string | null>(null)
const photoFile = ref<File | null>(null)
const photoInput = ref<HTMLInputElement | null>(null)
const photoSource = ref<'upload' | 'url'>('upload')

// Hardcoded categories matching backend schema
const categories = [
  'laptop',
  'desktop',
  'monitor',
  'phone',
  'tablet',
  'peripheral',
  'server',
  'network_equipment',
  'other'
]

const formatCategory = (cat: string) => {
  return cat.split('_').map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(' ')
}

// Custom fields state
const newCustomFieldKey = ref('')
const newCustomFieldValue = ref('')

const addCustomField = () => {
  if (newCustomFieldKey.value && newCustomFieldValue.value) {
    if (!form.custom_fields) {
      form.custom_fields = {}
    }
    form.custom_fields[newCustomFieldKey.value] = newCustomFieldValue.value
    newCustomFieldKey.value = ''
    newCustomFieldValue.value = ''
  }
}

const removeCustomField = (key: string) => {
  if (form.custom_fields) {
    delete form.custom_fields[key]
  }
}

interface Tab {
  id: string
  label: string
  description: string
  icon: () => any
  fields: string[]
}

// Tab definitions with vertical layout in mind
const tabs: Tab[] = [
  {
    id: 'asset-info',
    label: 'Asset information',
    description: 'Basic details and photo',
    icon: () =>
      h(
        'svg',
        { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
        h('path', {
          'stroke-linecap': 'round',
          'stroke-linejoin': 'round',
          'stroke-width': '2',
          d: 'M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
        })
      ),
    fields: ['name', 'serial_number', 'category', 'status', 'description'],
  },
  {
    id: 'purchase-info',
    label: 'Purchase details',
    description: 'Date, price, and vendor',
    icon: () =>
      h(
        'svg',
        { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
        h('path', {
          'stroke-linecap': 'round',
          'stroke-linejoin': 'round',
          'stroke-width': '2',
          d: 'M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z',
        })
      ),
    fields: ['purchase_date', 'purchase_price', 'vendor_id'],
  },
  {
    id: 'location-assignment',
    label: 'Location',
    description: 'Department and assignment',
    icon: () =>
      h(
        'svg',
        { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
        [
          h('path', {
            'stroke-linecap': 'round',
            'stroke-linejoin': 'round',
            'stroke-width': '2',
            d: 'M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z',
          }),
          h('path', {
            'stroke-linecap': 'round',
            'stroke-linejoin': 'round',
            'stroke-width': '2',
            d: 'M15 11a3 3 0 11-6 0 3 3 0 016 0z',
          }),
        ]
      ),
    fields: ['department_id', 'location_id', 'employee_id'],
  },
  {
    id: 'additional-info',
    label: 'Additional details',
    description: 'Warranty and notes',
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
    fields: ['warranty_expiration', 'condition', 'notes'],
  },
  {
    id: 'metadata',
    label: 'Metadata',
    description: 'Custom fields and properties',
    icon: () =>
      h(
        'svg',
        { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
        h('path', {
          'stroke-linecap': 'round',
          'stroke-linejoin': 'round',
          'stroke-width': '2',
          d: 'M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4m0 5c0 2.21-3.582 4-8 4s-8-1.79-8-4',
        })
      ),
    fields: ['custom_fields'],
  },
]

// Form data
const form = reactive({
  name: '',
  serial_number: '',
  category: '',
  status: '',
  description: '',
  purchase_date: '',
  purchase_price: '',
  vendor_id: '',
  department_id: '',
  location_id: '',
  employee_id: '',
  warranty_expiration: '',
  condition: '',
  notes: '',
  custom_fields: {} as Record<string, any>,
  photo_url: '',
})

// Form errors
const errors = reactive<Record<string, string>>({})

const clearError = (field: string) => {
  delete errors[field]
}

const validateForm = (): boolean => {
  const newErrors: Record<string, string> = {}

  if (!form.name.trim()) {
    newErrors.name = 'Asset name is required'
  }

  if (!form.category) {
    newErrors.category = 'Category is required'
  }

  if (!form.status) {
    newErrors.status = 'Status is required'
  }

  Object.assign(errors, newErrors)
  return Object.keys(newErrors).length === 0
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
    // Prepare asset data
    const assetData: CreateAssetData = {
      name: form.name,
      serial_number: form.serial_number || undefined,
      category: form.category,
      status: form.status,
      description: form.description || undefined,
      purchase_date: form.purchase_date || undefined,
      purchase_price: form.purchase_price ? Number(form.purchase_price) : undefined,
      vendor: form.vendor_id || undefined,
      location_id: form.location_id ? Number(form.location_id) : undefined,
      employee_id: form.employee_id ? Number(form.employee_id) : undefined,
      warranty_expiration: form.warranty_expiration || undefined,
      condition: form.condition || undefined,
      notes: form.notes || undefined,
      custom_fields: form.custom_fields,
    }

    // Handle Image Logic
    if (photoSource.value === 'upload') {
      if (photoFile.value) {
        assetData.photo = photoFile.value
      }
    } else {
      // Remote URL mode
      if (form.photo_url) {
        if (!assetData.custom_fields) assetData.custom_fields = {}
        assetData.custom_fields.photo_url = form.photo_url
      }
    }

    // Create asset via API
    const createdAsset = await assetsService.create(assetData)

    successMessage.value = `Asset "${createdAsset.name}" has been added successfully.`

    // Redirect to assets page after 2 seconds
    setTimeout(() => {
      router.push('/assets')
    }, 2000)
  } catch (error: any) {
    console.error('Error submitting form:', error)

    // Handle validation errors from API
    if (error.response?.data?.errors) {
      Object.assign(errors, error.response.data.errors)
    } else {
      alert('Failed to create asset. Please try again.')
    }
  } finally {
    isSubmitting.value = false
  }
}

const handleCancel = () => {
  if (confirm('Are you sure you want to cancel? Any unsaved changes will be lost.')) {
    router.push('/assets')
  }
}

// Check if a tab has errors
const hasErrors = (fields: string[]): boolean => {
  return fields.some((field) => errors[field])
}

// Photo upload handlers
const triggerPhotoUpload = () => {
  photoInput.value?.click()
}

const handlePhotoSelect = (event: Event) => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  if (file) {
    processPhotoFile(file)
  }
}

const handleDragOver = (event: DragEvent) => {
  isDragging.value = true
}

const handleDragLeave = (event: DragEvent) => {
  isDragging.value = false
}

const handleDrop = (event: DragEvent) => {
  isDragging.value = false
  const file = event.dataTransfer?.files[0]
  if (file && file.type.startsWith('image/')) {
    processPhotoFile(file)
  }
}

const processPhotoFile = (file: File) => {
  if (file.size > 10 * 1024 * 1024) {
    alert('File size must be less than 10MB')
    return
  }

  photoFile.value = file
  const reader = new FileReader()
  reader.onload = (e) => {
    photoPreview.value = e.target?.result as string
  }
  reader.readAsDataURL(file)
}

const removePhoto = () => {
  photoPreview.value = null
  photoFile.value = null
  if (photoInput.value) {
    photoInput.value.value = ''
  }
}

// QR Code scanner
const toggleScanner = () => {
  showScanner.value = !showScanner.value
}

// Mock function to simulate QR code scan result
const handleQRCodeScanned = (data: string) => {
  try {
    const scannedData = JSON.parse(data)
    // Prepopulate form with scanned data
    if (scannedData.name) form.name = scannedData.name
    if (scannedData.serial_number) form.serial_number = scannedData.serial_number
    if (scannedData.category) form.category = scannedData.category
    if (scannedData.status) form.status = scannedData.status
    // ... populate other fields

    showScanner.value = false
    successMessage.value = 'Asset information loaded from QR code'
    setTimeout(() => {
      successMessage.value = ''
    }, 3000)
  } catch (error) {
    console.error('Invalid QR code data:', error)
  }
}
</script>
