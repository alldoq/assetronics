<template>
  <div class="bg-white border border-slate-200/60 rounded-xl p-5 shadow-sm">
    <h3 class="text-sm font-semibold text-slate-700 mb-4 uppercase tracking-wider">{{ title }}</h3>
    <div v-if="workflows && workflows.length > 0" class="space-y-3">
      <div
        v-for="workflow in workflows"
        :key="workflow.id"
        class="p-3 bg-slate-50/50 border border-slate-100 rounded-lg hover:bg-slate-50 transition-colors"
      >
        <div class="flex items-start justify-between mb-3">
          <div class="flex-1 min-w-0">
            <p class="font-medium text-slate-800 text-sm truncate">{{ workflow.title }}</p>
            <div class="flex items-center gap-1.5 mt-1.5">
              <span :class="['px-2 py-0.5 rounded text-xs font-medium', getTypeBadgeClass(workflow.workflow_type)]">
                {{ formatWorkflowType(workflow.workflow_type) }}
              </span>
              <span :class="['px-2 py-0.5 rounded text-xs font-medium', getStatusBadgeClass(workflow.status)]">
                {{ formatStatus(workflow.status) }}
              </span>
            </div>
          </div>
          <div class="text-right flex-shrink-0 ml-2">
            <p class="text-lg font-semibold text-slate-800 font-poppins">{{ workflow.progress }}%</p>
          </div>
        </div>
        <div>
          <div class="flex justify-between text-xs text-slate-500 mb-1.5">
            <span>{{ workflow.completed_steps }}/{{ workflow.total_steps }} steps</span>
            <span v-if="workflow.due_date" :class="getDueDateColor(workflow.due_date)">{{ formatDueDate(workflow.due_date) }}</span>
          </div>
          <div class="w-full bg-slate-200 rounded-full h-1.5 overflow-hidden">
            <div
              :class="['h-1.5 rounded-full transition-all duration-300', getProgressBarClass(workflow.progress)]"
              :style="{ width: `${workflow.progress}%` }"
            />
          </div>
        </div>
      </div>
    </div>
    <div v-else class="py-8 text-center">
      <p class="text-slate-400 text-sm">No active workflows</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Workflow } from '@/services/dashboard'

interface Props {
  workflows: Workflow[]
  title?: string
}

withDefaults(defineProps<Props>(), {
  title: 'My workflows'
})

const formatWorkflowType = (type: string): string => {
  return type.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
}

const formatStatus = (status: string): string => {
  return status.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
}

const formatDueDate = (dateString: string): string => {
  const date = new Date(dateString)
  const now = new Date()
  const diffInDays = Math.floor((date.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))

  if (diffInDays < 0) return 'overdue'
  if (diffInDays === 0) return 'today'
  if (diffInDays === 1) return 'tomorrow'
  if (diffInDays < 7) return `in ${diffInDays} days`

  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
}

const getDueDateColor = (dateString: string): string => {
  const date = new Date(dateString)
  const now = new Date()
  const diffInDays = Math.floor((date.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))

  if (diffInDays < 0) return 'text-red-600 font-bold'
  if (diffInDays <= 2) return 'text-orange-600 font-semibold'
  return 'text-slate-500'
}

const getTypeBadgeClass = (type: string): string => {
  const classes: Record<string, string> = {
    onboarding: 'bg-green-50 text-green-700 border border-green-200',
    offboarding: 'bg-red-50 text-red-700 border border-red-200',
    repair: 'bg-orange-50 text-orange-700 border border-orange-200',
    maintenance: 'bg-blue-50 text-blue-700 border border-blue-200',
    procurement: 'bg-purple-50 text-purple-700 border border-purple-200',
  }
  return classes[type] || 'bg-slate-50 text-slate-700 border border-slate-200'
}

const getStatusBadgeClass = (status: string): string => {
  const classes: Record<string, string> = {
    pending: 'bg-yellow-50 text-yellow-700 border border-yellow-200',
    in_progress: 'bg-blue-50 text-blue-700 border border-blue-200',
    completed: 'bg-green-50 text-green-700 border border-green-200',
    cancelled: 'bg-red-50 text-red-700 border border-red-200',
  }
  return classes[status] || 'bg-slate-50 text-slate-700 border border-slate-200'
}

const getProgressBarClass = (progress: number): string => {
  if (progress >= 75) return 'bg-green-500'
  if (progress >= 50) return 'bg-blue-500'
  if (progress >= 25) return 'bg-yellow-500'
  return 'bg-orange-500'
}
</script>
