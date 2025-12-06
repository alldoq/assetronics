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
              <h1 class="text-3xl font-bold text-primary-dark">Departments</h1>
            </div>
            <p class="text-slate-600 mt-1">Manage departments within your organization</p>
          </div>
          <div class="flex items-center gap-3">
            <!-- View toggle -->
            <div class="flex items-center gap-1 bg-light-bg rounded-lg p-1 border border-slate-200">
              <button
                @click="viewMode = 'list'"
                :class="[
                  'px-3 py-1.5 rounded text-sm font-medium transition-all',
                  viewMode === 'list'
                    ? 'bg-white text-primary-dark shadow-sm'
                    : 'text-slate-600 hover:text-primary-dark'
                ]"
              >
                <svg class="w-4 h-4 inline-block mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 10h16M4 14h16M4 18h16" />
                </svg>
                List
              </button>
              <button
                @click="viewMode = 'tree'"
                :class="[
                  'px-3 py-1.5 rounded text-sm font-medium transition-all',
                  viewMode === 'tree'
                    ? 'bg-white text-primary-dark shadow-sm'
                    : 'text-slate-600 hover:text-primary-dark'
                ]"
              >
                <svg class="w-4 h-4 inline-block mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
                </svg>
                Tree
              </button>
            </div>
            <button @click="openAddDialog" class="btn-brand-primary">
              <svg class="w-5 h-5 mr-2 inline-block" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
              </svg>
              Add department
            </button>
          </div>
        </div>
      </div>

      <!-- Success message -->
      <div v-if="successMessage" class="mb-6 p-4 rounded-xl bg-teal-50 border border-teal-200 text-teal-800">
        {{ successMessage }}
      </div>

      <!-- Departments list -->
      <div class="bg-white border border-slate-200 rounded-lg overflow-hidden shadow-subtle">
        <div v-if="isLoading" class="p-8 text-center">
          <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-accent-blue mx-auto mb-4"></div>
          <p class="text-slate-700">Loading departments...</p>
        </div>

        <div v-else-if="departments.length === 0" class="p-8 text-center">
          <svg class="w-16 h-16 mx-auto mb-4 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
          </svg>
          <p class="text-slate-700 mb-4">No departments found</p>
          <button @click="openAddDialog" class="btn-brand-primary">
            Add your first department
          </button>
        </div>

        <!-- Tree View -->
        <div v-else-if="viewMode === 'tree'" class="p-4">
          <DepartmentTreeNode
            v-for="dept in departmentTree"
            :key="dept.id"
            :department="dept"
            :level="0"
            @edit="openEditDialog"
            @delete="handleDelete"
          />
        </div>

        <template v-else>
          <!-- Mobile card view -->
          <div class="lg:hidden space-y-4 p-4">
            <div v-for="department in departments" :key="department.id" class="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
              <div class="flex items-start justify-between mb-3">
                <div class="flex-1">
                  <h3 class="text-base font-bold text-primary-dark">{{ department.name }}</h3>
                  <p v-if="department.description" class="text-sm text-slate-600 mt-1">{{ department.description }}</p>
                  <p v-else class="text-sm text-slate-400 mt-1">No description</p>
                </div>
                <div class="relative inline-block text-left">
                  <button
                    @click="toggleDropdown(department.id)"
                    class="text-slate-500 hover:text-primary-dark p-1 transition-colors"
                    type="button"
                  >
                    <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                      <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM18 10a2 2 0 11-4 0 2 2 0 014 0z" />
                    </svg>
                  </button>
                  <div
                    v-if="openDropdownId === department.id"
                    @click.stop
                    class="absolute right-0 w-48 rounded-xl shadow-subtle bg-white border border-slate-200 z-10 origin-top-right top-full mt-2"
                  >
                    <div class="py-1">
                      <button
                        @click="openEditDialog(department)"
                        class="w-full text-left px-4 py-2 text-sm text-primary-dark hover:bg-light-bg flex items-center gap-2 transition-colors"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                        </svg>
                        Edit
                      </button>
                      <button
                        @click="handleDelete(department)"
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
                Created {{ formatDate(department.created_at) }}
              </div>
            </div>
          </div>

          <!-- Desktop table view -->
          <div class="hidden lg:block overflow-x-auto">
            <table class="w-full">
              <thead class="bg-light-bg border-b border-slate-200">
                <tr>
                  <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                    Name
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
                <tr v-for="department in departments" :key="department.id" class="hover:bg-light-bg transition-colors">
                  <td class="px-4 py-3 whitespace-nowrap">
                    <div class="text-sm font-medium text-primary-dark">{{ department.name }}</div>
                  </td>
                  <td class="px-4 py-3">
                    <div class="text-sm text-slate-700">{{ department.description || '-' }}</div>
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap text-sm text-slate-700">
                    {{ formatDate(department.created_at) }}
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap text-sm">
                    <div class="relative inline-block text-left">
                      <button
                        @click="toggleDropdown(department.id)"
                        class="text-slate-500 hover:text-primary-dark p-1 transition-colors"
                        type="button"
                      >
                        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                          <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM18 10a2 2 0 11-4 0 2 2 0 014 0z" />
                        </svg>
                      </button>
                      <div
                        v-if="openDropdownId === department.id"
                        @click.stop
                        class="absolute right-0 w-48 rounded-xl shadow-subtle bg-white border border-slate-200 z-10"
                        :class="shouldOpenUpward(department.id) ? 'origin-bottom-right bottom-full mb-2' : 'origin-top-right top-full mt-2'"
                      >
                        <div class="py-1">
                          <button
                            @click="openEditDialog(department)"
                            class="w-full text-left px-4 py-2 text-sm text-primary-dark hover:bg-light-bg flex items-center gap-2 transition-colors"
                          >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                            </svg>
                            Edit
                          </button>
                          <button
                            @click="handleDelete(department)"
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
        <div class="bg-white rounded-3xl border border-slate-200 shadow-subtle max-w-md w-full p-6">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-bold text-primary-dark">
              {{ isEditing ? 'Edit department' : 'Add new department' }}
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
                <label for="department-name" class="block text-sm font-medium text-slate-700 mb-2">
                  Department name <span class="text-red-500">*</span>
                </label>
                <input
                  id="department-name"
                  v-model="form.name"
                  type="text"
                  required
                  class="input-refined"
                  placeholder="e.g., Engineering"
                  @focus="clearError('name')"
                />
                <p v-if="errors.name" class="mt-2 text-sm text-red-600">{{ errors.name }}</p>
              </div>

              <!-- Type -->
              <div>
                <label for="department-type" class="block text-sm font-medium text-slate-700 mb-2">
                  Type
                </label>
                <select
                  id="department-type"
                  v-model="form.type"
                  class="input-refined"
                >
                  <option value="">Select a type...</option>
                  <option value="division">Division</option>
                  <option value="department">Department</option>
                  <option value="team">Team</option>
                  <option value="unit">Unit</option>
                  <option value="group">Group</option>
                  <option value="other">Other</option>
                </select>
              </div>

              <!-- Parent Department -->
              <div>
                <label for="department-parent" class="block text-sm font-medium text-slate-700 mb-2">
                  Parent Department
                </label>
                <select
                  id="department-parent"
                  v-model="form.parent_id"
                  class="input-refined"
                >
                  <option :value="null">None (root department)</option>
                  <option
                    v-for="dept in availableParents"
                    :key="dept.id"
                    :value="dept.id"
                  >
                    {{ dept.name }}
                  </option>
                </select>
                <p class="mt-1 text-xs text-slate-500">
                  Select a parent to create a sub-department
                </p>
              </div>

              <!-- Description -->
              <div>
                <label for="department-description" class="block text-sm font-medium text-slate-700 mb-2">
                  Description
                </label>
                <textarea
                  id="department-description"
                  v-model="form.description"
                  rows="3"
                  class="input-refined resize-none"
                  placeholder="Optional description..."
                ></textarea>
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
import { ref, reactive, computed, onMounted, onBeforeUnmount } from 'vue'
import { useRouter } from 'vue-router'
import MainLayout from '@/components/MainLayout.vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import DepartmentTreeNode from '@/components/settings/DepartmentTreeNode.vue'
import { departmentsService, type Department, type DepartmentType } from '@/services/departments'

const router = useRouter()

const departments = ref<Department[]>([])
const isLoading = ref(false)
const successMessage = ref('')
const showDialog = ref(false)
const isEditing = ref(false)
const isSubmitting = ref(false)
const editingId = ref<number | null>(null)
const openDropdownId = ref<number | null>(null)
const confirmDialog = ref<InstanceType<typeof ConfirmDialog>>()
const departmentToDelete = ref<Department | null>(null)
const viewMode = ref<'list' | 'tree'>('list')

const form = reactive({
  name: '',
  type: '' as DepartmentType | '',
  description: '',
  parent_id: null as number | null,
})

const errors = reactive<Record<string, string>>({})

// Build tree from flat array
const departmentTree = computed(() => {
  const buildTree = (parentId: number | null = null): Department[] => {
    return departments.value
      .filter(dept => dept.parent_id === parentId)
      .map(dept => ({
        ...dept,
        children: buildTree(dept.id)
      }))
      .sort((a, b) => a.name.localeCompare(b.name))
  }
  return buildTree(null)
})

// Get descendants of a department (for preventing circular references)
const getDescendants = (deptId: number): number[] => {
  const descendants: number[] = []
  const findDescendants = (id: number) => {
    departments.value
      .filter(d => d.parent_id === id)
      .forEach(child => {
        descendants.push(child.id)
        findDescendants(child.id)
      })
  }
  findDescendants(deptId)
  return descendants
}

// Available parents (excluding self and descendants when editing)
const availableParents = computed(() => {
  if (!isEditing.value || !editingId.value) {
    return departments.value
  }

  const excludeIds = [editingId.value, ...getDescendants(editingId.value)]
  return departments.value.filter(d => !excludeIds.includes(d.id))
})

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

const shouldOpenUpward = (departmentId: number) => {
  const index = departments.value.findIndex((d) => d.id === departmentId)
  const totalDepartments = departments.value.length
  return totalDepartments - index <= 2
}

const loadDepartments = async () => {
  isLoading.value = true
  try {
    departments.value = await departmentsService.getAll()
  } catch (error) {
    console.error('Failed to load departments:', error)
  } finally {
    isLoading.value = false
  }
}

const openAddDialog = () => {
  isEditing.value = false
  editingId.value = null
  form.name = ''
  form.type = ''
  form.description = ''
  form.parent_id = null
  Object.keys(errors).forEach((key) => delete errors[key])
  showDialog.value = true
}

const openEditDialog = (department: Department) => {
  closeDropdown()
  isEditing.value = true
  editingId.value = department.id
  form.name = department.name
  form.type = department.type || ''
  form.description = department.description || ''
  form.parent_id = department.parent_id || null
  Object.keys(errors).forEach((key) => delete errors[key])
  showDialog.value = true
}

const closeDialog = () => {
  showDialog.value = false
  form.name = ''
  form.type = ''
  form.description = ''
  form.parent_id = null
  Object.keys(errors).forEach((key) => delete errors[key])
}

const handleSubmit = async () => {
  Object.keys(errors).forEach((key) => delete errors[key])

  if (!form.name.trim()) {
    errors.name = 'Department name is required'
    return
  }

  isSubmitting.value = true

  try {
    const data = {
      name: form.name,
      type: form.type || undefined,
      description: form.description || undefined,
      parent_id: form.parent_id || undefined,
    }

    if (isEditing.value && editingId.value) {
      await departmentsService.update(editingId.value, data)
      successMessage.value = `Department "${form.name}" has been updated successfully.`
    } else {
      await departmentsService.create(data)
      successMessage.value = `Department "${form.name}" has been added successfully.`
    }

    closeDialog()
    await loadDepartments()

    setTimeout(() => {
      successMessage.value = ''
    }, 5000)
  } catch (error: any) {
    console.error('Error submitting form:', error)
    if (error.response?.data?.errors) {
      Object.assign(errors, error.response.data.errors)
    } else {
      alert(`Failed to ${isEditing.value ? 'update' : 'create'} department. Please try again.`)
    }
  } finally {
    isSubmitting.value = false
  }
}

const handleDelete = (department: Department) => {
  closeDropdown()
  departmentToDelete.value = department
  confirmDialogData.title = 'Delete department'
  confirmDialogData.message = `Are you sure you want to delete "${department.name}"? This action cannot be undone.`
  confirmDialog.value?.open()
}

const confirmDelete = async () => {
  if (!departmentToDelete.value) return

  try {
    await departmentsService.delete(departmentToDelete.value.id)
    successMessage.value = `Department "${departmentToDelete.value.name}" has been deleted successfully.`
    await loadDepartments()

    setTimeout(() => {
      successMessage.value = ''
    }, 5000)

    confirmDialog.value?.close()
    departmentToDelete.value = null
  } catch (error) {
    console.error('Failed to delete department:', error)
    confirmDialog.value?.close()
    alert('Failed to delete department. Please try again.')
  }
}

const cancelDelete = () => {
  departmentToDelete.value = null
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
  loadDepartments()
  document.addEventListener('click', handleClickOutside)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>
