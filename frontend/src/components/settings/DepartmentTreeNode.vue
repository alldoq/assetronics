<template>
  <div>
    <div
      class="flex items-center hover:bg-light-bg/50 rounded-lg transition-colors group"
      :class="{ 'bg-light-bg/30': isExpanded && hasChildren }"
      :style="{ paddingLeft: `${level * 24 + 8}px` }"
    >
      <!-- Expand/collapse button -->
      <button
        v-if="hasChildren"
        @click.stop="toggleExpand"
        class="mr-2 p-1 hover:bg-white rounded transition-all flex-shrink-0"
      >
        <svg
          class="w-4 h-4 text-slate-600 transition-transform"
          :class="{ 'rotate-90': isExpanded }"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
        </svg>
      </button>
      <div v-else class="w-6 mr-2"></div>

      <!-- Department info -->
      <div class="flex-1 flex items-center justify-between py-2 pr-2">
        <div class="flex items-center gap-3 min-w-0">
          <div class="flex items-center gap-2 min-w-0">
            <span class="font-medium text-primary-dark truncate">{{ department.name }}</span>
            <span
              v-if="department.type"
              class="px-2 py-0.5 text-xs font-medium rounded-full bg-violet-100 text-violet-700 whitespace-nowrap"
            >
              {{ formatType(department.type) }}
            </span>
          </div>
          <span v-if="department.description" class="text-sm text-slate-600 truncate hidden lg:inline">
            - {{ department.description }}
          </span>
        </div>

        <!-- Actions -->
        <div class="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity flex-shrink-0">
          <button
            @click.stop="$emit('edit', department)"
            class="p-1.5 text-slate-600 hover:text-accent-blue hover:bg-white rounded transition-colors"
            title="Edit"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
              />
            </svg>
          </button>
          <button
            @click.stop="$emit('delete', department)"
            class="p-1.5 text-slate-600 hover:text-red-600 hover:bg-white rounded transition-colors"
            title="Delete"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
              />
            </svg>
          </button>
        </div>
      </div>
    </div>

    <!-- Children -->
    <div v-if="isExpanded && hasChildren">
      <DepartmentTreeNode
        v-for="child in department.children"
        :key="child.id"
        :department="child"
        :level="level + 1"
        @edit="$emit('edit', $event)"
        @delete="$emit('delete', $event)"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import type { Department } from '@/services/departments'

const props = defineProps<{
  department: Department
  level: number
}>()

defineEmits<{
  edit: [department: Department]
  delete: [department: Department]
}>()

const isExpanded = ref(false)

const hasChildren = computed(() => {
  return props.department.children && props.department.children.length > 0
})

const toggleExpand = () => {
  isExpanded.value = !isExpanded.value
}

const formatType = (type: string): string => {
  return type
    .split('_')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ')
}

onMounted(() => {
  // Auto-expand first 2 levels
  if (props.level < 2) {
    isExpanded.value = true
  }
})
</script>
