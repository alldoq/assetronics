<template>
  <MainLayout>
    <div class="max-w-6xl mx-auto">
      <div class="mb-8">
        <div class="flex items-center gap-2 mb-2">
          <router-link to="/software" class="text-slate-500 hover:text-slate-700 transition-colors">
            Software
          </router-link>
          <span class="text-slate-400">/</span>
          <h1 class="text-2xl font-bold text-primary-dark">License Reclamation Report</h1>
        </div>
        <p class="text-slate-600">Identify unused licenses that can be reclaimed to save costs.</p>
      </div>

      <!-- Filters -->
      <div class="bg-white p-4 rounded-lg border border-slate-200 mb-6 flex gap-4 items-center">
        <div class="flex items-center gap-2">
          <span class="text-sm font-medium text-slate-700">Inactive for:</span>
          <select class="rounded-md border-slate-300 text-sm focus:ring-accent-blue focus:border-accent-blue">
            <option>30 Days</option>
            <option>60 Days</option>
            <option selected>90 Days</option>
            <option>180 Days</option>
          </select>
        </div>
        <div class="flex-1"></div>
        <button class="px-4 py-2 bg-accent-blue text-white text-sm font-medium rounded-md hover:bg-accent-blue transition-colors">
          Export CSV
        </button>
      </div>

      <!-- Report Table -->
      <div class="bg-white border border-slate-200 rounded-lg shadow-sm overflow-hidden">
        <table class="min-w-full divide-y divide-slate-200">
          <thead class="bg-slate-50">
            <tr>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Employee</th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Software</th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Last Login</th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Days Inactive</th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Est. Monthly Cost</th>
              <th scope="col" class="relative px-6 py-3"><span class="sr-only">Actions</span></th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-slate-200">
            <tr v-for="item in reportItems" :key="item.id" class="hover:bg-slate-50 transition-colors">
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="text-sm font-medium text-primary-dark">{{ item.employee_name }}</div>
                <div class="text-xs text-slate-500">{{ item.employee_email }}</div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="flex items-center">
                  <div class="h-8 w-8 bg-indigo-50 text-indigo-600 rounded flex items-center justify-center font-bold text-sm mr-3">
                    {{ item.license_name.charAt(0) }}
                  </div>
                  <div>
                    <div class="text-sm font-medium text-primary-dark">{{ item.license_name }}</div>
                  </div>
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-600">
                {{ item.last_login }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800">
                  {{ item.days_inactive }} days
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-primary-dark">
                ${{ item.cost }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                <button class="text-red-600 hover:text-red-900 bg-red-50 hover:bg-red-100 px-3 py-1 rounded-md transition-colors">
                  Reclaim
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </MainLayout>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import MainLayout from '@/components/MainLayout.vue'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const reportItems = ref([
  // Mock Data
  { id: 1, employee_name: 'John Doe', employee_email: 'john.doe@example.com', license_name: 'Adobe Creative Cloud', last_login: '2025-08-15', days_inactive: 105, cost: 80 },
  { id: 2, employee_name: 'Jane Smith', employee_email: 'jane.smith@example.com', license_name: 'Salesforce Sales Cloud', last_login: '2025-09-01', days_inactive: 88, cost: 150 },
  { id: 3, employee_name: 'Mike Jones', employee_email: 'mike.jones@example.com', license_name: 'Zoom Pro', last_login: '2025-07-20', days_inactive: 131, cost: 15 },
])

onMounted(async () => {
  // TODO: Fetch real data from /api/v1/reports/license-reclamation
  // const res = await fetch(...)
})
</script>
