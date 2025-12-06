<template>
  <div class="space-y-6">
    <!-- Header section -->
    <div class="bg-gradient-to-r from-[#1a2342] via-[#243156] to-[#2d7dd2] rounded-2xl p-6 shadow-lg relative overflow-hidden">
      <div class="absolute inset-0 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHZpZXdCb3g9IjAgMCA2MCA2MCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48ZyBmaWxsPSJub25lIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiPjxnIGZpbGw9IiNmZmZmZmYiIGZpbGwtb3BhY2l0eT0iMC4wMyI+PHBhdGggZD0iTTM2IDM0djZoNnYtNmgtNnptMCAwdi02aC02djZoNnoiLz48L2c+PC9nPjwvc3ZnPg==')] opacity-50"></div>
      <div class="relative z-10 flex items-center justify-between">
        <div>
          <div class="inline-flex items-center gap-2 px-3 py-1 bg-white/10 backdrop-blur-sm rounded-full border border-white/20 text-white text-xs font-medium tracking-wide mb-3">
            <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
            Personal overview
          </div>
          <h1 class="text-2xl font-semibold text-white mb-2 font-poppins">
            Welcome back, {{ data.employee.name }}
          </h1>
          <p class="text-blue-100/80 text-sm">{{ data.employee.job_title }} - {{ data.employee.department }}</p>
        </div>
        <div class="hidden md:flex items-center gap-3">
          <div class="text-right text-white/70 text-sm">
            <p class="font-medium text-white">{{ new Date().toLocaleDateString('en-US', { weekday: 'long' }) }}</p>
            <p>{{ new Date().toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' }) }}</p>
          </div>
          <div class="w-px h-10 bg-white/20"></div>
          <div class="w-12 h-12 bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl flex items-center justify-center">
            <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
          </div>
        </div>
      </div>
    </div>

    <!-- Stats section -->
    <div>
      <div class="flex items-center gap-2 mb-4">
        <h2 class="text-lg font-semibold text-slate-800 font-poppins">Summary</h2>
        <div class="flex-1 h-px bg-slate-200"></div>
      </div>
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
        <KpiCard
          title="My assets"
          :value="data.stats.total_assets"
          :icon="BoxIcon"
          icon-color="blue"
        />
        <KpiCard
          title="Active workflows"
          :value="data.stats.active_workflows"
          :icon="WorkflowIcon"
          icon-color="purple"
        />
        <KpiCard
          title="Pending tasks"
          :value="data.stats.pending_tasks"
          :icon="TaskIcon"
          icon-color="orange"
        />
      </div>
    </div>

    <!-- Assets and workflows section -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <AssetList :assets="data.my_assets" title="My assets" />
      <WorkflowList :workflows="data.my_workflows" title="My workflows" />
    </div>

    <!-- Recent activity section -->
    <ActivityFeed :activities="data.recent_activity" />
  </div>
</template>

<script setup lang="ts">
import { h, type Component } from 'vue'
import type { EmployeeDashboard } from '@/services/dashboard'
import KpiCard from './KpiCard.vue'
import AssetList from './AssetList.vue'
import WorkflowList from './WorkflowList.vue'
import ActivityFeed from './ActivityFeed.vue'

interface Props {
  data: EmployeeDashboard
}

defineProps<Props>()

// Icon components
const BoxIcon: Component = (props: any) => h('svg', { ...props, fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4' })
)

const WorkflowIcon: Component = (props: any) => h('svg', { ...props, fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4' })
)

const TaskIcon: Component = (props: any) => h('svg', { ...props, fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z' })
)
</script>
