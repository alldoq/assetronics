<template>
  <div class="relative inline-block text-left">
    <button
      @click.stop="toggleDropdown"
      class="text-slate-500 hover:text-primary-dark p-1 rounded transition-colors"
      type="button"
    >
      <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
        <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM18 10a2 2 0 11-4 0 2 2 0 014 0z" />
      </svg>
    </button>
    <div
      v-if="isOpen"
      @click.stop
      class="absolute right-0 w-48 rounded-2xl shadow-subtle bg-white border border-slate-200 z-10"
      :class="openUpward ? 'origin-bottom-right bottom-full mb-2' : 'origin-top-right top-full mt-2'"
    >
      <div class="py-1">
        <button
          @click="handleEdit"
          class="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-gray-50 hover:text-primary-dark flex items-center gap-2 transition-colors"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
          </svg>
          Edit
        </button>
        <button
          @click="handleDelete"
          class="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50 flex items-center gap-2 transition-colors"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
          </svg>
          Delete
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'

interface Props {
  itemIndex: number
  totalItems: number
  modelValue: boolean
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
  edit: []
  delete: []
}>()

const isOpen = computed({
  get: () => props.modelValue,
  set: (value: boolean) => emit('update:modelValue', value),
})

const openUpward = computed(() => {
  // Open upward if in the last 2 rows
  return props.totalItems - props.itemIndex <= 2
})

const toggleDropdown = () => {
  isOpen.value = !isOpen.value
}

const handleEdit = () => {
  emit('edit')
  isOpen.value = false
}

const handleDelete = () => {
  emit('delete')
  isOpen.value = false
}

const handleClickOutside = (event: MouseEvent) => {
  const target = event.target as HTMLElement
  if (isOpen.value && !target.closest('.relative')) {
    isOpen.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>
