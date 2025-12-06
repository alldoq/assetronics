<template>
  <div class="bg-white border border-slate-200 rounded-lg p-5 flex items-start gap-4 hover:border-accent-blue transition-colors relative">
    <!-- Icon -->
    <div class="p-3 bg-slate-50 rounded-lg border border-slate-100 shrink-0">
      <!-- Windows / Intune -->
      <svg v-if="icon === 'windows'" class="w-8 h-8 text-blue-600" viewBox="0 0 24 24" fill="currentColor">
        <path d="M0 3.449L9.75 2.1v9.451H0m10.949-9.602L24 0v11.4h-13.051M0 12.6h9.75v9.451L0 20.699M10.949 12.6H24V24l-12.9-1.801"/>
      </svg>
      
      <!-- Apple / Jamf -->
      <svg v-if="icon === 'apple'" class="w-8 h-8 text-slate-800" viewBox="0 0 24 24" fill="currentColor">
        <path d="M17.05 20.28c-.98.95-2.05.88-3.08.35-1.09-.56-2.18-.48-3.15.05-1.04.56-1.81.98-2.91.05-2.6-2.28-4.27-9.01-1.62-11.71 1.55-1.58 4.34-1.72 5.83-.35.33.28.67.53 1 .8.34-.27.67-.52 1-.8 1.49-1.37 4.28-1.23 5.83.35 1.13 1.16 2.06 3.01 2.06 3.07 0 .09-.09.28-.21.32-2.93 1.19-3.69 4.86-1.51 7.13.1.1.23.23.33.33-.26.68-.52 1.37-.78 2.05-.34.92-.99 1.83-1.8 2.31zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/>
      </svg>

      <!-- Google -->
      <svg v-if="icon === 'google'" class="w-8 h-8" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M23.52 12.27c0-.85-.08-1.68-.22-2.48H12v4.69h6.46c-.28 1.48-1.12 2.73-2.39 3.58v2.98h3.87c2.26-2.08 3.57-5.15 3.57-8.77z" fill="#4285F4"/>
        <path d="M12 24c3.24 0 5.96-1.08 7.94-2.91l-3.87-2.98c-1.08.72-2.45 1.15-4.07 1.15-3.14 0-5.79-2.12-6.74-4.97H1.29v3.13C3.26 21.31 7.37 24 12 24z" fill="#34A853"/>
        <path d="M5.26 14.29c-.24-.71-.37-1.47-.37-2.29s.13-1.58.37-2.29V6.58H1.29C.47 8.24 0 10.07 0 12s.47 3.76 1.29 5.42l3.97-3.13z" fill="#FBBC05"/>
        <path d="M12 4.75c1.76 0 3.34.6 4.58 1.79l3.43-3.43C17.96 1.17 15.24 0 12 0 7.37 0 3.26 2.69 1.29 6.58l3.97 3.13c.95-2.85 3.6-4.96 6.74-4.96z" fill="#EA4335"/>
      </svg>

      <!-- Users / Okta -->
      <svg v-if="icon === 'user-group'" class="w-8 h-8 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
      </svg>

      <!-- Truck / Dell -->
      <svg v-if="icon === 'truck'" class="w-8 h-8 text-blue-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M13 16V6a1 1 0 00-1-1H4a1 1 0 00-1 1v10a1 1 0 001 1h9zm0 0h5.5a2.5 2.5 0 010 5M13 16l5-8h4l2 8h-6m-2 0a2 2 0 100 4 2 2 0 000-4zM5 18a2 2 0 100 4 2 2 0 000-4z" />
      </svg>

      <!-- Bamboo / BambooHR -->
      <svg v-if="icon === 'bamboo'" class="w-8 h-8 text-accent-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 4v16m0-16c2 2 4 3 6 3M12 4c-2 2-4 3-6 3m6 5c1.5 1.5 3 2 4.5 2M12 13c-1.5 1.5-3 2-4.5 2" />
        <circle cx="12" cy="3" r="1.5" fill="currentColor"/>
        <circle cx="12" cy="9" r="1.5" fill="currentColor"/>
        <circle cx="12" cy="15" r="1.5" fill="currentColor"/>
        <circle cx="12" cy="21" r="1.5" fill="currentColor"/>
      </svg>

      <!-- Building / Workday -->
      <svg v-if="icon === 'building'" class="w-8 h-8 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
      </svg>

      <!-- Shield / Okta (Alternative for HRIS context) -->
      <svg v-if="icon === 'shield'" class="w-8 h-8 text-indigo-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
      </svg>

      <!-- Dollar / Finance -->
      <svg v-if="icon === 'dollar'" class="w-8 h-8 text-accent-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>

      <!-- Slack -->
      <svg v-if="icon === 'slack'" class="w-8 h-8" viewBox="0 0 24 24" fill="none">
        <path d="M5.042 15.165a2.528 2.528 0 0 1-2.52 2.523A2.528 2.528 0 0 1 0 15.165a2.527 2.527 0 0 1 2.522-2.52h2.52v2.52zM6.313 15.165a2.527 2.527 0 0 1 2.521-2.52 2.527 2.527 0 0 1 2.521 2.52v6.313A2.528 2.528 0 0 1 8.834 24a2.528 2.528 0 0 1-2.521-2.522v-6.313z" fill="#E01E5A"/>
        <path d="M8.834 5.042a2.528 2.528 0 0 1-2.521-2.52A2.528 2.528 0 0 1 8.834 0a2.528 2.528 0 0 1 2.521 2.522v2.52H8.834zM8.834 6.313a2.528 2.528 0 0 1 2.521 2.521 2.528 2.528 0 0 1-2.521 2.521H2.522A2.528 2.528 0 0 1 0 8.834a2.528 2.528 0 0 1 2.522-2.521h6.312z" fill="#36C5F0"/>
        <path d="M18.956 8.834a2.528 2.528 0 0 1 2.522-2.521A2.528 2.528 0 0 1 24 8.834a2.528 2.528 0 0 1-2.522 2.521h-2.522V8.834zM17.688 8.834a2.528 2.528 0 0 1-2.523 2.521 2.527 2.527 0 0 1-2.52-2.521V2.522A2.527 2.527 0 0 1 15.165 0a2.528 2.528 0 0 1 2.523 2.522v6.312z" fill="#2EB67D"/>
        <path d="M15.165 18.956a2.528 2.528 0 0 1 2.523 2.522A2.528 2.528 0 0 1 15.165 24a2.527 2.527 0 0 1-2.52-2.522v-2.522h2.52zM15.165 17.688a2.527 2.527 0 0 1-2.52-2.523 2.526 2.526 0 0 1 2.52-2.52h6.313A2.527 2.527 0 0 1 24 15.165a2.528 2.528 0 0 1-2.522 2.523h-6.313z" fill="#ECB22E"/>
      </svg>
    </div>

    <!-- Content -->
    <div class="flex-1">
      <div class="flex justify-between items-start">
        <div>
          <h3 class="font-bold text-primary-dark">{{ name }}</h3>
          <span class="text-xs font-medium px-2 py-0.5 rounded-full bg-slate-100 text-slate-600 border border-slate-200 uppercase tracking-wide">{{ type }}</span>
        </div>
        <!-- Status indicator -->
        <div class="flex flex-col items-end gap-1">
           <div class="flex items-center gap-2">
             <span
               class="w-2 h-2 rounded-full"
               :class="statusColorClass"
             ></span>
             <span
               class="text-xs font-medium"
               :class="statusTextClass"
             >
               {{ statusLabel }}
             </span>
           </div>
           <span v-if="lastSync && status === 'active'" class="text-[10px] text-slate-400">
             Synced {{ formatDate(lastSync) }}
           </span>
        </div>
      </div>
      
      <p class="text-sm text-slate-600 mt-2">{{ description }}</p>
      
      <div class="mt-4">
        <button
          @click="$emit('configure')"
          class="px-4 py-2 text-sm font-medium text-primary-dark bg-white border border-slate-300 rounded-md hover:bg-slate-50 hover:border-slate-400 transition-all focus:outline-none focus:ring-2 focus:ring-offset-1 focus:ring-accent-blue"
        >
          {{ isConfigured ? 'Manage' : 'Connect' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, watch } from 'vue'

const props = defineProps<{
  name: string
  description: string
  provider: string
  type: string
  icon: string
  status?: string  // Integration status from backend
  lastSync?: string
}>()

defineEmits(['configure'])

const isConfigured = computed(() => props.status !== undefined && props.status !== null)

const statusLabel = computed(() => {
  if (!props.status) return 'Not Connected'
  switch (props.status) {
    case 'active': return 'Active'
    case 'error': return 'Error'
    case 'syncing': return 'Syncing...'
    case 'inactive': return 'Inactive'
    default: return 'Not Connected'
  }
})

const statusColorClass = computed(() => {
  if (!props.status) return 'bg-slate-300'
  switch (props.status) {
    case 'active': return 'bg-accent-blue'
    case 'error': return 'bg-red-500'
    case 'syncing': return 'bg-accent-blue animate-pulse'
    case 'inactive': return 'bg-slate-400'
    default: return 'bg-slate-300'
  }
})

const statusTextClass = computed(() => {
  if (!props.status) return 'text-slate-500'
  switch (props.status) {
    case 'active': return 'text-accent-blue'
    case 'error': return 'text-red-600'
    case 'syncing': return 'text-accent-blue'
    case 'inactive': return 'text-slate-600'
    default: return 'text-slate-500'
  }
})

const formatDate = (dateString: string) => {
  const date = new Date(dateString)
  const now = new Date()
  const diff = now.getTime() - date.getTime()
  
  // If less than 24 hours, show relative time
  if (diff < 24 * 60 * 60 * 1000) {
    const hours = Math.floor(diff / (1000 * 60 * 60))
    if (hours < 1) return 'Just now'
    return `${hours}h ago`
  }
  
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric'
  }).format(date)
}

// Watch for status changes
watch(() => props.status, (newStatus, oldStatus) => {
  console.log(`[IntegrationCard] ${props.provider} - status changed from ${oldStatus} to ${newStatus}`)
}, { immediate: true })
</script>
