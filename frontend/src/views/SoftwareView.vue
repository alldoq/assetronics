<template>
  <MainLayout>
    <div class="max-w-6xl mx-auto">
      <!-- Header -->
      <div class="mb-8 flex justify-between items-end">
        <div>
          <h1 class="text-3xl font-bold text-primary-dark">Software Licenses</h1>
          <p class="text-slate-600 mt-1">Manage SaaS subscriptions and track usage</p>
        </div>
        <div class="flex gap-3">
          <router-link 
            to="/reports/license-reclamation"
            class="px-4 py-2 text-sm font-medium text-primary-dark bg-white border border-slate-300 rounded-md hover:bg-slate-50 transition-colors"
          >
            Reclamation Report
          </router-link>
          <button 
            class="px-4 py-2 text-sm font-medium text-white bg-primary-dark rounded-md hover:bg-primary-navy transition-colors"
          >
            Add License
          </button>
        </div>
      </div>

      <!-- Stats Overview -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
        <div class="bg-white p-5 rounded-lg border border-slate-200 shadow-sm">
          <div class="text-sm text-slate-500 font-medium">Total Spend (Annual)</div>
          <div class="text-2xl font-bold text-primary-dark mt-1">$482,000</div>
          <div class="text-xs text-emerald-600 mt-1 flex items-center">
            <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"></path></svg>
            +12% vs last year
          </div>
        </div>
        <div class="bg-white p-5 rounded-lg border border-slate-200 shadow-sm">
          <div class="text-sm text-slate-500 font-medium">Active Licenses</div>
          <div class="text-2xl font-bold text-primary-dark mt-1">42</div>
        </div>
        <div class="bg-white p-5 rounded-lg border border-slate-200 shadow-sm">
          <div class="text-sm text-slate-500 font-medium">Unused Seats</div>
          <div class="text-2xl font-bold text-amber-600 mt-1">158</div>
          <div class="text-xs text-slate-500 mt-1">Potential savings: $12k/mo</div>
        </div>
        <div class="bg-white p-5 rounded-lg border border-slate-200 shadow-sm">
          <div class="text-sm text-slate-500 font-medium">Upcoming Renewals</div>
          <div class="text-2xl font-bold text-primary-dark mt-1">3</div>
          <div class="text-xs text-slate-500 mt-1">Next 30 days</div>
        </div>
      </div>

      <!-- License Table -->
      <div class="bg-white border border-slate-200 rounded-lg shadow-sm overflow-hidden">
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-slate-200">
            <thead class="bg-slate-50">
              <tr>
                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Application</th>
                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Vendor</th>
                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Seats</th>
                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Annual Cost</th>
                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Renewal</th>
                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Status</th>
                <th scope="col" class="relative px-6 py-3"><span class="sr-only">Actions</span></th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-slate-200">
              <tr v-for="license in licenses" :key="license.id" class="hover:bg-slate-50 transition-colors">
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="flex items-center">
                    <div class="flex-shrink-0 h-10 w-10 bg-indigo-50 text-indigo-600 rounded-lg flex items-center justify-center font-bold text-lg">
                      {{ license.name.charAt(0) }}
                    </div>
                    <div class="ml-4">
                      <div class="text-sm font-medium text-primary-dark">{{ license.name }}</div>
                      <div class="text-xs text-slate-500">{{ license.description }}</div>
                    </div>
                  </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-600">{{ license.vendor }}</td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm text-primary-dark">{{ license.assigned_count }} / {{ license.total_seats }}</div>
                  <div class="w-full bg-slate-200 rounded-full h-1.5 mt-1 max-w-[80px]">
                    <div class="bg-accent-blue h-1.5 rounded-full" :style="`width: ${(license.assigned_count / license.total_seats) * 100}%`"></div>
                  </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-primary-dark font-medium">${{ license.annual_cost.toLocaleString() }}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-600">{{ license.renewal_date }}</td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-teal-100 text-teal-800">
                    Active
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  <button class="text-indigo-600 hover:text-indigo-900">Edit</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </MainLayout>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import MainLayout from '@/components/MainLayout.vue'

// Mock Data for MVP
const licenses = ref([
  {
    id: 1,
    name: 'Salesforce Sales Cloud',
    description: 'Enterprise CRM License',
    vendor: 'Salesforce',
    total_seats: 150,
    assigned_count: 142,
    annual_cost: 285000,
    renewal_date: '2025-12-31'
  },
  {
    id: 2,
    name: 'Zoom Pro',
    description: 'Video Conferencing',
    vendor: 'Zoom Video Communications',
    total_seats: 300,
    assigned_count: 210,
    annual_cost: 54000,
    renewal_date: '2025-06-15'
  },
  {
    id: 3,
    name: 'Slack Enterprise Grid',
    description: 'Messaging Platform',
    vendor: 'Slack Technologies',
    total_seats: 400,
    assigned_count: 385,
    annual_cost: 144000,
    renewal_date: '2026-01-01'
  },
  {
    id: 4,
    name: 'Adobe Creative Cloud',
    description: 'All Apps Plan',
    vendor: 'Adobe',
    total_seats: 50,
    assigned_count: 12, // Low usage!
    annual_cost: 48000,
    renewal_date: '2025-09-01'
  }
])
</script>
