<template>
  <div class="bg-white border border-slate-200/60 rounded-xl p-5 shadow-sm">
    <h3 class="text-sm font-semibold text-slate-700 mb-4 uppercase tracking-wider">{{ title }}</h3>
    <div v-if="activities && activities.length > 0" class="space-y-2">
      <div
        v-for="activity in activities"
        :key="activity.id"
        class="flex items-start gap-3 p-3 bg-slate-50/50 border border-slate-100 rounded-lg hover:bg-slate-50 transition-colors"
      >
        <div :class="['flex-shrink-0 p-2 rounded-lg', getIconBg(activity.transaction_type)]">
          <component :is="getIcon(activity.transaction_type)" :class="['w-4 h-4', getIconColor(activity.transaction_type)]" />
        </div>
        <div class="flex-1 min-w-0">
          <p class="text-sm text-slate-800 leading-snug">
            <span class="font-medium">{{ activity.asset_name || 'Asset' }}</span>
            <span class="text-slate-500"> was </span>
            <span class="text-slate-600">{{ getActionText(activity.transaction_type) }}</span>
            <span v-if="activity.employee_name" class="font-medium"> {{ activity.employee_name }}</span>
          </p>
          <p class="text-xs text-slate-400 mt-1">
            {{ formatTime(activity.performed_at) }}
          </p>
        </div>
      </div>
    </div>
    <div v-else class="py-8 text-center">
      <p class="text-slate-400 text-sm">No recent activity</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { h, type Component } from 'vue'
import type { Activity } from '@/services/dashboard'

interface Props {
  activities: Activity[]
  title?: string
}

withDefaults(defineProps<Props>(), {
  title: 'Recent activity'
})

const getActionText = (type: string): string => {
  const actions: Record<string, string> = {
    assign: 'assigned to',
    return: 'returned from',
    transfer: 'transferred to',
    repair: 'sent for repair by',
    maintenance: 'scheduled for maintenance by',
    audit: 'audited by',
  }
  return actions[type] || type
}

const getIcon = (type: string): Component => {
  const defaultIcon: Component = (props: any) => h('svg', { ...props, fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
    h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z' })
  )

  const icons: Record<string, Component> = {
    assign: (props: any) => h('svg', { ...props, fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
      h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M12 4v16m8-8H4' })
    ),
    return: (props: any) => h('svg', { ...props, fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
      h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6' })
    ),
    transfer: (props: any) => h('svg', { ...props, fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
      h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4' })
    ),
    repair: (props: any) => h('svg', { ...props, fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
      h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z' })
    ),
  }
  return icons[type] || defaultIcon
}

const getIconBg = (type: string): string => {
  const colors: Record<string, string> = {
    assign: 'bg-green-50',
    return: 'bg-blue-50',
    transfer: 'bg-purple-50',
    repair: 'bg-orange-50',
    maintenance: 'bg-yellow-50',
    audit: 'bg-slate-50',
  }
  return colors[type] || 'bg-slate-50'
}

const getIconColor = (type: string): string => {
  const colors: Record<string, string> = {
    assign: 'text-green-600',
    return: 'text-blue-600',
    transfer: 'text-purple-600',
    repair: 'text-orange-600',
    maintenance: 'text-yellow-600',
    audit: 'text-slate-600',
  }
  return colors[type] || 'text-slate-600'
}

const formatTime = (timestamp: string): string => {
  const date = new Date(timestamp)
  const now = new Date()
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000)

  if (diffInSeconds < 60) return 'Just now'
  if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)} minutes ago`
  if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)} hours ago`
  if (diffInSeconds < 604800) return `${Math.floor(diffInSeconds / 86400)} days ago`

  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}
</script>
