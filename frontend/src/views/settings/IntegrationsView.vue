<template>
  <MainLayout>
    <div class="max-w-5xl mx-auto">
      <!-- Success Message -->
      <div
        v-if="showSuccessMessage"
        class="mb-6 p-4 bg-teal-50 border border-teal-200 rounded-lg flex items-start gap-3"
      >
        <svg class="w-5 h-5 text-teal-600 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <div class="flex-1">
          <h3 class="text-sm font-semibold text-teal-900">Integration Connected Successfully!</h3>
          <p class="text-sm text-teal-700 mt-1">{{ successProviderName }} has been connected and is ready to sync.</p>
        </div>
        <button @click="dismissSuccess" class="text-teal-600 hover:text-teal-800">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      <!-- Header -->
      <div class="mb-8">
        <div class="flex items-center gap-2 mb-2">
          <router-link to="/settings" class="text-slate-500 hover:text-slate-700 transition-colors">
            Settings
          </router-link>
          <span class="text-slate-400">/</span>
          <h1 class="text-2xl font-bold text-primary-dark">Integrations</h1>
        </div>
        <p class="text-slate-600">Connect Assetronics with your existing tools to automate data collection.</p>
      </div>

      <!-- Refresh Controls -->
      <div class="flex justify-end mb-4">
        <button 
          @click="fetchIntegrations" 
          class="text-sm text-slate-500 hover:text-primary-dark flex items-center gap-1 transition-colors"
          :disabled="loadingIntegrations"
        >
          <svg 
            class="w-4 h-4" 
            :class="{ 'animate-spin': loadingIntegrations }" 
            fill="none" 
            stroke="currentColor" 
            viewBox="0 0 24 24"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          {{ loadingIntegrations ? 'Refreshing...' : 'Refresh Status' }}
        </button>
      </div>

      <!-- Integration Categories -->
      <div class="space-y-8">
        
        <!-- MDM & Device Management -->
        <section>
          <h2 class="text-lg font-semibold text-primary-dark mb-4 flex items-center gap-2">
            <svg class="w-5 h-5 text-accent-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
            </svg>
            Device management (MDM)
          </h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <IntegrationCard
              name="Microsoft Intune"
              description="Sync Windows devices, compliance status, and user assignments."
              provider="intune"
              type="mdm"
              icon="windows"
              :status="getIntegrationStatus('intune')"
              :last-sync="getIntegration('intune')?.last_sync_at"
              @configure="openConfig('intune')"
            />
            <IntegrationCard
              name="Jamf Pro"
              description="Sync Apple devices (macOS, iOS) and inventory details."
              provider="jamf"
              type="mdm"
              icon="apple"
              :status="getIntegrationStatus('jamf')"
              :last-sync="getIntegration('jamf')?.last_sync_at"
              @configure="openConfig('jamf')"
            />
            <IntegrationCard
              name="Google Workspace"
              description="Sync Chromebooks and mobile devices."
              provider="google_workspace"
              type="mdm"
              icon="google"
              :status="getIntegrationStatus('google_workspace')"
              :last-sync="getIntegration('google_workspace')?.last_sync_at"
              @configure="openConfig('google_workspace')"
            />
          </div>
        </section>

        <!-- HRIS (Human Resources) -->
        <section>
          <h2 class="text-lg font-semibold text-primary-dark mb-4 flex items-center gap-2">
            <svg class="w-5 h-5 text-accent-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
            Human resources (HRIS)
          </h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <IntegrationCard
              name="BambooHR"
              description="Sync employee data, automate onboarding/offboarding workflows."
              provider="bamboohr"
              type="hris"
              icon="bamboo"
              :status="getIntegrationStatus('bamboohr')"
              :last-sync="getIntegration('bamboohr')?.last_sync_at"
              @configure="openConfig('bamboohr')"
            />
            <IntegrationCard
              name="Okta"
              description="Sync users from Okta identity platform and manage employee lifecycle."
              provider="okta"
              type="hris"
              icon="shield"
              :status="getIntegrationStatus('okta')"
              :last-sync="getIntegration('okta')?.last_sync_at"
              @configure="openConfig('okta')"
            />
          </div>
        </section>

        <!-- Procurement -->
        <section>
          <h2 class="text-lg font-semibold text-primary-dark mb-4 flex items-center gap-2">
            <svg class="w-5 h-5 text-accent-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
            Procurement
          </h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <IntegrationCard
              name="Precoro"
              description="Sync purchase orders and automate procurement workflows."
              provider="precoro"
              type="procurement"
              icon="truck"
              :status="getIntegrationStatus('precoro')"
              :last-sync="getIntegration('precoro')?.last_sync_at"
              @configure="openConfig('precoro')"
            />
            <IntegrationCard
              name="Procurify"
              description="Import purchase orders and track procurement data."
              provider="procurify"
              type="procurement"
              icon="truck"
              :status="getIntegrationStatus('procurify')"
              :last-sync="getIntegration('procurify')?.last_sync_at"
              @configure="openConfig('procurify')"
            />
          </div>
        </section>

        <!-- Email & Invoices -->
        <section>
          <h2 class="text-lg font-semibold text-primary-dark mb-4 flex items-center gap-2">
            <svg class="w-5 h-5 text-accent-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
            </svg>
            Email & invoice processing
          </h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <IntegrationCard
              name="Gmail"
              description="Automatically parse invoices from Gmail and create assets."
              provider="gmail"
              type="email"
              icon="google"
              :status="getIntegrationStatus('gmail')"
              :last-sync="getIntegration('gmail')?.last_sync_at"
              @configure="openConfig('gmail')"
            />
            <IntegrationCard
              name="Microsoft 365 Mail"
              description="Parse invoice PDFs from Outlook and auto-import assets."
              provider="microsoft_graph"
              type="email"
              icon="windows"
              :status="getIntegrationStatus('microsoft_graph')"
              :last-sync="getIntegration('microsoft_graph')?.last_sync_at"
              @configure="openConfig('microsoft_graph')"
            />
          </div>
        </section>

        <!-- Finance & Accounting -->
        <section>
          <h2 class="text-lg font-semibold text-primary-dark mb-4 flex items-center gap-2">
            <svg class="w-5 h-5 text-accent-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            Finance & Accounting
          </h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <IntegrationCard
              name="QuickBooks"
              description="Sync purchase orders and track IT expenses."
              provider="quickbooks"
              type="finance"
              icon="dollar"
              :status="getIntegrationStatus('quickbooks')"
              :last-sync="getIntegration('quickbooks')?.last_sync_at"
              @configure="openConfig('quickbooks')"
            />
            <IntegrationCard
              name="NetSuite"
              description="Import procurement data and track asset depreciation."
              provider="netsuite"
              type="finance"
              icon="dollar"
              :status="getIntegrationStatus('netsuite')"
              :last-sync="getIntegration('netsuite')?.last_sync_at"
              @configure="openConfig('netsuite')"
            />
          </div>
        </section>

        <!-- Communications -->
        <section>
          <h2 class="text-lg font-semibold text-primary-dark mb-4 flex items-center gap-2">
            <svg class="w-5 h-5 text-accent-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
            </svg>
            Notifications
          </h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <IntegrationCard
              name="Slack"
              description="Send asset alerts and approval requests to Slack channels."
              provider="slack"
              type="communication"
              icon="slack"
              :status="getIntegrationStatus('slack')"
              :last-sync="getIntegration('slack')?.last_sync_at"
              @configure="openConfig('slack')"
            />
          </div>
        </section>

      </div>
    </div>

    <!-- Configuration Modal -->
    <IntegrationConfigModal
      v-if="showConfig"
      :provider="selectedProvider"
      :existingIntegration="getIntegration(selectedProvider)"
      @close="closeConfig"
      @saved="refreshIntegrations"
    />

  </MainLayout>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import MainLayout from '@/components/MainLayout.vue'
import IntegrationCard from '@/components/settings/IntegrationCard.vue'
import IntegrationConfigModal from '@/components/settings/IntegrationConfigModal.vue'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

const showConfig = ref(false)
const selectedProvider = ref('')
const showSuccessMessage = ref(false)
const successProvider = ref('')
const integrations = ref<Record<string, any>>({})
const loadingIntegrations = ref(true)

// Provider display names
const providerNames: Record<string, string> = {
  intune: 'Microsoft Intune',
  jamf: 'Jamf Pro',
  bamboohr: 'BambooHR',
  okta: 'Okta',
  quickbooks: 'QuickBooks',
  netsuite: 'NetSuite',
  slack: 'Slack',
  google_workspace: 'Google Workspace',
  precoro: 'Precoro',
  procurify: 'Procurify'
}

const successProviderName = computed(() => {
  return providerNames[successProvider.value] || successProvider.value
})

// Get integration status by provider
const getIntegrationStatus = (provider: string) => {
  return integrations.value[provider]?.status || null
}

// Get full integration object by provider
const getIntegration = (provider: string) => {
  return integrations.value[provider] || null
}

// Fetch integrations from backend
const fetchIntegrations = async () => {
  try {
    loadingIntegrations.value = true

    // Check if user is authenticated
    if (!authStore.token) {
      console.warn('No auth token available, skipping integration fetch')
      loadingIntegrations.value = false
      return
    }

    const tenantId = authStore.user?.tenant_id || import.meta.env.VITE_DEFAULT_TENANT || 'acme'

    console.log('Fetching integrations with tenant:', tenantId)
    console.log('Auth token exists:', !!authStore.token)

    const response = await fetch(`${import.meta.env.VITE_API_URL}/api/v1/integrations`, {
      headers: {
        'Authorization': `Bearer ${authStore.token}`,
        'X-Tenant-ID': tenantId
      }
    })

    console.log('Integrations response status:', response.status)

    if (response.ok) {
      const data = await response.json()
      console.log('Integrations data received:', data)

      // Create a map of provider -> integration
      const integrationsMap: Record<string, any> = {}
      data.data.forEach((integration: any) => {
        console.log(`Mapping integration: ${integration.provider} -> status: ${integration.status}`)
        integrationsMap[integration.provider] = integration
      })
      integrations.value = integrationsMap
      console.log('Final integrations map:', integrationsMap)
    } else {
      const errorText = await response.text()
      console.error('Failed to fetch integrations:', response.status, errorText)
    }
  } catch (error) {
    console.error('Failed to fetch integrations:', error)
  } finally {
    loadingIntegrations.value = false
  }
}

onMounted(async () => {
  // Fetch integrations
  await fetchIntegrations()

  // Check for success query parameter from OAuth redirect
  if (route.query.success === 'true' && route.query.provider) {
    showSuccessMessage.value = true
    successProvider.value = route.query.provider as string

    // Clean up URL (remove query params)
    router.replace({ path: '/settings/integrations' })

    // Refresh integrations to show updated status
    await fetchIntegrations()

    // Auto-dismiss after 10 seconds
    setTimeout(() => {
      showSuccessMessage.value = false
    }, 10000)
  }

  // Check for error query parameter from OAuth redirect
  if (route.query.error) {
    const errorCode = route.query.error as string
    const errorMessage = route.query.message as string || 'OAuth authentication failed'

    console.error('OAuth error:', errorCode, errorMessage)

    // You can add a toast notification here to show the error
    alert(`OAuth Error: ${errorMessage}`)

    // Clean up URL (remove query params)
    router.replace({ path: '/settings/integrations' })
  }
})

const openConfig = (provider: string) => {
  selectedProvider.value = provider
  showConfig.value = true
}

const closeConfig = () => {
  showConfig.value = false
  selectedProvider.value = ''
}

const refreshIntegrations = async () => {
  await fetchIntegrations()
  closeConfig()
}

const dismissSuccess = () => {
  showSuccessMessage.value = false
}
</script>
