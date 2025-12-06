<template>
  <div class="relative" ref="containerRef">
    <label v-if="label" class="block text-xs font-medium text-slate-700 mb-1">{{ label }}</label>
    <div class="relative">
      <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none z-10">
        <svg class="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
      </div>
      <input
        v-model="searchQuery"
        type="text"
        :placeholder="placeholder"
        class="input-refined w-full !pl-10 pr-10"
        @focus="showDropdown = true"
        @input="handleInput"
        @keydown="handleKeydown"
      />
      <button
        v-if="modelValue"
        @click="clearSelection"
        class="absolute inset-y-0 right-0 flex items-center pr-3 z-10"
        type="button"
      >
        <svg class="w-5 h-5 text-slate-400 hover:text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>

    <!-- Dropdown with assets -->
    <div
      v-if="showDropdown"
      class="absolute z-50 mt-1 w-full bg-white rounded-lg shadow-xl border border-slate-200 max-h-64 overflow-auto"
    >
      <!-- Asset results -->
      <div
        v-for="(asset, index) in filteredAssets"
        :key="asset.id"
        @click="selectAsset(asset)"
        @mouseenter="highlightedIndex = index"
        :class="[
          'flex items-center gap-3 px-4 py-3 cursor-pointer transition-colors',
          highlightedIndex === index ? 'bg-blue-50' : 'hover:bg-slate-50',
          index > 0 ? 'border-t border-slate-100' : ''
        ]"
      >
        <!-- Asset image/icon -->
        <div class="w-10 h-10 flex-shrink-0 rounded-lg bg-gradient-to-br from-slate-50 to-slate-100 flex items-center justify-center overflow-hidden border border-slate-200">
          <img
            v-if="asset.image_url"
            :src="getImageUrl(asset.image_url)"
            :alt="asset.name"
            class="w-full h-full object-contain"
            @error="handleImageError"
          />
          <svg v-else class="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
          </svg>
        </div>

        <!-- Asset info -->
        <div class="flex-1 min-w-0">
          <div class="text-sm font-semibold text-slate-900 truncate">
            {{ asset.name }}
          </div>
          <div class="text-xs text-slate-500 truncate">
            {{ asset.serial_number || 'No serial' }} • {{ formatStatus(asset.status) }}
          </div>
        </div>

        <!-- Status badge -->
        <span
          class="px-2 py-0.5 text-xs font-mono font-bold rounded border flex-shrink-0"
          :class="getStatusClass(asset.status)"
        >
          {{ formatStatus(asset.status) }}
        </span>
      </div>

      <!-- No results -->
      <div
        v-if="searchQuery && filteredAssets.length === 0"
        class="px-4 py-3 text-sm text-slate-500 text-center"
      >
        No assets found
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount, watch } from 'vue'
import type { Asset } from '@/services/assets'

interface Props {
  modelValue: string
  assets: Asset[]
  placeholder?: string
  label?: string
}

const props = withDefaults(defineProps<Props>(), {
  placeholder: 'Search assets...',
  label: ''
})

const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

const searchQuery = ref('')
const showDropdown = ref(false)
const highlightedIndex = ref(0)
const containerRef = ref<HTMLElement | null>(null)

// Filter assets based on search query
const filteredAssets = computed(() => {
  if (!searchQuery.value) {
    return props.assets.slice(0, 10) // Show first 10 when no search
  }

  const query = searchQuery.value.toLowerCase()
  return props.assets.filter(asset => {
    const name = asset.name?.toLowerCase() || ''
    const serial = asset.serial_number?.toLowerCase() || ''
    const category = asset.category?.toLowerCase() || ''
    return name.includes(query) || serial.includes(query) || category.includes(query)
  })
})

// Handle input
const handleInput = () => {
  showDropdown.value = true
  highlightedIndex.value = 0
}

// Handle keyboard navigation
const handleKeydown = (event: KeyboardEvent) => {
  if (!showDropdown.value) return

  switch (event.key) {
    case 'ArrowDown':
      event.preventDefault()
      highlightedIndex.value = Math.min(highlightedIndex.value + 1, filteredAssets.value.length - 1)
      break
    case 'ArrowUp':
      event.preventDefault()
      highlightedIndex.value = Math.max(highlightedIndex.value - 1, 0)
      break
    case 'Enter':
      event.preventDefault()
      const selectedAsset = filteredAssets.value[highlightedIndex.value]
      if (selectedAsset) {
        selectAsset(selectedAsset)
      }
      break
    case 'Escape':
      showDropdown.value = false
      break
  }
}

// Select asset
const selectAsset = (asset: Asset) => {
  searchQuery.value = `${asset.name} - ${asset.serial_number || 'No serial'}`
  emit('update:modelValue', asset.id)
  showDropdown.value = false
}

// Clear selection
const clearSelection = () => {
  searchQuery.value = ''
  emit('update:modelValue', '')
  showDropdown.value = false
}

// Format status
const formatStatus = (status: string): string => {
  const statusMap: Record<string, string> = {
    on_order: 'On order',
    in_stock: 'In stock',
    assigned: 'Assigned',
    in_transit: 'In transit',
    in_repair: 'In repair',
    retired: 'Retired',
    lost: 'Lost',
    stolen: 'Stolen',
  }
  return statusMap[status] || status
}

// Get status class
const getStatusClass = (status: string): string => {
  const classMap: Record<string, string> = {
    on_order: 'bg-purple-50 text-purple-700 border-purple-200',
    in_stock: 'bg-teal-50 text-teal-700 border-teal-200',
    assigned: 'bg-blue-100 text-blue-800 border-blue-200',
    in_transit: 'bg-indigo-50 text-indigo-700 border-indigo-200',
    in_repair: 'bg-amber-100 text-amber-800 border-amber-200',
    retired: 'bg-slate-100 text-slate-700 border-slate-300',
    lost: 'bg-orange-100 text-orange-800 border-orange-200',
    stolen: 'bg-red-100 text-red-800 border-red-200',
  }
  return classMap[status] || 'bg-slate-100 text-slate-700 border-slate-300'
}

// Get image URL
const getImageUrl = (url: string): string => {
  if (!url) return ''
  if (url.startsWith('/uploads')) {
    return `${import.meta.env.VITE_API_URL}${url}`
  }
  return url
}

// Handle image error
const handleImageError = (event: Event) => {
  const img = event.target as HTMLImageElement
  img.style.display = 'none'
}

// Click outside to close
const handleClickOutside = (event: MouseEvent) => {
  if (containerRef.value && !containerRef.value.contains(event.target as Node)) {
    showDropdown.value = false
  }
}

// Set initial display value based on modelValue
watch(() => props.modelValue, (newValue) => {
  if (!newValue || typeof newValue !== 'string') {
    searchQuery.value = ''
    return
  }

  const asset = props.assets.find(a => a.id === newValue)
  if (asset) {
    searchQuery.value = `${asset.name} - ${asset.serial_number || 'No serial'}`
  }
}, { immediate: true })

// Watch assets array changes
watch(() => props.assets, () => {
  if (props.modelValue) {
    const asset = props.assets.find(a => a.id === props.modelValue)
    if (asset) {
      searchQuery.value = `${asset.name} - ${asset.serial_number || 'No serial'}`
    }
  }
})

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>
