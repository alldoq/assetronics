<template>
  <Modal
    :model-value="modelValue"
    @update:model-value="$emit('update:modelValue', $event)"
    title="Assign asset"
    size="md"
  >
    <form @submit.prevent="handleSubmit" class="space-y-4">
      <!-- Employee Selection -->
      <div>
        <label class="block text-sm font-medium text-slate-700 mb-2">
          Employee <span class="text-red-500">*</span>
        </label>
        <EmployeeAutocomplete
          v-model="selectedEmployeeId"
          :employees="employees"
          placeholder="Select employee..."
          :show-special-options="false"
        />
        <p v-if="errors.employee_id" class="mt-1 text-sm text-red-600">{{ errors.employee_id }}</p>
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

      <!-- Asset Info Display -->
      <div v-if="asset" class="bg-light-bg rounded-lg p-4 border border-slate-200">
        <p class="text-sm font-medium text-slate-700 mb-2">Asset to assign</p>
        <div class="flex items-center gap-3">
          <div class="w-12 h-12 flex-shrink-0 rounded-lg bg-gradient-to-br from-slate-50 to-slate-100 flex items-center justify-center overflow-hidden border border-slate-200">
            <img
              v-if="asset.image_url"
              :src="asset.image_url"
              :alt="asset.name"
              class="w-full h-full object-contain"
            />
            <svg v-else class="w-6 h-6 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
            </svg>
          </div>
          <div>
            <div class="text-sm font-bold text-primary-dark">{{ asset.name }}</div>
            <div class="text-sm text-slate-500 font-mono">{{ asset.serial_number || 'No serial' }}</div>
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
          :disabled="isSubmitting || !selectedEmployeeId"
        >
          <span v-if="isSubmitting">Assigning...</span>
          <span v-else>Assign asset</span>
        </button>
      </div>
    </template>
  </Modal>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import Modal from './Modal.vue'
import EmployeeAutocomplete from './EmployeeAutocomplete.vue'
import { assetsService, type Asset } from '@/services/assets'
import type { Employee } from '@/services/employees'

interface Props {
  modelValue: boolean
  asset: Asset | null
  employees: Employee[]
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
  'assigned': []
}>()

const selectedEmployeeId = ref('')
const assignmentType = ref<'permanent' | 'temporary' | 'loaner'>('permanent')
const expectedReturnDate = ref('')
const isSubmitting = ref(false)
const errorMessage = ref('')
const errors = ref<Record<string, string>>({})

// Minimum date is today
const minDate = computed(() => {
  const today = new Date()
  return today.toISOString().split('T')[0]
})

// Reset form when modal opens/closes
watch(() => props.modelValue, (isOpen) => {
  if (isOpen) {
    resetForm()
  }
})

const resetForm = () => {
  selectedEmployeeId.value = ''
  assignmentType.value = 'permanent'
  expectedReturnDate.value = ''
  errorMessage.value = ''
  errors.value = {}
}

const validate = (): boolean => {
  errors.value = {}

  if (!selectedEmployeeId.value) {
    errors.value.employee_id = 'Please select an employee'
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
  if (!props.asset) return
  if (!validate()) return

  isSubmitting.value = true
  errorMessage.value = ''

  try {
    await assetsService.assign(
      props.asset.id,
      selectedEmployeeId.value,
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
