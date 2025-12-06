<template>
  <Modal :modelValue="true" @update:modelValue="handleClose">
    <template #title>Create New Workflow</template>
    <div>
      <!-- Step 1: Select Template -->
      <div v-if="step === 1">
        <h3 class="text-lg font-semibold text-primary-dark mb-4">Choose a Workflow Template</h3>

        <!-- Show warning if API failed but we have fallback templates -->
        <div v-if="templateError && templates.length > 0" class="mb-4 p-3 bg-yellow-50 border border-yellow-200 rounded-md">
          <p class="text-xs text-yellow-800">
            <strong>Note:</strong> Could not connect to server. Showing default templates.
          </p>
        </div>

        <div class="space-y-3">
          <div
            v-for="template in templates"
            :key="template.key"
            @click="selectTemplate(template)"
            class="border border-slate-200 rounded-lg p-4 cursor-pointer hover:border-accent-blue hover:bg-accent-blue/5 transition-all"
            :class="{ 'border-accent-blue bg-accent-blue/5': selectedTemplate?.key === template.key }"
          >
            <div class="flex items-start justify-between">
              <div>
                <h4 class="font-semibold text-primary-dark">{{ template.name }}</h4>
                <p class="text-sm text-slate-600 mt-1">{{ template.description }}</p>
                <div class="flex gap-3 mt-2 text-xs text-slate-500">
                  <span>{{ template.step_count }} steps</span>
                  <span>~{{ template.estimated_duration_days }} days</span>
                  <span class="capitalize">{{ template.type }}</span>
                </div>
              </div>
              <div v-if="selectedTemplate?.key === template.key" class="text-accent-blue">
                <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                </svg>
              </div>
            </div>
          </div>
        </div>

        <div class="flex justify-end gap-3 mt-6">
          <button
            @click="$emit('close')"
            class="px-4 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-md hover:bg-slate-50"
          >
            Cancel
          </button>
          <button
            @click="step = 2"
            :disabled="!selectedTemplate"
            class="px-4 py-2 text-sm font-medium text-white bg-primary-dark rounded-md hover:bg-primary-navy disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Next
          </button>
        </div>
      </div>

      <!-- Step 2: Configure Workflow -->
      <div v-if="step === 2 && selectedTemplate">
        <div class="mb-4">
          <button
            @click="step = 1"
            class="flex items-center gap-1 text-sm text-slate-600 hover:text-slate-900"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
            </svg>
            Back to templates
          </button>
        </div>

        <h3 class="text-lg font-semibold text-primary-dark mb-4">Configure {{ selectedTemplate.name }}</h3>

        <form @submit.prevent="createWorkflow" class="space-y-4">
          <!-- Asset Selection (for procurement and equipment workflows) -->
          <div v-if="['procurement', 'repair'].includes(selectedTemplate.type)">
            <label class="block text-sm font-medium text-slate-700 mb-2">Asset</label>
            <select
              v-model="form.asset_id"
              class="w-full px-4 py-3 text-base rounded-md border border-slate-300 shadow-sm focus:border-accent-blue focus:ring-2 focus:ring-accent-blue focus:outline-none"
              required
            >
              <option value="">Select an asset...</option>
              <option v-for="asset in assets" :key="asset.id" :value="asset.id">
                {{ asset.name }} ({{ asset.asset_tag }})
              </option>
            </select>
          </div>

          <!-- Employee Selection (for onboarding workflows) -->
          <div v-if="selectedTemplate.type === 'onboarding'">
            <label class="block text-sm font-medium text-slate-700 mb-2">Employee</label>
            <select
              v-model="form.employee_id"
              class="w-full px-4 py-3 text-base rounded-md border border-slate-300 shadow-sm focus:border-accent-blue focus:ring-2 focus:ring-accent-blue focus:outline-none"
              required
            >
              <option value="">Select an employee...</option>
              <option v-for="employee in employees" :key="employee.id" :value="employee.id">
                {{ employee.first_name }} {{ employee.last_name }} ({{ employee.email }})
              </option>
            </select>
          </div>

          <!-- Assigned To -->
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-2">Assigned To (Email)</label>
            <input
              v-model="form.assigned_to"
              type="email"
              class="w-full px-4 py-3 text-base rounded-md border border-slate-300 shadow-sm focus:border-accent-blue focus:ring-2 focus:ring-accent-blue focus:outline-none"
              placeholder="it@company.com"
            >
          </div>

          <!-- Due Date -->
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-2">Due Date</label>
            <input
              v-model="form.due_date"
              type="date"
              class="w-full px-4 py-3 text-base rounded-md border border-slate-300 shadow-sm focus:border-accent-blue focus:ring-2 focus:ring-accent-blue focus:outline-none"
            >
          </div>

          <!-- Priority -->
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-2">Priority</label>
            <select
              v-model="form.priority"
              class="w-full px-4 py-3 text-base rounded-md border border-slate-300 shadow-sm focus:border-accent-blue focus:ring-2 focus:ring-accent-blue focus:outline-none"
            >
              <option value="low">Low</option>
              <option value="normal">Normal</option>
              <option value="high">High</option>
              <option value="urgent">Urgent</option>
            </select>
          </div>

          <div class="flex justify-end gap-3 mt-6">
            <button
              type="button"
              @click="$emit('close')"
              class="px-4 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-md hover:bg-slate-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="creating"
              class="px-4 py-2 text-sm font-medium text-white bg-primary-dark rounded-md hover:bg-primary-navy flex items-center gap-2 disabled:opacity-50"
            >
              <svg v-if="creating" class="animate-spin h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              {{ creating ? 'Creating...' : 'Create Workflow' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </Modal>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import Modal from '@/components/Modal.vue'

interface Template {
  key: string
  name: string
  type: string
  description: string
  estimated_duration_days: number
  step_count: number
}

interface Asset {
  id: string
  name: string
  asset_tag: string
}

interface Employee {
  id: string
  first_name: string
  last_name: string
  email: string
}

const emit = defineEmits(['close', 'created'])
const authStore = useAuthStore()

const step = ref(1)
const loadingTemplates = ref(false)
const creating = ref(false)
const templateError = ref('')

const getFallbackTemplates = (): Template[] => {
  return [
    {
      key: 'incoming_hardware',
      name: 'Incoming Hardware Setup',
      type: 'procurement',
      description: 'Complete process for receiving, configuring, and deploying new hardware',
      estimated_duration_days: 3,
      step_count: 8
    },
    {
      key: 'new_employee',
      name: 'New Employee IT Onboarding',
      type: 'onboarding',
      description: 'Complete IT setup process for new staff members',
      estimated_duration_days: 7,
      step_count: 9
    },
    {
      key: 'equipment_return',
      name: 'Equipment Return & Offboarding',
      type: 'offboarding',
      description: 'Secure process for recovering equipment and removing access',
      estimated_duration_days: 2,
      step_count: 6
    },
    {
      key: 'emergency_replacement',
      name: 'Emergency Hardware Replacement',
      type: 'repair',
      description: 'Fast-track replacement for failed or damaged equipment',
      estimated_duration_days: 1,
      step_count: 5
    }
  ]
}

// Initialize with fallback templates immediately
const templates = ref<Template[]>(getFallbackTemplates())
const selectedTemplate = ref<Template | null>(null)

const assets = ref<Asset[]>([])
const employees = ref<Employee[]>([])

const form = ref({
  asset_id: '',
  employee_id: '',
  assigned_to: '',
  due_date: '',
  priority: 'normal'
})

const handleClose = (value: boolean) => {
  if (!value) {
    emit('close')
  }
}

const fetchTemplates = async () => {
  loadingTemplates.value = true
  templateError.value = ''

  try {
    const response = await fetch(`${import.meta.env.VITE_API_URL}/api/v1/workflows/templates`, {
      headers: {
        'Authorization': `Bearer ${authStore.token}`,
        'X-Tenant-ID': authStore.user?.tenant_id || ''
      }
    })

    if (!response.ok) {
      const errorText = await response.text()
      console.error('Template fetch failed:', response.status, errorText)
      throw new Error(`Failed to fetch templates (${response.status})`)
    }

    const data = await response.json()
    console.log('Templates loaded:', data)

    if (data.data && Array.isArray(data.data)) {
      templates.value = data.data
    } else {
      console.warn('Invalid template data format, using fallback')
      templates.value = getFallbackTemplates()
    }

    // If no templates returned, use fallback
    if (templates.value.length === 0) {
      console.warn('No templates available from API, using fallback')
      templates.value = getFallbackTemplates()
    }
  } catch (error) {
    console.error('Error fetching templates:', error)
    templateError.value = error instanceof Error ? error.message : 'Failed to load templates'
    // Use fallback templates
    templates.value = getFallbackTemplates()
  } finally {
    loadingTemplates.value = false
  }
}

const retryFetchTemplates = () => {
  fetchTemplates()
}

const fetchAssets = async () => {
  try {
    const response = await fetch(`${import.meta.env.VITE_API_URL}/api/v1/assets`, {
      headers: {
        'Authorization': `Bearer ${authStore.token}`,
        'X-Tenant-ID': authStore.user?.tenant_id || ''
      }
    })

    if (!response.ok) throw new Error('Failed to fetch assets')

    const data = await response.json()
    assets.value = data.data
  } catch (error) {
    console.error('Error fetching assets:', error)
  }
}

const fetchEmployees = async () => {
  try {
    const response = await fetch(`${import.meta.env.VITE_API_URL}/api/v1/employees`, {
      headers: {
        'Authorization': `Bearer ${authStore.token}`,
        'X-Tenant-ID': authStore.user?.tenant_id || ''
      }
    })

    if (!response.ok) throw new Error('Failed to fetch employees')

    const data = await response.json()
    employees.value = data.data
  } catch (error) {
    console.error('Error fetching employees:', error)
  }
}

const selectTemplate = (template: Template) => {
  selectedTemplate.value = template
}

const createWorkflow = async () => {
  if (!selectedTemplate.value) return

  creating.value = true
  try {
    const payload = {
      template_key: selectedTemplate.value.key,
      ...form.value
    }

    // Remove empty values
    Object.keys(payload).forEach(key => {
      if (payload[key as keyof typeof payload] === '') {
        delete payload[key as keyof typeof payload]
      }
    })

    const response = await fetch(`${import.meta.env.VITE_API_URL}/api/v1/workflows/from-template`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authStore.token}`,
        'X-Tenant-ID': authStore.user?.tenant_id || ''
      },
      body: JSON.stringify(payload)
    })

    if (!response.ok) throw new Error('Failed to create workflow')

    emit('created')
  } catch (error) {
    console.error('Error creating workflow:', error)
    alert('Failed to create workflow. Please try again.')
  } finally {
    creating.value = false
  }
}

onMounted(() => {
  // Templates are already loaded from fallback, but try to fetch from API for latest version
  fetchTemplates()
  fetchAssets()
  fetchEmployees()

  // Set default due date to 7 days from now
  const defaultDueDate = new Date()
  defaultDueDate.setDate(defaultDueDate.getDate() + 7)
  form.value.due_date = defaultDueDate.toISOString().split('T')[0]!
})
</script>
