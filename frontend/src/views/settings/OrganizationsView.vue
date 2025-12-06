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
              <h1 class="text-3xl font-bold text-primary-dark">Organizations</h1>
            </div>
            <p class="text-slate-600 mt-1">Manage your organizational hierarchy</p>
          </div>
          <button @click="openAddDialog" class="btn-brand-primary">
            <svg class="w-5 h-5 mr-2 inline-block" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Add organization
          </button>
        </div>
      </div>

      <!-- View Toggle -->
      <div class="mb-4 flex items-center gap-2">
        <button
          @click="viewMode = 'list'"
          :class="[
            'px-4 py-2 text-sm font-medium rounded-lg transition-all',
            viewMode === 'list'
              ? 'bg-accent-blue text-white'
              : 'bg-white text-slate-700 border border-slate-200 hover:border-accent-blue'
          ]"
        >
          <svg class="w-4 h-4 inline-block mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
          </svg>
          List View
        </button>
        <button
          @click="viewMode = 'tree'"
          :class="[
            'px-4 py-2 text-sm font-medium rounded-lg transition-all',
            viewMode === 'tree'
              ? 'bg-accent-blue text-white'
              : 'bg-white text-slate-700 border border-slate-200 hover:border-accent-blue'
          ]"
        >
          <svg class="w-4 h-4 inline-block mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
          </svg>
          Tree View
        </button>
      </div>

      <!-- Success message -->
      <div v-if="successMessage" class="mb-6 p-4 rounded-xl bg-teal-50 border border-teal-200 text-teal-800">
        {{ successMessage }}
      </div>

      <!-- Organizations list -->
      <div class="bg-white border border-slate-200 rounded-lg overflow-hidden shadow-subtle">
        <div v-if="isLoading" class="p-8 text-center">
          <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-accent-blue mx-auto mb-4"></div>
          <p class="text-slate-700">Loading organizations...</p>
        </div>

        <div v-else-if="organizations.length === 0" class="p-8 text-center">
          <svg class="w-16 h-16 mx-auto mb-4 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
          </svg>
          <p class="text-slate-700 mb-4">No organizations found</p>
          <button @click="openAddDialog" class="btn-brand-primary">
            Add your first organization
          </button>
        </div>

        <!-- List View -->
        <template v-else-if="viewMode === 'list'">
          <!-- Mobile card view -->
          <div class="lg:hidden space-y-4 p-4">
            <div v-for="organization in organizations" :key="organization.id" class="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
              <div class="flex items-start justify-between mb-3">
                <div class="flex-1">
                  <div class="flex items-center gap-2 mb-1">
                    <h3 class="text-base font-bold text-primary-dark">{{ organization.name }}</h3>
                    <span v-if="organization.type" class="px-2 py-0.5 text-xs font-medium rounded bg-purple-100 text-purple-700">
                      {{ formatType(organization.type) }}
                    </span>
                  </div>
                  <p v-if="organization.parent" class="text-xs text-slate-500 mb-2">
                    Parent: {{ organization.parent.name }}
                  </p>
                  <p v-if="organization.description" class="text-sm text-slate-600 mt-1">{{ organization.description }}</p>
                  <p v-else class="text-sm text-slate-400 mt-1">No description</p>
                </div>
                <div class="relative inline-block text-left">
                  <button
                    @click="toggleDropdown(organization.id)"
                    class="text-slate-500 hover:text-primary-dark p-1 transition-colors"
                    type="button"
                  >
                    <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                      <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM18 10a2 2 0 11-4 0 2 2 0 014 0z" />
                    </svg>
                  </button>
                  <div
                    v-if="openDropdownId === organization.id"
                    @click.stop
                    class="absolute right-0 w-48 rounded-xl shadow-subtle bg-white border border-slate-200 z-10 origin-top-right top-full mt-2"
                  >
                    <div class="py-1">
                      <button
                        @click="openEditDialog(organization)"
                        class="w-full text-left px-4 py-2 text-sm text-primary-dark hover:bg-light-bg flex items-center gap-2 transition-colors"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                        </svg>
                        Edit
                      </button>
                      <button
                        @click="handleDelete(organization)"
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
                Created {{ formatDate(organization.created_at) }}
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
                    Type
                  </th>
                  <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                    Parent
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
                <tr v-for="organization in organizations" :key="organization.id" class="hover:bg-light-bg transition-colors">
                  <td class="px-4 py-3 whitespace-nowrap">
                    <div class="text-sm font-medium text-primary-dark">{{ organization.name }}</div>
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap">
                    <span v-if="organization.type" class="px-2 py-1 text-xs font-medium rounded bg-purple-100 text-purple-700">
                      {{ formatType(organization.type) }}
                    </span>
                    <span v-else class="text-xs text-slate-400">-</span>
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap">
                    <div v-if="organization.parent" class="text-sm text-slate-700">{{ organization.parent.name }}</div>
                    <span v-else class="text-sm text-slate-400">-</span>
                  </td>
                  <td class="px-4 py-3">
                    <div class="text-sm text-slate-700">{{ organization.description || '-' }}</div>
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap text-sm text-slate-700">
                    {{ formatDate(organization.created_at) }}
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap text-sm">
                    <div class="relative inline-block text-left">
                      <button
                        @click="toggleDropdown(organization.id)"
                        class="text-slate-500 hover:text-primary-dark p-1 transition-colors"
                        type="button"
                      >
                        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                          <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM18 10a2 2 0 11-4 0 2 2 0 014 0z" />
                        </svg>
                      </button>
                      <div
                        v-if="openDropdownId === organization.id"
                        @click.stop
                        class="absolute right-0 w-48 rounded-xl shadow-subtle bg-white border border-slate-200 z-10"
                        :class="shouldOpenUpward(organization.id) ? 'origin-bottom-right bottom-full mb-2' : 'origin-top-right top-full mt-2'"
                      >
                        <div class="py-1">
                          <button
                            @click="openEditDialog(organization)"
                            class="w-full text-left px-4 py-2 text-sm text-primary-dark hover:bg-light-bg flex items-center gap-2 transition-colors"
                          >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                            </svg>
                            Edit
                          </button>
                          <button
                            @click="handleDelete(organization)"
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

        <!-- Tree View -->
        <div v-else-if="viewMode === 'tree'" class="p-4">
          <div v-if="organizationTree.length === 0" class="text-center py-8 text-slate-500">
            No organizations to display
          </div>
          <div v-else class="space-y-2">
            <OrganizationTreeNode
              v-for="org in organizationTree"
              :key="org.id"
              :organization="org"
              :level="0"
              @edit="openEditDialog"
              @delete="handleDelete"
              @add-child="handleAddChild"
            />
          </div>
        </div>
      </div>

      <!-- Add/Edit Dialog -->
      <div
        v-if="showDialog"
        class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
        @click.self="closeDialog"
      >
        <div class="bg-white rounded-3xl border border-slate-200 shadow-subtle max-w-md w-full p-6 max-h-[90vh] overflow-y-auto">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-bold text-primary-dark">
              {{ isEditing ? 'Edit organization' : 'Add new organization' }}
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
                <label for="organization-name" class="block text-sm font-medium text-slate-700 mb-2">
                  Organization name <span class="text-red-500">*</span>
                </label>
                <input
                  id="organization-name"
                  v-model="form.name"
                  type="text"
                  required
                  class="input-refined"
                  placeholder="e.g., Acme Corporation"
                  @focus="clearError('name')"
                />
                <p v-if="errors.name" class="mt-2 text-sm text-red-600">{{ errors.name }}</p>
              </div>

              <!-- Type -->
              <div>
                <label for="organization-type" class="block text-sm font-medium text-slate-700 mb-2">
                  Organization type
                </label>
                <select
                  id="organization-type"
                  v-model="form.type"
                  class="input-refined"
                >
                  <option value="">Select type (optional)</option>
                  <option value="holding_company">Holding Company</option>
                  <option value="parent_company">Parent Company</option>
                  <option value="subsidiary">Subsidiary</option>
                  <option value="division">Division</option>
                  <option value="business_unit">Business Unit</option>
                  <option value="branch">Branch</option>
                  <option value="other">Other</option>
                </select>
              </div>

              <!-- Parent Organization -->
              <div>
                <label for="organization-parent" class="block text-sm font-medium text-slate-700 mb-2">
                  Parent organization
                </label>
                <select
                  id="organization-parent"
                  v-model="form.parent_id"
                  class="input-refined"
                >
                  <option :value="null">None (Top-level)</option>
                  <option
                    v-for="org in availableParents"
                    :key="org.id"
                    :value="org.id"
                  >
                    {{ org.name }}{{ org.type ? ` (${formatType(org.type)})` : '' }}
                  </option>
                </select>
                <p class="mt-1 text-xs text-slate-500">Select a parent to create a hierarchical structure</p>
              </div>

              <!-- Description -->
              <div>
                <label for="organization-description" class="block text-sm font-medium text-slate-700 mb-2">
                  Description
                </label>
                <textarea
                  id="organization-description"
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
import OrganizationTreeNode from '@/components/settings/OrganizationTreeNode.vue'
import { organizationsService, type Organization, type OrganizationType } from '@/services/organizations'

const router = useRouter()

const organizations = ref<Organization[]>([])
const isLoading = ref(false)
const successMessage = ref('')
const showDialog = ref(false)
const isEditing = ref(false)
const isSubmitting = ref(false)
const editingId = ref<number | null>(null)
const openDropdownId = ref<number | null>(null)
const confirmDialog = ref<InstanceType<typeof ConfirmDialog>>()
const organizationToDelete = ref<Organization | null>(null)
const viewMode = ref<'list' | 'tree'>('list')

const form = reactive({
  name: '',
  type: '' as OrganizationType | '',
  parent_id: null as number | null,
  description: '',
})

const errors = reactive<Record<string, string>>({})

const confirmDialogData = reactive({
  title: '',
  message: '',
})

// Build tree structure from flat array
const organizationTree = computed(() => {
  const buildTree = (parentId: number | null = null): Organization[] => {
    return organizations.value
      .filter(org => org.parent_id === parentId)
      .map(org => ({
        ...org,
        children: buildTree(org.id)
      }))
      .sort((a, b) => a.name.localeCompare(b.name))
  }
  return buildTree(null)
})

// Available parents (excluding self and descendants when editing)
const availableParents = computed(() => {
  if (!isEditing.value) return organizations.value

  // When editing, exclude the current organization and its descendants
  const excludeIds = new Set<number>([editingId.value!])

  const addDescendants = (orgId: number) => {
    const children = organizations.value.filter(o => o.parent_id === orgId)
    children.forEach(child => {
      excludeIds.add(child.id)
      addDescendants(child.id)
    })
  }

  addDescendants(editingId.value!)

  return organizations.value.filter(org => !excludeIds.has(org.id))
})

const formatType = (type: OrganizationType): string => {
  const typeMap: Record<OrganizationType, string> = {
    holding_company: 'Holding Company',
    parent_company: 'Parent Company',
    subsidiary: 'Subsidiary',
    division: 'Division',
    business_unit: 'Business Unit',
    branch: 'Branch',
    other: 'Other'
  }
  return typeMap[type] || type
}

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

const shouldOpenUpward = (organizationId: number) => {
  const index = organizations.value.findIndex((o) => o.id === organizationId)
  const totalOrganizations = organizations.value.length
  return totalOrganizations - index <= 2
}

const loadOrganizations = async () => {
  isLoading.value = true
  try {
    organizations.value = await organizationsService.getAll()
  } catch (error) {
    console.error('Failed to load organizations:', error)
  } finally {
    isLoading.value = false
  }
}

const openAddDialog = () => {
  isEditing.value = false
  editingId.value = null
  form.name = ''
  form.type = ''
  form.parent_id = null
  form.description = ''
  Object.keys(errors).forEach((key) => delete errors[key])
  showDialog.value = true
}

const handleAddChild = async (data: { parent_id: string; name: string; type: string }) => {
  try {
    await organizationsService.create({
      name: data.name,
      type: data.type as OrganizationType,
      parent_id: Number(data.parent_id)
    })
    successMessage.value = `Organization "${data.name}" added successfully`
    setTimeout(() => {
      successMessage.value = ''
    }, 3000)
    await loadOrganizations()
  } catch (error: any) {
    console.error('Failed to add child organization:', error)
    alert('Failed to add organization: ' + (error.response?.data?.error || 'Unknown error'))
  }
}

const openEditDialog = (organization: Organization) => {
  closeDropdown()
  isEditing.value = true
  editingId.value = organization.id
  form.name = organization.name
  form.type = organization.type || ''
  form.parent_id = organization.parent_id || null
  form.description = organization.description || ''
  Object.keys(errors).forEach((key) => delete errors[key])
  showDialog.value = true
}

const closeDialog = () => {
  showDialog.value = false
  form.name = ''
  form.type = ''
  form.parent_id = null
  form.description = ''
  Object.keys(errors).forEach((key) => delete errors[key])
}

const handleSubmit = async () => {
  Object.keys(errors).forEach((key) => delete errors[key])

  if (!form.name.trim()) {
    errors.name = 'Organization name is required'
    return
  }

  isSubmitting.value = true

  try {
    const data = {
      name: form.name,
      type: form.type || undefined,
      parent_id: form.parent_id || undefined,
      description: form.description || undefined,
    }

    if (isEditing.value && editingId.value) {
      await organizationsService.update(editingId.value, data)
      successMessage.value = `Organization "${form.name}" has been updated successfully.`
    } else {
      await organizationsService.create(data)
      successMessage.value = `Organization "${form.name}" has been added successfully.`
    }

    closeDialog()
    await loadOrganizations()

    setTimeout(() => {
      successMessage.value = ''
    }, 5000)
  } catch (error: any) {
    console.error('Error submitting form:', error)
    if (error.response?.data?.errors) {
      Object.assign(errors, error.response.data.errors)
    } else {
      alert(`Failed to ${isEditing.value ? 'update' : 'create'} organization. Please try again.`)
    }
  } finally {
    isSubmitting.value = false
  }
}

const handleDelete = (organization: Organization) => {
  closeDropdown()
  organizationToDelete.value = organization
  confirmDialogData.title = 'Delete organization'
  confirmDialogData.message = `Are you sure you want to delete "${organization.name}"? This action cannot be undone.`
  confirmDialog.value?.open()
}

const confirmDelete = async () => {
  if (!organizationToDelete.value) return

  try {
    await organizationsService.delete(organizationToDelete.value.id)
    successMessage.value = `Organization "${organizationToDelete.value.name}" has been deleted successfully.`
    await loadOrganizations()

    setTimeout(() => {
      successMessage.value = ''
    }, 5000)

    confirmDialog.value?.close()
    organizationToDelete.value = null
  } catch (error) {
    console.error('Failed to delete organization:', error)
    confirmDialog.value?.close()
    alert('Failed to delete organization. Please try again.')
  }
}

const cancelDelete = () => {
  organizationToDelete.value = null
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
  loadOrganizations()
  document.addEventListener('click', handleClickOutside)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>
