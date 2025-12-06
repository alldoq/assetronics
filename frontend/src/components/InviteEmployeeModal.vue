<template>
  <Modal v-model="isOpen">
    <template #title>Invite employee to system</template>
    <form @submit.prevent="handleSubmit" class="space-y-4">
      <div class="grid grid-cols-2 gap-4">
        <div>
          <label class="form-label">First name</label>
          <input
            v-model="formData.first_name"
            type="text"
            required
            class="input-refined"
            :placeholder="employee?.first_name || 'John'"
          />
        </div>
        <div>
          <label class="form-label">Last name</label>
          <input
            v-model="formData.last_name"
            type="text"
            required
            class="input-refined"
            :placeholder="employee?.last_name || 'Doe'"
          />
        </div>
      </div>

      <div>
        <label class="form-label">Email</label>
        <input
          v-model="formData.email"
          type="email"
          required
          class="input-refined"
          :placeholder="employee?.email || 'john.doe@company.com'"
        />
      </div>

      <div>
        <label class="form-label">Password</label>
        <input
          v-model="formData.password"
          type="password"
          required
          class="input-refined"
          placeholder="••••••••"
          minlength="8"
        />
        <p class="helper-text">Must be at least 8 characters with uppercase, lowercase, and a number</p>
      </div>

      <div>
        <label class="form-label">Role</label>
        <select v-model="formData.role" class="input-refined" required>
          <option value="" disabled>Select a role</option>
          <option v-for="role in availableRoles" :key="role.value" :value="role.value">
            {{ role.label }}
          </option>
        </select>
        <p class="helper-text">You can only assign roles equal to or lower than your own</p>
      </div>

      <div>
        <label class="form-label">Phone (optional)</label>
        <input
          v-model="formData.phone"
          type="tel"
          class="input-refined"
          :placeholder="employee?.phone || '+1234567890'"
        />
      </div>

      <div v-if="errorMessage" class="alert-error">
        {{ errorMessage }}
      </div>

      <div class="flex justify-end gap-3 pt-4">
        <button type="button" @click="handleClose" class="btn-brand-secondary">
          Cancel
        </button>
        <button type="submit" :disabled="isSubmitting" class="btn-brand-primary">
          {{ isSubmitting ? 'Inviting...' : 'Send invitation' }}
        </button>
      </div>
    </form>
  </Modal>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useAuthStore } from '@/stores/auth'
import Modal from '@/components/Modal.vue'
import { usersService, type CreateUserData } from '@/services/users'
import type { Employee } from '@/services/employees'

interface Props {
  modelValue: boolean
  employee?: Employee | null
}

interface Emits {
  (e: 'update:modelValue', value: boolean): void
  (e: 'invited'): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()
const authStore = useAuthStore()

const isOpen = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
})

const isSubmitting = ref(false)
const errorMessage = ref('')

const formData = ref<CreateUserData>({
  email: '',
  password: '',
  first_name: '',
  last_name: '',
  role: 'employee',
  phone: '',
})

// Define role hierarchy
const roleHierarchy = {
  super_admin: 5,
  admin: 4,
  manager: 3,
  employee: 2,
  viewer: 1
}

// Compute available roles based on current user's role
const availableRoles = computed(() => {
  const currentUserRole = authStore.userRole
  if (!currentUserRole) return []

  const currentRoleLevel = roleHierarchy[currentUserRole as keyof typeof roleHierarchy] || 0

  return [
    { value: 'viewer', label: 'Viewer', level: 1 },
    { value: 'employee', label: 'Employee', level: 2 },
    { value: 'manager', label: 'Manager', level: 3 },
    { value: 'admin', label: 'Admin', level: 4 },
  ].filter(role => role.level <= currentRoleLevel)
})

// Pre-fill form when employee data is provided
watch(() => props.employee, (employee) => {
  if (employee) {
    formData.value.first_name = employee.first_name || ''
    formData.value.last_name = employee.last_name || ''
    formData.value.email = employee.email || ''
    formData.value.phone = employee.phone || ''
    // Reset password when reopening
    formData.value.password = ''
    formData.value.role = 'employee'
  }
}, { immediate: true })

const handleSubmit = async () => {
  isSubmitting.value = true
  errorMessage.value = ''

  try {
    await usersService.create(formData.value)
    emit('invited')
    handleClose()
  } catch (error: any) {
    console.error('Failed to invite employee:', error)
    errorMessage.value = error.response?.data?.error?.message || 'Failed to invite employee. Please try again.'
  } finally {
    isSubmitting.value = false
  }
}

const handleClose = () => {
  isOpen.value = false
  // Reset form
  formData.value = {
    email: '',
    password: '',
    first_name: '',
    last_name: '',
    role: 'employee',
    phone: '',
  }
  errorMessage.value = ''
}
</script>
