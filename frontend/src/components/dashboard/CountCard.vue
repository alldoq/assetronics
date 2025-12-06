<template>
  <div class="bg-white rounded-lg shadow-sm hover:shadow-md transition-all duration-300 overflow-hidden">
    <div class="p-5">
      <div class="flex items-start justify-between mb-4">
        <div v-if="icon" :class="['w-12 h-12 rounded-lg flex items-center justify-center flex-shrink-0', iconBgClass]">
          <component :is="icon" :class="['w-6 h-6', iconColorClass]" />
        </div>
        <div class="flex-1" :class="icon ? 'ml-4' : ''">
          <span class="text-sm text-slate-500 font-normal">{{ title }}</span>
          <h4 class="text-3xl font-semibold text-slate-900 font-poppins mt-1">{{ formattedValue }}</h4>
        </div>
      </div>

      <div v-if="trend" class="flex items-center gap-2 pt-3 border-t border-slate-100">
        <span :class="['flex items-center gap-1 text-sm font-medium', trendColorClass]">
          <svg
            v-if="trend.direction === 'up'"
            xmlns="http://www.w3.org/2000/svg"
            width="20"
            height="20"
            viewBox="0 0 24 24"
            fill="currentColor"
          >
            <path d="M17.71,11.29l-5-5a1,1,0,0,0-.33-.21,1,1,0,0,0-.76,0,1,1,0,0,0-.33.21l-5,5a1,1,0,0,0,1.42,1.42L11,9.41V17a1,1,0,0,0,2,0V9.41l3.29,3.3a1,1,0,0,0,1.42,0A1,1,0,0,0,17.71,11.29Z"></path>
          </svg>
          <svg
            v-else
            xmlns="http://www.w3.org/2000/svg"
            width="20"
            height="20"
            viewBox="0 0 24 24"
            fill="currentColor"
          >
            <path d="M17.71,12.71a1,1,0,0,0-1.42,0L13,16.41V9a1,1,0,0,0-2,0v7.41l-3.29-3.3a1,1,0,0,0-1.42,1.42l5,5a1,1,0,0,0,.33.21.94.94,0,0,0,.76,0,1,1,0,0,0,.33-.21l5-5A1,1,0,0,0,17.71,12.71Z"></path>
          </svg>
          {{ trend.value }}
        </span>
        <span class="text-xs text-slate-400">{{ trend.label }}</span>
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
  format?: 'number' | 'currency' | 'percent'
  icon?: Component
  iconColor?: 'primary' | 'success' | 'warning' | 'danger' | 'info' | 'purple'
  trend?: Trend
}

const props = withDefaults(defineProps<Props>(), {
  format: 'number',
  iconColor: 'primary'
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
    primary: 'bg-pink-50',
    success: 'bg-green-50',
    warning: 'bg-orange-50',
    danger: 'bg-red-50',
    info: 'bg-blue-50',
    purple: 'bg-purple-50',
  }
  return colors[props.iconColor]
})

const iconColorClass = computed(() => {
  const colors = {
    primary: 'text-pink-500',
    success: 'text-green-500',
    warning: 'text-orange-500',
    danger: 'text-red-500',
    info: 'text-blue-500',
    purple: 'text-purple-500',
  }
  return colors[props.iconColor]
})

const trendColorClass = computed(() => {
  if (!props.trend) return ''
  return props.trend.isPositive ? 'text-green-500' : 'text-red-500'
})
</script>
