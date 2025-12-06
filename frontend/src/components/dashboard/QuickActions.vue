<template>
  <div class="bg-white border border-slate-100 rounded-xl p-5 shadow-soft mb-6">
    <div class="flex items-center justify-between mb-4">
      <h3 class="text-sm font-semibold text-slate-700 uppercase tracking-wider">Quick Actions</h3>
      <span class="text-xs text-slate-400">Common tasks</span>
    </div>
    <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
      <button
        v-for="action in actions"
        :key="action.label"
        class="flex flex-col items-center gap-2 p-4 rounded-xl border border-slate-100 hover:border-accent-blue hover:bg-blue-50/50 transition-all duration-200 group"
        @click="handleAction(action.action)"
      >
        <div :class="['w-10 h-10 rounded-xl flex items-center justify-center transition-all duration-200', action.bgClass, 'group-hover:scale-110']">
          <component :is="action.icon" :class="['w-5 h-5', action.iconClass]" />
        </div>
        <span class="text-xs font-medium text-slate-700 text-center">{{ action.label }}</span>
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { h, type Component } from 'vue'

interface Props {
  role?: 'admin' | 'manager' | 'employee'
}

const props = withDefaults(defineProps<Props>(), {
  role: 'admin'
})

const emit = defineEmits<{
  action: [actionName: string]
}>()

const handleAction = (actionName: string) => {
  emit('action', actionName)
}

// Icon components
const AddAssetIcon: Component = (props: any) => h('svg', { ...props, fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M12 6v6m0 0v6m0-6h6m-6 0H6' })
)

const WorkflowIcon: Component = (props: any) => h('svg', { ...props, fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2' })
)

const UserAddIcon: Component = (props: any) => h('svg', { ...props, fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z' })
)

const ReportIcon: Component = (props: any) => h('svg', { ...props, fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z' })
)

const SettingsIcon: Component = (props: any) => h('svg', { ...props, fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z' }),
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M15 12a3 3 0 11-6 0 3 3 0 016 0z' })
)

const SearchIcon: Component = (props: any) => h('svg', { ...props, fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z' })
)

const actions = [
  {
    label: 'Add Asset',
    action: 'add-asset',
    icon: AddAssetIcon,
    bgClass: 'bg-blue-50',
    iconClass: 'text-blue-600'
  },
  {
    label: 'New Workflow',
    action: 'new-workflow',
    icon: WorkflowIcon,
    bgClass: 'bg-purple-50',
    iconClass: 'text-purple-600'
  },
  {
    label: 'Invite User',
    action: 'invite-user',
    icon: UserAddIcon,
    bgClass: 'bg-green-50',
    iconClass: 'text-green-600'
  },
  {
    label: 'Generate Report',
    action: 'generate-report',
    icon: ReportIcon,
    bgClass: 'bg-orange-50',
    iconClass: 'text-orange-600'
  },
  {
    label: 'Search Assets',
    action: 'search-assets',
    icon: SearchIcon,
    bgClass: 'bg-cyan-50',
    iconClass: 'text-cyan-600'
  },
  {
    label: 'Settings',
    action: 'settings',
    icon: SettingsIcon,
    bgClass: 'bg-slate-50',
    iconClass: 'text-slate-600'
  }
]
</script>
