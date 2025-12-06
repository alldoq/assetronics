<template>
  <MainLayout>
    <div>
      <!-- Page header -->
      <div class="mb-6">
        <h1 class="text-3xl font-bold text-primary-dark">Employees</h1>
        <p class="text-slate-600 mt-1">Manage your team and employee assignments</p>
      </div>

      <!-- Success message -->
      <div v-if="successMessage" class="alert-success mb-6">
        {{ successMessage }}
      </div>

      <!-- Actions bar -->
      <div class="flex flex-col sm:flex-row gap-4 mb-6">
        <div class="flex-1">
          <input
            v-model="searchQuery"
            type="search"
            placeholder="Search employees..."
            class="input-refined w-full"
          />
        </div>
        <button 
          @click="$router.push('/employees/add')" 
          class="px-6 py-3 btn-brand-primary whitespace-nowrap"
        >
          <svg class="w-5 h-5 mr-2 inline-block" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          Add employee
        </button>
      </div>

      <!-- Loading State -->
      <div v-if="isLoading" class="text-center py-12">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-accent-blue mx-auto mb-4"></div>
        <p class="text-slate-600">Loading employees...</p>
      </div>

      <!-- Employees grid -->
      <div v-else-if="filteredEmployees.length > 0" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <div 
          v-for="employee in filteredEmployees" 
          :key="employee.id" 
          class="bg-white border border-slate-200 rounded-lg p-6 hover:border-accent-blue transition-all duration-200 shadow-subtle"
        >
          <div class="flex items-start space-x-4">
            <div class="flex-shrink-0">
              <div v-if="employee.custom_fields?.photo_url" class="w-12 h-12 rounded-full overflow-hidden border border-slate-200">
                <img :src="employee.custom_fields.photo_url" alt="" class="w-full h-full object-cover">
              </div>
              <div v-else class="w-12 h-12 rounded-full bg-accent-blue flex items-center justify-center text-primary-dark font-bold text-lg">
                {{ getInitials(employee) }}
              </div>
            </div>
            <div class="flex-1 min-w-0">
              <h3 class="text-sm font-bold text-primary-dark truncate">
                {{ employee.first_name }} {{ employee.last_name }}
              </h3>
              <p class="text-sm text-slate-600 truncate">{{ employee.email }}</p>
              <p class="text-xs text-slate-500 mt-1">
                {{ employee.job_title || 'No Job Title' }}
                <span v-if="employee.department"> • {{ employee.department }}</span>
              </p>
              
              <!-- Status Badge -->
              <div class="mt-2">
                <span
                  class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium"
                  :class="getStatusClass(employee.employment_status)"
                >
                  {{ formatStatus(employee.employment_status) }}
                </span>
              </div>

              <!-- Assets Count -->
              <div v-if="employee.assets_count !== undefined" class="mt-3 flex items-center text-xs text-slate-500">
                <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                </svg>
                <span v-if="employee.assets_count === 0">No assets assigned</span>
                <span v-else-if="employee.assets_count === 1">1 asset assigned</span>
                <span v-else>{{ employee.assets_count }} assets assigned</span>
              </div>
            </div>
          </div>
          <div class="mt-4 flex space-x-2">
            <button
              @click="$router.push(`/employees/${employee.id}`)"
              class="flex-1 px-4 py-2 btn-brand-secondary text-sm"
            >
              View
            </button>
            <button
              @click="$router.push(`/employees/${employee.id}/edit`)"
              class="flex-1 px-4 py-2 btn-brand-secondary text-sm"
            >
              Edit
            </button>
            <div class="relative">
              <button
                @click="toggleDropdown(employee.id, $event)"
                class="px-3 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-accent-blue"
              >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
                </svg>
              </button>

              <!-- Dropdown menu using Teleport -->
              <Teleport to="body">
                <div
                  v-if="openDropdownId === employee.id"
                  :style="dropdownPosition"
                  class="fixed z-[9999] w-48 rounded-lg bg-white shadow-xl ring-1 ring-black ring-opacity-5 focus:outline-none"
                  @click.stop
                >
                  <div class="py-1">
                    <button
                      @click="handleInviteEmployee(employee)"
                      class="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 flex items-center gap-2"
                    >
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                      </svg>
                      Invite to system
                    </button>
                    <button
                      @click="handleAssignAsset(employee)"
                      class="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 flex items-center gap-2"
                    >
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                      </svg>
                      Assign asset
                    </button>
                  </div>
                </div>
              </Teleport>
            </div>
          </div>
        </div>
      </div>

      <!-- Empty state -->
      <div v-else class="col-span-full bg-white border border-slate-200 rounded-lg p-12 text-center shadow-subtle">
        <svg class="w-16 h-16 mx-auto text-slate-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
        </svg>
        <h3 class="text-lg font-medium text-slate-900">No employees found</h3>
        <p class="text-slate-500 mt-1">Get started by adding your first team member.</p>
        <div class="mt-6">
          <button 
            @click="$router.push('/employees/add')" 
            class="px-6 py-3 btn-brand-primary"
          >
            Add employee
          </button>
        </div>
      </div>
    </div>

    <!-- Invite Employee Modal -->
    <InviteEmployeeModal
      v-model="showInviteModal"
      :employee="selectedEmployee"
      @invited="handleEmployeeInvited"
    />

    <!-- Assign Asset Modal -->
    <AssignAssetToEmployeeModal
      v-model="showAssignModal"
      :employee="selectedEmployee"
      @assigned="handleAssetAssigned"
    />
  </MainLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount, Teleport } from 'vue'
import MainLayout from '@/components/MainLayout.vue'
import AssignAssetToEmployeeModal from '@/components/AssignAssetToEmployeeModal.vue'
import InviteEmployeeModal from '@/components/InviteEmployeeModal.vue'
import { employeesService, type Employee } from '@/services/employees'

const employees = ref<Employee[]>([])
const isLoading = ref(true)
const searchQuery = ref('')
const showAssignModal = ref(false)
const showInviteModal = ref(false)
const selectedEmployee = ref<Employee | null>(null)
const successMessage = ref('')
const openDropdownId = ref<string | null>(null)
const dropdownPosition = ref({ top: '0px', left: '0px' })

const filteredEmployees = computed(() => {
  if (!searchQuery.value) return employees.value
  
  const query = searchQuery.value.toLowerCase()
  return employees.value.filter(emp => 
    emp.first_name.toLowerCase().includes(query) ||
    emp.last_name.toLowerCase().includes(query) ||
    emp.email.toLowerCase().includes(query) ||
    (emp.department && emp.department.toLowerCase().includes(query)) ||
    (emp.job_title && emp.job_title.toLowerCase().includes(query))
  )
})

const getInitials = (employee: Employee) => {
  return `${employee.first_name.charAt(0)}${employee.last_name.charAt(0)}`.toUpperCase()
}

const getStatusClass = (status: string) => {
  switch (status) {
    case 'active': return 'bg-teal-100 text-teal-800'
    case 'on_leave': return 'bg-yellow-100 text-yellow-800'
    case 'terminated': return 'bg-red-100 text-red-800'
    default: return 'bg-slate-100 text-slate-800'
  }
}

const formatStatus = (status: string) => {
  return status.split('_').map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(' ')
}

const loadEmployees = async () => {
  isLoading.value = true
  try {
    employees.value = await employeesService.getAll()
  } catch (error) {
    console.error('Failed to load employees:', error)
  } finally {
    isLoading.value = false
  }
}

const getDropdownPosition = (event: MouseEvent) => {
  const buttonEl = event.currentTarget as HTMLElement
  if (!buttonEl) {
    return { top: '0px', left: '0px' }
  }

  const rect = buttonEl.getBoundingClientRect()
  const dropdownWidth = 192 // w-48 = 12rem = 192px
  const dropdownHeight = 96 // Approximate height for two items

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

const toggleDropdown = (employeeId: string, event: MouseEvent) => {
  if (openDropdownId.value === employeeId) {
    openDropdownId.value = null
  } else {
    openDropdownId.value = employeeId
    dropdownPosition.value = getDropdownPosition(event)
  }
}

const closeDropdown = () => {
  openDropdownId.value = null
}

const handleInviteEmployee = (employee: Employee) => {
  closeDropdown()
  selectedEmployee.value = employee
  showInviteModal.value = true
}

const handleEmployeeInvited = async () => {
  await loadEmployees()
  successMessage.value = `User account has been created for ${selectedEmployee.value?.first_name} ${selectedEmployee.value?.last_name}.`
  setTimeout(() => {
    successMessage.value = ''
  }, 5000)
}

const handleAssignAsset = (employee: Employee) => {
  closeDropdown()
  selectedEmployee.value = employee
  showAssignModal.value = true
}

const handleAssetAssigned = async () => {
  await loadEmployees()
  showAssignModal.value = false
  // You can add a success message here if desired
}

// Close dropdown when clicking outside
const handleClickOutside = (event: MouseEvent) => {
  const target = event.target as HTMLElement
  if (!target.closest('[class*="relative"]') && !target.closest('[class*="fixed"]')) {
    closeDropdown()
  }
}

onMounted(() => {
  loadEmployees()
  document.addEventListener('click', handleClickOutside)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>