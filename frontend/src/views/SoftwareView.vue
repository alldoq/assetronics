<template>
  <MainLayout>
    <div>
      <!-- Page header -->
      <div class="mb-6">
        <h1 class="text-3xl font-bold text-primary-dark">Software Licenses</h1>
        <p class="text-slate-500 mt-1">Manage software licenses and seat assignments</p>
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
              placeholder="Search licenses..."
              class="input-refined w-full"
            />
          </div>
          <router-link to="/software/add" class="px-6 py-3 btn-brand-primary whitespace-nowrap text-center">
            <svg class="w-5 h-5 mr-2 inline-block" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Add license
          </router-link>
        </div>

        <!-- Filters -->
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div>
            <label class="block text-xs font-medium text-slate-700 mb-1">Status</label>
            <select v-model="filters.status" class="input-refined w-full">
              <option value="">All statuses</option>
              <option value="active">Active</option>
              <option value="expired">Expired</option>
              <option value="cancelled">Cancelled</option>
              <option value="future">Future</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-medium text-slate-700 mb-1">Vendor</label>
            <select v-model="filters.vendor" class="input-refined w-full">
              <option value="">All vendors</option>
              <option value="Microsoft">Microsoft</option>
              <option value="Google">Google</option>
              <option value="Adobe">Adobe</option>
              <option value="Salesforce">Salesforce</option>
              <option value="Slack">Slack</option>
              <option value="Zoom">Zoom</option>
            </select>
          </div>
          <div>
            <!-- Placeholder -->
          </div>
        </div>
      </div>

      <!-- Desktop Table View -->
      <div class="hidden md:block bg-white border border-border-light rounded-lg shadow-subtle">
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-light-bg border-b border-slate-200">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">License</th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">Vendor</th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">Status</th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">Seats</th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">Utilization</th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-slate-200">
              <tr v-if="isLoading">
                <td colspan="6" class="px-4 py-6 text-center text-slate-500">Loading licenses...</td>
              </tr>
              <tr v-else-if="licenses.length === 0">
                <td colspan="6" class="px-4 py-6 text-center text-slate-500">
                  {{ searchQuery ? 'No licenses found matching your search.' : 'No licenses found. Click "Add license" to get started.' }}
                </td>
              </tr>
              <tr v-else v-for="license in licenses" :key="license.id" class="hover:bg-light-bg transition-colors">
                <td class="px-4 py-3 whitespace-nowrap">
                  <div class="flex items-center gap-3">
                    <div class="w-12 h-12 flex-shrink-0 rounded-lg bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center border border-blue-200">
                      <svg class="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                      </svg>
                    </div>
                    <div>
                      <div class="text-sm font-bold text-primary-dark">{{ license.name }}</div>
                      <div class="text-sm text-slate-500">{{ license.description || 'No description' }}</div>
                    </div>
                  </div>
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-slate-600">{{ license.vendor }}</td>
                <td class="px-4 py-3 whitespace-nowrap">
                  <span class="px-2 py-1 text-xs font-mono font-bold rounded border" :class="getStatusClass(license.status)">
                    {{ formatStatus(license.status) }}
                  </span>
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-slate-600">
                  <span class="font-mono">{{ license.assigned_count || 0 }} / {{ license.total_seats }}</span>
                </td>
                <td class="px-4 py-3 whitespace-nowrap">
                  <div class="flex items-center gap-2">
                    <div class="flex-1 h-2 bg-slate-200 rounded-full overflow-hidden max-w-[100px]">
                      <div class="h-full transition-all" :class="getUtilizationClass(getUtilization(license))" :style="{ width: `${getUtilization(license)}%` }"></div>
                    </div>
                    <span class="text-xs font-mono text-slate-600">{{ Math.round(getUtilization(license)) }}%</span>
                  </div>
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm">
                  <div class="relative inline-block text-left">
                    <button @click="toggleDropdown(license.id, $event)" class="inline-flex items-center gap-1 px-3 py-1.5 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-50">
                      Actions
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                      </svg>
                    </button>
                    <Teleport to="body">
                      <div v-if="openDropdownId === license.id" :style="dropdownPosition" class="fixed z-[9999] w-48 rounded-lg bg-white shadow-xl ring-1 ring-black ring-opacity-5" @click.stop>
                        <div class="py-1">
                          <button @click="handleViewLicense(license)" class="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 flex items-center gap-2">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" /></svg>
                            View details
                          </button>
                          <button @click="handleEditLicense(license)" class="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 flex items-center gap-2">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" /></svg>
                            Edit
                          </button>
                          <button @click="handleDeleteLicense(license)" class="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50 flex items-center gap-2">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
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
      </div>

      <!-- Mobile Card View -->
      <div class="md:hidden space-y-4">
        <div v-if="isLoading" class="bg-white border border-border-light rounded-lg p-6 text-center text-slate-500">Loading licenses...</div>
        <div v-else-if="licenses.length === 0" class="bg-white border border-border-light rounded-lg p-6 text-center text-slate-500">
          {{ searchQuery ? 'No licenses found matching your search.' : 'No licenses found. Click "Add license" to get started.' }}
        </div>
        <div v-else v-for="license in licenses" :key="license.id" class="bg-white border border-border-light rounded-lg overflow-hidden shadow-subtle">
          <div class="p-4 space-y-3">
            <div class="flex items-start justify-between gap-3">
              <div class="w-16 h-16 flex-shrink-0 rounded-lg bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center border border-blue-200">
                <svg class="w-8 h-8 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
              <div class="flex-1 min-w-0">
                <h3 class="text-lg font-bold text-primary-dark truncate">{{ license.name }}</h3>
                <p class="text-sm text-slate-500">{{ license.vendor }}</p>
              </div>
              <button @click="toggleDropdown(license.id, $event)" class="p-2 text-slate-600 hover:bg-slate-100 rounded-lg">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" /></svg>
              </button>
            </div>
            <div class="grid grid-cols-2 gap-3 pt-3 border-t border-slate-200">
              <div>
                <p class="text-xs font-medium text-slate-500 mb-1">Status</p>
                <span class="inline-block px-2 py-1 text-xs font-mono font-bold rounded border" :class="getStatusClass(license.status)">{{ formatStatus(license.status) }}</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 mb-1">Seats</p>
                <p class="text-sm text-slate-900 font-mono">{{ license.assigned_count || 0 }} / {{ license.total_seats }}</p>
              </div>
              <div class="col-span-2">
                <p class="text-xs font-medium text-slate-500 mb-1">Utilization</p>
                <div class="flex items-center gap-2">
                  <div class="flex-1 h-2 bg-slate-200 rounded-full overflow-hidden">
                    <div class="h-full transition-all" :class="getUtilizationClass(getUtilization(license))" :style="{ width: `${getUtilization(license)}%` }"></div>
                  </div>
                  <span class="text-xs font-mono text-slate-600">{{ Math.round(getUtilization(license)) }}%</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </MainLayout>
</template>

<script setup lang="ts">
import { ref, onMounted, watch, computed, onBeforeUnmount, Teleport } from 'vue'
import { useRouter } from 'vue-router'
import MainLayout from '@/components/MainLayout.vue'
import { softwareService } from '@/services/software'

const router = useRouter()
const searchQuery = ref('')
const successMessage = ref('')
const isLoading = ref(false)
const openDropdownId = ref<string | null>(null)
const dropdownPosition = ref({ top: '0px', left: '0px' })
const allLicenses = ref<any[]>([])

// Filters
const filters = ref({
  status: '',
  vendor: ''
})

// Load licenses from API
const loadLicenses = async () => {
  try {
    isLoading.value = true
    const response = await softwareService.getAll()
    allLicenses.value = response.data || []
  } catch (error) {
    console.error('Failed to load licenses:', error)
  } finally {
    isLoading.value = false
  }
}

// Computed filtered licenses
const licenses = computed(() => {
  let filtered = allLicenses.value

  // Apply search
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(license =>
      license.name.toLowerCase().includes(query) ||
      license.vendor.toLowerCase().includes(query) ||
      license.description?.toLowerCase().includes(query)
    )
  }

  // Apply status filter
  if (filters.value.status) {
    filtered = filtered.filter(license => license.status === filters.value.status)
  }

  // Apply vendor filter
  if (filters.value.vendor) {
    filtered = filtered.filter(license => license.vendor === filters.value.vendor)
  }

  return filtered
})

const getUtilization = (license: any) => {
  if (!license.total_seats) return 0
  return (license.assigned_count / license.total_seats) * 100
}

const getUtilizationClass = (utilization: number) => {
  if (utilization >= 90) return 'bg-red-500'
  if (utilization >= 70) return 'bg-amber-500'
  if (utilization >= 50) return 'bg-blue-500'
  return 'bg-teal-500'
}

const formatStatus = (status: string) => {
  const map: Record<string, string> = {
    active: 'Active',
    expired: 'Expired',
    cancelled: 'Cancelled',
    future: 'Future'
  }
  return map[status] || status
}

const getStatusClass = (status: string) => {
  const map: Record<string, string> = {
    active: 'bg-teal-50 text-teal-700 border-teal-200',
    expired: 'bg-red-100 text-red-800 border-red-200',
    cancelled: 'bg-slate-100 text-slate-700 border-slate-300',
    future: 'bg-purple-50 text-purple-700 border-purple-200'
  }
  return map[status] || 'bg-slate-100 text-slate-700 border-slate-300'
}

const getDropdownPosition = (event: MouseEvent) => {
  const buttonEl = event.currentTarget as HTMLElement
  if (!buttonEl) return { top: '0px', left: '0px' }
  
  const rect = buttonEl.getBoundingClientRect()
  const dropdownWidth = 192
  const dropdownHeight = 120
  
  let top = rect.bottom + 8
  let left = rect.right - dropdownWidth
  
  if (top + dropdownHeight > window.innerHeight) {
    top = rect.top - dropdownHeight - 8
  }
  
  if (left < 8) left = 8
  if (left + dropdownWidth > window.innerWidth - 8) {
    left = window.innerWidth - dropdownWidth - 8
  }
  
  return { top: `${top}px`, left: `${left}px` }
}

const toggleDropdown = (licenseId: string, event: MouseEvent) => {
  if (openDropdownId.value === licenseId) {
    openDropdownId.value = null
  } else {
    openDropdownId.value = licenseId
    dropdownPosition.value = getDropdownPosition(event)
  }
}

const closeDropdown = () => {
  openDropdownId.value = null
}

const handleViewLicense = (license: any) => {
  closeDropdown()
  router.push(`/software/${license.id}`)
}

const handleEditLicense = (license: any) => {
  closeDropdown()
  router.push(`/software/${license.id}/edit`)
}

const handleDeleteLicense = async (license: any) => {
  closeDropdown()
  if (!confirm(`Are you sure you want to delete "${license.name}"?`)) return

  try {
    await softwareService.delete(license.id)
    successMessage.value = `License "${license.name}" has been deleted successfully.`
    setTimeout(() => { successMessage.value = '' }, 5000)
    await loadLicenses()
  } catch (error) {
    console.error('Failed to delete license:', error)
    alert('Failed to delete license. Please try again.')
  }
}

const handleClickOutside = (event: MouseEvent) => {
  const target = event.target as HTMLElement
  if (!target.closest('[class*="relative"]') && !target.closest('[class*="fixed"]')) {
    closeDropdown()
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
  loadLicenses()
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>
