<template>
  <div class="bg-white border border-slate-200/60 rounded-xl p-5 shadow-sm">
    <h3 class="text-sm font-semibold text-slate-700 mb-4 uppercase tracking-wider">{{ title }}</h3>
    <div v-if="assets && assets.length > 0" class="space-y-2">
      <div
        v-for="asset in assets"
        :key="asset.id"
        class="flex items-center justify-between p-3 bg-slate-50/50 border border-slate-100 rounded-lg hover:bg-slate-50 transition-colors"
      >
        <div class="flex-1 min-w-0">
          <p class="font-medium text-slate-800 text-sm truncate">{{ asset.name }}</p>
          <div class="flex items-center gap-2 mt-1">
            <span class="text-xs font-mono text-slate-500 bg-slate-100 px-1.5 py-0.5 rounded">{{ asset.asset_tag }}</span>
            <span class="text-xs text-slate-400 capitalize">{{ formatCategory(asset.category) }}</span>
          </div>
        </div>
        <div v-if="asset.assignment_type" :class="['px-2 py-0.5 rounded text-xs font-medium flex-shrink-0 ml-2', getTypeBadgeClass(asset.assignment_type)]">
          {{ formatAssignmentType(asset.assignment_type) }}
        </div>
      </div>
    </div>
    <div v-else class="py-8 text-center">
      <p class="text-slate-400 text-sm">No assets assigned</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Asset } from '@/services/dashboard'

interface Props {
  assets: Asset[]
  title?: string
}

withDefaults(defineProps<Props>(), {
  title: 'My assets'
})

const formatCategory = (category: string): string => {
  return category.replace(/_/g, ' ')
}

const formatAssignmentType = (type: string): string => {
  return type.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
}

const formatDate = (dateString: string): string => {
  const date = new Date(dateString)
  const now = new Date()
  const diffInDays = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24))

  if (diffInDays === 0) return 'today'
  if (diffInDays === 1) return 'yesterday'
  if (diffInDays < 7) return `${diffInDays} days ago`
  if (diffInDays < 30) return `${Math.floor(diffInDays / 7)} weeks ago`

  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}

const getTypeBadgeClass = (type: string): string => {
  switch (type) {
    case 'permanent':
      return 'bg-green-50 text-green-700 border border-green-200'
    case 'temporary':
      return 'bg-blue-50 text-blue-700 border border-blue-200'
    case 'trial':
      return 'bg-yellow-50 text-yellow-700 border border-yellow-200'
    default:
      return 'bg-slate-50 text-slate-700 border border-slate-200'
  }
}
</script>
