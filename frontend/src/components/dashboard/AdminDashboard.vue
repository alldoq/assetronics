<template>
  <div class="space-y-6">
    <!-- Header section -->
    <div class="bg-gradient-to-r from-[#1a2342] via-[#243156] to-[#2d7dd2] rounded-2xl p-6 shadow-lg relative overflow-hidden">
      <div class="absolute inset-0 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHZpZXdCb3g9IjAgMCA2MCA2MCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48ZyBmaWxsPSJub25lIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiPjxnIGZpbGw9IiNmZmZmZmYiIGZpbGwtb3BhY2l0eT0iMC4wMyI+PHBhdGggZD0iTTM2IDM0djZoNnYtNmgtNnptMCAwdi02aC02djZoNnoiLz48L2c+PC9nPjwvc3ZnPg==')] opacity-50"></div>
      <div class="relative z-10 flex items-center justify-between">
        <div>
          <div class="inline-flex items-center gap-2 px-3 py-1 bg-white/10 backdrop-blur-sm rounded-full border border-white/20 text-white text-xs font-medium tracking-wide mb-3">
            <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
            System overview
          </div>
          <h1 class="text-2xl font-semibold text-white mb-2 font-poppins">
            Admin dashboard
          </h1>
          <p class="text-blue-100/80 text-sm max-w-lg">Monitor system-wide metrics, asset utilization, and team performance.</p>
        </div>
        <div class="hidden md:flex items-center gap-3">
          <div class="text-right text-white/70 text-sm">
            <p class="font-medium text-white">{{ new Date().toLocaleDateString('en-US', { weekday: 'long' }) }}</p>
            <p>{{ new Date().toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' }) }}</p>
          </div>
          <div class="w-px h-10 bg-white/20"></div>
          <div class="w-12 h-12 bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl flex items-center justify-center">
            <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
            </svg>
          </div>
        </div>
      </div>
    </div>

    <!-- Alerts -->
    <AlertBanner :alerts="data.alerts" />

    <!-- Asset inventory section -->
    <div>
      <div class="flex items-center gap-2 mb-4">
        <h2 class="text-lg font-semibold text-slate-800 font-poppins">Asset inventory</h2>
        <div class="flex-1 h-px bg-slate-200"></div>
      </div>
      <div class="grid grid-cols-1 lg:grid-cols-5 gap-4">
        <div class="lg:col-span-2 grid grid-cols-2 gap-3">
          <CountCard
            title="Total assets"
            :value="data.asset_inventory.total"
            :icon="TrendingUpIcon"
            icon-color="primary"
            :trend="{
              direction: 'up',
              value: '12.5%',
              label: 'Since last month',
              isPositive: true
            }"
          />
          <CountCard
            title="Assigned"
            :value="data.asset_inventory.by_status.assigned"
            :icon="CheckCircleIcon"
            icon-color="success"
            :trend="{
              direction: 'up',
              value: '8.2%',
              label: 'Since last month',
              isPositive: true
            }"
          />
          <CountCard
            title="In stock"
            :value="data.asset_inventory.by_status.in_stock"
            :icon="BoxIcon"
            icon-color="info"
            :trend="{
              direction: 'down',
              value: '3.1%',
              label: 'Since last month',
              isPositive: false
            }"
          />
          <CountCard
            title="Utilization"
            :value="data.asset_inventory.utilization_rate"
            format="percent"
            :icon="ChartBarIcon"
            icon-color="purple"
            :trend="{
              direction: 'up',
              value: '5.4%',
              label: 'Since last month',
              isPositive: true
            }"
          />
        </div>
        <div class="lg:col-span-3 bg-white border border-slate-200/60 rounded-xl p-5 shadow-sm">
          <h3 class="text-sm font-semibold text-slate-700 mb-3 uppercase tracking-wider">Status distribution</h3>
          <div class="h-[280px]">
            <DonutChart
              :labels="assetStatusLabels"
              :data="assetStatusData"
              :colors="assetStatusColors"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Employee stats section -->
    <div>
      <div class="flex items-center gap-2 mb-4">
        <h2 class="text-lg font-semibold text-slate-800 font-poppins">Team overview</h2>
        <div class="flex-1 h-px bg-slate-200"></div>
      </div>
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <CountCard
          title="Total employees"
          :value="data.employee_status.total"
          :icon="UsersIcon"
          icon-color="info"
          :trend="{
            direction: 'up',
            value: '6.3%',
            label: 'Since last month',
            isPositive: true
          }"
        />
        <CountCard
          title="Active"
          :value="data.employee_status.active"
          :icon="UserCheckIcon"
          icon-color="success"
        />
        <CountCard
          title="New hires (30d)"
          :value="data.employee_status.new_hires"
          :icon="UserPlusIcon"
          icon-color="primary"
          :trend="{
            direction: 'up',
            value: data.employee_status.new_hires.toString(),
            label: 'This month',
            isPositive: true
          }"
        />
        <CountCard
          title="Terminations (30d)"
          :value="data.employee_status.terminations"
          :icon="UserMinusIcon"
          icon-color="danger"
          :trend="{
            direction: 'down',
            value: data.employee_status.terminations.toString(),
            label: 'This month',
            isPositive: true
          }"
        />
      </div>
    </div>

    <!-- Workflow section -->
    <div>
      <div class="flex items-center gap-2 mb-4">
        <h2 class="text-lg font-semibold text-slate-800 font-poppins">Workflow metrics</h2>
        <div class="flex-1 h-px bg-slate-200"></div>
        <div v-if="data.workflow_metrics.overdue > 0" class="px-2.5 py-1 bg-red-50 text-red-600 border border-red-100 rounded-lg text-xs font-semibold">
          {{ data.workflow_metrics.overdue }} overdue
        </div>
      </div>
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div class="bg-white border border-slate-200/60 rounded-xl p-5 shadow-sm">
          <h3 class="text-sm font-semibold text-slate-700 mb-4 uppercase tracking-wider">Active by type</h3>
          <div class="grid grid-cols-2 gap-3">
            <div class="flex items-center gap-3 p-3 bg-blue-50/50 rounded-lg border border-blue-100/50 hover:bg-blue-50 transition-colors">
              <div class="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                <span class="text-lg font-bold text-blue-600 font-poppins">{{ data.workflow_metrics.active_by_type.onboarding }}</span>
              </div>
              <span class="text-sm font-medium text-slate-700">Onboarding</span>
            </div>
            <div class="flex items-center gap-3 p-3 bg-orange-50/50 rounded-lg border border-orange-100/50 hover:bg-orange-50 transition-colors">
              <div class="w-10 h-10 bg-orange-100 rounded-lg flex items-center justify-center">
                <span class="text-lg font-bold text-orange-600 font-poppins">{{ data.workflow_metrics.active_by_type.offboarding }}</span>
              </div>
              <span class="text-sm font-medium text-slate-700">Offboarding</span>
            </div>
            <div class="flex items-center gap-3 p-3 bg-purple-50/50 rounded-lg border border-purple-100/50 hover:bg-purple-50 transition-colors">
              <div class="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
                <span class="text-lg font-bold text-purple-600 font-poppins">{{ data.workflow_metrics.active_by_type.repair }}</span>
              </div>
              <span class="text-sm font-medium text-slate-700">Repair</span>
            </div>
            <div class="flex items-center gap-3 p-3 bg-teal-50/50 rounded-lg border border-teal-100/50 hover:bg-teal-50 transition-colors">
              <div class="w-10 h-10 bg-teal-100 rounded-lg flex items-center justify-center">
                <span class="text-lg font-bold text-teal-600 font-poppins">{{ data.workflow_metrics.active_by_type.maintenance }}</span>
              </div>
              <span class="text-sm font-medium text-slate-700">Maintenance</span>
            </div>
          </div>
        </div>
        <div class="bg-white border border-slate-200/60 rounded-xl p-5 shadow-sm">
          <h3 class="text-sm font-semibold text-slate-700 mb-3 uppercase tracking-wider">Distribution</h3>
          <div class="h-[200px]">
            <BarChart
              :labels="workflowTypeLabels"
              :data="workflowTypeData"
              label="Active workflows"
              color="#2d7dd2"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Integration and activity section -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <div class="bg-white border border-slate-200/60 rounded-xl p-5 shadow-sm">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-sm font-semibold text-slate-700 uppercase tracking-wider">Integration health</h3>
          <div class="flex items-center gap-2 px-2.5 py-1 rounded-lg" :class="data.integration_health.success_rate_24h >= 90 ? 'bg-emerald-50' : 'bg-orange-50'">
            <span class="text-xs text-slate-500">24h</span>
            <span class="text-sm font-semibold" :class="data.integration_health.success_rate_24h >= 90 ? 'text-emerald-600' : 'text-orange-600'">
              {{ data.integration_health.success_rate_24h }}%
            </span>
          </div>
        </div>
        <div v-if="data.integration_health.integrations.length > 0" class="space-y-2">
          <div
            v-for="integration in data.integration_health.integrations"
            :key="integration.id"
            class="flex items-center justify-between p-3 bg-slate-50/50 border border-slate-100 rounded-lg hover:bg-slate-50 transition-colors"
          >
            <div class="flex items-center gap-3">
              <div class="relative flex-shrink-0">
                <div :class="['w-2.5 h-2.5 rounded-full', getIntegrationStatusColor(integration.last_sync_status)]" />
                <div :class="['absolute top-0 left-0 w-2.5 h-2.5 rounded-full animate-ping opacity-75', getIntegrationStatusColor(integration.last_sync_status)]" v-if="integration.last_sync_status === 'success'"></div>
              </div>
              <div class="min-w-0">
                <p class="font-medium text-slate-800 text-sm truncate">{{ integration.name }}</p>
                <p class="text-xs text-slate-500">{{ integration.provider }}</p>
              </div>
            </div>
            <div class="text-right flex-shrink-0">
              <p class="text-sm font-medium text-slate-700">
                {{ integration.last_sync_records_count || 0 }} records
              </p>
              <p class="text-xs text-slate-400">
                {{ formatLastSync(integration.last_sync_at) }}
              </p>
            </div>
          </div>
        </div>
        <div v-else class="py-8 text-center">
          <p class="text-slate-400 text-sm">No integrations configured</p>
        </div>
      </div>

      <ActivityFeed :activities="data.recent_activity" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, h } from 'vue'
import type { AdminDashboard } from '@/services/dashboard'
import CountCard from './CountCard.vue'
import AlertBanner from './AlertBanner.vue'
import ActivityFeed from './ActivityFeed.vue'
import DonutChart from './charts/DonutChart.vue'
import BarChart from './charts/BarChart.vue'

// Icon components
const TrendingUpIcon = h('svg', {
  xmlns: 'http://www.w3.org/2000/svg',
  viewBox: '0 0 28 16.803',
  fill: 'currentColor'
}, h('path', {
  d: 'M29.882,6.868A1.421,1.421,0,0,0,28.595,6h-7a1.4,1.4,0,1,0,0,2.8h3.625L17.4,16.623,12.793,12a1.4,1.4,0,0,0-1.987,0l-8.4,8.4A1.405,1.405,0,1,0,4.4,22.389l7.4-7.418,4.6,4.619a1.4,1.4,0,0,0,1.987,0l8.8-8.817V14.4a1.4,1.4,0,1,0,2.8,0v-7A1.4,1.4,0,0,0,29.882,6.868Z',
  transform: 'translate(-1.994 -6)'
}))

const CheckCircleIcon = h('svg', {
  xmlns: 'http://www.w3.org/2000/svg',
  viewBox: '0 0 24 24',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: '2'
}, h('path', {
  d: 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z'
}))

const BoxIcon = h('svg', {
  xmlns: 'http://www.w3.org/2000/svg',
  viewBox: '0 0 24 24',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: '2'
}, [
  h('path', { d: 'M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4' })
])

const ChartBarIcon = h('svg', {
  xmlns: 'http://www.w3.org/2000/svg',
  viewBox: '0 0 24 24',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: '2'
}, h('path', {
  d: 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z'
}))

const UsersIcon = h('svg', {
  xmlns: 'http://www.w3.org/2000/svg',
  viewBox: '0 0 24 24',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: '2'
}, [
  h('path', { d: 'M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2' }),
  h('circle', { cx: '9', cy: '7', r: '4' }),
  h('path', { d: 'M23 21v-2a4 4 0 00-3-3.87m-4-12a4 4 0 010 7.75' })
])

const UserCheckIcon = h('svg', {
  xmlns: 'http://www.w3.org/2000/svg',
  viewBox: '0 0 24 24',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: '2'
}, [
  h('path', { d: 'M16 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2' }),
  h('circle', { cx: '8.5', cy: '7', r: '4' }),
  h('polyline', { points: '17 11 19 13 23 9' })
])

const UserPlusIcon = h('svg', {
  xmlns: 'http://www.w3.org/2000/svg',
  viewBox: '0 0 24 24',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: '2'
}, [
  h('path', { d: 'M16 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2' }),
  h('circle', { cx: '8.5', cy: '7', r: '4' }),
  h('line', { x1: '20', y1: '8', x2: '20', y2: '14' }),
  h('line', { x1: '23', y1: '11', x2: '17', y2: '11' })
])

const UserMinusIcon = h('svg', {
  xmlns: 'http://www.w3.org/2000/svg',
  viewBox: '0 0 24 24',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: '2'
}, [
  h('path', { d: 'M16 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2' }),
  h('circle', { cx: '8.5', cy: '7', r: '4' }),
  h('line', { x1: '23', y1: '11', x2: '17', y2: '11' })
])

interface Props {
  data: AdminDashboard
}

const props = defineProps<Props>()

// Asset Status Chart Data
const assetStatusLabels = computed(() => {
  const status = props.data.asset_inventory.by_status
  return Object.keys(status)
    .filter(key => status[key as keyof typeof status] > 0)
    .map(key => key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase()))
})

const assetStatusData = computed(() => {
  const status = props.data.asset_inventory.by_status
  return Object.values(status).filter(value => value > 0)
})

const assetStatusColors = computed(() => [
  '#10b981', // in_stock - green
  '#3b82f6', // assigned - blue
  '#f59e0b', // in_repair - amber
  '#64748b', // retired - slate
  '#06b6d4', // on_order - cyan
  '#8b5cf6', // in_transit - purple
  '#ef4444', // lost - red
  '#dc2626'  // stolen - red
])

// Workflow Type Chart Data
const workflowTypeLabels = computed(() => {
  const types = props.data.workflow_metrics.active_by_type
  return Object.keys(types).map(key =>
    key.charAt(0).toUpperCase() + key.slice(1)
  )
})

const workflowTypeData = computed(() => {
  const types = props.data.workflow_metrics.active_by_type
  return Object.values(types)
})

const getIntegrationStatusColor = (status: string | null): string => {
  switch (status) {
    case 'success':
      return 'bg-green-500'
    case 'failed':
    case 'error':
      return 'bg-red-500'
    case 'pending':
    case 'in_progress':
      return 'bg-yellow-500'
    default:
      return 'bg-slate-300'
  }
}

const formatLastSync = (timestamp: string | null): string => {
  if (!timestamp) return 'Never synced'

  const date = new Date(timestamp)
  const now = new Date()
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000)

  if (diffInSeconds < 60) return 'Just now'
  if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)}m ago`
  if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)}h ago`
  if (diffInSeconds < 604800) return `${Math.floor(diffInSeconds / 86400)}d ago`

  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
}
</script>
