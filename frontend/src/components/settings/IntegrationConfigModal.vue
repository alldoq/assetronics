<template>
  <Modal :modelValue="true" @update:modelValue="handleClose">
    <template #title>{{ isEditMode ? 'Manage' : 'Configure' }} {{ providerName }}</template>
    <div>
      <div class="mb-6 flex items-center gap-4 pb-6 border-b border-slate-200">
        <!-- Dynamic Icon based on provider -->
        <div class="p-3 bg-gradient-to-br from-cyan-50 to-blue-50 rounded-xl border border-accent-blue/20">
           <svg v-if="props.provider === 'intune'" class="w-8 h-8 text-blue-600" viewBox="0 0 24 24" fill="currentColor"><path d="M0 3.449L9.75 2.1v9.451H0m10.949-9.602L24 0v11.4h-13.051M0 12.6h9.75v9.451L0 20.699M10.949 12.6H24V24l-12.9-1.801"/></svg>
           <svg v-else-if="props.provider === 'jamf'" class="w-8 h-8 text-slate-800" viewBox="0 0 24 24" fill="currentColor"><path d="M17.05 20.28c-.98.95-2.05.88-3.08.35-1.09-.56-2.18-.48-3.15.05-1.04.56-1.81.98-2.91.05-2.6-2.28-4.27-9.01-1.62-11.71 1.55-1.58 4.34-1.72 5.83-.35.33.28.67.53 1 .8.34-.27.67-.52 1-.8 1.49-1.37 4.28-1.23 5.83.35 1.13 1.16 2.06 3.01 2.06 3.07 0 .09-.09.28-.21.32-2.93 1.19-3.69 4.86-1.51 7.13.1.1.23.23.33.33-.26.68-.52 1.37-.78 2.05-.34.92-.99 1.83-1.8 2.31zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/></svg>
           <svg v-else-if="props.provider === 'okta'" class="w-8 h-8 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" /></svg>
           <svg v-else-if="props.provider === 'bamboohr'" class="w-8 h-8 text-accent-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" /></svg>
           <svg v-else-if="props.provider === 'google_workspace'" class="w-8 h-8 text-blue-600" viewBox="0 0 24 24" fill="currentColor"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/></svg>
           <svg v-else class="w-8 h-8 text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" /></svg>
        </div>

        <div>
          <h2 class="text-2xl font-bold text-primary-dark">{{ isEditMode ? 'Manage' : 'Configure' }} {{ providerName }}</h2>
          <p class="text-sm text-slate-600 mt-1">{{ isEditMode ? 'Manage sync settings and credentials.' : 'Enter your credentials to enable sync.' }}</p>
        </div>
      </div>

      <!-- Connected Integration View -->
      <div v-if="isConnected" class="space-y-4">
        <!-- Status Banner -->
        <div class="p-4 bg-cyan-50 border border-accent-blue/30 rounded-lg flex items-center gap-3">
          <div class="w-2 h-2 bg-accent-blue rounded-full"></div>
          <div class="flex-1">
            <p class="text-sm font-medium text-primary-dark">Connected</p>
            <p class="text-xs text-slate-600 mt-0.5" v-if="props.existingIntegration?.last_sync_at">
              Last synced: {{ formatDate(props.existingIntegration.last_sync_at) }}
            </p>
          </div>
        </div>

        <!-- Sync Controls -->
        <div class="space-y-4">
          <div>
            <label class="flex items-center gap-2 mb-3">
              <input
                type="checkbox"
                v-model="form.sync_enabled"
                @change="toggleAutoSync"
                class="rounded border-slate-300 text-accent-blue focus:ring-accent-blue"
              >
              <span class="text-sm font-medium text-primary-dark">Enable automatic sync</span>
            </label>

            <div v-if="form.sync_enabled" class="ml-6">
              <label class="block text-sm font-medium text-slate-700 mb-2">Sync Frequency</label>
              <select
                v-model="form.sync_frequency"
                @change="updateSyncSettings"
                class="w-full px-4 py-2 text-sm rounded-md border border-slate-300 shadow-sm focus:border-accent-blue focus:ring-2 focus:ring-accent-blue focus:outline-none"
              >
                <option value="hourly">Hourly</option>
                <option value="daily">Daily</option>
                <option value="weekly">Weekly</option>
              </select>
            </div>
          </div>

          <!-- Last Sync Status -->
          <div v-if="props.existingIntegration?.last_sync_status" class="p-3 rounded-md text-sm" :class="getSyncStatusClass()">
            <p class="font-medium">
              Last Sync: {{ props.existingIntegration.last_sync_status === 'success' ? '✓ Success' : '✗ Failed' }}
            </p>
            <p v-if="props.existingIntegration.last_sync_error" class="text-xs mt-1 opacity-90">
              {{ props.existingIntegration.last_sync_error }}
            </p>
          </div>
        </div>

        <!-- Footer Actions -->
        <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-slate-200">
          <button
            @click="$emit('close')"
            type="button"
            class="px-6 py-3 text-sm font-semibold text-slate-700 bg-white border-2 border-slate-300 rounded-xl hover:bg-slate-50 transition-all"
          >
            Close
          </button>
          <button
            @click="manualSync"
            :disabled="syncing"
            type="button"
            class="px-6 py-3 text-sm font-semibold text-primary-dark bg-white border-2 border-slate-300 rounded-xl hover:bg-slate-50 hover:border-slate-400 disabled:bg-slate-100 disabled:text-slate-400 disabled:cursor-not-allowed flex items-center gap-2 transition-all"
          >
            <svg v-if="syncing" class="animate-spin h-4 w-4" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            <svg v-else class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
            {{ syncing ? 'Syncing...' : 'Sync now' }}
          </button>
        </div>
      </div>

      <!-- New Integration Form -->
      <form v-else @submit.prevent="saveIntegration" class="space-y-4">

        <!-- Base URL (Common) -->
        <div v-if="hasBaseUrl">
          <label class="block text-sm font-medium text-slate-700 mb-2">
            {{ provider === 'jamf' ? 'Jamf Pro Instance URL' : 'Instance URL / Tenant Domain' }}
          </label>
          <input
            v-model="form.base_url"
            type="text"
            class="w-full px-4 py-3 text-base rounded-md border border-slate-300 shadow-sm focus:border-accent-blue focus:ring-2 focus:ring-accent-blue focus:outline-none"
            :placeholder="baseUrlPlaceholder"
            required
          >
          <p v-if="provider === 'jamf'" class="text-xs text-slate-500 mt-1">
            This is your Jamf Pro server URL (e.g., https://yourcompany.jamfcloud.com)
          </p>
        </div>

        <!-- Google Workspace (Service Account JSON) -->
        <div v-if="provider === 'google_workspace'">
          <div class="mb-4 p-3 bg-blue-50 border border-blue-200 rounded-md">
            <p class="text-xs text-blue-800">
              <strong>Google Workspace Service Account Setup:</strong><br>
              1. Go to Google Cloud Console → IAM & Admin → Service Accounts<br>
              2. Create a service account with Admin SDK API access<br>
              3. Enable domain-wide delegation<br>
              4. Download the JSON key file and paste its contents below<br>
              5. Provide an admin email for domain-wide delegation
            </p>
          </div>

          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-slate-700 mb-2">Admin Email (required)</label>
              <input
                v-model="form.admin_email"
                type="email"
                class="w-full px-4 py-3 text-base rounded-md border border-slate-300 shadow-sm focus:border-accent-blue focus:ring-2 focus:ring-accent-blue focus:outline-none"
                placeholder="admin@yourdomain.com"
                required
              >
              <p class="text-xs text-slate-500 mt-1">
                A Google Workspace admin email address for domain-wide delegation
              </p>
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 mb-2">Service Account JSON</label>
              <textarea
                v-model="form.service_account_json"
                rows="8"
                class="w-full px-4 py-3 text-sm font-mono rounded-md border border-slate-300 shadow-sm focus:border-accent-blue focus:ring-2 focus:ring-accent-blue focus:outline-none"
                placeholder='{"type": "service_account", "project_id": "...", ...}'
                required
              ></textarea>
              <p class="text-xs text-slate-500 mt-1">
                Paste the entire contents of your service account JSON key file
              </p>
            </div>
          </div>
        </div>

        <!-- BambooHR Simplified (API Key Only) -->
        <div v-else-if="provider === 'bamboohr'">
          <div class="mb-4 p-3 bg-blue-50 border border-blue-200 rounded-md">
            <p class="text-xs text-blue-800">
              <strong>BambooHR API Key Setup:</strong><br>
              1. Log into your BambooHR account<br>
              2. Go to Settings → API Keys<br>
              3. Click "Add New Key" and copy it below
            </p>
          </div>

          <div>
            <label class="block text-sm font-medium text-slate-700 mb-2">API Key</label>
            <input
              v-model="form.client_secret"
              type="password"
              class="w-full px-4 py-3 text-base rounded-md border border-slate-300 shadow-sm focus:border-accent-blue focus:ring-2 focus:ring-accent-blue focus:outline-none"
              placeholder="Enter your BambooHR API key (will be encrypted)"
              required
            >
          </div>
        </div>

        <!-- Okta API Token Setup -->
        <div v-else-if="provider === 'okta'">
          <div class="mb-4 p-3 bg-blue-50 border border-blue-200 rounded-md">
            <p class="text-xs text-blue-800 mb-2">
              <strong>How to get your Okta API Token:</strong>
            </p>
            <ol class="text-xs text-blue-800 ml-4 space-y-1 list-decimal">
              <li>Log into your Okta Admin Console</li>
              <li>Navigate to <strong>Security → API → Tokens</strong></li>
              <li>Click <strong>"Create Token"</strong></li>
              <li>Give it a name (e.g., "Assetronics Integration")</li>
              <li>Click <strong>"Create Token"</strong> and copy it immediately</li>
              <li><strong class="text-red-700">⚠️ Important:</strong> Save the token now - you won't be able to see it again!</li>
            </ol>
            <p class="text-xs text-blue-600 mt-2">
              💡 The token will look like: <code class="bg-blue-100 px-1 py-0.5 rounded">00abcdefghijklmnopqrstuvwxyz1234567890ABCD</code>
            </p>
          </div>

          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-slate-700 mb-2">
                Okta Domain
                <span class="text-xs font-normal text-slate-500 ml-1">(without https://)</span>
              </label>
              <input
                v-model="form.base_url"
                type="text"
                class="w-full px-4 py-3 text-base rounded-md border border-slate-300 shadow-sm focus:border-accent-blue focus:ring-2 focus:ring-accent-blue focus:outline-none"
                placeholder="dev-12345.okta.com or yourcompany.okta.com"
                required
              >
              <p class="text-xs text-slate-500 mt-1">
                Find this in your browser's address bar when logged into Okta
              </p>
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 mb-2">API Token (SSWS)</label>
              <input
                v-model="form.api_key"
                type="password"
                class="w-full px-4 py-3 text-base rounded-md border border-slate-300 shadow-sm focus:border-accent-blue focus:ring-2 focus:ring-accent-blue focus:outline-none"
                placeholder="00abcdefghijklmnopqrstuvwxyz1234567890ABCD"
                required
              >
              <p class="text-xs text-slate-500 mt-1">
                Your API token will be encrypted and stored securely
              </p>
            </div>
          </div>

          <!-- Webhook Setup Instructions (Collapsible) -->
          <details class="mt-4">
            <summary class="cursor-pointer text-sm font-medium text-accent-blue hover:text-blue-700 flex items-center gap-2">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              Optional: Set up real-time sync with Okta Event Hooks
            </summary>
            <div class="mt-3 p-3 bg-slate-50 border border-slate-200 rounded-md">
              <p class="text-xs text-slate-700 mb-2">
                <strong>For real-time employee updates, configure an Event Hook in Okta:</strong>
              </p>
              <ol class="text-xs text-slate-600 ml-4 space-y-1 list-decimal">
                <li>Go to Okta Admin Console → <strong>Workflow → Event Hooks</strong></li>
                <li>Click <strong>"Create Event Hook"</strong></li>
                <li>Name: "Assetronics Sync"</li>
                <li>URL: <code class="bg-slate-100 px-1 py-0.5 rounded text-xs">https://your-domain.com/api/v1/webhooks/okta?tenant=your_tenant</code></li>
                <li>Subscribe to <strong>User Lifecycle Events</strong> (create, activate, deactivate, etc.)</li>
                <li>Click <strong>"Verify"</strong> to complete setup</li>
              </ol>
              <p class="text-xs text-slate-500 mt-2 italic">
                This enables automatic sync when users are created, updated, or deactivated in Okta
              </p>
            </div>
          </details>
        </div>

        <!-- OAuth Credentials (Intune, Dell, Jamf) -->
        <div v-else-if="isOAuthProvider">
          <div class="mb-4 p-3 bg-blue-50 border border-blue-200 rounded-md">
            <p class="text-xs text-blue-800">
              <strong>{{ getOAuthSetupTitle() }} OAuth Setup:</strong><br>
              {{ getOAuthSetupInstructions() }}
            </p>
          </div>

          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-slate-700 mb-2">Client ID</label>
              <input
                v-model="form.client_id"
                type="text"
                class="w-full px-4 py-3 text-base rounded-md border border-slate-300 shadow-sm focus:border-accent-blue focus:ring-2 focus:ring-accent-blue focus:outline-none"
                :placeholder="getClientIdPlaceholder()"
                required
              >
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 mb-2">Client Secret</label>
              <input
                v-model="form.client_secret"
                type="password"
                class="w-full px-4 py-3 text-base rounded-md border border-slate-300 shadow-sm focus:border-accent-blue focus:ring-2 focus:ring-accent-blue focus:outline-none"
                placeholder="Your client secret (encrypted in database)"
                required
              >
            </div>
          </div>
        </div>

        <!-- Non-OAuth Credentials -->
        <template v-else-if="!['google_workspace'].includes(provider)">
          <!-- API Key / Username -->
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-2">{{ apiKeyLabel }}</label>
            <input
              v-model="form.api_key"
              type="text"
              class="w-full px-4 py-3 text-base rounded-md border border-slate-300 shadow-sm focus:border-accent-blue focus:ring-2 focus:ring-accent-blue focus:outline-none"
              required
            >
          </div>

          <!-- API Secret (Jamf password, etc.) -->
          <div v-if="needsSecret">
            <label class="block text-sm font-medium text-slate-700 mb-2">{{ apiSecretLabel }}</label>
            <input
              v-model="form.api_secret"
              type="password"
              class="w-full px-4 py-3 text-base rounded-md border border-slate-300 shadow-sm focus:border-accent-blue focus:ring-2 focus:ring-accent-blue focus:outline-none"
              required
            >
          </div>
        </template>

        <!-- Sync Settings -->
        <div class="pt-4 border-t border-slate-100">
          <label class="flex items-center gap-2 mb-3">
            <input type="checkbox" v-model="form.sync_enabled" class="rounded border-slate-300 text-accent-blue focus:ring-accent-blue">
            <span class="text-sm text-primary-dark">Enable automatic sync</span>
          </label>

          <div v-if="form.sync_enabled" class="ml-6">
            <label class="block text-sm font-medium text-slate-700 mb-2">Sync Frequency</label>
            <select
              v-model="form.sync_frequency"
              class="w-full px-4 py-2 text-sm rounded-md border border-slate-300 shadow-sm focus:border-accent-blue focus:ring-2 focus:ring-accent-blue focus:outline-none"
            >
              <option value="hourly">Hourly</option>
              <option value="daily">Daily</option>
              <option value="weekly">Weekly</option>
            </select>
          </div>
        </div>

        <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-slate-200">
          <button
            type="button"
            @click="$emit('close')"
            class="px-6 py-3 text-sm font-semibold text-slate-700 bg-white border-2 border-slate-300 rounded-xl hover:bg-slate-50 transition-all"
          >
            Cancel
          </button>
          <button
            type="submit"
            :disabled="loading"
            class="px-6 py-3 text-base font-bold text-white bg-gradient-to-r from-primary-dark to-primary-navy rounded-xl hover:from-primary-navy hover:to-primary-dark disabled:from-slate-300 disabled:to-slate-300 disabled:cursor-not-allowed flex items-center gap-2 shadow-subtle hover:shadow-lg transition-all"
          >
            <svg v-if="loading" class="animate-spin h-5 w-5 text-white" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            {{ loading ? 'Saving...' : 'Save & Connect' }}
          </button>
        </div>
      </form>
    </div>
  </Modal>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import Modal from '@/components/Modal.vue'
import { useAuthStore } from '@/stores/auth'
import { useToast } from '@/composables/useToast'

const props = defineProps<{
  provider: string
  existingIntegration?: any  // If provided, we're managing an existing integration
}>()

const emit = defineEmits(['close', 'saved'])
const authStore = useAuthStore()
const toast = useToast()

const PLACEHOLDER = '********'

const loading = ref(false)
const syncing = ref(false)

// Helper to get auth_config values
const getAuthConfigValue = (key: string, isSensitive = false) => {
  // If no existing integration, return empty
  if (!props.existingIntegration) return ''

  // If credentials are configured and this is a sensitive field (filtered out by backend), show placeholder
  if (props.existingIntegration.credentials_configured && isSensitive) {
    return PLACEHOLDER
  }

  // Otherwise, try to get the actual value from auth_config
  const value = props.existingIntegration.auth_config?.[key]
  return value || ''
}

const form = ref({
  base_url: props.existingIntegration?.base_url || '',
  api_key: props.existingIntegration?.credentials_configured ? PLACEHOLDER : '',
  api_secret: props.existingIntegration?.credentials_configured ? PLACEHOLDER : '',
  client_id: getAuthConfigValue('client_id', true),  // Sensitive
  client_secret: getAuthConfigValue('client_secret', true),  // Sensitive
  service_account_json: getAuthConfigValue('service_account_json', true),  // Sensitive
  admin_email: getAuthConfigValue('admin_email', false),  // Not sensitive, show actual value
  sync_enabled: props.existingIntegration?.sync_enabled ?? true,
  sync_frequency: props.existingIntegration?.sync_frequency || 'daily',
  sync_direction: props.existingIntegration?.sync_direction || 'inbound_only'
})

// Watch for changes to existingIntegration and update form
watch(() => props.existingIntegration, (newIntegration) => {
  if (newIntegration) {
    form.value = {
      base_url: newIntegration.base_url || '',
      api_key: newIntegration.credentials_configured ? PLACEHOLDER : '',
      api_secret: newIntegration.credentials_configured ? PLACEHOLDER : '',
      client_id: newIntegration.auth_config?.client_id ? PLACEHOLDER : '',
      client_secret: newIntegration.auth_config?.client_secret ? PLACEHOLDER : '',
      service_account_json: newIntegration.auth_config?.service_account_json ? PLACEHOLDER : '',
      admin_email: newIntegration.auth_config?.admin_email || '',
      sync_enabled: newIntegration.sync_enabled ?? true,
      sync_frequency: newIntegration.sync_frequency || 'daily',
      sync_direction: newIntegration.sync_direction || 'inbound_only'
    }
  }
}, { immediate: true })

const isConnected = computed(() => props.existingIntegration?.status === 'active')
const isEditMode = computed(() => !!props.existingIntegration)

// Dynamic labels based on provider
const providerName = computed(() => {
  const names: Record<string, string> = {
    intune: 'Microsoft Intune',
    jamf: 'Jamf Pro',
    okta: 'Okta',
    bamboohr: 'BambooHR',
    google_workspace: 'Google Workspace',
    precoro: 'Precoro',
    procurify: 'Procurify'
  }
  return names[props.provider] || props.provider
})

const isOAuthProvider = computed(() => ['intune', 'bamboohr', 'jamf', 'procurify'].includes(props.provider))
const hasBaseUrl = computed(() => !['intune', 'google_workspace'].includes(props.provider)) // BambooHR and Jamf need base_url, others don't
const needsSecret = computed(() => false) // No providers use api_secret anymore

const apiKeyLabel = computed(() => {
  if (isOAuthProvider.value) return 'OAuth Client ID'
  if (props.provider === 'okta') return 'API Token'
  if (props.provider === 'jamf') return 'Username'
  return 'API Key'
})

const apiSecretLabel = computed(() => {
  if (props.provider === 'jamf') return 'Password'
  return 'Secret'
})

const baseUrlPlaceholder = computed(() => {
  if (props.provider === 'jamf') return 'https://your-instance.jamfcloud.com'
  if (props.provider === 'okta') return 'https://your-org.okta.com'
  if (props.provider === 'bamboohr') return 'https://your-company.bamboohr.com'
  return 'https://api.example.com'
})

const getOAuthSetupTitle = () => {
  if (props.provider === 'intune') return 'Azure AD'
  if (props.provider === 'bamboohr') return 'BambooHR'
  if (props.provider === 'jamf') return 'Jamf Pro'
  return 'OAuth'
}

const getOAuthSetupInstructions = () => {
  if (props.provider === 'intune') {
    return 'Register your app at portal.azure.com. Required permissions: DeviceManagementManagedDevices.Read.All, User.Read.All'
  }
  if (props.provider === 'bamboohr') {
    return 'Go to BambooHR Settings → API Keys to generate your Client ID and Client Secret for API access.'
  }
  if (props.provider === 'jamf') {
    return 'Go to Jamf Pro → Settings → API Roles and Clients → Create an API client with appropriate permissions. Copy the Client ID and Client Secret.'
  }
  return 'Configure OAuth credentials for this integration.'
}

const getClientIdPlaceholder = () => {
  if (props.provider === 'intune') return 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
  if (props.provider === 'bamboohr') return 'your-bamboohr-client-id'
  return 'your-client-id'
}

const handleClose = (value: boolean) => {
  if (!value) {
    emit('close')
  }
}

const saveIntegration = async () => {
  loading.value = true
  try {
    const tenantId = authStore.user?.tenant_id || import.meta.env.VITE_DEFAULT_TENANT || 'acme'

    // Check if integration already exists for this provider
    const checkResponse = await fetch(
      `${import.meta.env.VITE_API_URL}/api/v1/integrations?provider=${props.provider}`,
      {
        headers: {
          'Authorization': `Bearer ${authStore.token}`,
          'X-Tenant-ID': tenantId
        }
      }
    )

    let existingIntegration = null
    if (checkResponse.ok) {
      const checkData = await checkResponse.json()
      existingIntegration = checkData.data?.find((i: any) => i.provider === props.provider)
    }

    const getPayloadValue = (val: string) => val === PLACEHOLDER ? undefined : val

    // Build auth_config for OAuth providers (excluding BambooHR which uses API key)
    const authConfig = (isOAuthProvider.value && props.provider !== 'bamboohr')
      ? {
          client_id: getPayloadValue(form.value.client_id),
          client_secret: getPayloadValue(form.value.client_secret),
          ...(props.provider === 'jamf' && form.value.base_url ? { endpoint: form.value.base_url } : {})
        }
      : (props.provider === 'bamboohr')
        ? { client_secret: getPayloadValue(form.value.client_secret) } // BambooHR: API key in client_secret field
        : (props.provider === 'google_workspace')
          ? {
              service_account_json: getPayloadValue(form.value.service_account_json),
              admin_email: getPayloadValue(form.value.admin_email)
            } // Google Workspace: Service Account JSON + Admin Email
          : {}

    // Clean up empty/undefined values from authConfig
    Object.keys(authConfig).forEach(key => {
      if ((authConfig as any)[key] === undefined) {
        delete (authConfig as any)[key]
      }
    })

    const payload = {
      integration: {
        name: providerName.value,
        provider: props.provider,
        integration_type: getIntegrationType(props.provider),
        auth_type: getAuthType(props.provider),
        base_url: form.value.base_url || null,
        api_key: (isOAuthProvider.value && props.provider !== 'bamboohr') ? null : getPayloadValue(form.value.api_key),
        api_secret: (isOAuthProvider.value && props.provider !== 'bamboohr') ? null : getPayloadValue(form.value.api_secret),
        auth_config: Object.keys(authConfig).length > 0 ? authConfig : undefined,
        sync_enabled: form.value.sync_enabled,
        sync_frequency: form.value.sync_frequency,
        sync_direction: form.value.sync_direction,
        status: existingIntegration ? undefined : 'inactive' // Only set inactive for new integrations
      }
    }

    console.log('Sending payload:', JSON.stringify(payload, null, 2))

    let response, integrationId

    if (existingIntegration) {
      // Update existing integration
      console.log(`Updating existing integration: ${existingIntegration.id}`)
      response = await fetch(
        `${import.meta.env.VITE_API_URL}/api/v1/integrations/${existingIntegration.id}`,
        {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${authStore.token}`,
            'X-Tenant-ID': tenantId
          },
          body: JSON.stringify(payload)
        }
      )
      integrationId = existingIntegration.id
      toast.info('Updating existing integration...')
    } else {
      // Create new integration
      console.log('Creating new integration')
      response = await fetch(`${import.meta.env.VITE_API_URL}/api/v1/integrations`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authStore.token}`,
          'X-Tenant-ID': tenantId
        },
        body: JSON.stringify(payload)
      })
    }

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({ error: 'Unknown error' }))
      console.error('Backend error response:', errorData)
      throw new Error(JSON.stringify(errorData))
    }

    const data = await response.json()
    if (!integrationId) {
      integrationId = data.data.id
    }

    // For OAuth providers that need redirect flow (Intune, Dell), initiate OAuth flow
    // For client credentials OAuth (Jamf) and API key providers, trigger sync immediately
    if (isOAuthProvider.value && !['bamboohr', 'jamf'].includes(props.provider)) {
      await initiateOAuthFlow(integrationId)
    } else {
      // For non-OAuth, BambooHR, and Jamf (client credentials), trigger sync immediately
      await triggerSync(integrationId)
      toast.success('Integration saved! Syncing data...')

      // Wait a moment for the sync to start and potentially complete
      // This gives time for the backend to update the status
      setTimeout(() => {
        emit('saved')
      }, 2000) // 2 second delay to allow sync to complete
    }
  } catch (error) {
    console.error('Full error:', error)

    // Try to parse and show backend error
    let errorMessage = 'Failed to connect. Please check credentials.'
    try {
      const errorObj = JSON.parse((error as any).message)
      if (errorObj.errors) {
        errorMessage = 'Validation errors:\n' + JSON.stringify(errorObj.errors, null, 2)
      } else if (errorObj.error) {
        errorMessage = errorObj.error
      }
    } catch (e) {
      // Keep default message
    }

    toast.error(errorMessage)
  } finally {
    loading.value = false
  }
}

const initiateOAuthFlow = async (integrationId: string) => {
  try {
    const tenantId = authStore.user?.tenant_id || import.meta.env.VITE_DEFAULT_TENANT || 'acme'

    // Get OAuth authorization URL from backend
    const response = await fetch(
      `${import.meta.env.VITE_API_URL}/api/v1/integrations/auth/connect?provider=${props.provider}&integration_id=${integrationId}`,
      {
        headers: {
          'Authorization': `Bearer ${authStore.token}`,
          'X-Tenant-ID': tenantId
        }
      }
    )

    if (!response.ok) throw new Error('Failed to initiate OAuth')

    const { url } = await response.json()

    // Redirect user to OAuth provider (Microsoft/Dell)
    window.location.href = url
  } catch (error) {
    console.error('OAuth initiation failed:', error)
    toast.error('Failed to start OAuth flow. Please try again.')
  }
}

const triggerSync = async (id: string) => {
  const tenantId = authStore.user?.tenant_id || import.meta.env.VITE_DEFAULT_TENANT || 'acme'

  await fetch(`${import.meta.env.VITE_API_URL}/api/v1/integrations/${id}/sync`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${authStore.token}`,
      'X-Tenant-ID': tenantId
    }
  })
}

const manualSync = async () => {
  if (!props.existingIntegration?.id) return

  syncing.value = true
  try {
    await triggerSync(props.existingIntegration.id)
    toast.success('Sync started successfully! This may take a few moments.')
    emit('saved') // Refresh the parent view
  } catch (error) {
    console.error('Sync failed:', error)
    toast.error('Failed to start sync. Please try again.')
  } finally {
    syncing.value = false
  }
}

const toggleAutoSync = async () => {
  if (!props.existingIntegration?.id) return

  const tenantId = authStore.user?.tenant_id || import.meta.env.VITE_DEFAULT_TENANT || 'acme'
  const endpoint = form.value.sync_enabled ? 'enable-sync' : 'disable-sync'

  try {
    const response = await fetch(
      `${import.meta.env.VITE_API_URL}/api/v1/integrations/${props.existingIntegration.id}/${endpoint}`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${authStore.token}`,
          'X-Tenant-ID': tenantId
        }
      }
    )

    if (!response.ok) throw new Error('Failed to update sync settings')
    toast.success(`Automatic sync ${form.value.sync_enabled ? 'enabled' : 'disabled'}`)
    emit('saved')
  } catch (error) {
    console.error('Failed to toggle auto-sync:', error)
    form.value.sync_enabled = !form.value.sync_enabled // Revert
    toast.error('Failed to update sync settings')
  }
}

const updateSyncSettings = async () => {
  if (!props.existingIntegration?.id) return

  const tenantId = authStore.user?.tenant_id || import.meta.env.VITE_DEFAULT_TENANT || 'acme'

  try {
    const response = await fetch(
      `${import.meta.env.VITE_API_URL}/api/v1/integrations/${props.existingIntegration.id}`,
      {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authStore.token}`,
          'X-Tenant-ID': tenantId
        },
        body: JSON.stringify({
          integration: {
            sync_frequency: form.value.sync_frequency
          }
        })
      }
    )

    if (!response.ok) throw new Error('Failed to update sync frequency')
    toast.success(`Sync frequency updated to ${form.value.sync_frequency}`)
    emit('saved')
  } catch (error) {
    console.error('Failed to update sync frequency:', error)
    toast.error('Failed to update sync frequency')
  }
}

const formatDate = (dateString: string) => {
  if (!dateString) return 'Never'
  const date = new Date(dateString)
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit'
  }).format(date)
}

const getSyncStatusClass = () => {
  if (props.existingIntegration?.last_sync_status === 'success') {
    return 'bg-cyan-50 border border-accent-blue/30 text-primary-dark'
  }
  return 'bg-red-50 border border-red-200 text-red-800'
}

const getIntegrationType = (p: string) => {
  if (['intune', 'jamf', 'google_workspace'].includes(p)) return 'mdm'
  if (p === 'okta') return 'identity'
  if (p === 'bamboohr') return 'hris'
  if (p === 'precoro') return 'procurement'
  if (p === 'procurify') return 'procurement'
  return 'other'
}

const getAuthType = (p: string) => {
  if (p === 'intune') return 'oauth2' // Microsoft OAuth 2.0
  if (p === 'okta') return 'api_key' // SSWS
  if (p === 'jamf') return 'oauth2' // Jamf OAuth 2.0 Client Credentials
  if (p === 'bamboohr') return 'api_key' // BambooHR API Key (OAuth doesn't work for API access)
  if (p === 'google_workspace') return 'custom' // Google Workspace uses Service Account
  if (p === 'precoro') return 'api_key' // Precoro API Key (X-AUTH-TOKEN)
  if (p === 'procurify') return 'oauth2' // Procurify OAuth 2.0 Client Credentials
  return 'api_key'
}
</script>
