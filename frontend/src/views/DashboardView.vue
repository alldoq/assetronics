<template>
  <MainLayout>
    <div v-if="loading" class="flex items-center justify-center py-12">
      <div class="text-center">
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-accent-blue"></div>
        <p class="text-slate-500 mt-4">Loading dashboard...</p>
      </div>
    </div>

    <div v-else-if="error" class="bg-red-50 border border-red-200 rounded-lg p-6 text-center">
      <p class="text-red-800 font-medium">{{ error }}</p>
      <button
        @click="loadDashboard"
        class="mt-4 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
      >
        Try again
      </button>
    </div>

    <div v-else-if="dashboardData">
      <EmployeeDashboard
        v-if="dashboardRole === 'employee'"
        :data="dashboardData as EmployeeDashboard"
      />
      <ManagerDashboard
        v-else-if="dashboardRole === 'manager'"
        :data="dashboardData as ManagerDashboard"
      />
      <AdminDashboard
        v-else-if="dashboardRole === 'admin' || dashboardRole === 'super_admin'"
        :data="dashboardData as AdminDashboard"
      />
      <div v-else class="bg-yellow-50 border border-yellow-200 rounded-lg p-6 text-center">
        <p class="text-yellow-800">Unknown role: {{ dashboardRole }}</p>
      </div>
    </div>
  </MainLayout>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import MainLayout from '@/components/MainLayout.vue'
import EmployeeDashboard from '@/components/dashboard/EmployeeDashboard.vue'
import ManagerDashboard from '@/components/dashboard/ManagerDashboard.vue'
import AdminDashboard from '@/components/dashboard/AdminDashboard.vue'
import { dashboardService, type EmployeeDashboard as EmployeeDashboardType, type ManagerDashboard as ManagerDashboardType, type AdminDashboard as AdminDashboardType } from '@/services/dashboard'

// Type aliases to avoid confusion
type EmployeeDashboard = EmployeeDashboardType
type ManagerDashboard = ManagerDashboardType
type AdminDashboard = AdminDashboardType

const authStore = useAuthStore()

const loading = ref(true)
const error = ref<string | null>(null)
const dashboardData = ref<EmployeeDashboard | ManagerDashboard | AdminDashboard | null>(null)
const dashboardRole = ref<string | null>(null)

const loadDashboard = async () => {
  loading.value = true
  error.value = null

  try {
    const response = await dashboardService.getDashboard()
    dashboardData.value = response.data
    dashboardRole.value = response.role
  } catch (err: any) {
    console.error('Failed to load dashboard:', err)
    error.value = err.response?.data?.error?.message || 'Failed to load dashboard. Please try again.'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadDashboard()
})
</script>
