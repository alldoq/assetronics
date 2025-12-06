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

    <!-- Dropdown with special options and employees -->
    <div
      v-if="showDropdown"
      class="absolute z-50 mt-1 w-full bg-white rounded-lg shadow-xl border border-slate-200 max-h-64 overflow-auto"
    >
      <!-- Special options (only when no search query) -->
      <template v-if="!searchQuery && showSpecialOptions">
        <div
          @click="selectSpecialOption('')"
          class="flex items-center gap-3 px-4 py-3 cursor-pointer hover:bg-slate-50 transition-colors"
        >
          <div class="w-10 h-10 flex-shrink-0 rounded-full bg-slate-100 flex items-center justify-center">
            <svg class="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
          </div>
          <div class="flex-1 min-w-0">
            <div class="text-sm font-semibold text-slate-900">All assignees</div>
            <div class="text-xs text-slate-500">Show all assets</div>
          </div>
        </div>
        <div
          @click="selectSpecialOption('unassigned')"
          class="flex items-center gap-3 px-4 py-3 cursor-pointer hover:bg-slate-50 transition-colors border-t border-slate-100"
        >
          <div class="w-10 h-10 flex-shrink-0 rounded-full bg-slate-100 flex items-center justify-center">
            <svg class="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
            </svg>
          </div>
          <div class="flex-1 min-w-0">
            <div class="text-sm font-semibold text-slate-900">Unassigned</div>
            <div class="text-xs text-slate-500">Assets not assigned to anyone</div>
          </div>
        </div>
      </template>

      <!-- Employee results (when searching or showing all) -->
      <template v-if="searchQuery || !showSpecialOptions">
        <div
          v-for="(employee, index) in filteredEmployees"
          :key="employee.id"
          @click="selectEmployee(employee)"
          @mouseenter="highlightedIndex = index"
          :class="[
            'flex items-center gap-3 px-4 py-3 cursor-pointer transition-colors',
            highlightedIndex === index ? 'bg-blue-50' : 'hover:bg-slate-50',
            index > 0 ? 'border-t border-slate-100' : ''
          ]"
        >
          <!-- Avatar -->
          <div class="w-10 h-10 flex-shrink-0 rounded-full bg-gradient-to-br from-blue-400 to-blue-600 flex items-center justify-center overflow-hidden">
            <img
              v-if="employee.avatar_url"
              :src="employee.avatar_url"
              :alt="`${employee.first_name} ${employee.last_name}`"
              class="w-full h-full object-cover"
              @error="handleImageError"
            />
            <span v-else class="text-white font-semibold text-sm">
              {{ getInitials(employee) }}
            </span>
          </div>

          <!-- Employee info -->
          <div class="flex-1 min-w-0">
            <div class="text-sm font-semibold text-slate-900 truncate">
              {{ employee.first_name }} {{ employee.last_name }}
            </div>
            <div class="text-xs text-slate-500 truncate">
              {{ employee.job_title || 'No title' }}
            </div>
          </div>
        </div>

        <!-- No results -->
        <div
          v-if="searchQuery && filteredEmployees.length === 0"
          class="px-4 py-3 text-sm text-slate-500 text-center"
        >
          No employees found
        </div>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount, watch } from 'vue'
import type { Employee } from '@/services/employees'

interface Props {
  modelValue: string | undefined
  employees: Employee[]
  placeholder?: string
  label?: string
  showSpecialOptions?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  placeholder: 'Search employees...',
  label: '',
  showSpecialOptions: true
})

const emit = defineEmits<{
  'update:modelValue': [value: string | undefined]
}>()

const searchQuery = ref('')
const showDropdown = ref(false)
const highlightedIndex = ref(0)
const containerRef = ref<HTMLElement | null>(null)

// Get employee initials for avatar
const getInitials = (employee: Employee): string => {
  const first = employee.first_name?.charAt(0) || ''
  const last = employee.last_name?.charAt(0) || ''
  return (first + last).toUpperCase()
}

// Filter employees based on search query
const filteredEmployees = computed(() => {
  if (!searchQuery.value) {
    return props.employees.slice(0, 10) // Show first 10 when no search
  }

  const query = searchQuery.value.toLowerCase()
  return props.employees.filter(employee => {
    const fullName = `${employee.first_name} ${employee.last_name}`.toLowerCase()
    const jobTitle = employee.job_title?.toLowerCase() || ''
    return fullName.includes(query) || jobTitle.includes(query)
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
      highlightedIndex.value = Math.min(highlightedIndex.value + 1, filteredEmployees.value.length - 1)
      break
    case 'ArrowUp':
      event.preventDefault()
      highlightedIndex.value = Math.max(highlightedIndex.value - 1, 0)
      break
    case 'Enter':
      event.preventDefault()
      const selectedEmployee = filteredEmployees.value[highlightedIndex.value]
      if (selectedEmployee) {
        selectEmployee(selectedEmployee)
      }
      break
    case 'Escape':
      showDropdown.value = false
      break
  }
}

// Select employee
const selectEmployee = (employee: Employee) => {
  searchQuery.value = `${employee.first_name} ${employee.last_name}`
  emit('update:modelValue', employee.id)
  showDropdown.value = false
}

// Select special option
const selectSpecialOption = (value: string) => {
  if (value === '') {
    searchQuery.value = ''
  } else if (value === 'unassigned') {
    searchQuery.value = 'Unassigned'
  }
  emit('update:modelValue', value)
  showDropdown.value = false
}

// Clear selection
const clearSelection = () => {
  searchQuery.value = ''
  emit('update:modelValue', undefined)
  showDropdown.value = false
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
  if (!newValue) {
    searchQuery.value = ''
    return
  }

  if (newValue === 'unassigned') {
    searchQuery.value = 'Unassigned'
    return
  }

  const employee = props.employees.find(e => e.id === newValue)
  if (employee) {
    searchQuery.value = `${employee.first_name} ${employee.last_name}`
  }
}, { immediate: true })

// Watch employees array changes
watch(() => props.employees, () => {
  // Update display if we have a selected employee
  if (props.modelValue && props.modelValue !== 'unassigned') {
    const employee = props.employees.find(e => e.id === props.modelValue)
    if (employee) {
      searchQuery.value = `${employee.first_name} ${employee.last_name}`
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
