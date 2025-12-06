<template>
  <div class="bg-white border border-slate-200/60 rounded-xl p-5 shadow-sm hover:shadow-md hover:border-slate-300/60 transition-all duration-300 group">
    <div class="flex items-center gap-4">
      <div v-if="icon" :class="['w-12 h-12 rounded-lg flex items-center justify-center flex-shrink-0 transition-transform duration-300 group-hover:scale-105', iconBgClass]">
        <component :is="icon" :class="['w-6 h-6', iconColorClass]" />
      </div>
      <div class="flex-1 min-w-0">
        <p class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1">{{ title }}</p>
        <p class="text-2xl font-semibold text-slate-900 font-poppins tracking-tight truncate">{{ formattedValue }}</p>
        <p v-if="subtitle" class="text-xs text-slate-400 mt-0.5 truncate">{{ subtitle }}</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, type Component } from 'vue'

interface Trend {
  direction: 'up' | 'down'
  value: string
  label: string
  isPositive: boolean
}

interface Props {
  title: string
  value: number | string
  subtitle?: string
  icon?: Component
  iconColor?: 'teal' | 'blue' | 'purple' | 'orange' | 'red' | 'green'
  trend?: Trend
  format?: 'number' | 'currency' | 'percent'
}

const props = withDefaults(defineProps<Props>(), {
  iconColor: 'teal',
  format: 'number'
})

const formattedValue = computed(() => {
  if (typeof props.value === 'string') return props.value

  switch (props.format) {
    case 'currency':
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
      }).format(props.value)
    case 'percent':
      return `${props.value}%`
    case 'number':
    default:
      return new Intl.NumberFormat('en-US').format(props.value)
  }
})

const iconBgClass = computed(() => {
  const colors = {
    teal: 'bg-teal-50',
    blue: 'bg-blue-50',
    purple: 'bg-purple-50',
    orange: 'bg-orange-50',
    red: 'bg-red-50',
    green: 'bg-green-50',
  }
  return colors[props.iconColor]
})

const iconColorClass = computed(() => {
  const colors = {
    teal: 'text-teal-600',
    blue: 'text-blue-600',
    purple: 'text-purple-600',
    orange: 'text-orange-600',
    red: 'text-red-600',
    green: 'text-green-600',
  }
  return colors[props.iconColor]
})
</script>
