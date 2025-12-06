<template>
  <MainLayout>
    <div v-if="loading" class="text-center py-12">
      <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-dark"></div>
    </div>

    <div v-else-if="workflow" class="max-w-5xl mx-auto">
      <!-- Header -->
      <div class="mb-8">
        <div class="flex items-center justify-between">
          <div>
            <div class="flex items-center gap-2 mb-2">
              <router-link to="/workflows" class="text-slate-500 hover:text-slate-700 transition-colors">
                Workflows
              </router-link>
              <span class="text-slate-400">/</span>
              <h1 class="text-2xl font-bold text-primary-dark">{{ workflow.title }}</h1>
            </div>
            <div class="flex items-center gap-2 mt-2">
              <span class="text-xs px-2 py-1 rounded-full uppercase tracking-wide" :class="statusBadgeClass">
                {{ workflow.status.replace('_', ' ') }}
              </span>
              <span class="text-xs px-2 py-1 rounded-full uppercase tracking-wide" :class="priorityBadgeClass">
                {{ workflow.priority }}
              </span>
              <span class="text-xs text-slate-500 capitalize">{{ workflow.workflow_type.replace('_', ' ') }}</span>
            </div>
          </div>

          <!-- Action buttons in header -->
          <div class="flex gap-2">
            <button
              v-if="workflow.status === 'pending'"
              @click="startWorkflow"
              class="px-4 py-2 text-sm font-medium text-white bg-accent-blue rounded-md hover:bg-accent-blue/90"
            >
              Start workflow
            </button>
            <button
              v-if="workflow.status === 'in_progress' && canAdvance"
              @click="advanceStep"
              class="px-4 py-2 text-sm font-medium text-white bg-accent-blue rounded-md hover:bg-accent-blue/90"
            >
              Complete current step
            </button>
            <button
              v-if="workflow.status === 'in_progress' && canComplete"
              @click="completeWorkflow"
              class="px-4 py-2 text-sm font-medium text-white bg-teal-600 rounded-md hover:bg-teal-700"
            >
              Complete workflow
            </button>
            <button
              v-if="workflow.status === 'in_progress' || workflow.status === 'pending'"
              @click="showCancelDialog = true"
              class="px-4 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-md hover:bg-slate-50"
            >
              Cancel
            </button>
          </div>
        </div>
      </div>

      <!-- Workflow Info -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div class="bg-white border border-slate-200 rounded-lg p-6">
          <div class="text-sm text-slate-600 mb-1">Progress</div>
          <div class="text-2xl font-bold text-primary-dark mb-2">
            {{ workflow.current_step }} / {{ workflow.total_steps }}
          </div>
          <div class="w-full bg-slate-200 rounded-full h-2">
            <div
              class="bg-accent-blue h-2 rounded-full transition-all"
              :style="{ width: `${progressPercentage}%` }"
            ></div>
          </div>
        </div>

        <div v-if="workflow.due_date" class="bg-white border border-slate-200 rounded-lg p-6">
          <div class="text-sm text-slate-600 mb-1">Due Date</div>
          <div class="text-2xl font-bold" :class="dueDateClass">
            {{ formatDate(workflow.due_date) }}
          </div>
        </div>

        <div v-if="workflow.assigned_to" class="bg-white border border-slate-200 rounded-lg p-6">
          <div class="text-sm text-slate-600 mb-1">Assigned To</div>
          <div class="text-lg font-medium text-primary-dark">
            {{ workflow.assigned_to }}
          </div>
        </div>
      </div>

      <!-- Employee and Asset Info -->
      <div v-if="workflow.employee || workflow.asset" class="bg-white border border-slate-200 rounded-lg p-6 mb-8">
        <h3 class="text-lg font-semibold text-primary-dark mb-4">Related Information</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div v-if="workflow.employee">
            <div class="text-sm text-slate-600 mb-2">Employee</div>
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 bg-accent-blue-100 rounded-full flex items-center justify-center">
                <span class="text-accent-blue-700 font-medium">
                  {{ workflow.employee.first_name[0] }}{{ workflow.employee.last_name[0] }}
                </span>
              </div>
              <div>
                <div class="font-medium text-primary-dark">
                  {{ workflow.employee.first_name }} {{ workflow.employee.last_name }}
                </div>
                <div class="text-sm text-slate-600">{{ workflow.employee.email }}</div>
              </div>
            </div>
          </div>

          <div v-if="workflow.asset">
            <div class="text-sm text-slate-600 mb-2">Asset</div>
            <div>
              <div class="font-medium text-primary-dark">{{ workflow.asset.name }}</div>
              <div class="text-sm text-slate-600">{{ workflow.asset.asset_tag }}</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Description -->
      <div v-if="workflow.description" class="bg-white border border-slate-200 rounded-lg p-6 mb-8">
        <h3 class="text-lg font-semibold text-primary-dark mb-3">Description</h3>
        <p class="text-slate-700">{{ workflow.description }}</p>
      </div>

      <!-- Workflow Steps -->
      <div class="bg-white border border-slate-200 rounded-lg p-6 mb-8">
        <div class="flex items-center justify-between mb-6">
          <h3 class="text-lg font-semibold text-primary-dark">Workflow Steps</h3>
          <div class="flex gap-2">
            <button
              v-if="workflow.status === 'pending'"
              @click="startWorkflow"
              class="px-4 py-2 text-sm font-medium text-white bg-accent-blue rounded-md hover:bg-accent-blue-700"
            >
              Start Workflow
            </button>
            <button
              v-if="workflow.status === 'in_progress' && canAdvance"
              @click="advanceStep"
              class="px-4 py-2 text-sm font-medium text-white bg-accent-blue rounded-md hover:bg-accent-blue-700"
            >
              Complete Current Step
            </button>
            <button
              v-if="workflow.status === 'in_progress' && canComplete"
              @click="completeWorkflow"
              class="px-4 py-2 text-sm font-medium text-white bg-teal-600 rounded-md hover:bg-teal-700"
            >
              Complete Workflow
            </button>
            <button
              v-if="workflow.status === 'in_progress'"
              @click="showCancelDialog = true"
              class="px-4 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-md hover:bg-slate-50"
            >
              Cancel
            </button>
          </div>
        </div>

        <div class="space-y-4">
          <div
            v-for="(step, index) in workflow.steps"
            :key="index"
            class="border border-slate-200 rounded-lg p-4"
            :class="{
              'border-accent-blue bg-accent-blue-50': index === workflow.current_step && workflow.status === 'in_progress',
              'bg-teal-50 border-teal-200': step.completed
            }"
          >
            <div class="flex items-start gap-4">
              <!-- Step Number/Status -->
              <div class="flex-shrink-0">
                <div
                  class="w-8 h-8 rounded-full flex items-center justify-center font-semibold"
                  :class="{
                    'bg-teal-600 text-white': step.completed,
                    'bg-accent-blue text-white': index === workflow.current_step && workflow.status === 'in_progress' && !step.completed,
                    'bg-slate-200 text-slate-600': !step.completed && index !== workflow.current_step
                  }"
                >
                  <svg v-if="step.completed" class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                  </svg>
                  <span v-else>{{ step.order || index + 1 }}</span>
                </div>
              </div>

              <!-- Step Content -->
              <div class="flex-1">
                <h4 class="font-semibold text-primary-dark">{{ step.name }}</h4>
                <p class="text-sm text-slate-600 mt-1">{{ step.description }}</p>

                <!-- Instructions (expandable) -->
                <div v-if="step.instructions" class="mt-3">
                  <button
                    @click="toggleInstructions(index)"
                    class="text-sm text-accent-blue hover:text-accent-blue-700 flex items-center gap-1"
                  >
                    <svg class="w-4 h-4 transition-transform" :class="{ 'rotate-180': expandedSteps.has(index) }" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                    </svg>
                    {{ expandedSteps.has(index) ? 'Hide' : 'Show' }} Instructions
                  </button>
                  <div v-if="expandedSteps.has(index)" class="mt-3 pl-4 border-l-2 border-accent-blue-300">
                    <pre class="text-sm text-slate-700 whitespace-pre-wrap font-sans">{{ step.instructions }}</pre>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Cancel Dialog -->
    <Modal v-if="showCancelDialog" :modelValue="true" @update:modelValue="showCancelDialog = false">
      <template #title>Cancel Workflow</template>
      <div>
        <p class="text-slate-700 mb-4">Are you sure you want to cancel this workflow? This action cannot be undone.</p>
        <div class="mb-4">
          <label class="block text-sm font-medium text-slate-700 mb-2">Reason for cancellation</label>
          <textarea
            v-model="cancelReason"
            rows="3"
            class="w-full px-4 py-3 text-base rounded-md border border-slate-300 shadow-sm focus:border-accent-blue focus:ring-2 focus:ring-accent-blue focus:outline-none"
            placeholder="Explain why this workflow is being cancelled..."
          ></textarea>
        </div>
        <div class="flex justify-end gap-3">
          <button
            @click="showCancelDialog = false"
            class="px-4 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-md hover:bg-slate-50"
          >
            Keep Workflow
          </button>
          <button
            @click="cancelWorkflow"
            class="px-4 py-2 text-sm font-medium text-white bg-red-600 rounded-md hover:bg-red-700"
          >
            Cancel Workflow
          </button>
        </div>
      </div>
    </Modal>
  </MainLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import MainLayout from '@/components/MainLayout.vue'
import Modal from '@/components/Modal.vue'
import api from '@/services/api'

interface WorkflowStep {
  order: number
  name: string
  description: string
  instructions?: string
  completed: boolean
}

interface Workflow {
  id: string
  workflow_type: string
  title: string
  description?: string
  status: string
  priority: string
  current_step: number
  total_steps: number
  steps: WorkflowStep[]
  due_date?: string
  assigned_to?: string
  employee?: {
    first_name: string
    last_name: string
    email: string
  }
  asset?: {
    name: string
    asset_tag: string
  }
}

const route = useRoute()
const router = useRouter()

const workflow = ref<Workflow | null>(null)
const loading = ref(false)
const expandedSteps = ref(new Set<number>())
const showCancelDialog = ref(false)
const cancelReason = ref('')

const progressPercentage = computed(() => {
  if (!workflow.value || workflow.value.total_steps === 0) return 0
  return Math.round((workflow.value.current_step / workflow.value.total_steps) * 100)
})

const canAdvance = computed(() => {
  return workflow.value && workflow.value.current_step < workflow.value.total_steps
})

const canComplete = computed(() => {
  return workflow.value && workflow.value.current_step === workflow.value.total_steps
})

const statusBadgeClass = computed(() => {
  if (!workflow.value) return ''
  const colors = {
    pending: 'bg-yellow-100 text-yellow-700 border border-yellow-200',
    in_progress: 'bg-blue-100 text-blue-700 border border-blue-200',
    completed: 'bg-teal-100 text-teal-700 border border-teal-200',
    cancelled: 'bg-slate-100 text-slate-700 border border-slate-200'
  }
  return colors[workflow.value.status as keyof typeof colors] || 'bg-slate-100 text-slate-700'
})

const priorityBadgeClass = computed(() => {
  if (!workflow.value) return ''
  const colors = {
    low: 'bg-slate-100 text-slate-600 border border-slate-200',
    normal: 'bg-blue-100 text-blue-600 border border-blue-200',
    high: 'bg-orange-100 text-orange-600 border border-orange-200',
    urgent: 'bg-red-100 text-red-600 border border-red-200'
  }
  return colors[workflow.value.priority as keyof typeof colors] || 'bg-slate-100 text-slate-600'
})

const dueDateClass = computed(() => {
  if (!workflow.value?.due_date) return 'text-primary-dark'
  const dueDate = new Date(workflow.value.due_date)
  const today = new Date()
  const isOverdue = dueDate < today && workflow.value.status !== 'completed'
  return isOverdue ? 'text-red-600' : 'text-primary-dark'
})

const fetchWorkflow = async () => {
  loading.value = true
  try {
    const response = await api.get(`/workflows/${route.params.id}`)
    workflow.value = response.data.data
  } catch (error) {
    console.error('Error fetching workflow:', error)
    router.push('/workflows')
  } finally {
    loading.value = false
  }
}

const startWorkflow = async () => {
  try {
    await api.post(`/workflows/${route.params.id}/start`)
    await fetchWorkflow()
  } catch (error) {
    console.error('Error starting workflow:', error)
  }
}

const advanceStep = async () => {
  try {
    await api.post(`/workflows/${route.params.id}/advance`)
    await fetchWorkflow()
  } catch (error) {
    console.error('Error advancing workflow:', error)
  }
}

const completeWorkflow = async () => {
  try {
    await api.post(`/workflows/${route.params.id}/complete`)
    await fetchWorkflow()
  } catch (error) {
    console.error('Error completing workflow:', error)
  }
}

const cancelWorkflow = async () => {
  try {
    await api.post(`/workflows/${route.params.id}/cancel`, { reason: cancelReason.value })
    showCancelDialog.value = false
    await fetchWorkflow()
  } catch (error) {
    console.error('Error cancelling workflow:', error)
  }
}

const toggleInstructions = (index: number) => {
  if (expandedSteps.value.has(index)) {
    expandedSteps.value.delete(index)
  } else {
    expandedSteps.value.add(index)
  }
}

const formatDate = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })
}

onMounted(() => {
  fetchWorkflow()
})
</script>
