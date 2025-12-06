<template>
  <Modal
    :model-value="modelValue"
    @update:model-value="$emit('update:modelValue', $event)"
    title="Assign asset to employee"
    size="md"
  >
    <form @submit.prevent="handleSubmit" class="space-y-4">
      <!-- Asset Selection -->
      <div>
        <label class="block text-sm font-medium text-slate-700 mb-2">
          Asset <span class="text-red-500">*</span>
        </label>
        <AssetAutocomplete
          v-model="selectedAssetId"
          :assets="availableAssets"
          placeholder="Search available assets..."
        />
        <p v-if="errors.asset_id" class="mt-1 text-sm text-red-600">{{ errors.asset_id }}</p>
      </div>

      <!-- Assignment Type -->
      <div>
        <label class="block text-sm font-medium text-slate-700 mb-2">
          Assignment type
        </label>
        <select
          v-model="assignmentType"
          class="input-refined w-full"
        >
          <option value="permanent">Permanent</option>
          <option value="temporary">Temporary</option>
          <option value="loaner">Loaner</option>
        </select>
      </div>

      <!-- Expected Return Date (only for temporary/loaner) -->
      <div v-if="assignmentType !== 'permanent'">
        <label class="block text-sm font-medium text-slate-700 mb-2">
          Expected return date
        </label>
        <input
          v-model="expectedReturnDate"
          type="date"
          class="input-refined w-full"
          :min="minDate"
        />
        <p v-if="errors.expected_return_date" class="mt-1 text-sm text-red-600">{{ errors.expected_return_date }}</p>
      </div>

      <!-- Employee Info Display -->
      <div v-if="employee" class="bg-light-bg rounded-lg p-4 border border-slate-200">
        <p class="text-sm font-medium text-slate-700 mb-2">Assigning to</p>
        <div class="flex items-center gap-3">
          <div class="w-12 h-12 flex-shrink-0 rounded-full bg-accent-blue flex items-center justify-center text-primary-dark font-bold">
            {{ getInitials(employee) }}
          </div>
          <div>
            <div class="text-sm font-bold text-primary-dark">{{ employee.first_name }} {{ employee.last_name }}</div>
            <div class="text-sm text-slate-500">{{ employee.email }}</div>
          </div>
        </div>
      </div>

      <!-- Error Message -->
      <div v-if="errorMessage" class="alert-error">
        {{ errorMessage }}
      </div>
    </form>

    <template #footer>
      <div class="flex justify-end gap-3">
        <button
          type="button"
          @click="$emit('update:modelValue', false)"
          class="px-4 py-2 btn-refined"
          :disabled="isSubmitting"
        >
          Cancel
        </button>
        <button
          type="submit"
          @click="handleSubmit"
          class="px-4 py-2 btn-brand-primary"
          :disabled="isSubmitting || !selectedAssetId"
        >
          <span v-if="isSubmitting">Assigning...</span>
          <span v-else>Assign asset</span>
        </button>
      </div>
    </template>
  </Modal>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import Modal from './Modal.vue'
import AssetAutocomplete from './AssetAutocomplete.vue'
import { assetsService, type Asset } from '@/services/assets'
import type { Employee } from '@/services/employees'

interface Props {
  modelValue: boolean
  employee: Employee | null
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
  'assigned': []
}>()

const selectedAssetId = ref('')
const assignmentType = ref<'permanent' | 'temporary' | 'loaner'>('permanent')
const expectedReturnDate = ref('')
const isSubmitting = ref(false)
const errorMessage = ref('')
const errors = ref<Record<string, string>>({})
const availableAssets = ref<Asset[]>([])

// Minimum date is today
const minDate = computed(() => {
  const today = new Date()
  return today.toISOString().split('T')[0]
})

// Get employee initials
const getInitials = (employee: Employee) => {
  return `${employee.first_name.charAt(0)}${employee.last_name.charAt(0)}`.toUpperCase()
}

// Load available assets when modal opens
const loadAvailableAssets = async () => {
  try {
    const response = await assetsService.getAll({
      status: 'in_stock',
      per_page: 100
    })
    availableAssets.value = response.data
  } catch (error) {
    console.error('Failed to load available assets:', error)
  }
}

// Reset form when modal opens/closes
watch(() => props.modelValue, (isOpen) => {
  if (isOpen) {
    resetForm()
    loadAvailableAssets()
  }
})

const resetForm = () => {
  selectedAssetId.value = ''
  assignmentType.value = 'permanent'
  expectedReturnDate.value = ''
  errorMessage.value = ''
  errors.value = {}
}

const validate = (): boolean => {
  errors.value = {}

  if (!selectedAssetId.value) {
    errors.value.asset_id = 'Please select an asset'
    return false
  }

  if (assignmentType.value !== 'permanent' && expectedReturnDate.value) {
    const returnDate = new Date(expectedReturnDate.value)
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    if (returnDate < today) {
      errors.value.expected_return_date = 'Return date must be in the future'
      return false
    }
  }

  return true
}

const handleSubmit = async () => {
  if (!props.employee) return
  if (!validate()) return

  isSubmitting.value = true
  errorMessage.value = ''

  try {
    await assetsService.assign(
      selectedAssetId.value,
      props.employee.id,
      assignmentType.value,
      expectedReturnDate.value || undefined
    )

    emit('assigned')
    emit('update:modelValue', false)
  } catch (error: any) {
    console.error('Failed to assign asset:', error)
    errorMessage.value = error.response?.data?.error?.message || 'Failed to assign asset. Please try again.'
  } finally {
    isSubmitting.value = false
  }
}
</script>
