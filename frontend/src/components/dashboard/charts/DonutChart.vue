<template>
  <div class="h-full w-full">
    <Doughnut :data="chartData" :options="chartOptions" />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { Doughnut } from 'vue-chartjs'
import {
  Chart as ChartJS,
  ArcElement,
  Tooltip,
  Legend,
  type ChartData,
  type ChartOptions
} from 'chart.js'

ChartJS.register(ArcElement, Tooltip, Legend)

interface Props {
  labels: string[]
  data: number[]
  colors?: string[]
  title?: string
}

const props = withDefaults(defineProps<Props>(), {
  colors: () => [
    '#10b981', // green
    '#3b82f6', // blue
    '#f59e0b', // amber
    '#ef4444', // red
    '#8b5cf6', // purple
    '#ec4899', // pink
    '#06b6d4', // cyan
    '#64748b'  // slate
  ]
})

const chartData = computed<ChartData<'doughnut'>>(() => ({
  labels: props.labels,
  datasets: [
    {
      data: props.data,
      backgroundColor: props.colors,
      borderColor: '#ffffff',
      borderWidth: 2,
      hoverOffset: 8
    }
  ]
}))

const chartOptions = computed<ChartOptions<'doughnut'>>(() => ({
  responsive: true,
  maintainAspectRatio: false,
  layout: {
    padding: {
      top: 0,
      bottom: 0,
      left: 0,
      right: 0
    }
  },
  plugins: {
    legend: {
      position: 'right',
      align: 'center',
      labels: {
        padding: 12,
        usePointStyle: true,
        font: {
          size: 13,
          family: "'Open Sans', sans-serif"
        },
        color: '#2c3e50',
        boxWidth: 12,
        boxHeight: 12
      }
    },
    tooltip: {
      backgroundColor: '#1a2342',
      padding: 12,
      bodyFont: {
        size: 13,
        family: "'Open Sans', sans-serif"
      },
      callbacks: {
        label: (context) => {
          const label = context.label || ''
          const value = context.parsed || 0
          const total = context.dataset.data.reduce((a: number, b: number) => a + b, 0)
          const percentage = total > 0 ? ((value / total) * 100).toFixed(1) : 0
          return `${label}: ${value} (${percentage}%)`
        }
      }
    }
  },
  cutout: '55%'
}))
</script>
