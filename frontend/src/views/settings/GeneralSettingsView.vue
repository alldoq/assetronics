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
          <h1 class="text-3xl font-bold text-primary-dark">General settings</h1>
        </div>
        <p class="text-slate-600 mt-1">Manage system-wide configuration and defaults</p>
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
        <p class="text-slate-700">Loading settings...</p>
      </div>

      <!-- Settings form -->
      <form v-else @submit.prevent="saveSettings" class="space-y-6">
        <!-- Quiet Hours -->
        <div class="bg-white border border-slate-200 rounded-lg p-6 shadow-subtle">
          <h2 class="text-xl font-bold text-primary-dark mb-4 flex items-center gap-2">
            <svg class="w-6 h-6 text-accent-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
            </svg>
            Default quiet hours
          </h2>

          <div class="space-y-4">
            <label class="flex items-center gap-2">
              <input v-model="settings.quiet_hours!.enabled" type="checkbox" class="w-5 h-5 text-accent-blue border-slate-300 rounded focus:ring-accent-blue" />
              <span class="font-medium text-primary-dark">Enable default quiet hours</span>
            </label>

            <div v-if="settings.quiet_hours!.enabled" class="pl-7 space-y-4 pt-2 border-l-2 border-accent-blue/20">
              <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                  <label class="block text-sm font-medium text-primary-dark mb-2">Start time</label>
                  <input
                    v-model="settings.quiet_hours!.start"
                    type="time"
                    class="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-accent-blue focus:border-transparent"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-primary-dark mb-2">End time</label>
                  <input
                    v-model="settings.quiet_hours!.end"
                    type="time"
                    class="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-accent-blue focus:border-transparent"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-primary-dark mb-2">Timezone</label>
                  <input
                    v-model="settings.quiet_hours!.timezone"
                    type="text"
                    placeholder="UTC"
                    class="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-accent-blue focus:border-transparent"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Workflow Settings -->
        <div class="bg-white border border-slate-200 rounded-lg p-6 shadow-subtle">
          <h2 class="text-xl font-bold text-primary-dark mb-4 flex items-center gap-2">
            <svg class="w-6 h-6 text-accent-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
            </svg>
            Workflow defaults
          </h2>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-4 max-w-3xl">
            <label class="flex items-center gap-2">
              <input v-model="settings.workflow!.auto_create_onboarding" type="checkbox" class="w-5 h-5 text-accent-blue border-slate-300 rounded focus:ring-accent-blue" />
              <span class="text-sm font-medium text-primary-dark">Auto-create onboarding workflows</span>
            </label>
            <label class="flex items-center gap-2">
              <input v-model="settings.workflow!.auto_create_offboarding" type="checkbox" class="w-5 h-5 text-accent-blue border-slate-300 rounded focus:ring-accent-blue" />
              <span class="text-sm font-medium text-primary-dark">Auto-create offboarding workflows</span>
            </label>
            <div>
              <label class="block text-sm font-medium text-primary-dark mb-2">Default priority</label>
              <select v-model="settings.workflow!.default_priority" class="w-48 px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-accent-blue focus:border-transparent">
                <option value="low">Low</option>
                <option value="normal">Normal</option>
                <option value="high">High</option>
                <option value="urgent">Urgent</option>
              </select>
            </div>
            <div>
              <label class="block text-sm font-medium text-primary-dark mb-2">Default due days</label>
              <input
                v-model.number="settings.workflow!.default_due_days"
                type="number"
                min="1"
                class="w-32 px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-accent-blue focus:border-transparent"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-primary-dark mb-2">Auto-escalate after (days)</label>
              <input
                v-model.number="settings.workflow!.auto_escalate_days"
                type="number"
                min="0"
                class="w-32 px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-accent-blue focus:border-transparent"
              />
            </div>
            <label class="flex items-center gap-2">
              <input v-model="settings.workflow!.notify_manager_overdue" type="checkbox" class="w-5 h-5 text-accent-blue border-slate-300 rounded focus:ring-accent-blue" />
              <span class="text-sm font-medium text-primary-dark">Notify manager on overdue</span>
            </label>
          </div>
        </div>

        <!-- Security Settings -->
        <div class="bg-white border border-slate-200 rounded-lg p-6 shadow-subtle">
          <h2 class="text-xl font-bold text-primary-dark mb-4 flex items-center gap-2">
            <svg class="w-6 h-6 text-accent-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
            </svg>
            Security & access
          </h2>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-4 max-w-3xl">
            <label class="flex items-center gap-2 md:col-span-2">
              <input v-model="settings.security!.require_2fa" type="checkbox" class="w-5 h-5 text-accent-blue border-slate-300 rounded focus:ring-accent-blue" />
              <span class="text-sm font-medium text-primary-dark">Require two-factor authentication</span>
            </label>
            <label class="flex items-center gap-2 md:col-span-2">
              <input v-model="settings.security!.require_strong_passwords" type="checkbox" class="w-5 h-5 text-accent-blue border-slate-300 rounded focus:ring-accent-blue" />
              <span class="text-sm font-medium text-primary-dark">Require strong passwords</span>
            </label>
            <div>
              <label class="block text-sm font-medium text-primary-dark mb-2">Session timeout (minutes)</label>
              <input
                v-model.number="settings.security!.session_timeout_minutes"
                type="number"
                min="1"
                class="w-32 px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-accent-blue focus:border-transparent"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-primary-dark mb-2">Failed login lockout count</label>
              <input
                v-model.number="settings.security!.failed_login_lockout_count"
                type="number"
                min="1"
                class="w-32 px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-accent-blue focus:border-transparent"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-primary-dark mb-2">Lockout duration (minutes)</label>
              <input
                v-model.number="settings.security!.lockout_duration_minutes"
                type="number"
                min="1"
                class="w-32 px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-accent-blue focus:border-transparent"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-primary-dark mb-2">API key expiration (days)</label>
              <input
                v-model.number="settings.security!.api_key_expiration_days"
                type="number"
                min="1"
                class="w-32 px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-accent-blue focus:border-transparent"
              />
            </div>
          </div>
        </div>

        <!-- Save button -->
        <div class="flex justify-end gap-4">
          <button
            type="button"
            @click="loadSettings"
            class="px-6 py-2 border border-slate-300 rounded-lg text-primary-dark hover:bg-light-bg transition-colors"
          >
            Reset
          </button>
          <button
            type="submit"
            :disabled="isSaving"
            class="btn-brand-primary"
          >
            <span v-if="isSaving" class="flex items-center gap-2">
              <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
              Saving...
            </span>
            <span v-else>Save settings</span>
          </button>
        </div>
      </form>
    </div>
  </MainLayout>
</template>

<script setup lang="ts">
import { ref, onMounted, reactive } from 'vue'
import { useRouter } from 'vue-router'
import MainLayout from '@/components/MainLayout.vue'
import { settingsApi, type TenantSettings } from '@/services/api'
import { usePermissions } from '@/composables/usePermissions'

const router = useRouter()
const { canViewTenantSettings } = usePermissions()

// Redirect if user doesn't have permission
if (!canViewTenantSettings.value) {
  router.push('/settings')
}

const settings = reactive<Partial<TenantSettings>>({
  quiet_hours: { enabled: false, start: '', end: '', timezone: 'UTC' },
  workflow: {
    auto_create_onboarding: true,
    auto_create_offboarding: true,
    default_priority: 'normal',
    default_due_days: 7,
    auto_escalate_days: 3,
    notify_manager_overdue: true,
  },
  security: {
    require_2fa: false,
    session_timeout_minutes: 480,
    failed_login_lockout_count: 5,
    lockout_duration_minutes: 30,
    require_strong_passwords: true,
    api_key_expiration_days: 365,
  },
})

const isLoading = ref(false)
const isSaving = ref(false)
const successMessage = ref('')
const errorMessage = ref('')

const loadSettings = async () => {
  isLoading.value = true
  errorMessage.value = ''

  try {
    const data = await settingsApi.getTenantSettings()
    Object.assign(settings, data)
  } catch (error: any) {
    errorMessage.value = error.response?.data?.message || 'Failed to load settings'
    console.error('Failed to load settings:', error)
  } finally {
    isLoading.value = false
  }
}

const saveSettings = async () => {
  isSaving.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    await settingsApi.updateTenantSettings(settings)
    successMessage.value = 'Settings saved successfully'
    setTimeout(() => {
      successMessage.value = ''
    }, 5000)
  } catch (error: any) {
    errorMessage.value = error.response?.data?.message || 'Failed to save settings'
    console.error('Failed to save settings:', error)
  } finally {
    isSaving.value = false
  }
}

onMounted(() => {
  loadSettings()
})
</script>
