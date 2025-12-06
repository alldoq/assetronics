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
              <h1 class="text-3xl font-bold text-primary-dark">Locations</h1>
            </div>
            <p class="text-slate-600 mt-1">Manage physical locations and sites</p>
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
              Add location
            </button>
          </div>
        </div>
      </div>

      <!-- Success message -->
      <div v-if="successMessage" class="mb-6 p-4 rounded-xl bg-teal-50 border border-teal-200 text-teal-800">
        {{ successMessage }}
      </div>

      <!-- Locations list -->
      <div class="bg-white border border-slate-200 rounded-lg overflow-hidden shadow-subtle">
        <div v-if="isLoading" class="p-8 text-center">
          <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-accent-blue mx-auto mb-4"></div>
          <p class="text-slate-700">Loading locations...</p>
        </div>

        <div v-else-if="locations.length === 0" class="p-8 text-center">
          <svg class="w-16 h-16 mx-auto mb-4 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
          <p class="text-slate-700 mb-4">No locations found</p>
          <button @click="openAddDialog" class="btn-brand-primary">
            Add your first location
          </button>
        </div>

        <!-- Tree View -->
        <div v-else-if="viewMode === 'tree'" class="p-4">
          <LocationTreeNode
            v-for="loc in locationTree"
            :key="loc.id"
            :location="loc"
            :level="0"
            @edit="openEditDialog"
            @delete="handleDelete"
            @add-child="handleAddChild"
          />
        </div>

        <template v-else>
          <!-- Mobile card view -->
          <div class="lg:hidden space-y-4 p-4">
            <div v-for="location in locations" :key="location.id" class="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
              <div class="flex items-start justify-between mb-3">
                <div class="flex-1">
                  <h3 class="text-base font-bold text-primary-dark">{{ location.name }}</h3>
                  <div v-if="hasAddress(location)" class="mt-2 text-sm text-slate-600 space-y-1">
                    <p v-if="location.address_line1" class="flex items-start gap-2">
                      <svg class="w-4 h-4 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                      </svg>
                      <span>{{ location.address_line1 }}</span>
                    </p>
                    <p v-if="location.city || location.state_province || location.postal_code" class="flex items-start gap-2 ml-6">
                      {{ [location.city, location.state_province, location.postal_code].filter(Boolean).join(', ') }}
                    </p>
                    <p v-if="location.country" class="flex items-start gap-2 ml-6">
                      {{ location.country }}
                    </p>
                  </div>
                  <p v-else class="text-sm text-slate-400 mt-2">No address provided</p>
                </div>
                <div class="relative inline-block text-left">
                  <button
                    @click="toggleDropdown(location.id)"
                    class="text-slate-500 hover:text-primary-dark p-1 transition-colors"
                    type="button"
                  >
                    <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                      <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM18 10a2 2 0 11-4 0 2 2 0 014 0z" />
                    </svg>
                  </button>
                  <div
                    v-if="openDropdownId === location.id"
                    @click.stop
                    class="absolute right-0 w-48 rounded-xl shadow-subtle bg-white border border-slate-200 z-10 origin-top-right top-full mt-2"
                  >
                    <div class="py-1">
                      <button
                        @click="openEditDialog(location)"
                        class="w-full text-left px-4 py-2 text-sm text-primary-dark hover:bg-light-bg flex items-center gap-2 transition-colors"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                        </svg>
                        Edit
                      </button>
                      <button
                        @click="handleDelete(location)"
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
                Created {{ formatDate((location.inserted_at || location.created_at)!) }}
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
                    Address
                  </th>
                  <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                    City
                  </th>
                  <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                    Country
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
                <tr v-for="location in locations" :key="location.id" class="hover:bg-light-bg transition-colors">
                  <td class="px-4 py-3 whitespace-nowrap">
                    <div class="text-sm font-medium text-primary-dark">{{ location.name }}</div>
                  </td>
                  <td class="px-4 py-3">
                    <div class="text-sm text-slate-700">{{ location.address_line1 || '-' }}</div>
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap">
                    <div class="text-sm text-slate-700">{{ location.city || '-' }}</div>
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap">
                    <div class="text-sm text-slate-700">{{ location.country || '-' }}</div>
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap text-sm text-slate-700">
                    {{ formatDate((location.inserted_at || location.created_at)!) }}
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap text-sm">
                    <div class="relative inline-block text-left">
                      <button
                        @click="toggleDropdown(location.id)"
                        class="text-slate-500 hover:text-primary-dark p-1 transition-colors"
                        type="button"
                      >
                        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                          <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM18 10a2 2 0 11-4 0 2 2 0 014 0z" />
                        </svg>
                      </button>
                      <div
                        v-if="openDropdownId === location.id"
                        @click.stop
                        class="absolute right-0 w-48 rounded-xl shadow-subtle bg-white border border-slate-200 z-10"
                        :class="shouldOpenUpward(location.id) ? 'origin-bottom-right bottom-full mb-2' : 'origin-top-right top-full mt-2'"
                      >
                        <div class="py-1">
                          <button
                            @click="openEditDialog(location)"
                            class="w-full text-left px-4 py-2 text-sm text-primary-dark hover:bg-light-bg flex items-center gap-2 transition-colors"
                          >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                            </svg>
                            Edit
                          </button>
                          <button
                            @click="handleDelete(location)"
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
        <div class="bg-white rounded-3xl border border-slate-200 shadow-subtle max-w-2xl w-full p-6 max-h-[90vh] overflow-y-auto">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-bold text-primary-dark">
              {{ isEditing ? 'Edit location' : 'Add new location' }}
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
                <label for="location-name" class="block text-sm font-medium text-slate-700 mb-2">
                  Location name <span class="text-red-500">*</span>
                </label>
                <input
                  id="location-name"
                  v-model="form.name"
                  type="text"
                  required
                  class="input-refined"
                  placeholder="e.g., Headquarters"
                  @focus="clearError('name')"
                />
                <p v-if="errors.name" class="mt-2 text-sm text-red-600">{{ errors.name }}</p>
              </div>

              <!-- Type -->
              <div>
                <label for="location-type" class="block text-sm font-medium text-slate-700 mb-2">
                  Type <span class="text-red-500">*</span>
                </label>
                <select
                  id="location-type"
                  v-model="form.location_type"
                  required
                  class="input-refined"
                >
                  <option value="">Select a type...</option>
                  <option value="region">Region</option>
                  <option value="country">Country</option>
                  <option value="state">State</option>
                  <option value="city">City</option>
                  <option value="office">Office</option>
                  <option value="building">Building</option>
                  <option value="floor">Floor</option>
                  <option value="warehouse">Warehouse</option>
                  <option value="datacenter">Datacenter</option>
                  <option value="store">Store</option>
                  <option value="other">Other</option>
                </select>
              </div>

              <!-- Parent Location -->
              <div>
                <label for="location-parent" class="block text-sm font-medium text-slate-700 mb-2">
                  Parent Location
                </label>
                <select
                  id="location-parent"
                  v-model="form.parent_id"
                  class="input-refined"
                >
                  <option :value="null">None (root location)</option>
                  <option
                    v-for="loc in availableParents"
                    :key="loc.id"
                    :value="loc.id"
                  >
                    {{ loc.name }}
                  </option>
                </select>
                <p class="mt-1 text-xs text-slate-500">
                  Select a parent to create a sub-location
                </p>
              </div>

              <!-- Address -->
              <div>
                <label for="location-address" class="block text-sm font-medium text-slate-700 mb-2">
                  Street address
                </label>
                <input
                  id="location-address"
                  v-model="form.address_line1"
                  type="text"
                  class="input-refined"
                  placeholder="e.g., 123 Main Street"
                />
              </div>

              <!-- City and State -->
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label for="location-city" class="block text-sm font-medium text-slate-700 mb-2">
                    City
                  </label>
                  <input
                    id="location-city"
                    v-model="form.city"
                    type="text"
                    class="input-refined"
                    placeholder="e.g., San Francisco"
                  />
                </div>
                <div>
                  <label for="location-state" class="block text-sm font-medium text-slate-700 mb-2">
                    State / Province
                  </label>
                  <input
                    id="location-state"
                    v-model="form.state_province"
                    type="text"
                    class="input-refined"
                    placeholder="e.g., CA"
                  />
                </div>
              </div>

              <!-- Postal Code and Country -->
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label for="location-postal-code" class="block text-sm font-medium text-slate-700 mb-2">
                    Postal code
                  </label>
                  <input
                    id="location-postal-code"
                    v-model="form.postal_code"
                    type="text"
                    class="input-refined"
                    placeholder="e.g., 94102"
                  />
                </div>
                <div>
                  <label for="location-country" class="block text-sm font-medium text-slate-700 mb-2">
                    Country
                  </label>
                  <input
                    id="location-country"
                    v-model="form.country"
                    type="text"
                    class="input-refined"
                    placeholder="e.g., United States"
                  />
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
import { ref, reactive, computed, onMounted, onBeforeUnmount } from 'vue'
import { useRouter } from 'vue-router'
import MainLayout from '@/components/MainLayout.vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import LocationTreeNode from '@/components/settings/LocationTreeNode.vue'
import { locationsService, type Location, type LocationType } from '@/services/locations'

const router = useRouter()

const locations = ref<Location[]>([])
const isLoading = ref(false)
const successMessage = ref('')
const showDialog = ref(false)
const isEditing = ref(false)
const isSubmitting = ref(false)
const editingId = ref<number | null>(null)
const openDropdownId = ref<number | null>(null)
const confirmDialog = ref<InstanceType<typeof ConfirmDialog>>()
const locationToDelete = ref<Location | null>(null)
const viewMode = ref<'list' | 'tree'>('list')

const form = reactive({
  name: '',
  location_type: '' as LocationType | '',
  parent_id: null as number | null,
  address_line1: '',
  city: '',
  state_province: '',
  country: '',
  postal_code: '',
})

const errors = reactive<Record<string, string>>({})

// Build tree from flat array
const locationTree = computed(() => {
  const buildTree = (parentId: number | null = null): Location[] => {
    return locations.value
      .filter(loc => loc.parent_id === parentId)
      .map(loc => ({
        ...loc,
        children: buildTree(loc.id)
      }))
      .sort((a, b) => a.name.localeCompare(b.name))
  }
  return buildTree(null)
})

// Get descendants of a location (for preventing circular references)
const getDescendants = (locId: number): number[] => {
  const descendants: number[] = []
  const findDescendants = (id: number) => {
    locations.value
      .filter(l => l.parent_id === id)
      .forEach(child => {
        descendants.push(child.id)
        findDescendants(child.id)
      })
  }
  findDescendants(locId)
  return descendants
}

// Available parents (excluding self and descendants when editing)
const availableParents = computed(() => {
  if (!isEditing.value || !editingId.value) {
    return locations.value
  }

  const excludeIds = [editingId.value, ...getDescendants(editingId.value)]
  return locations.value.filter(l => !excludeIds.includes(l.id))
})

const confirmDialogData = reactive({
  title: '',
  message: '',
})

const hasAddress = (location: Location): boolean => {
  return !!(location.address_line1 || location.city || location.state_province || location.country || location.postal_code)
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

const shouldOpenUpward = (locationId: number) => {
  const index = locations.value.findIndex((l) => l.id === locationId)
  const totalLocations = locations.value.length
  return totalLocations - index <= 2
}

const loadLocations = async () => {
  isLoading.value = true
  try {
    locations.value = await locationsService.getAll()
  } catch (error) {
    console.error('Failed to load locations:', error)
  } finally {
    isLoading.value = false
  }
}

const openAddDialog = () => {
  isEditing.value = false
  editingId.value = null
  form.name = ''
  form.location_type = ''
  form.parent_id = null
  form.address_line1 = ''
  form.city = ''
  form.state_province = ''
  form.country = ''
  form.postal_code = ''
  Object.keys(errors).forEach((key) => delete errors[key])
  showDialog.value = true
}

const handleAddChild = async (data: { parent_id: string; name: string; location_type: string }) => {
  try {
    await locationsService.create({
      name: data.name,
      location_type: data.location_type as LocationType,
      parent_id: Number(data.parent_id),
      is_active: true
    })
    successMessage.value = `Location "${data.name}" added successfully`
    setTimeout(() => {
      successMessage.value = ''
    }, 3000)
    await loadLocations()
  } catch (error: any) {
    console.error('Failed to add child location:', error)
    alert('Failed to add location: ' + (error.response?.data?.error || 'Unknown error'))
  }
}

const openEditDialog = (location: Location) => {
  closeDropdown()
  isEditing.value = true
  editingId.value = location.id
  form.name = location.name
  form.location_type = location.location_type || ''
  form.parent_id = location.parent_id || null
  form.address_line1 = location.address_line1 || ''
  form.city = location.city || ''
  form.state_province = location.state_province || ''
  form.country = location.country || ''
  form.postal_code = location.postal_code || ''
  Object.keys(errors).forEach((key) => delete errors[key])
  showDialog.value = true
}

const closeDialog = () => {
  showDialog.value = false
  form.name = ''
  form.location_type = ''
  form.parent_id = null
  form.address_line1 = ''
  form.city = ''
  form.state_province = ''
  form.country = ''
  form.postal_code = ''
  Object.keys(errors).forEach((key) => delete errors[key])
}

const handleSubmit = async () => {
  Object.keys(errors).forEach((key) => delete errors[key])

  if (!form.name.trim()) {
    errors.name = 'Location name is required'
    return
  }

  if (!form.location_type) {
    errors.location_type = 'Location type is required'
    return
  }

  isSubmitting.value = true

  try {
    const data = {
      name: form.name,
      location_type: form.location_type,
      parent_id: form.parent_id || undefined,
      address_line1: form.address_line1 || undefined,
      city: form.city || undefined,
      state_province: form.state_province || undefined,
      country: form.country || undefined,
      postal_code: form.postal_code || undefined,
    }

    if (isEditing.value && editingId.value) {
      await locationsService.update(editingId.value, data)
      successMessage.value = `Location "${form.name}" has been updated successfully.`
    } else {
      await locationsService.create(data)
      successMessage.value = `Location "${form.name}" has been added successfully.`
    }

    closeDialog()
    await loadLocations()

    setTimeout(() => {
      successMessage.value = ''
    }, 5000)
  } catch (error: any) {
    console.error('Error submitting form:', error)
    if (error.response?.data?.errors) {
      Object.assign(errors, error.response.data.errors)
    } else {
      alert(`Failed to ${isEditing.value ? 'update' : 'create'} location. Please try again.`)
    }
  } finally {
    isSubmitting.value = false
  }
}

const handleDelete = (location: Location) => {
  closeDropdown()
  locationToDelete.value = location
  confirmDialogData.title = 'Delete location'
  confirmDialogData.message = `Are you sure you want to delete "${location.name}"? This action cannot be undone.`
  confirmDialog.value?.open()
}

const confirmDelete = async () => {
  if (!locationToDelete.value) return

  try {
    await locationsService.delete(locationToDelete.value.id)
    successMessage.value = `Location "${locationToDelete.value.name}" has been deleted successfully.`
    await loadLocations()

    setTimeout(() => {
      successMessage.value = ''
    }, 5000)

    confirmDialog.value?.close()
    locationToDelete.value = null
  } catch (error) {
    console.error('Failed to delete location:', error)
    confirmDialog.value?.close()
    alert('Failed to delete location. Please try again.')
  }
}

const cancelDelete = () => {
  locationToDelete.value = null
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
  loadLocations()
  document.addEventListener('click', handleClickOutside)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>
