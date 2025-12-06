<template>
  <div class="bg-white border border-border-light rounded-xl p-6">
    <h3 class="text-lg font-bold text-primary-dark mb-4">{{ title }}</h3>
    <div v-if="data && data.length > 0" class="space-y-3">
      <div
        v-for="(item, index) in data"
        :key="item.label"
        class="flex items-center justify-between"
      >
        <div class="flex items-center gap-3 flex-1">
          <div
            class="w-3 h-3 rounded-full flex-shrink-0"
            :style="{ backgroundColor: getColor(index) }"
          />
          <span class="text-sm text-slate-600 capitalize">{{ formatLabel(item.label) }}</span>
        </div>
        <div class="flex items-center gap-4">
          <span class="text-sm font-semibold text-slate-900">{{ item.value }}</span>
          <div class="w-24 bg-slate-100 rounded-full h-2">
            <div
              class="h-2 rounded-full transition-all duration-300"
              :style="{
                width: `${getPercentage(item.value)}%`,
                backgroundColor: getColor(index)
              }"
            />
          </div>
        </div>
      </div>
    </div>
    <div v-else class="py-8 text-center">
      <p class="text-slate-500">No data available</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface ChartData {
  label: string
  value: number
}

interface Props {
  title: string
  data: ChartData[]
  colors?: string[]
}

const props = withDefaults(defineProps<Props>(), {
  colors: () => [
    '#14b8a6', // teal
    '#3b82f6', // blue
    '#a855f7', // purple
    '#f59e0b', // orange
    '#10b981', // green
    '#ef4444', // red
    '#6366f1', // indigo
    '#ec4899', // pink
  ]
})

const totalValue = computed(() => {
  return props.data.reduce((sum, item) => sum + item.value, 0)
})

const getPercentage = (value: number): number => {
  if (totalValue.value === 0) return 0
  return Math.round((value / totalValue.value) * 100)
}

const getColor = (index: number): string => {
  return props.colors[index % props.colors.length] || '#14b8a6'
}

const formatLabel = (label: string): string => {
  return label.replace(/_/g, ' ')
}
</script>
