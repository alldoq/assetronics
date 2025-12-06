<template>
  <MainLayout>
    <div>
      <!-- Page header -->
      <div class="mb-6">
        <div class="flex items-center justify-between flex-wrap gap-4">
          <div>
            <div class="flex items-center gap-3 mb-2">
              <router-link to="/settings" class="text-slate-500 hover:text-primary-dark transition-colors">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
                </svg>
              </router-link>
              <h1 class="text-3xl font-bold text-primary-dark">Asset statuses</h1>
            </div>
            <p class="text-slate-500 mt-1">Manage status options for your assets</p>
          </div>
          <button @click="openAddDialog" class="btn-brand-primary">
            <svg class="w-5 h-5 mr-2 inline-block" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Add status
          </button>
        </div>
      </div>

      <!-- Success message -->
      <div v-if="successMessage" class="mb-6 p-4 rounded-2xl bg-teal-50 border border-teal-200 text-teal-800">
        {{ successMessage }}
      </div>

      <!-- Statuses list -->
      <div class="bg-white border border-slate-200 rounded-lg overflow-hidden shadow-subtle">
        <div v-if="isLoading" class="p-8 text-center">
          <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-accent-blue mx-auto mb-4"></div>
          <p class="text-slate-700">Loading statuses...</p>
        </div>

        <div v-else-if="statuses.length === 0" class="p-8 text-center">
          <svg class="w-16 h-16 mx-auto mb-4 text-slate-200" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <p class="text-slate-700 mb-4">No statuses found</p>
          <button @click="openAddDialog" class="btn-brand-primary">
            Add your first status
          </button>
        </div>

        <template v-else>
          <!-- Mobile card view -->
          <div class="lg:hidden space-y-4 p-4">
            <div v-for="status in statuses" :key="status.id" class="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
              <div class="flex items-start justify-between mb-3">
                <div class="flex-1">
                  <span class="inline-flex px-3 py-1 text-sm font-medium rounded mb-2" :style="getStatusStyle(status)">
                    {{ status.name }}
                  </span>
                  <div class="mt-2">
                    <code class="text-xs text-slate-700 bg-light-bg px-2 py-1 rounded font-mono">{{ status.value }}</code>
                  </div>
                  <p v-if="status.description" class="text-sm text-slate-600 mt-2">{{ status.description }}</p>
                  <p v-else class="text-sm text-slate-400 mt-2">No description</p>
                </div>
                <div class="relative inline-block text-left">
                  <button
                    @click="toggleDropdown(status.id)"
                    class="text-slate-500 hover:text-primary-dark p-1 transition-colors"
                    type="button"
                  >
                    <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                      <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM18 10a2 2 0 11-4 0 2 2 0 014 0z" />
                    </svg>
                  </button>
                  <div
                    v-if="openDropdownId === status.id"
                    @click.stop
                    class="absolute right-0 w-48 rounded-2xl shadow-subtle bg-white border border-slate-200 z-10 origin-top-right top-full mt-2"
                  >
                    <div class="py-1">
                      <button
                        @click="openEditDialog(status)"
                        class="w-full text-left px-4 py-2 text-sm text-primary-dark hover:bg-light-bg flex items-center gap-2 transition-colors"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                        </svg>
                        Edit
                      </button>
                      <button
                        @click="handleDelete(status)"
                        class="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50 flex items-center gap-2 transition-colors"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                        Delete
                      </button>
                    </div>
                  </div>
                </div>
              </div>
              <div class="flex items-center text-xs text-slate-500 mt-2">
                <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                Created {{ formatDate(status.created_at) }}
              </div>
            </div>
          </div>

          <!-- Desktop table view -->
          <div class="hidden lg:block overflow-x-auto">
          <table class="w-full">
            <thead class="bg-light-bg border-b border-slate-200">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Status
                </th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Value
                </th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Description
                </th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Created
                </th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-slate-200">
              <tr v-for="status in statuses" :key="status.id" class="hover:bg-light-bg transition-colors">
                <td class="px-4 py-3 whitespace-nowrap">
                  <span class="inline-flex px-3 py-1 text-sm font-medium rounded" :style="getStatusStyle(status)">
                    {{ status.name }}
                  </span>
                </td>
                <td class="px-4 py-3 whitespace-nowrap">
                  <code class="text-sm text-slate-700 bg-light-bg px-2 py-1 rounded font-mono">{{ status.value }}</code>
                </td>
                <td class="px-4 py-3">
                  <div class="text-sm text-slate-700">{{ status.description || '-' }}</div>
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-slate-700">
                  {{ formatDate(status.created_at) }}
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm">
                  <div class="relative inline-block text-left">
                    <button
                      @click="toggleDropdown(status.id)"
                      class="text-slate-500 hover:text-primary-dark p-1 transition-colors"
                      type="button"
                    >
                      <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                        <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM18 10a2 2 0 11-4 0 2 2 0 014 0z" />
                      </svg>
                    </button>
                    <div
                      v-if="openDropdownId === status.id"
                      @click.stop
                      class="absolute right-0 w-48 rounded-2xl shadow-subtle bg-white border border-slate-200 z-10"
                      :class="shouldOpenUpward(status.id) ? 'origin-bottom-right bottom-full mb-2' : 'origin-top-right top-full mt-2'"
                    >
                      <div class="py-1">
                        <button
                          @click="openEditDialog(status)"
                          class="w-full text-left px-4 py-2 text-sm text-primary-dark hover:bg-light-bg flex items-center gap-2 transition-colors"
                        >
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                          </svg>
                          Edit
                        </button>
                        <button
                          @click="handleDelete(status)"
                          class="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50 flex items-center gap-2 transition-colors"
                        >
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                          </svg>
                          Delete
                        </button>
                      </div>
                    </div>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
          </div>
        </template>
      </div>

      <!-- Add/Edit Dialog -->
      <div
        v-if="showDialog"
        class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
        @click.self="closeDialog"
      >
        <div class="bg-white rounded-2xl border border-slate-200 shadow-subtle max-w-md w-full p-6">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-bold text-primary-dark">
              {{ isEditing ? 'Edit status' : 'Add new status' }}
            </h3>
            <button @click="closeDialog" class="text-slate-500 hover:text-primary-dark transition-colors">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <form @submit.prevent="handleSubmit">
            <div class="space-y-4">
              <!-- Name -->
              <div>
                <label for="status-name" class="block text-sm font-medium text-slate-700 mb-2">
                  Status name <span class="text-red-500">*</span>
                </label>
                <input
                  id="status-name"
                  v-model="form.name"
                  type="text"
                  required
                  class="input-refined"
                  placeholder="e.g., Available"
                  @focus="clearError('name')"
                />
                <p v-if="errors.name" class="mt-2 text-sm text-red-600">{{ errors.name }}</p>
              </div>

              <!-- Value -->
              <div>
                <label for="status-value" class="block text-sm font-medium text-slate-700 mb-2">
                  Status value <span class="text-red-500">*</span>
                </label>
                <input
                  id="status-value"
                  v-model="form.value"
                  type="text"
                  required
                  class="input-refined"
                  placeholder="e.g., available"
                  @focus="clearError('value')"
                />
                <p class="mt-1 text-xs text-slate-500">
                  Lowercase alphanumeric value used internally (e.g., "available", "in_maintenance")
                </p>
                <p v-if="errors.value" class="mt-2 text-sm text-red-600">{{ errors.value }}</p>
              </div>

              <!-- Color -->
              <div>
                <label for="status-color" class="block text-sm font-medium text-slate-700 mb-2">
                  Badge color <span class="text-red-500">*</span>
                </label>
                <div class="grid grid-cols-3 gap-3">
                  <div
                    v-for="colorOption in colorOptions"
                    :key="colorOption.value"
                    @click="form.color = colorOption.value"
                    class="cursor-pointer rounded-2xl border-2 p-3 transition-all"
                    :class="form.color === colorOption.value ? 'border-accent-blue ring-2 ring-accent-blue/10' : 'border-slate-200 hover:border-primary-dark'"
                  >
                    <div class="flex flex-col items-center gap-2">
                      <div class="w-8 h-8 rounded-full" :class="colorOption.class"></div>
                      <span class="text-xs text-slate-700">{{ colorOption.label }}</span>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Description -->
              <div>
                <label for="status-description" class="block text-sm font-medium text-slate-700 mb-2">
                  Description
                </label>
                <textarea
                  id="status-description"
                  v-model="form.description"
                  rows="3"
                  class="input-refined resize-none"
                  placeholder="Optional description..."
                ></textarea>
              </div>

              <!-- Preview -->
              <div>
                <label class="block text-sm font-medium text-slate-700 mb-2">Preview</label>
                <div class="p-4 bg-light-bg rounded-2xl">
                  <span
                    v-if="form.name"
                    class="inline-flex px-3 py-1 text-sm font-medium rounded"
                    :style="getPreviewStyle()"
                  >
                    {{ form.name }}
                  </span>
                  <span v-else class="text-sm text-slate-500">Enter a name to see preview</span>
                </div>
              </div>
            </div>

            <!-- Actions -->
            <div class="mt-6 flex justify-end gap-3">
              <button type="button" @click="closeDialog" class="btn-brand-secondary">
                Cancel
              </button>
              <button type="submit" :disabled="isSubmitting" class="btn-brand-primary disabled:opacity-50">
                <span v-if="!isSubmitting">{{ isEditing ? 'Update' : 'Add' }}</span>
                <span v-else>{{ isEditing ? 'Updating...' : 'Adding...' }}</span>
              </button>
            </div>
          </form>
        </div>
      </div>

      <!-- Confirm Dialog -->
      <ConfirmDialog
        ref="confirmDialog"
        :title="confirmDialogData.title"
        :message="confirmDialogData.message"
        confirm-text="Delete"
        cancel-text="Cancel"
        @confirm="confirmDelete"
        @cancel="cancelDelete"
      />
    </div>
  </MainLayout>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, onBeforeUnmount } from 'vue'
import { useRouter } from 'vue-router'
import MainLayout from '@/components/MainLayout.vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import { statusesService, type Status } from '@/services/statuses'

const router = useRouter()

const statuses = ref<Status[]>([])
const isLoading = ref(false)
const successMessage = ref('')
const showDialog = ref(false)
const isEditing = ref(false)
const isSubmitting = ref(false)
const editingId = ref<number | null>(null)
const openDropdownId = ref<number | null>(null)
const confirmDialog = ref<InstanceType<typeof ConfirmDialog>>()
const statusToDelete = ref<Status | null>(null)

const colorOptions = [
  { label: 'Primary', value: 'primary', class: 'bg-accent-blue/80' },
  { label: 'Blue', value: 'blue', class: 'bg-blue-600' },
  { label: 'Green', value: 'green', class: 'bg-emerald-600' },
  { label: 'Amber', value: 'amber', class: 'bg-amber-600' },
  { label: 'Red', value: 'red', class: 'bg-red-600' },
  { label: 'Gray', value: 'gray', class: 'bg-slate-600' },
]

const form = reactive({
  name: '',
  value: '',
  description: '',
  color: 'primary',
})

const errors = reactive<Record<string, string>>({})

const confirmDialogData = reactive({
  title: '',
  message: '',
})

const clearError = (field: string) => {
  delete errors[field]
}

const toggleDropdown = (id: number) => {
  openDropdownId.value = openDropdownId.value === id ? null : id
}

const closeDropdown = () => {
  openDropdownId.value = null
}

const handleClickOutside = (event: MouseEvent) => {
  const target = event.target as HTMLElement
  if (!target.closest('.relative')) {
    closeDropdown()
  }
}

const shouldOpenUpward = (statusId: number) => {
  const index = statuses.value.findIndex((s) => s.id === statusId)
  const totalStatuses = statuses.value.length
  // Open upward if in the last 2 rows
  return totalStatuses - index <= 2
}

const getStatusStyle = (status: Status) => {
  const colorMap: Record<string, { bg: string; text: string }> = {
    primary: { bg: '#F0F4FF', text: '#3B5BDB' },
    blue: { bg: '#E0F2FE', text: '#0369A1' },
    green: { bg: '#D1FAE5', text: '#047857' },
    amber: { bg: '#FEF3C7', text: '#D97706' },
    red: { bg: '#FEE2E2', text: '#DC2626' },
    gray: { bg: '#F3F4F6', text: '#4B5563' },
  }

  const colors = colorMap[status.color] || colorMap.primary
  return {
    backgroundColor: colors!.bg,
    color: colors!.text,
  }
}

const getPreviewStyle = () => {
  const colorMap: Record<string, { bg: string; text: string }> = {
    primary: { bg: '#F0F4FF', text: '#3B5BDB' },
    blue: { bg: '#E0F2FE', text: '#0369A1' },
    green: { bg: '#D1FAE5', text: '#047857' },
    amber: { bg: '#FEF3C7', text: '#D97706' },
    red: { bg: '#FEE2E2', text: '#DC2626' },
    gray: { bg: '#F3F4F6', text: '#4B5563' },
  }

  const colors = colorMap[form.color] || colorMap.primary
  return {
    backgroundColor: colors!.bg,
    color: colors!.text,
  }
}

const loadStatuses = async () => {
  isLoading.value = true
  try {
    statuses.value = await statusesService.getAll()
  } catch (error) {
    console.error('Failed to load statuses:', error)
  } finally {
    isLoading.value = false
  }
}

const openAddDialog = () => {
  isEditing.value = false
  editingId.value = null
  form.name = ''
  form.value = ''
  form.description = ''
  form.color = 'primary'
  Object.keys(errors).forEach((key) => delete errors[key])
  showDialog.value = true
}

const openEditDialog = (status: Status) => {
  closeDropdown()
  isEditing.value = true
  editingId.value = status.id
  form.name = status.name
  form.value = status.value
  form.description = status.description || ''
  form.color = status.color
  Object.keys(errors).forEach((key) => delete errors[key])
  showDialog.value = true
}

const closeDialog = () => {
  showDialog.value = false
  form.name = ''
  form.value = ''
  form.description = ''
  form.color = 'primary'
  Object.keys(errors).forEach((key) => delete errors[key])
}

const handleSubmit = async () => {
  // Clear previous errors
  Object.keys(errors).forEach((key) => delete errors[key])

  if (!form.name.trim()) {
    errors.name = 'Status name is required'
    return
  }

  if (!form.value.trim()) {
    errors.value = 'Status value is required'
    return
  }

  isSubmitting.value = true

  try {
    if (isEditing.value && editingId.value) {
      // Update existing status
      await statusesService.update(editingId.value, {
        name: form.name,
        value: form.value,
        description: form.description || undefined,
        color: form.color,
      })
      successMessage.value = `Status "${form.name}" has been updated successfully.`
    } else {
      // Create new status
      await statusesService.create({
        name: form.name,
        value: form.value,
        description: form.description || undefined,
        color: form.color,
      })
      successMessage.value = `Status "${form.name}" has been added successfully.`
    }

    closeDialog()
    await loadStatuses()

    // Clear success message after 5 seconds
    setTimeout(() => {
      successMessage.value = ''
    }, 5000)
  } catch (error: any) {
    console.error('Error submitting form:', error)
    if (error.response?.data?.errors) {
      Object.assign(errors, error.response.data.errors)
    } else {
      alert(`Failed to ${isEditing.value ? 'update' : 'create'} status. Please try again.`)
    }
  } finally {
    isSubmitting.value = false
  }
}

const handleDelete = (status: Status) => {
  closeDropdown()
  statusToDelete.value = status
  confirmDialogData.title = 'Delete status'
  confirmDialogData.message = `Are you sure you want to delete "${status.name}"? This action cannot be undone.`
  confirmDialog.value?.open()
}

const confirmDelete = async () => {
  if (!statusToDelete.value) return

  try {
    await statusesService.delete(statusToDelete.value.id)
    successMessage.value = `Status "${statusToDelete.value.name}" has been deleted successfully.`
    await loadStatuses()

    setTimeout(() => {
      successMessage.value = ''
    }, 5000)

    confirmDialog.value?.close()
    statusToDelete.value = null
  } catch (error) {
    console.error('Failed to delete status:', error)
    confirmDialog.value?.close()
    alert('Failed to delete status. Please try again.')
  }
}

const cancelDelete = () => {
  statusToDelete.value = null
}

const formatDate = (dateString: string): string => {
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  })
}

onMounted(() => {
  loadStatuses()
  document.addEventListener('click', handleClickOutside)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>
