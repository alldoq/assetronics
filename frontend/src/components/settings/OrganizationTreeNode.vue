<template>
  <div class="organization-tree-node">
    <div
      class="flex items-center gap-2 p-3 rounded-lg hover:bg-light-bg transition-colors group"
      :style="{ paddingLeft: `${level * 24 + 12}px` }"
    >
      <!-- Expand/Collapse button -->
      <button
        v-if="organization.children && organization.children.length > 0"
        @click="toggleExpanded"
        class="flex-shrink-0 w-5 h-5 flex items-center justify-center text-slate-500 hover:text-primary-dark transition-colors"
      >
        <svg v-if="isExpanded" class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
        </svg>
        <svg v-else class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
        </svg>
      </button>
      <div v-else class="w-5"></div>

      <!-- Icon -->
      <div class="flex-shrink-0 p-1.5 rounded-lg bg-purple-100 border border-purple-200">
        <svg class="w-4 h-4 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
        </svg>
      </div>

      <!-- Content -->
      <div class="flex-1 min-w-0">
        <div class="flex items-center gap-2 flex-wrap">
          <span class="text-sm font-semibold text-primary-dark">{{ organization.name }}</span>
          <span v-if="organization.type" class="px-2 py-0.5 text-xs font-medium rounded bg-purple-100 text-purple-700">
            {{ formatType(organization.type) }}
          </span>
          <span v-if="organization.children && organization.children.length > 0" class="text-xs text-slate-500">
            ({{ organization.children.length }} {{ organization.children.length === 1 ? 'child' : 'children' }})
          </span>
        </div>
        <p v-if="organization.description" class="text-xs text-slate-600 mt-0.5 truncate">
          {{ organization.description }}
        </p>
      </div>

      <!-- Actions -->
      <div class="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
        <button
          @click.stop="startAddingChild"
          class="p-1.5 text-slate-500 hover:text-purple-600 hover:bg-white rounded transition-colors"
          title="Add sub-organization"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
          </svg>
        </button>
        <button
          @click.stop="$emit('edit', organization)"
          class="p-1.5 text-slate-500 hover:text-primary-dark hover:bg-white rounded transition-colors"
          title="Edit"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
          </svg>
        </button>
        <button
          @click.stop="$emit('delete', organization)"
          class="p-1.5 text-slate-500 hover:text-red-600 hover:bg-white rounded transition-colors"
          title="Delete"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
          </svg>
        </button>
      </div>
    </div>

    <!-- Inline add form -->
    <div
      v-if="showAddForm"
      class="bg-purple-50 border-l-4 border-purple-400 rounded-lg p-3 mb-2"
      :style="{ marginLeft: `${(level + 1) * 24 + 12}px` }"
    >
      <div class="flex items-start gap-2">
        <div class="flex-1 space-y-2">
          <input
            ref="nameInput"
            v-model="newOrgName"
            type="text"
            placeholder="Enter organization name..."
            class="w-full px-3 py-2 text-sm border border-purple-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 bg-white"
            @keydown.enter="handleAddChild"
            @keydown.esc="cancelAddingChild"
          />
          <div class="flex gap-2">
            <select
              v-model="newOrgType"
              class="flex-1 px-3 py-2 text-sm border border-purple-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 bg-white"
            >
              <option value="subsidiary">Subsidiary</option>
              <option value="division">Division</option>
              <option value="business_unit">Business Unit</option>
              <option value="branch">Branch</option>
              <option value="holding_company">Holding Company</option>
              <option value="parent_company">Parent Company</option>
              <option value="other">Other</option>
            </select>
            <button
              @click="handleAddChild"
              :disabled="!newOrgName.trim()"
              class="px-3 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex-shrink-0"
              title="Add"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
              </svg>
            </button>
            <button
              @click="cancelAddingChild"
              class="px-3 py-2 bg-slate-200 text-slate-700 rounded-lg hover:bg-slate-300 transition-colors flex-shrink-0"
              title="Cancel"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Children -->
    <div v-if="isExpanded && organization.children && organization.children.length > 0" class="mt-1">
      <OrganizationTreeNode
        v-for="child in organization.children"
        :key="child.id"
        :organization="child"
        :level="level + 1"
        @edit="$emit('edit', $event)"
        @delete="$emit('delete', $event)"
        @add-child="$emit('add-child', $event)"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, nextTick } from 'vue'
import type { Organization, OrganizationType } from '@/services/organizations'

interface Props {
  organization: Organization
  level: number
}

const props = defineProps<Props>()

const emit = defineEmits<{
  edit: [organization: Organization]
  delete: [organization: Organization]
  'add-child': [data: { parent_id: string; name: string; type: string }]
}>()

const isExpanded = ref(props.level < 2) // Auto-expand first 2 levels
const showAddForm = ref(false)
const newOrgName = ref('')
const newOrgType = ref<OrganizationType>('subsidiary')
const nameInput = ref<HTMLInputElement | null>(null)

const toggleExpanded = () => {
  isExpanded.value = !isExpanded.value
}

const startAddingChild = () => {
  showAddForm.value = true
  isExpanded.value = true
  newOrgName.value = ''
  newOrgType.value = 'subsidiary'
  nextTick(() => {
    nameInput.value?.focus()
  })
}

const handleAddChild = () => {
  if (!newOrgName.value.trim()) return

  emit('add-child', {
    parent_id: String(props.organization.id),
    name: newOrgName.value.trim(),
    type: newOrgType.value
  })

  cancelAddingChild()
}

const cancelAddingChild = () => {
  showAddForm.value = false
  newOrgName.value = ''
  newOrgType.value = 'subsidiary'
}

const formatType = (type: OrganizationType): string => {
  const typeMap: Record<OrganizationType, string> = {
    holding_company: 'Holding Company',
    parent_company: 'Parent Company',
    subsidiary: 'Subsidiary',
    division: 'Division',
    business_unit: 'Business Unit',
    branch: 'Branch',
    other: 'Other'
  }
  return typeMap[type] || type
}
</script>

<style scoped>
.organization-tree-node {
  position: relative;
}

.organization-tree-node::before {
  content: '';
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 2px;
  background: linear-gradient(to bottom, transparent 0%, #e2e8f0 20%, #e2e8f0 80%, transparent 100%);
}
</style>
