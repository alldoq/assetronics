<template>
  <MainLayout>
    <div class="max-w-7xl mx-auto">
      <!-- Header -->
      <div class="mb-6">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-3xl font-bold text-primary-dark">Add new employee</h1>
            <p class="text-slate-500 mt-1">Add a new team member manually</p>
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
          </nav>
        </div>

        <!-- Tab Content -->
        <div class="lg:col-span-3">
          <form @submit.prevent="handleSubmit">
            <!-- Tab 1: Personal Information -->
            <div v-show="activeTab === 'personal-info'" class="bg-white border border-border-light rounded-2xl p-6">
              <h2 class="text-lg font-bold text-primary-dark mb-6">Personal information</h2>
              <div class="space-y-6">
                <!-- Photo Upload -->
                <div>
                  <label class="block text-sm font-medium text-slate-600 mb-2">
                    Profile photo
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

                  <!-- File Upload -->
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
                      <p class="text-xs text-slate-500">PNG, JPG, GIF up to 5MB</p>
                    </div>

                    <!-- Photo Preview -->
                    <div v-else class="relative w-32 h-32 mx-auto">
                      <img :src="photoPreview" alt="Profile preview" class="w-full h-full object-cover rounded-full border border-slate-200" />
                      <button
                        @click.prevent="removePhoto"
                        class="absolute top-0 right-0 p-1 bg-red-600 text-white rounded-full border border-slate-200 hover:bg-red-700 transition-colors"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
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
                      placeholder="https://example.com/profile.jpg"
                      class="input-refined w-full mb-2"
                    />
                    <div v-if="form.photo_url" class="relative mt-2 w-32 h-32 mx-auto">
                      <img 
                        :src="form.photo_url" 
                        alt="Preview" 
                        class="w-full h-full object-cover rounded-full border border-slate-200"
                        @error="handleImageError"
                      />
                    </div>
                  </div>
                </div>

                <!-- Name -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
                  <div>
                    <label for="first-name" class="block text-sm font-medium text-slate-600 mb-2">
                      First name <span class="text-red-500">*</span>
                    </label>
                    <input
                      id="first-name"
                      v-model="form.first_name"
                      type="text"
                      required
                      class="input-refined"
                      placeholder="e.g., John"
                      @focus="clearError('first_name')"
                    />
                    <p v-if="errors.first_name" class="mt-2 text-sm text-red-600">{{ errors.first_name }}</p>
                  </div>
                  <div>
                    <label for="last-name" class="block text-sm font-medium text-slate-600 mb-2">
                      Last name <span class="text-red-500">*</span>
                    </label>
                    <input
                      id="last-name"
                      v-model="form.last_name"
                      type="text"
                      required
                      class="input-refined"
                      placeholder="e.g., Doe"
                      @focus="clearError('last_name')"
                    />
                    <p v-if="errors.last_name" class="mt-2 text-sm text-red-600">{{ errors.last_name }}</p>
                  </div>
                </div>

                <!-- Contact -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
                  <div>
                    <label for="email" class="block text-sm font-medium text-slate-600 mb-2">
                      Email address <span class="text-red-500">*</span>
                    </label>
                    <input
                      id="email"
                      v-model="form.email"
                      type="email"
                      required
                      class="input-refined"
                      placeholder="john.doe@company.com"
                      @focus="clearError('email')"
                    />
                    <p v-if="errors.email" class="mt-2 text-sm text-red-600">{{ errors.email }}</p>
                  </div>
                  <div>
                    <label for="phone" class="block text-sm font-medium text-slate-600 mb-2">
                      Phone number
                    </label>
                    <input
                      id="phone"
                      v-model="form.phone"
                      type="tel"
                      class="input-refined"
                      placeholder="+1 (555) 000-0000"
                    />
                  </div>
                </div>
              </div>
            </div>

            <!-- Tab 2: Employment Details -->
            <div v-show="activeTab === 'employment-details'" class="bg-white border border-border-light rounded-2xl p-6">
              <h2 class="text-lg font-bold text-primary-dark mb-6">Employment details</h2>
              <div class="space-y-6">
                <!-- Job & Department -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
                  <div>
                    <label for="job-title" class="block text-sm font-medium text-slate-600 mb-2">
                      Job title
                    </label>
                    <input
                      id="job-title"
                      v-model="form.job_title"
                      type="text"
                      class="input-refined"
                      placeholder="e.g., Software Engineer"
                    />
                  </div>
                  <div>
                    <label for="department" class="block text-sm font-medium text-slate-600 mb-2">
                      Department
                    </label>
                    <input
                      id="department"
                      v-model="form.department"
                      type="text"
                      class="input-refined"
                      placeholder="e.g., Engineering"
                    />
                  </div>
                </div>

                <!-- IDs & Status -->
                <div class="grid grid-cols-1 sm:grid-cols-3 gap-6">
                  <div>
                    <label for="employee-id" class="block text-sm font-medium text-slate-600 mb-2">
                      Employee ID
                    </label>
                    <input
                      id="employee-id"
                      v-model="form.employee_id"
                      type="text"
                      class="input-refined"
                      placeholder="e.g., EMP-001"
                    />
                  </div>
                  <div>
                    <label for="status" class="block text-sm font-medium text-slate-600 mb-2">
                      Status <span class="text-red-500">*</span>
                    </label>
                    <select
                      id="status"
                      v-model="form.employment_status"
                      required
                      class="input-refined"
                    >
                      <option value="active">Active</option>
                      <option value="on_leave">On Leave</option>
                      <option value="terminated">Terminated</option>
                    </select>
                  </div>
                   <div>
                    <label for="hire-date" class="block text-sm font-medium text-slate-600 mb-2">
                      Hire date
                    </label>
                    <input
                      id="hire-date"
                      v-model="form.hire_date"
                      type="date"
                      class="input-refined"
                    />
                  </div>
                </div>
                
                 <!-- Work Location -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
                  <div>
                    <label for="work-type" class="block text-sm font-medium text-slate-600 mb-2">
                      Work location type
                    </label>
                    <select
                      id="work-type"
                      v-model="form.work_location_type"
                      class="input-refined"
                    >
                      <option value="">Select type</option>
                      <option value="office">Office</option>
                      <option value="remote">Remote</option>
                      <option value="hybrid">Hybrid</option>
                    </select>
                  </div>
                </div>

              </div>
            </div>

            <!-- Tab 3: Additional Information -->
            <div v-show="activeTab === 'additional-info'" class="bg-white border border-border-light rounded-2xl p-6">
              <h2 class="text-lg font-bold text-primary-dark mb-6">Additional information</h2>
              <div class="space-y-6">
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
                    placeholder="Add any internal notes..."
                  ></textarea>
                </div>
              </div>
            </div>

            <!-- Tab 4: Metadata -->
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
                        placeholder="Field name (e.g. T-Shirt Size)"
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
                <span v-if="!isSubmitting">Add employee</span>
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
import { ref, reactive, h } from 'vue'
import { useRouter } from 'vue-router'
import MainLayout from '@/components/MainLayout.vue'
import { employeesService, type CreateEmployeeData } from '@/services/employees'

const router = useRouter()

const activeTab = ref<string>('personal-info')
const isSubmitting = ref(false)
const successMessage = ref('')

// Photo state
const photoFile = ref<File | null>(null)
const photoInput = ref<HTMLInputElement | null>(null)
const photoSource = ref<'upload' | 'url'>('upload')
const photoPreview = ref<string | null>(null)
const isDragging = ref(false)

// Custom fields state
const newCustomFieldKey = ref('')
const newCustomFieldValue = ref('')

// Photo handlers
const triggerPhotoUpload = () => photoInput.value?.click()

const handlePhotoSelect = (event: Event) => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  if (file) processPhotoFile(file)
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
  if (file.size > 5 * 1024 * 1024) {
    alert('File size must be less than 5MB')
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
  if (photoInput.value) photoInput.value.value = ''
}

const handleImageError = (e: Event) => {
  (e.target as HTMLImageElement).src = 'https://via.placeholder.com/128?text=Error'
}

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

const tabs: Tab[] = [
  {
    id: 'personal-info',
    label: 'Personal Information',
    description: 'Name, email, and contact details',
    icon: () => h('svg', { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' }, h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z' })),
    fields: ['first_name', 'last_name', 'email', 'phone']
  },
  {
    id: 'employment-details',
    label: 'Employment Details',
    description: 'Job title, department, and status',
    icon: () => h('svg', { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' }, h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z' })),
    fields: ['job_title', 'department', 'employee_id', 'employment_status', 'hire_date', 'work_location_type']
  },
  {
    id: 'additional-info',
    label: 'Additional Info',
    description: 'Notes and comments',
    icon: () => h('svg', { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' }, h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z' })),
    fields: ['notes']
  },
  {
    id: 'metadata',
    label: 'Metadata',
    description: 'Custom fields',
    icon: () => h('svg', { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' }, h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4m0 5c0 2.21-3.582 4-8 4s-8-1.79-8-4' })),
    fields: ['custom_fields']
  }
]

const form = reactive({
  first_name: '',
  last_name: '',
  email: '',
  phone: '',
  job_title: '',
  department: '',
  employee_id: '',
  employment_status: 'active',
  hire_date: '',
  work_location_type: '',
  notes: '',
  custom_fields: {} as Record<string, any>,
  photo_url: ''
})

const errors = reactive<Record<string, string>>({})

const clearError = (field: string) => {
  delete errors[field]
}

const validateForm = (): boolean => {
  const newErrors: Record<string, string> = {}
  
  if (!form.first_name.trim()) newErrors.first_name = 'First name is required'
  if (!form.last_name.trim()) newErrors.last_name = 'Last name is required'
  if (!form.email.trim()) newErrors.email = 'Email is required'
  else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) newErrors.email = 'Invalid email format'

  Object.assign(errors, newErrors)
  return Object.keys(newErrors).length === 0
}

const handleSubmit = async () => {
  Object.keys(errors).forEach(key => delete errors[key])
  
  if (!validateForm()) {
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
    const employeeData: CreateEmployeeData = {
      first_name: form.first_name,
      last_name: form.last_name,
      email: form.email,
      phone: form.phone || undefined,
      job_title: form.job_title || undefined,
      department: form.department || undefined,
      employee_id: form.employee_id || undefined,
      employment_status: form.employment_status,
      hire_date: form.hire_date || undefined,
      work_location_type: form.work_location_type || undefined,
      notes: form.notes || undefined,
      custom_fields: form.custom_fields
    }

    // Handle Photo
    if (photoSource.value === 'upload' && photoFile.value) {
      // If uploading file, we pass it. The service needs to handle FormData.
      // We'll temporarily add it to custom_fields or handle in service
      (employeeData as any).photo = photoFile.value
    } else if (photoSource.value === 'url' && form.photo_url) {
      if (!employeeData.custom_fields) employeeData.custom_fields = {}
      employeeData.custom_fields.photo_url = form.photo_url
    }

    const createdEmployee = await employeesService.create(employeeData)
    successMessage.value = `Employee "${createdEmployee.first_name} ${createdEmployee.last_name}" added successfully.`
    
    setTimeout(() => {
      router.push('/employees')
    }, 2000)
  } catch (error: any) {
    console.error('Error creating employee:', error)
    if (error.response?.data?.errors) {
      Object.assign(errors, error.response.data.errors)
    } else {
      alert('Failed to add employee. Please try again.')
    }
  } finally {
    isSubmitting.value = false
  }
}

const handleCancel = () => {
  if (confirm('Are you sure you want to cancel? Any unsaved changes will be lost.')) {
    router.push('/employees')
  }
}

const hasErrors = (fields: string[]): boolean => {
  return fields.some(field => errors[field])
}
</script>
