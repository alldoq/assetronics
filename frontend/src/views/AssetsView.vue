<template>
  <MainLayout>
    <div>
      <!-- Page header -->
      <div class="mb-6">
        <h1 class="text-3xl font-bold text-primary-dark">Assets</h1>
        <p class="text-slate-500 mt-1">Manage your company's assets and equipment</p>
      </div>

      <!-- Success message -->
      <div v-if="successMessage" class="alert-success mb-6">
        {{ successMessage }}
      </div>

      <!-- Actions bar -->
      <div class="flex flex-col gap-4 mb-6">
        <!-- Search and Add button -->
        <div class="flex flex-col sm:flex-row gap-4">
          <div class="flex-1">
            <input
              v-model="searchQuery"
              type="search"
              placeholder="Search assets..."
              class="input-refined w-full"
            />
          </div>
          <router-link to="/assets/add" class="px-6 py-3 btn-brand-primary whitespace-nowrap text-center">
            <svg class="w-5 h-5 mr-2 inline-block" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Add asset
          </router-link>
        </div>

        <!-- Filters -->
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div>
            <label class="block text-xs font-medium text-slate-700 mb-1">Status</label>
            <select v-model="filters.status" class="input-refined w-full">
              <option value="">All statuses</option>
              <option value="on_order">On order</option>
              <option value="in_stock">In stock</option>
              <option value="assigned">Assigned</option>
              <option value="in_transit">In transit</option>
              <option value="in_repair">In repair</option>
              <option value="retired">Retired</option>
              <option value="lost">Lost</option>
              <option value="stolen">Stolen</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-medium text-slate-700 mb-1">Category</label>
            <select v-model="filters.category" class="input-refined w-full">
              <option value="">All categories</option>
              <option value="laptop">Laptop</option>
              <option value="desktop">Desktop</option>
              <option value="monitor">Monitor</option>
              <option value="phone">Phone</option>
              <option value="tablet">Tablet</option>
              <option value="peripheral">Peripheral</option>
              <option value="server">Server</option>
              <option value="network_equipment">Network equipment</option>
              <option value="other">Other</option>
            </select>
          </div>
          <div>
            <EmployeeAutocomplete
              v-model="filters.employee_id"
              :employees="employees"
              label="Assignee"
              placeholder="Search employees..."
              :show-special-options="true"
            />
          </div>
        </div>
      </div>

      <!-- Desktop Table View (hidden on mobile) -->
      <div class="hidden md:block bg-white border border-border-light rounded-lg shadow-subtle">
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-light-bg border-b border-slate-200">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Asset
                </th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Category
                </th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Status
                </th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Assigned to
                </th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-slate-200">
              <tr v-if="isLoading || isSearching">
                <td colspan="5" class="px-4 py-6 text-center text-slate-500">
                  {{ isSearching ? 'Searching...' : 'Loading assets...' }}
                </td>
              </tr>
              <tr v-else-if="assets.length === 0">
                <td colspan="5" class="px-4 py-6 text-center text-slate-500">
                  {{ searchQuery ? 'No assets found matching your search.' : 'No assets found. Click "Add asset" to get started.' }}
                </td>
              </tr>
              <tr v-else v-for="asset in assets" :key="asset.id" class="hover:bg-light-bg transition-colors">
                <td class="px-4 py-3 whitespace-nowrap">
                  <div class="flex items-center gap-3">
                    <!-- Asset image or icon -->
                    <div class="w-12 h-12 flex-shrink-0 rounded-lg bg-gradient-to-br from-slate-50 to-slate-100 flex items-center justify-center overflow-hidden border border-slate-200">
                      <img
                        v-if="asset.image_url"
                        :src="getImageUrl(asset.image_url)"
                        :alt="asset.name"
                        class="w-full h-full object-contain"
                        @error="(e) => handleImageError(e)"
                      />
                      <svg v-else class="w-6 h-6 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                      </svg>
                    </div>
                    <!-- Asset name and serial -->
                    <div>
                      <div class="text-sm font-bold text-primary-dark">{{ asset.name }}</div>
                      <div class="text-sm text-slate-500 font-mono">Serial: {{ asset.serial_number || 'N/A' }}</div>
                    </div>
                  </div>
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-slate-600">{{ getCategoryName(asset) }}</td>
                <td class="px-4 py-3 whitespace-nowrap">
                  <span
                    class="px-2 py-1 text-xs font-mono font-bold rounded border"
                    :class="getStatusClass(asset.status)"
                  >
                    {{ formatStatus(asset.status) }}
                  </span>
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-slate-600">
                  {{ getAssignedTo(asset) }}
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm">
                  <div class="relative inline-block text-left">
                    <button
                      @click="toggleDropdown(asset.id, $event)"
                      class="inline-flex items-center gap-1 px-3 py-1.5 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-accent-blue"
                    >
                      Actions
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                      </svg>
                    </button>

                    <!-- Dropdown menu using Teleport to avoid overflow issues -->
                    <Teleport to="body">
                      <div
                        v-if="openDropdownId === asset.id"
                        :style="dropdownPosition"
                        class="fixed z-[9999] w-48 rounded-lg bg-white shadow-xl ring-1 ring-black ring-opacity-5 focus:outline-none"
                        @click.stop
                      >
                        <div class="py-1">
                          <button
                            @click="handleViewAsset(asset)"
                            class="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 flex items-center gap-2"
                          >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                            </svg>
                            View details
                          </button>
                          <button
                            v-if="asset.status === 'in_stock' || asset.status === 'on_order'"
                            @click="handleAssignAsset(asset)"
                            class="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 flex items-center gap-2"
                          >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                            </svg>
                            Assign to employee
                          </button>
                          <button
                            @click="handleEditAsset(asset)"
                            class="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 flex items-center gap-2"
                          >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                            </svg>
                            Edit
                          </button>
                          <button
                            @click="handlePrintLabel(asset)"
                            class="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 flex items-center gap-2"
                          >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z" />
                            </svg>
                            Print label
                          </button>
                          <button
                            @click="handleDeleteAsset(asset)"
                            class="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50 flex items-center gap-2"
                          >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                            </svg>
                            Delete
                          </button>
                        </div>
                      </div>
                    </Teleport>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Pagination for desktop -->
        <Pagination
          v-if="paginationMeta && !isLoading"
          :current-page="paginationMeta.page"
          :total-pages="paginationMeta.total_pages"
          :total="paginationMeta.total"
          :per-page="paginationMeta.per_page"
          @page-change="handlePageChange"
        />
      </div>

      <!-- Mobile Card View (visible on mobile only) -->
      <div class="md:hidden space-y-4">
        <!-- Loading/Empty states -->
        <div v-if="isLoading || isSearching" class="bg-white border border-border-light rounded-lg p-6 text-center text-slate-500">
          {{ isSearching ? 'Searching...' : 'Loading assets...' }}
        </div>
        <div v-else-if="assets.length === 0" class="bg-white border border-border-light rounded-lg p-6 text-center text-slate-500">
          {{ searchQuery ? 'No assets found matching your search.' : 'No assets found. Click "Add asset" to get started.' }}
        </div>

        <!-- Asset cards -->
        <div v-else v-for="asset in assets" :key="asset.id" class="bg-white border border-border-light rounded-lg overflow-hidden shadow-subtle">
          <div class="p-4 space-y-3">
            <!-- Header with image, name and dropdown -->
            <div class="flex items-start justify-between gap-3">
              <!-- Asset image -->
              <div class="w-16 h-16 flex-shrink-0 rounded-lg bg-gradient-to-br from-slate-50 to-slate-100 flex items-center justify-center overflow-hidden border border-slate-200">
                <img
                  v-if="asset.image_url"
                  :src="getImageUrl(asset.image_url)"
                  :alt="asset.name"
                  class="w-full h-full object-contain"
                  @error="(e) => handleImageError(e)"
                />
                <svg v-else class="w-8 h-8 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                </svg>
              </div>
              <div class="flex-1 min-w-0">
                <h3 class="text-lg font-bold text-primary-dark truncate">{{ asset.name }}</h3>
                <p class="text-sm text-slate-500 font-mono">Serial: {{ asset.serial_number || 'N/A' }}</p>
              </div>

              <!-- Mobile dropdown -->
              <div class="relative flex-shrink-0">
                <button
                  @click="toggleDropdown(asset.id, $event)"
                  class="p-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
                  </svg>
                </button>

                <!-- Dropdown menu using Teleport -->
                <Teleport to="body">
                  <div
                    v-if="openDropdownId === asset.id"
                    :style="dropdownPosition"
                    class="fixed z-[9999] w-48 rounded-lg bg-white shadow-xl ring-1 ring-black ring-opacity-5"
                    @click.stop
                  >
                    <div class="py-1">
                      <button
                        @click="handleViewAsset(asset)"
                        class="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 flex items-center gap-2"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                        </svg>
                        View details
                      </button>
                      <button
                        v-if="asset.status === 'in_stock' || asset.status === 'on_order'"
                        @click="handleAssignAsset(asset)"
                        class="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 flex items-center gap-2"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                        </svg>
                        Assign to employee
                      </button>
                      <button
                        @click="handleEditAsset(asset)"
                        class="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 flex items-center gap-2"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                        </svg>
                        Edit
                      </button>
                      <button
                        @click="handlePrintLabel(asset)"
                        class="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 flex items-center gap-2"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z" />
                        </svg>
                        Print label
                      </button>
                      <button
                        @click="handleDeleteAsset(asset)"
                        class="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50 flex items-center gap-2"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                        Delete
                      </button>
                    </div>
                  </div>
                </Teleport>
              </div>
            </div>

            <!-- Asset details -->
            <div class="grid grid-cols-2 gap-3 pt-3 border-t border-slate-200">
              <div>
                <p class="text-xs font-medium text-slate-500 mb-1">Category</p>
                <p class="text-sm text-slate-900">{{ getCategoryName(asset) }}</p>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 mb-1">Status</p>
                <span
                  class="inline-block px-2 py-1 text-xs font-mono font-bold rounded border"
                  :class="getStatusClass(asset.status)"
                >
                  {{ formatStatus(asset.status) }}
                </span>
              </div>
              <div class="col-span-2">
                <p class="text-xs font-medium text-slate-500 mb-1">Assigned to</p>
                <p class="text-sm text-slate-900">{{ getAssignedTo(asset) }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Pagination for mobile -->
      <Pagination
        v-if="paginationMeta && !isLoading"
        :current-page="paginationMeta.page"
        :total-pages="paginationMeta.total_pages"
        :total="paginationMeta.total"
        :per-page="paginationMeta.per_page"
        @page-change="handlePageChange"
        class="md:hidden mt-4"
      />
    </div>

    <!-- Assign Asset Modal -->
    <AssignAssetModal
      v-model="showAssignModal"
      :asset="selectedAsset"
      :employees="employees"
      @assigned="handleAssetAssigned"
    />

    <!-- Print Label Modal -->
    <AssetLabelModal
      v-model="showPrintLabelModal"
      :label-data="labelData"
      :loading="loadingLabel"
    />
  </MainLayout>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, watch, onBeforeUnmount, Teleport } from 'vue'
import { useRouter } from 'vue-router'
import MainLayout from '@/components/MainLayout.vue'
import Pagination from '@/components/Pagination.vue'
import EmployeeAutocomplete from '@/components/EmployeeAutocomplete.vue'
import AssignAssetModal from '@/components/AssignAssetModal.vue'
import AssetLabelModal from '@/components/AssetLabelModal.vue'
import { assetsService, type Asset, type AssetFilters, type PaginationMeta } from '@/services/assets'
import { employeesService, type Employee } from '@/services/employees'
import { useAuthStore } from '@/stores/auth'
import { useToast } from '@/composables/useToast'

const router = useRouter()
const authStore = useAuthStore()
const toast = useToast()

const searchQuery = ref('')
const successMessage = ref('')
const isLoading = ref(false)
const assets = ref<Asset[]>([])
const paginationMeta = ref<PaginationMeta | null>(null)
const isSearching = ref(false)
const openDropdownId = ref<string | null>(null)
const employees = ref<Employee[]>([])
const showAssignModal = ref(false)
const showPrintLabelModal = ref(false)
const labelData = ref<any>(null)
const loadingLabel = ref(false)
const selectedAsset = ref<Asset | null>(null)

// Filters state
const filters = ref<AssetFilters>({
  page: 1,
  per_page: 25,
  status: '',
  category: '',
  employee_id: '',
  q: ''
})

// Load assets from API with pagination and filters
const loadAssets = async () => {
  isLoading.value = true
  try {
    const params: AssetFilters = {
      page: filters.value.page,
      per_page: filters.value.per_page,
    }

    // Add filters only if they have values
    if (filters.value.status) params.status = filters.value.status
    if (filters.value.category) params.category = filters.value.category
    if (filters.value.employee_id) params.employee_id = filters.value.employee_id
    if (searchQuery.value.trim()) params.q = searchQuery.value.trim()

    const response = await assetsService.getAll(params)
    assets.value = response.data
    paginationMeta.value = response.meta
  } catch (error) {
    console.error('Failed to load assets:', error)
    successMessage.value = 'Failed to load assets. Please try again.'
  } finally {
    isLoading.value = false
  }
}

// Load employees for the assignee filter
const loadEmployees = async () => {
  try {
    employees.value = await employeesService.getAll()
  } catch (error) {
    console.error('Failed to load employees:', error)
  }
}

// Handle page change
const handlePageChange = (page: number) => {
  filters.value.page = page
  loadAssets()
  // Scroll to top
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

// Search functionality with debouncing
let searchTimeout: ReturnType<typeof setTimeout> | null = null

// Watch search query with debouncing
watch(searchQuery, () => {
  if (searchTimeout) {
    clearTimeout(searchTimeout)
  }

  searchTimeout = setTimeout(() => {
    filters.value.page = 1 // Reset to first page on search
    loadAssets()
  }, 300)
})

// Watch filters for changes
watch(
  () => [filters.value.status, filters.value.category, filters.value.employee_id],
  () => {
    filters.value.page = 1 // Reset to first page when filters change
    loadAssets()
  }
)

// Navigate to view asset
const handleViewAsset = (asset: Asset) => {
  closeDropdown()
  router.push(`/assets/${asset.id}`)
}

// Navigate to edit asset
const handleEditAsset = (asset: Asset) => {
  closeDropdown()
  router.push(`/assets/${asset.id}/edit`)
}

// Assign asset
const handleAssignAsset = (asset: Asset) => {
  closeDropdown()
  selectedAsset.value = asset
  showAssignModal.value = true
}

// Handle successful assignment
const handleAssetAssigned = async () => {
  await loadAssets()
  successMessage.value = `Asset "${selectedAsset.value?.name}" has been assigned successfully.`
  setTimeout(() => {
    successMessage.value = ''
  }, 5000)
}

// Print label
const handlePrintLabel = async (asset: Asset) => {
  closeDropdown()
  loadingLabel.value = true
  showPrintLabelModal.value = true

  try {
    const tenantId = authStore.user?.tenant_id || import.meta.env.VITE_DEFAULT_TENANT || 'acme'

    const response = await fetch(`${import.meta.env.VITE_API_URL}/api/v1/assets/${asset.id}/label`, {
      headers: {
        'Authorization': `Bearer ${authStore.token}`,
        'X-Tenant-ID': tenantId
      }
    })

    if (!response.ok) {
      throw new Error('Failed to generate label')
    }

    const data = await response.json()
    labelData.value = data.data
  } catch (err: any) {
    console.error('Failed to generate label:', err)
    toast.error('Failed to generate label. Please try again.')
    showPrintLabelModal.value = false
  } finally {
    loadingLabel.value = false
  }
}

// Delete asset
const handleDeleteAsset = async (asset: Asset) => {
  closeDropdown()

  if (!confirm(`Are you sure you want to delete "${asset.name}"?`)) {
    return
  }

  try {
    await assetsService.delete(asset.id)
    await loadAssets()
    successMessage.value = `Asset "${asset.name}" has been deleted successfully.`
    setTimeout(() => {
      successMessage.value = ''
    }, 5000)
  } catch (error) {
    console.error('Failed to delete asset:', error)
    alert('Failed to delete asset. Please try again.')
  }
}

const formatStatus = (status: string): string => {
  const statusMap: Record<string, string> = {
    on_order: 'On order',
    in_stock: 'In stock',
    assigned: 'Assigned',
    in_transit: 'In transit',
    in_repair: 'In repair',
    retired: 'Retired',
    lost: 'Lost',
    stolen: 'Stolen',
  }
  return statusMap[status] || status
}

const getStatusClass = (status: string): string => {
  const classMap: Record<string, string> = {
    on_order: 'bg-purple-50 text-purple-700 border-purple-200',
    in_stock: 'bg-teal-50 text-teal-700 border-teal-200',
    assigned: 'bg-blue-100 text-blue-800 border-blue-200',
    in_transit: 'bg-indigo-50 text-indigo-700 border-indigo-200',
    in_repair: 'bg-amber-100 text-amber-800 border-amber-200',
    retired: 'bg-slate-100 text-slate-700 border-slate-300',
    lost: 'bg-orange-100 text-orange-800 border-orange-200',
    stolen: 'bg-red-100 text-red-800 border-red-200',
  }
  return classMap[status] || 'bg-slate-100 text-slate-700 border-slate-300'
}

// Get assigned employee name
const getAssignedTo = (asset: Asset): string => {
  if (asset.employee) {
    return `${asset.employee.first_name} ${asset.employee.last_name}`
  }
  return '-'
}

// Get category name
const getCategoryName = (asset: Asset): string => {
  // Handle both string and object formats
  if (typeof asset.category === 'string') {
    return asset.category || 'Unknown'
  }
  return (asset.category as any)?.name || 'Unknown'
}

// Image handling functions
const getImageUrl = (url: string): string => {
  if (!url) return ''
  // If it's a relative URL (starts with /uploads), prepend the API base URL
  if (url.startsWith('/uploads')) {
    return `${import.meta.env.VITE_API_URL}${url}`
  }
  // Otherwise return the URL as-is (for S3 URLs)
  return url
}

const handleImageError = (event: Event) => {
  // Hide broken image on error
  const img = event.target as HTMLImageElement
  img.style.display = 'none'
}

// Dropdown management
const dropdownPosition = ref({ top: '0px', left: '0px' })

const getDropdownPosition = (event: MouseEvent) => {
  const buttonEl = event.currentTarget as HTMLElement
  if (!buttonEl) {
    return { top: '0px', left: '0px' }
  }

  const rect = buttonEl.getBoundingClientRect()
  const dropdownWidth = 192 // w-48 = 12rem = 192px
  const dropdownHeight = 120 // Approximate height

  // Calculate position: below button, aligned to the right
  let top = rect.bottom + 8 // 8px gap below button
  let left = rect.right - dropdownWidth

  // If dropdown would go off bottom of screen, show above button
  if (top + dropdownHeight > window.innerHeight) {
    top = rect.top - dropdownHeight - 8
  }

  // Ensure dropdown doesn't go off-screen horizontally
  if (left < 8) {
    left = 8
  }
  if (left + dropdownWidth > window.innerWidth - 8) {
    left = window.innerWidth - dropdownWidth - 8
  }

  return {
    top: `${top}px`,
    left: `${left}px`
  }
}

const toggleDropdown = (assetId: string, event: MouseEvent) => {
  if (openDropdownId.value === assetId) {
    openDropdownId.value = null
  } else {
    openDropdownId.value = assetId
    // Calculate position based on the clicked button
    dropdownPosition.value = getDropdownPosition(event)
  }
}

const closeDropdown = () => {
  openDropdownId.value = null
}

// Close dropdown when clicking outside
const handleClickOutside = (event: MouseEvent) => {
  const target = event.target as HTMLElement
  if (!target.closest('[class*="relative"]') && !target.closest('[class*="fixed"]')) {
    closeDropdown()
  }
}

onMounted(() => {
  loadAssets()
  loadEmployees()
  document.addEventListener('click', handleClickOutside)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside)
  if (searchTimeout) {
    clearTimeout(searchTimeout)
  }
})
</script>
