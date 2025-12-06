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

      <!-- Location info -->
      <div class="flex-1 flex items-center justify-between py-2 pr-2">
        <div class="flex items-center gap-3 min-w-0">
          <div class="flex items-center gap-2 min-w-0">
            <span class="font-medium text-primary-dark truncate">{{ location.name }}</span>
            <span
              v-if="location.location_type"
              class="px-2 py-0.5 text-xs font-medium rounded-full bg-teal-100 text-teal-700 whitespace-nowrap"
            >
              {{ formatType(location.location_type) }}
            </span>
            <span
              v-if="!location.is_active"
              class="px-2 py-0.5 text-xs font-medium rounded-full bg-slate-100 text-slate-600 whitespace-nowrap"
            >
              Inactive
            </span>
          </div>
          <span v-if="location.city || location.country" class="text-sm text-slate-600 truncate hidden lg:inline">
            - {{ [location.city, location.country].filter(Boolean).join(', ') }}
          </span>
        </div>

        <!-- Actions -->
        <div class="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity flex-shrink-0">
          <button
            @click.stop="startAddingChild"
            class="p-1.5 text-slate-600 hover:text-teal-600 hover:bg-white rounded transition-colors"
            title="Add sub-location"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 6v6m0 0v6m0-6h6m-6 0H6"
              />
            </svg>
          </button>
          <button
            @click.stop="$emit('edit', location)"
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
            @click.stop="$emit('delete', location)"
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

    <!-- Inline add form -->
    <div
      v-if="showAddForm"
      class="bg-teal-50 border-l-4 border-teal-400 rounded-lg p-3 ml-6 mb-2"
      :style="{ marginLeft: `${(level + 1) * 24 + 8}px` }"
    >
      <div class="flex items-center gap-2">
        <input
          ref="nameInput"
          v-model="newLocationName"
          type="text"
          placeholder="Enter location name..."
          class="flex-1 px-3 py-2 text-sm border border-teal-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 bg-white"
          @keydown.enter="handleAddChild"
          @keydown.esc="cancelAddingChild"
        />
        <select
          v-model="newLocationType"
          class="px-3 py-2 text-sm border border-teal-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 bg-white"
        >
          <option value="office">Office</option>
          <option value="warehouse">Warehouse</option>
          <option value="datacenter">Datacenter</option>
          <option value="store">Store</option>
          <option value="building">Building</option>
          <option value="floor">Floor</option>
          <option value="region">Region</option>
          <option value="country">Country</option>
          <option value="state">State</option>
          <option value="city">City</option>
          <option value="other">Other</option>
        </select>
        <button
          @click="handleAddChild"
          :disabled="!newLocationName.trim()"
          class="px-3 py-2 bg-teal-600 text-white rounded-lg hover:bg-teal-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          title="Add"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
        </button>
        <button
          @click="cancelAddingChild"
          class="px-3 py-2 bg-slate-200 text-slate-700 rounded-lg hover:bg-slate-300 transition-colors"
          title="Cancel"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
    </div>

    <!-- Children -->
    <div v-if="isExpanded && hasChildren">
      <LocationTreeNode
        v-for="child in location.children"
        :key="child.id"
        :location="child"
        :level="level + 1"
        @edit="$emit('edit', $event)"
        @delete="$emit('delete', $event)"
        @add-child="$emit('add-child', $event)"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, nextTick } from 'vue'
import type { Location } from '@/services/locations'

const props = defineProps<{
  location: Location
  level: number
}>()

const emit = defineEmits<{
  edit: [location: Location]
  delete: [location: Location]
  'add-child': [data: { parent_id: string; name: string; location_type: string }]
}>()

const isExpanded = ref(false)
const showAddForm = ref(false)
const newLocationName = ref('')
const newLocationType = ref('office')
const nameInput = ref<HTMLInputElement | null>(null)

const hasChildren = computed(() => {
  return props.location.children && props.location.children.length > 0
})

const toggleExpand = () => {
  isExpanded.value = !isExpanded.value
}

const startAddingChild = () => {
  showAddForm.value = true
  isExpanded.value = true
  newLocationName.value = ''
  newLocationType.value = 'office'
  nextTick(() => {
    nameInput.value?.focus()
  })
}

const handleAddChild = () => {
  if (!newLocationName.value.trim()) return

  emit('add-child', {
    parent_id: String(props.location.id),
    name: newLocationName.value.trim(),
    location_type: newLocationType.value
  })

  cancelAddingChild()
}

const cancelAddingChild = () => {
  showAddForm.value = false
  newLocationName.value = ''
  newLocationType.value = 'office'
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
