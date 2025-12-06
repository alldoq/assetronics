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
              <h1 class="text-3xl font-bold text-primary-dark">Asset categories</h1>
            </div>
            <p class="text-slate-600 mt-1">Manage categories for organizing your assets</p>
          </div>
          <button @click="openAddDialog" class="btn-brand-primary">
            <svg class="w-5 h-5 mr-2 inline-block" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Add category
          </button>
        </div>
      </div>

      <!-- Success message -->
      <div v-if="successMessage" class="mb-6 p-4 rounded-xl bg-teal-50 border border-teal-200 text-teal-800">
        {{ successMessage }}
      </div>

      <!-- Categories list -->
      <div class="bg-white border border-slate-200 rounded-lg overflow-hidden shadow-subtle">
        <div v-if="isLoading" class="p-8 text-center">
          <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-accent-blue mx-auto mb-4"></div>
          <p class="text-slate-700">Loading categories...</p>
        </div>

        <div v-else-if="categories.length === 0" class="p-8 text-center">
          <svg class="w-16 h-16 mx-auto mb-4 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
          </svg>
          <p class="text-slate-700 mb-4">No categories found</p>
          <button @click="openAddDialog" class="btn-brand-primary">
            Add your first category
          </button>
        </div>

        <template v-else>
          <!-- Mobile card view -->
          <div class="lg:hidden space-y-4 p-4">
            <div v-for="category in categories" :key="category.id" class="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
              <div class="flex items-start justify-between mb-3">
                <div class="flex-1">
                  <h3 class="text-base font-bold text-primary-dark">{{ category.name }}</h3>
                  <p v-if="category.description" class="text-sm text-slate-600 mt-1">{{ category.description }}</p>
                  <p v-else class="text-sm text-slate-400 mt-1">No description</p>
                </div>
                <div class="relative inline-block text-left">
                  <button
                    @click="toggleDropdown(category.id)"
                    class="text-slate-500 hover:text-primary-dark p-1 transition-colors"
                    type="button"
                  >
                    <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                      <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM18 10a2 2 0 11-4 0 2 2 0 014 0z" />
                    </svg>
                  </button>
                  <div
                    v-if="openDropdownId === category.id"
                    @click.stop
                    class="absolute right-0 w-48 rounded-xl shadow-subtle bg-white border border-slate-200 z-10 origin-top-right top-full mt-2"
                  >
                    <div class="py-1">
                      <button
                        @click="openEditDialog(category)"
                        class="w-full text-left px-4 py-2 text-sm text-primary-dark hover:bg-light-bg flex items-center gap-2 transition-colors"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                        </svg>
                        Edit
                      </button>
                      <button
                        @click="handleDelete(category)"
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
                Created {{ formatDate(category.created_at) }}
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
              <tr v-for="category in categories" :key="category.id" class="hover:bg-light-bg transition-colors">
                <td class="px-4 py-3 whitespace-nowrap">
                  <div class="text-sm font-medium text-primary-dark">{{ category.name }}</div>
                </td>
                <td class="px-4 py-3">
                  <div class="text-sm text-slate-700">{{ category.description || '-' }}</div>
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-slate-700">
                  {{ formatDate(category.created_at) }}
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm">
                  <div class="relative inline-block text-left">
                    <button
                      @click="toggleDropdown(category.id)"
                      class="text-slate-500 hover:text-primary-dark p-1 transition-colors"
                      type="button"
                    >
                      <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                        <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM18 10a2 2 0 11-4 0 2 2 0 014 0z" />
                      </svg>
                    </button>
                    <div
                      v-if="openDropdownId === category.id"
                      @click.stop
                      class="absolute right-0 w-48 rounded-xl shadow-subtle bg-white border border-slate-200 z-10"
                      :class="shouldOpenUpward(category.id) ? 'origin-bottom-right bottom-full mb-2' : 'origin-top-right top-full mt-2'"
                    >
                      <div class="py-1">
                        <button
                          @click="openEditDialog(category)"
                          class="w-full text-left px-4 py-2 text-sm text-primary-dark hover:bg-light-bg flex items-center gap-2 transition-colors"
                        >
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                          </svg>
                          Edit
                        </button>
                        <button
                          @click="handleDelete(category)"
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
              {{ isEditing ? 'Edit category' : 'Add new category' }}
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
                <label for="category-name" class="block text-sm font-medium text-slate-700 mb-2">
                  Category name <span class="text-red-500">*</span>
                </label>
                <input
                  id="category-name"
                  v-model="form.name"
                  type="text"
                  required
                  class="input-refined"
                  placeholder="e.g., Computers"
                  @focus="clearError('name')"
                />
                <p v-if="errors.name" class="mt-2 text-sm text-red-600">{{ errors.name }}</p>
              </div>

              <!-- Description -->
              <div>
                <label for="category-description" class="block text-sm font-medium text-slate-700 mb-2">
                  Description
                </label>
                <textarea
                  id="category-description"
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
import { ref, reactive, onMounted, onBeforeUnmount } from 'vue'
import { useRouter } from 'vue-router'
import MainLayout from '@/components/MainLayout.vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import { categoriesService, type Category } from '@/services/categories'

const router = useRouter()

const categories = ref<Category[]>([])
const isLoading = ref(false)
const successMessage = ref('')
const showDialog = ref(false)
const isEditing = ref(false)
const isSubmitting = ref(false)
const editingId = ref<number | null>(null)
const openDropdownId = ref<number | null>(null)
const confirmDialog = ref<InstanceType<typeof ConfirmDialog>>()
const categoryToDelete = ref<Category | null>(null)

const form = reactive({
  name: '',
  description: '',
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

const shouldOpenUpward = (categoryId: number) => {
  const index = categories.value.findIndex((c) => c.id === categoryId)
  const totalCategories = categories.value.length
  // Open upward if in the last 2 rows
  return totalCategories - index <= 2
}

const loadCategories = async () => {
  isLoading.value = true
  try {
    categories.value = await categoriesService.getAll()
  } catch (error) {
    console.error('Failed to load categories:', error)
  } finally {
    isLoading.value = false
  }
}

const openAddDialog = () => {
  isEditing.value = false
  editingId.value = null
  form.name = ''
  form.description = ''
  Object.keys(errors).forEach((key) => delete errors[key])
  showDialog.value = true
}

const openEditDialog = (category: Category) => {
  closeDropdown()
  isEditing.value = true
  editingId.value = category.id
  form.name = category.name
  form.description = category.description || ''
  Object.keys(errors).forEach((key) => delete errors[key])
  showDialog.value = true
}

const closeDialog = () => {
  showDialog.value = false
  form.name = ''
  form.description = ''
  Object.keys(errors).forEach((key) => delete errors[key])
}

const handleSubmit = async () => {
  // Clear previous errors
  Object.keys(errors).forEach((key) => delete errors[key])

  if (!form.name.trim()) {
    errors.name = 'Category name is required'
    return
  }

  isSubmitting.value = true

  try {
    if (isEditing.value && editingId.value) {
      // Update existing category
      await categoriesService.update(editingId.value, {
        name: form.name,
        description: form.description || undefined,
      })
      successMessage.value = `Category "${form.name}" has been updated successfully.`
    } else {
      // Create new category
      await categoriesService.create({
        name: form.name,
        description: form.description || undefined,
      })
      successMessage.value = `Category "${form.name}" has been added successfully.`
    }

    closeDialog()
    await loadCategories()

    // Clear success message after 5 seconds
    setTimeout(() => {
      successMessage.value = ''
    }, 5000)
  } catch (error: any) {
    console.error('Error submitting form:', error)
    if (error.response?.data?.errors) {
      Object.assign(errors, error.response.data.errors)
    } else {
      alert(`Failed to ${isEditing.value ? 'update' : 'create'} category. Please try again.`)
    }
  } finally {
    isSubmitting.value = false
  }
}

const handleDelete = (category: Category) => {
  closeDropdown()
  categoryToDelete.value = category
  confirmDialogData.title = 'Delete category'
  confirmDialogData.message = `Are you sure you want to delete "${category.name}"? This action cannot be undone.`
  confirmDialog.value?.open()
}

const confirmDelete = async () => {
  if (!categoryToDelete.value) return

  try {
    await categoriesService.delete(categoryToDelete.value.id)
    successMessage.value = `Category "${categoryToDelete.value.name}" has been deleted successfully.`
    await loadCategories()

    setTimeout(() => {
      successMessage.value = ''
    }, 5000)

    confirmDialog.value?.close()
    categoryToDelete.value = null
  } catch (error) {
    console.error('Failed to delete category:', error)
    confirmDialog.value?.close()
    alert('Failed to delete category. Please try again.')
  }
}

const cancelDelete = () => {
  categoryToDelete.value = null
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
  loadCategories()
  document.addEventListener('click', handleClickOutside)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>
