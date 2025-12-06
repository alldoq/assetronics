<template>
  <MainLayout>
    <div>
      <!-- Page header -->
      <div class="mb-6">
        <div class="flex items-center gap-3 mb-2">
          <router-link to="/settings" class="text-slate-500 hover:text-primary-dark transition-colors">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
          </router-link>
          <h1 class="text-3xl font-bold text-primary-dark">Notification preferences</h1>
        </div>
        <p class="text-slate-600 mt-1">Manage how you receive notifications across different channels</p>
      </div>

      <!-- Success message -->
      <div v-if="successMessage" class="mb-6 p-4 rounded-xl bg-teal-50 border border-teal-200 text-teal-800">
        {{ successMessage }}
      </div>

      <!-- Error message -->
      <div v-if="errorMessage" class="mb-6 p-4 rounded-xl bg-red-50 border border-red-200 text-red-800">
        {{ errorMessage }}
      </div>

      <!-- Loading state -->
      <div v-if="isLoading" class="bg-white border border-slate-200 rounded-lg p-8 text-center shadow-subtle">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-accent-blue mx-auto mb-4"></div>
        <p class="text-slate-700">Loading notification preferences...</p>
      </div>

      <!-- Preferences list -->
      <div v-else class="space-y-4">
        <div
          v-for="pref in notificationPreferences"
          :key="pref.notification_type"
          class="bg-white border border-slate-200 rounded-lg p-5 shadow-subtle"
        >
          <div class="flex items-start justify-between mb-4">
            <div>
              <h3 class="text-lg font-bold text-primary-dark">{{ formatNotificationType(pref.notification_type) }}</h3>
              <p class="text-sm text-slate-600 mt-1">{{ getNotificationDescription(pref.notification_type) }}</p>
            </div>
          </div>

          <!-- Channels -->
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
            <label class="flex items-center gap-3 p-3 rounded-lg border border-slate-200 cursor-pointer hover:bg-light-bg transition-colors">
              <input
                type="checkbox"
                :checked="pref.channels.email"
                @change="updateChannel(pref.notification_type, 'email', $event)"
                class="w-5 h-5 text-accent-blue border-slate-300 rounded focus:ring-accent-blue"
              />
              <div class="flex-1">
                <div class="text-sm font-medium text-primary-dark">Email</div>
              </div>
            </label>

            <label class="flex items-center gap-3 p-3 rounded-lg border border-slate-200 cursor-pointer hover:bg-light-bg transition-colors">
              <input
                type="checkbox"
                :checked="pref.channels.in_app"
                @change="updateChannel(pref.notification_type, 'in_app', $event)"
                class="w-5 h-5 text-accent-blue border-slate-300 rounded focus:ring-accent-blue"
              />
              <div class="flex-1">
                <div class="text-sm font-medium text-primary-dark">In-app</div>
              </div>
            </label>

            <label class="flex items-center gap-3 p-3 rounded-lg border border-slate-200 cursor-pointer hover:bg-light-bg transition-colors">
              <input
                type="checkbox"
                :checked="pref.channels.sms"
                @change="updateChannel(pref.notification_type, 'sms', $event)"
                class="w-5 h-5 text-accent-blue border-slate-300 rounded focus:ring-accent-blue"
              />
              <div class="flex-1">
                <div class="text-sm font-medium text-primary-dark">SMS</div>
              </div>
            </label>

            <label class="flex items-center gap-3 p-3 rounded-lg border border-slate-200 cursor-pointer hover:bg-light-bg transition-colors">
              <input
                type="checkbox"
                :checked="pref.channels.push"
                @change="updateChannel(pref.notification_type, 'push', $event)"
                class="w-5 h-5 text-accent-blue border-slate-300 rounded focus:ring-accent-blue"
              />
              <div class="flex-1">
                <div class="text-sm font-medium text-primary-dark">Push</div>
              </div>
            </label>
          </div>

          <!-- Additional options -->
          <div class="flex flex-col sm:flex-row gap-4 pt-4 border-t border-slate-200">
            <div class="w-full sm:w-48">
              <label class="block text-sm font-medium text-primary-dark mb-2">Frequency</label>
              <select
                :value="pref.frequency"
                @change="updateFrequency(pref.notification_type, $event)"
                class="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-accent-blue focus:border-transparent"
              >
                <option value="immediate">Immediate</option>
                <option value="daily_digest">Daily digest</option>
                <option value="weekly_digest">Weekly digest</option>
                <option value="off">Off</option>
              </select>
            </div>

            <div class="flex items-end">
              <label class="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  :checked="pref.respect_quiet_hours"
                  @change="updateQuietHours(pref.notification_type, $event)"
                  class="w-5 h-5 text-accent-blue border-slate-300 rounded focus:ring-accent-blue"
                />
                <span class="text-sm font-medium text-primary-dark">Respect quiet hours</span>
              </label>
            </div>
          </div>
        </div>
      </div>
    </div>
  </MainLayout>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import MainLayout from '@/components/MainLayout.vue'
import { settingsApi, type NotificationPreference } from '@/services/api'

const notificationPreferences = ref<NotificationPreference[]>([])
const isLoading = ref(false)
const successMessage = ref('')
const errorMessage = ref('')

const notificationTypes = {
  asset_assigned: {
    title: 'Asset assigned',
    description: 'When an asset is assigned to you',
  },
  asset_returned: {
    title: 'Asset returned',
    description: 'When an asset assigned to you is returned',
  },
  asset_due_soon: {
    title: 'Asset due soon',
    description: 'Reminders when an asset return date is approaching',
  },
  workflow_assigned: {
    title: 'Workflow assigned',
    description: 'When a workflow task is assigned to you',
  },
  workflow_completed: {
    title: 'Workflow completed',
    description: 'When a workflow you created is completed',
  },
  workflow_overdue: {
    title: 'Workflow overdue',
    description: 'When a workflow task assigned to you is overdue',
  },
  integration_sync_failed: {
    title: 'Integration sync failed',
    description: 'When an integration sync encounters an error',
  },
  security_alert: {
    title: 'Security alert',
    description: 'Important security notifications',
  },
  system_announcement: {
    title: 'System announcement',
    description: 'Important system updates and announcements',
  },
}

const formatNotificationType = (type: string): string => {
  return notificationTypes[type as keyof typeof notificationTypes]?.title || type
}

const getNotificationDescription = (type: string): string => {
  return notificationTypes[type as keyof typeof notificationTypes]?.description || ''
}

const loadPreferences = async () => {
  isLoading.value = true
  errorMessage.value = ''

  try {
    notificationPreferences.value = await settingsApi.getUserNotificationPreferences()
  } catch (error: any) {
    errorMessage.value = error.response?.data?.message || 'Failed to load notification preferences'
    console.error('Failed to load preferences:', error)
  } finally {
    isLoading.value = false
  }
}

const updateChannel = async (notificationType: string, channel: string, event: Event) => {
  const target = event.target as HTMLInputElement
  const enabled = target.checked

  try {
    const pref = notificationPreferences.value.find(p => p.notification_type === notificationType)
    if (!pref) return

    const updatedChannels = { ...pref.channels, [channel]: enabled }

    await settingsApi.updateUserNotificationPreference(notificationType, {
      ...pref,
      channels: updatedChannels,
    })

    // Update local state
    pref.channels = updatedChannels

    successMessage.value = 'Notification preference updated'
    setTimeout(() => {
      successMessage.value = ''
    }, 3000)
  } catch (error: any) {
    errorMessage.value = error.response?.data?.message || 'Failed to update notification preference'
    // Revert the checkbox
    target.checked = !enabled
    setTimeout(() => {
      errorMessage.value = ''
    }, 5000)
  }
}

const updateFrequency = async (notificationType: string, event: Event) => {
  const target = event.target as HTMLSelectElement
  const frequency = target.value as NotificationPreference['frequency']

  try {
    const pref = notificationPreferences.value.find(p => p.notification_type === notificationType)
    if (!pref) return

    await settingsApi.updateUserNotificationPreference(notificationType, {
      ...pref,
      frequency,
    })

    // Update local state
    pref.frequency = frequency

    successMessage.value = 'Notification frequency updated'
    setTimeout(() => {
      successMessage.value = ''
    }, 3000)
  } catch (error: any) {
    errorMessage.value = error.response?.data?.message || 'Failed to update notification frequency'
    setTimeout(() => {
      errorMessage.value = ''
    }, 5000)
  }
}

const updateQuietHours = async (notificationType: string, event: Event) => {
  const target = event.target as HTMLInputElement
  const respectQuietHours = target.checked

  try {
    const pref = notificationPreferences.value.find(p => p.notification_type === notificationType)
    if (!pref) return

    await settingsApi.updateUserNotificationPreference(notificationType, {
      ...pref,
      respect_quiet_hours: respectQuietHours,
    })

    // Update local state
    pref.respect_quiet_hours = respectQuietHours

    successMessage.value = 'Quiet hours preference updated'
    setTimeout(() => {
      successMessage.value = ''
    }, 3000)
  } catch (error: any) {
    errorMessage.value = error.response?.data?.message || 'Failed to update quiet hours preference'
    // Revert the checkbox
    target.checked = !respectQuietHours
    setTimeout(() => {
      errorMessage.value = ''
    }, 5000)
  }
}

onMounted(() => {
  loadPreferences()
})
</script>
