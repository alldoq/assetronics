<template>
  <div class="bg-white border border-slate-200 rounded-lg p-6 hover:border-accent-blue transition-colors cursor-pointer">
    <div class="flex items-start justify-between">
      <div class="flex-1">
        <div class="flex items-center gap-3 mb-2">
          <!-- Type Icon -->
          <div class="p-2 rounded-lg" :class="typeColorClass">
            <svg v-if="workflow.workflow_type === 'onboarding'" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
            </svg>
            <svg v-else-if="workflow.workflow_type === 'offboarding'" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7a4 4 0 11-8 0 4 4 0 018 0zM9 14a6 6 0 00-6 6v1h12v-1a6 6 0 00-6-6zM21 12h-6" />
            </svg>
            <svg v-else-if="workflow.workflow_type === 'procurement'" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
            <svg v-else-if="workflow.workflow_type === 'repair'" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            <svg v-else class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
            </svg>
          </div>

          <div>
            <h3 class="text-lg font-semibold text-primary-dark">{{ workflow.title }}</h3>
            <div class="flex items-center gap-2 mt-1">
              <span class="text-xs px-2 py-0.5 rounded-full uppercase tracking-wide" :class="statusBadgeClass">
                {{ workflow.status.replace('_', ' ') }}
              </span>
              <span class="text-xs px-2 py-0.5 rounded-full uppercase tracking-wide" :class="priorityBadgeClass">
                {{ workflow.priority }}
              </span>
              <span class="text-xs text-slate-500">{{ workflow.workflow_type }}</span>
            </div>
          </div>
        </div>

        <p v-if="workflow.description" class="text-sm text-slate-600 mb-4">{{ workflow.description }}</p>

        <!-- Progress Bar -->
        <div class="mb-4">
          <div class="flex justify-between text-sm text-slate-600 mb-1">
            <span>Progress</span>
            <span>{{ workflow.current_step }} / {{ workflow.total_steps }} steps</span>
          </div>
          <div class="w-full bg-slate-200 rounded-full h-2">
            <div
              class="bg-accent-blue h-2 rounded-full transition-all"
              :style="{ width: `${progressPercentage}%` }"
            ></div>
          </div>
        </div>

        <!-- Employee/Asset Info -->
        <div class="flex gap-4 text-sm">
          <div v-if="workflow.employee" class="flex items-center gap-2">
            <svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
            <span class="text-slate-700">{{ workflow.employee.first_name }} {{ workflow.employee.last_name }}</span>
          </div>
          <div v-if="workflow.asset" class="flex items-center gap-2">
            <svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
            </svg>
            <span class="text-slate-700">{{ workflow.asset.name }}</span>
          </div>
          <div v-if="workflow.due_date" class="flex items-center gap-2">
            <svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
            <span :class="dueDateClass">Due {{ formatDate(workflow.due_date) }}</span>
          </div>
        </div>
      </div>

      <!-- Actions -->
      <div class="flex gap-2">
        <button
          v-if="workflow.status === 'pending'"
          @click.stop="$emit('start', workflow.id)"
          class="px-3 py-1.5 text-sm font-medium text-white bg-accent-blue rounded-md hover:bg-accent-blue/90"
        >
          Start
        </button>
        <button
          v-if="workflow.status === 'in_progress' && workflow.current_step === workflow.total_steps"
          @click.stop="$emit('complete', workflow.id)"
          class="px-3 py-1.5 text-sm font-medium text-white bg-teal-600 rounded-md hover:bg-teal-700"
        >
          Complete
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  workflow: {
    id: string
    workflow_type: string
    title: string
    description?: string
    status: string
    priority: string
    current_step: number
    total_steps: number
    due_date?: string
    employee?: {
      first_name: string
      last_name: string
    }
    asset?: {
      name: string
    }
  }
}

const props = defineProps<Props>()
defineEmits(['start', 'complete'])

const progressPercentage = computed(() => {
  if (props.workflow.total_steps === 0) return 0
  return Math.round((props.workflow.current_step / props.workflow.total_steps) * 100)
})

const typeColorClass = computed(() => {
  const colors = {
    onboarding: 'bg-blue-100 text-blue-600',
    offboarding: 'bg-orange-100 text-orange-600',
    procurement: 'bg-teal-100 text-teal-600',
    repair: 'bg-purple-100 text-purple-600',
    maintenance: 'bg-yellow-100 text-yellow-600'
  }
  return colors[props.workflow.workflow_type as keyof typeof colors] || 'bg-slate-100 text-slate-600'
})

const statusBadgeClass = computed(() => {
  const colors = {
    pending: 'bg-yellow-100 text-yellow-700 border border-yellow-200',
    in_progress: 'bg-blue-100 text-blue-700 border border-blue-200',
    completed: 'bg-teal-100 text-teal-700 border border-teal-200',
    cancelled: 'bg-slate-100 text-slate-700 border border-slate-200'
  }
  return colors[props.workflow.status as keyof typeof colors] || 'bg-slate-100 text-slate-700'
})

const priorityBadgeClass = computed(() => {
  const colors = {
    low: 'bg-slate-100 text-slate-600 border border-slate-200',
    normal: 'bg-blue-100 text-blue-600 border border-blue-200',
    high: 'bg-orange-100 text-orange-600 border border-orange-200',
    urgent: 'bg-red-100 text-red-600 border border-red-200'
  }
  return colors[props.workflow.priority as keyof typeof colors] || 'bg-slate-100 text-slate-600'
})

const dueDateClass = computed(() => {
  if (!props.workflow.due_date) return 'text-slate-600'
  const dueDate = new Date(props.workflow.due_date)
  const today = new Date()
  const isOverdue = dueDate < today && props.workflow.status !== 'completed'
  return isOverdue ? 'text-red-600 font-medium' : 'text-slate-600'
})

const formatDate = (dateString: string) => {
  const date = new Date(dateString)
  const today = new Date()
  const diffTime = date.getTime() - today.getTime()
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))

  if (diffDays === 0) return 'today'
  if (diffDays === 1) return 'tomorrow'
  if (diffDays === -1) return 'yesterday'
  if (diffDays < 0) return `${Math.abs(diffDays)} days ago`
  if (diffDays < 7) return `in ${diffDays} days`

  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}
</script>
