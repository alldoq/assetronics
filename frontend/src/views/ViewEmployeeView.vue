<template>
  <MainLayout>
    <div class="max-w-7xl mx-auto">
      <!-- Header -->
      <div class="mb-6 flex justify-between items-center">
        <div>
          <div class="flex items-center gap-2 mb-1">
            <router-link to="/employees" class="text-slate-500 hover:text-primary-dark">Employees</router-link>
            <span class="text-slate-400">/</span>
            <span class="text-slate-900 font-medium">Details</span>
          </div>
          <h1 class="text-3xl font-bold text-primary-dark" v-if="employee">
            {{ employee.first_name }} {{ employee.last_name }}
          </h1>
        </div>
        <div class="flex gap-3">
          <button @click="handleDelete" class="px-4 py-2 btn-brand-danger">
            Delete
          </button>
          <button @click="$router.push(`/employees/${employeeId}/edit`)" class="px-4 py-2 btn-brand-primary">
            Edit employee
          </button>
        </div>
      </div>

      <!-- Loading State -->
      <div v-if="isLoading" class="bg-white border border-border-light rounded-2xl p-8 text-center">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-accent-blue mx-auto mb-4"></div>
        <p class="text-slate-600">Loading employee details...</p>
      </div>

      <!-- Content -->
      <div v-else-if="employee" class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        <!-- Left Column: Info Cards -->
        <div class="lg:col-span-1 space-y-6">
          <!-- Profile Card -->
          <div class="bg-white border border-border-light rounded-2xl p-6">
            <div class="flex items-center gap-4 mb-6">
              <div v-if="employee.custom_fields?.photo_url" class="w-16 h-16 rounded-full overflow-hidden border border-slate-200">
                <img :src="employee.custom_fields.photo_url" alt="Employee Photo" class="w-full h-full object-cover">
              </div>
              <div v-else class="w-16 h-16 rounded-full bg-accent-blue flex items-center justify-center text-primary-dark font-bold text-2xl">
                {{ getInitials(employee) }}
              </div>
              <div>
                <h2 class="text-lg font-bold text-primary-dark">{{ employee.first_name }} {{ employee.last_name }}</h2>
                <p class="text-slate-600 text-sm">{{ employee.job_title || 'No Job Title' }}</p>
                <div class="mt-1">
                  <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium" :class="getStatusClass(employee.employment_status)">
                    {{ formatStatus(employee.employment_status) }}
                  </span>
                </div>
              </div>
            </div>
            
            <div class="space-y-4 border-t border-slate-100 pt-4">
              <div>
                <label class="text-xs font-bold text-slate-500 uppercase tracking-wider">Email</label>
                <p class="text-slate-900 break-all">{{ employee.email }}</p>
              </div>
              <div v-if="employee.phone">
                <label class="text-xs font-bold text-slate-500 uppercase tracking-wider">Phone</label>
                <p class="text-slate-900">{{ employee.phone }}</p>
              </div>
              <div v-if="employee.department">
                <label class="text-xs font-bold text-slate-500 uppercase tracking-wider">Department</label>
                <p class="text-slate-900">{{ employee.department }}</p>
              </div>
              <div v-if="employee.employee_id">
                <label class="text-xs font-bold text-slate-500 uppercase tracking-wider">Employee ID</label>
                <p class="text-slate-900">{{ employee.employee_id }}</p>
              </div>
              <div v-if="employee.hire_date">
                <label class="text-xs font-bold text-slate-500 uppercase tracking-wider">Hire date</label>
                <p class="text-slate-900">{{ formatDate(employee.hire_date) }}</p>
              </div>
            </div>
          </div>

          <!-- Metadata Card -->
          <div v-if="displayableCustomFields && Object.keys(displayableCustomFields).length > 0" class="bg-white border border-border-light rounded-2xl p-6">
            <h3 class="text-lg font-bold text-primary-dark mb-4">Additional information</h3>
            <div class="space-y-4">
              <div v-for="(value, key) in displayableCustomFields" :key="key">
                <label class="text-xs font-bold text-slate-500 uppercase tracking-wider">{{ formatFieldName(String(key)) }}</label>
                <p class="text-slate-900">{{ value }}</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Right Column: Assets & Activity -->
        <div class="lg:col-span-2 space-y-6">
          
          <!-- Assigned Assets -->
          <div class="bg-white border border-border-light rounded-2xl p-6">
            <h3 class="text-lg font-bold text-primary-dark mb-4">Assigned assets</h3>
            
            <div v-if="assetsLoading" class="text-center py-4">
              <div class="animate-spin rounded-full h-6 w-6 border-b-2 border-accent-blue mx-auto"></div>
            </div>

            <div v-else-if="assets.length > 0" class="overflow-x-auto">
              <table class="w-full">
                <thead>
                  <tr class="text-left text-xs font-medium text-slate-500 uppercase tracking-wider border-b border-slate-100">
                    <th class="pb-3 pl-2">Asset tag</th>
                    <th class="pb-3">Name</th>
                    <th class="pb-3">Category</th>
                    <th class="pb-3">Date assigned</th>
                    <th class="pb-3">Actions</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-50">
                  <tr v-for="asset in assets" :key="asset.id" class="text-sm">
                    <td class="py-3 pl-2 font-medium text-primary-dark">{{ asset.asset_tag || 'N/A' }}</td>
                    <td class="py-3 text-slate-700">{{ asset.name }}</td>
                    <td class="py-3 text-slate-600">{{ formatCategory(asset.category) }}</td>
                    <td class="py-3 text-slate-600">{{ formatDate(asset.assigned_at) }}</td>
                    <td class="py-3">
                      <router-link :to="`/assets/${asset.id}`" class="text-accent-blue-700 hover:text-accent-blue-800 font-medium">
                        View
                      </router-link>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <div v-else class="text-center py-8 text-slate-500 bg-slate-50 rounded-lg border border-slate-100 border-dashed">
              No assets currently assigned.
            </div>
          </div>

          <!-- Notes -->
          <div v-if="employee.notes" class="bg-white border border-border-light rounded-2xl p-6">
            <h3 class="text-lg font-bold text-primary-dark mb-4">Notes</h3>
            <p class="text-slate-600 whitespace-pre-line">{{ employee.notes }}</p>
          </div>

        </div>
      </div>
    </div>
  </MainLayout>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import MainLayout from '@/components/MainLayout.vue'
import { employeesService, type Employee } from '@/services/employees'

const route = useRoute()
const router = useRouter()
const employeeId = ref<string>(route.params.id as string)

const employee = ref<Employee | null>(null)
const assets = ref<any[]>([])
const isLoading = ref(true)
const assetsLoading = ref(false)

// Filter out photo_url from custom fields display
const displayableCustomFields = computed(() => {
  if (!employee.value?.custom_fields) return {}

  const { photo_url, ...rest } = employee.value.custom_fields
  return rest
})

const formatFieldName = (fieldName: string): string => {
  return fieldName
    .split('_')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ')
}

const getInitials = (emp: Employee) => {
  return `${emp.first_name.charAt(0)}${emp.last_name.charAt(0)}`.toUpperCase()
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

const formatCategory = (cat: string) => {
  return cat ? cat.split('_').map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(' ') : 'N/A'
}

const formatDate = (dateString?: string) => {
  if (!dateString) return 'N/A'
  return new Date(dateString).toLocaleDateString()
}

const loadData = async () => {
  isLoading.value = true
  try {
    employee.value = await employeesService.getById(employeeId.value)
    
    // Load assets separately
    assetsLoading.value = true
    try {
      assets.value = await employeesService.getAssets(employeeId.value)
    } catch (e) {
      console.warn('Failed to load employee assets', e)
    } finally {
      assetsLoading.value = false
    }

  } catch (error) {
    console.error('Failed to load employee:', error)
    alert('Failed to load employee.')
    router.push('/employees')
  } finally {
    isLoading.value = false
  }
}

const handleDelete = async () => {
  if (!confirm('Are you sure you want to delete this employee? This action cannot be undone.')) return
  
  try {
    await employeesService.delete(employeeId.value)
    router.push('/employees')
  } catch (error) {
    console.error('Failed to delete employee:', error)
    alert('Failed to delete employee. They may have assets assigned.')
  }
}

onMounted(() => {
  loadData()
})
</script>
