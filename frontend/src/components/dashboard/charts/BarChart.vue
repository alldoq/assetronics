<template>
  <div class="h-full w-full">
    <Bar :data="chartData" :options="chartOptions" />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { Bar } from 'vue-chartjs'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
  type ChartData,
  type ChartOptions
} from 'chart.js'

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend)

interface Props {
  labels: string[]
  data: number[]
  label?: string
  color?: string
}

const props = withDefaults(defineProps<Props>(), {
  label: 'Count',
  color: '#3b82f6'
})

const chartData = computed<ChartData<'bar'>>(() => ({
  labels: props.labels,
  datasets: [
    {
      label: props.label,
      data: props.data,
      backgroundColor: props.color,
      borderRadius: 6,
      borderSkipped: false,
      maxBarThickness: 60,
      minBarLength: 2
    }
  ]
}))

const chartOptions = computed<ChartOptions<'bar'>>(() => ({
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      display: false
    },
    tooltip: {
      backgroundColor: '#1a2342',
      padding: 12,
      bodyFont: {
        size: 13,
        family: "'Open Sans', sans-serif"
      }
    }
  },
  scales: {
    x: {
      grid: {
        display: false
      },
      ticks: {
        font: {
          size: 11,
          family: "'Open Sans', sans-serif"
        },
        color: '#6c7a8a',
        maxRotation: 45,
        minRotation: 0,
        autoSkip: false
      }
    },
    y: {
      beginAtZero: true,
      grid: {
        color: '#e1e8ef',
        drawBorder: false
      },
      ticks: {
        font: {
          size: 11,
          family: "'Open Sans', sans-serif"
        },
        color: '#6c7a8a',
        precision: 0,
        padding: 4
      }
    }
  }
}))
</script>
