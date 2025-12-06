<template>
  <div class="space-y-6">
    <!-- Header section -->
    <div class="bg-gradient-to-r from-[#1a2342] via-[#243156] to-[#2d7dd2] rounded-2xl p-6 shadow-lg relative overflow-hidden">
      <div class="absolute inset-0 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHZpZXdCb3g9IjAgMCA2MCA2MCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48ZyBmaWxsPSJub25lIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiPjxnIGZpbGw9IiNmZmZmZmYiIGZpbGwtb3BhY2l0eT0iMC4wMyI+PHBhdGggZD0iTTM2IDM0djZoNnYtNmgtNnptMCAwdi02aC02djZoNnoiLz48L2c+PC9nPjwvc3ZnPg==')] opacity-50"></div>
      <div class="relative z-10 flex items-center justify-between">
        <div>
          <div class="inline-flex items-center gap-2 px-3 py-1 bg-white/10 backdrop-blur-sm rounded-full border border-white/20 text-white text-xs font-medium tracking-wide mb-3">
            <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
            Team overview
          </div>
          <h1 class="text-2xl font-semibold text-white mb-2 font-poppins">
            Team dashboard
          </h1>
          <p class="text-blue-100/80 text-sm">{{ data.manager.department }} - {{ data.manager.name }}</p>
        </div>
        <div class="hidden md:flex items-center gap-3">
          <div class="text-right text-white/70 text-sm">
            <p class="font-medium text-white">{{ new Date().toLocaleDateString('en-US', { weekday: 'long' }) }}</p>
            <p>{{ new Date().toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' }) }}</p>
          </div>
          <div class="w-px h-10 bg-white/20"></div>
          <div class="w-12 h-12 bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl flex items-center justify-center">
            <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
            </svg>
          </div>
        </div>
      </div>
    </div>

    <!-- Team stats section -->
    <div>
      <div class="flex items-center gap-2 mb-4">
        <h2 class="text-lg font-semibold text-slate-800 font-poppins">Team summary</h2>
        <div class="flex-1 h-px bg-slate-200"></div>
      </div>
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
        <KpiCard
          title="Team size"
          :value="data.team_overview.team_size"
          :icon="TeamIcon"
          icon-color="blue"
        />
        <KpiCard
          title="Total assets"
          :value="data.team_overview.total_assets"
          :icon="BoxIcon"
          icon-color="teal"
        />
        <KpiCard
          title="Active workflows"
          :value="data.team_overview.active_workflows"
          :icon="WorkflowIcon"
          icon-color="purple"
        />
      </div>
    </div>

    <!-- Key metrics section -->
    <div>
      <div class="flex items-center gap-2 mb-4">
        <h2 class="text-lg font-semibold text-slate-800 font-poppins">Key metrics</h2>
        <div class="flex-1 h-px bg-slate-200"></div>
      </div>
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <KpiCard
          title="Utilization"
          :value="data.key_metrics.team_utilization"
          format="percent"
          :icon="ChartIcon"
          icon-color="blue"
        />
        <KpiCard
          title="Onboarding rate"
          :value="data.key_metrics.onboarding_completion_rate"
          format="percent"
          :icon="CheckIcon"
          icon-color="green"
        />
        <KpiCard
          title="Time to equipment"
          :value="`${data.key_metrics.avg_time_to_equipment}d`"
          :icon="ClockIcon"
          icon-color="orange"
        />
        <KpiCard
          title="Assets per employee"
          :value="data.key_metrics.assets_per_employee.toFixed(1)"
          :icon="BoxIcon"
          icon-color="teal"
        />
      </div>
    </div>

    <!-- Charts section -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <div class="bg-white border border-slate-200/60 rounded-xl p-5 shadow-sm">
        <h3 class="text-sm font-semibold text-slate-700 mb-3 uppercase tracking-wider">Asset distribution</h3>
        <div class="h-[280px]">
          <BarChart
            :labels="assetCategoryLabels"
            :data="assetCategoryData"
            label="Assets"
            color="#2d7dd2"
          />
        </div>
      </div>
      <div class="bg-white border border-slate-200/60 rounded-xl p-5 shadow-sm">
        <h3 class="text-sm font-semibold text-slate-700 mb-3 uppercase tracking-wider">Workflow status</h3>
        <div class="h-[280px]">
          <DonutChart
            :labels="workflowTypeLabels"
            :data="workflowTypeData"
            :colors="['#10b981', '#f59e0b', '#ef4444', '#3b82f6', '#06b6d4']"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { h, computed, type Component } from 'vue'
import type { ManagerDashboard } from '@/services/dashboard'
import KpiCard from './KpiCard.vue'
import DonutChart from './charts/DonutChart.vue'
import BarChart from './charts/BarChart.vue'

interface Props {
  data: ManagerDashboard
}

const props = defineProps<Props>()

// Asset distribution chart data
const assetCategoryLabels = computed(() => {
  return props.data.asset_distribution.map(item =>
    item.category.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
  )
})

const assetCategoryData = computed(() => {
  return props.data.asset_distribution.map(item => item.count)
})

// Workflow status chart data
const workflowTypeLabels = computed(() => {
  return props.data.workflow_status.map(item =>
    item.workflow_type.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
  )
})

const workflowTypeData = computed(() => {
  return props.data.workflow_status.map(item => item.count)
})

// Icon components
const TeamIcon: Component = (props: any) => h('svg', { ...props, fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z' })
)

const BoxIcon: Component = (props: any) => h('svg', { ...props, fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4' })
)

const WorkflowIcon: Component = (props: any) => h('svg', { ...props, fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4' })
)

const ChartIcon: Component = (props: any) => h('svg', { ...props, fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z' })
)

const CheckIcon: Component = (props: any) => h('svg', { ...props, fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z' })
)

const ClockIcon: Component = (props: any) => h('svg', { ...props, fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z' })
)
</script>
