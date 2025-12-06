<template>
  <MainLayout>
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
      <!-- Loading state -->
      <div v-if="isLoading" class="flex items-center justify-center min-h-[60vh]">
        <div class="text-center">
          <div class="animate-spin rounded-full h-16 w-16 border-b-4 border-accent-blue mx-auto mb-4"></div>
          <p class="text-slate-600 text-lg">Loading asset...</p>
        </div>
      </div>

      <!-- Error state -->
      <div v-else-if="error" class="max-w-md mx-auto mt-12">
        <div class="bg-red-50 border-2 border-red-200 rounded-xl p-8 text-center">
          <svg class="w-16 h-16 text-red-500 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <h2 class="text-xl font-bold text-red-900 mb-2">Failed to load asset</h2>
          <p class="text-red-700 mb-6">{{ error }}</p>
          <button @click="router.push('/assets')" class="btn-brand-secondary">
            Back to Assets
          </button>
        </div>
      </div>

      <!-- Asset details -->
      <div v-else-if="asset" class="space-y-6">
        <!-- Hero Header with gradient background -->
        <div class="relative bg-gradient-to-br from-primary-dark via-primary-navy to-accent-blue rounded-2xl shadow-subtle" style="overflow: visible;">
          <!-- Background pattern with contained overflow -->
          <div class="absolute inset-0 opacity-10 rounded-2xl overflow-hidden">
            <div class="absolute inset-0" style="background-image: url('data:image/svg+xml,%3Csvg width=60 height=60 xmlns=http://www.w3.org/2000/svg%3E%3Cpath d=M0 0h60v60H0z fill=none/%3E%3Cpath d=M30 0v60M0 30h60 stroke=%23fff stroke-width=1/%3E%3C/svg%3E');"></div>
          </div>

          <div class="relative px-6 sm:px-8 lg:px-12 py-8 sm:py-12" style="overflow: visible;">
            <div class="flex flex-col lg:flex-row items-start lg:items-center justify-between gap-6">
              <div class="flex-1">
                <!-- Breadcrumb -->
                <div class="flex items-center gap-2 text-sm text-slate-300 mb-3">
                  <router-link to="/assets" class="hover:text-white transition-colors">Assets</router-link>
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                  </svg>
                  <span class="text-white">{{ asset.name }}</span>
                </div>

                <!-- Device name and info -->
                <h1 class="text-3xl sm:text-4xl lg:text-5xl font-bold text-white mb-3">{{ asset.name }}</h1>

                <div class="flex flex-wrap items-center gap-3 text-slate-200">
                  <!-- Status badge -->
                  <span
                    class="inline-flex items-center gap-2 px-4 py-2 rounded-full text-sm font-semibold"
                    :class="getStatusBadgeClass(asset.status)"
                  >
                    <span class="w-2 h-2 rounded-full bg-current"></span>
                    {{ formatStatus(asset.status) }}
                  </span>

                  <!-- Category badge -->
                  <span v-if="asset.category" class="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/10 backdrop-blur-sm text-white text-sm font-medium">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z" />
                    </svg>
                    {{ asset.category }}
                  </span>

                  <!-- Last check-in -->
                  <span v-if="asset.last_checkin_at" class="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/10 backdrop-blur-sm text-white text-sm">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    Last seen {{ formatRelativeTime(asset.last_checkin_at) }}
                  </span>
                </div>
              </div>

              <!-- Action buttons -->
              <div class="flex gap-3">
                <!-- Back button - always visible -->
                <button @click="router.push('/assets')" class="px-4 py-2 bg-white/10 hover:bg-white/20 backdrop-blur-sm text-white rounded-lg transition-all duration-200 border border-white/20">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
                  </svg>
                </button>

                <!-- Actions dropdown -->
                <div>
                  <button
                    ref="actionsButtonRef"
                    @click="toggleActionsMenu"
                    class="inline-flex items-center gap-2 px-4 py-2 bg-white/10 hover:bg-white/20 backdrop-blur-sm text-white rounded-lg transition-all duration-200 border border-white/20"
                  >
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
                    </svg>
                    <span class="hidden sm:inline">Actions</span>
                  </button>

                  <!-- Dropdown menu using Teleport -->
                  <Teleport to="body">
                    <div
                      v-if="showActionsMenu"
                      :style="actionsMenuPosition"
                      class="fixed z-[9999] w-48 rounded-lg bg-white shadow-subtle ring-1 ring-black ring-opacity-5"
                      @click.stop
                    >
                      <div class="py-1">
                        <router-link
                          :to="`/assets/${asset.id}/edit`"
                          class="flex items-center gap-2 px-4 py-2 text-sm text-slate-700 hover:bg-slate-50"
                        >
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                          </svg>
                          Edit asset
                        </router-link>
                        <button
                          @click="handleDeleteAsset"
                          class="w-full flex items-center gap-2 px-4 py-2 text-sm text-red-600 hover:bg-red-50"
                        >
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                          </svg>
                          Delete asset
                        </button>
                      </div>
                    </div>
                  </Teleport>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Tabs -->
        <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-2">
          <div class="flex gap-2">
            <button
              @click="activeTab = 'details'"
              :class="[
                'flex-1 px-6 py-3 rounded-xl font-semibold transition-all',
                activeTab === 'details'
                  ? 'bg-accent-blue text-primary-dark'
                  : 'text-slate-600 hover:bg-slate-50'
              ]"
            >
              <svg class="w-5 h-5 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              Details
            </button>
            <button
              @click="activeTab = 'transactions'"
              :class="[
                'flex-1 px-6 py-3 rounded-xl font-semibold transition-all',
                activeTab === 'transactions'
                  ? 'bg-accent-blue text-primary-dark'
                  : 'text-slate-600 hover:bg-slate-50'
              ]"
            >
              <svg class="w-5 h-5 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
              Transactions
              <span v-if="transactions.length > 0" class="ml-2 px-2 py-0.5 text-xs rounded-full bg-primary-dark text-accent-blue">
                {{ transactions.length }}
              </span>
            </button>
          </div>
        </div>

        <!-- Main Content Grid -->
        <div v-show="activeTab === 'details'" class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <!-- Left Column - Key Info & Visual -->
          <div class="lg:col-span-1 space-y-6">
            <!-- Device Visual Card -->
            <div class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
              <div class="p-6">
                <h3 class="text-sm font-semibold text-slate-500 uppercase tracking-wide mb-4">Device</h3>
                <div class="aspect-square bg-gradient-to-br from-slate-50 to-slate-100 rounded-xl flex items-center justify-center mb-4 overflow-hidden">
                  <!-- Show actual device image if available -->
                  <img
                    v-if="asset.image_url"
                    :src="getImageUrl(asset.image_url)"
                    :alt="asset.name"
                    class="w-full h-full object-contain"
                    @error="handleImageError"
                  />
                  <!-- Fallback to icon -->
                  <svg v-else class="w-32 h-32 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                  </svg>
                </div>
                <div class="space-y-3">
                  <div v-if="asset.make || asset.model">
                    <p class="text-lg font-bold text-primary-dark">{{ asset.make }} {{ asset.model }}</p>
                    <p v-if="asset.os_info" class="text-sm text-slate-600">{{ asset.os_info }}</p>
                  </div>
                  <div v-if="asset.serial_number" class="pt-3 border-t border-slate-100">
                    <p class="text-xs font-medium text-slate-500 mb-1">Serial Number</p>
                    <p class="text-sm font-mono text-primary-dark">{{ asset.serial_number }}</p>
                  </div>
                  <div v-if="asset.asset_tag" class="pt-3 border-t border-slate-100">
                    <p class="text-xs font-medium text-slate-500 mb-1">Asset Tag</p>
                    <p class="text-sm font-mono text-primary-dark">{{ asset.asset_tag }}</p>
                  </div>
                </div>
              </div>
            </div>

            <!-- Assignment Card -->
            <div v-if="asset.employee_id || asset.location_id" class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
              <h3 class="text-sm font-semibold text-slate-500 uppercase tracking-wide mb-4">Assignment</h3>
              <div class="space-y-4">
                <div v-if="asset.employee_id" class="flex items-start gap-3">
                  <div class="w-10 h-10 rounded-full bg-accent-blue-100 flex items-center justify-center flex-shrink-0">
                    <svg class="w-5 h-5 text-accent-blue-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                  </div>
                  <div class="flex-1">
                    <p class="text-xs font-medium text-slate-500">Assigned to</p>
                    <p class="text-sm font-semibold text-primary-dark">{{ getEmployeeName() }}</p>
                    <p v-if="asset.custom_fields?.user_principal_name" class="text-xs text-slate-600 mt-1">{{ asset.custom_fields.user_principal_name }}</p>
                  </div>
                </div>
                <div v-if="asset.location_id" class="flex items-start gap-3">
                  <div class="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center flex-shrink-0">
                    <svg class="w-5 h-5 text-blue-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                  </div>
                  <div class="flex-1">
                    <p class="text-xs font-medium text-slate-500">Location</p>
                    <p class="text-sm font-semibold text-primary-dark">{{ asset.location || 'Not specified' }}</p>
                  </div>
                </div>
              </div>
            </div>

            <!-- Security & Compliance (from Intune data) -->
            <div v-if="asset.custom_fields?.compliance_state || asset.custom_fields?.is_encrypted" class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
              <h3 class="text-sm font-semibold text-slate-500 uppercase tracking-wide mb-4">Security</h3>
              <div class="space-y-3">
                <div v-if="asset.custom_fields.compliance_state" class="flex items-center justify-between">
                  <span class="text-sm text-slate-600">Compliance</span>
                  <span
                    class="px-3 py-1 rounded-full text-xs font-semibold"
                    :class="asset.custom_fields.compliance_state === 'compliant' ? 'bg-teal-100 text-teal-700' : 'bg-red-100 text-red-700'"
                  >
                    {{ asset.custom_fields.compliance_state }}
                  </span>
                </div>
                <div v-if="asset.custom_fields.is_encrypted !== undefined" class="flex items-center justify-between">
                  <span class="text-sm text-slate-600">Encryption</span>
                  <span
                    class="px-3 py-1 rounded-full text-xs font-semibold"
                    :class="asset.custom_fields.is_encrypted ? 'bg-teal-100 text-teal-700' : 'bg-amber-100 text-amber-700'"
                  >
                    {{ asset.custom_fields.is_encrypted ? 'Enabled' : 'Disabled' }}
                  </span>
                </div>
                <div v-if="asset.custom_fields.is_supervised !== undefined" class="flex items-center justify-between">
                  <span class="text-sm text-slate-600">Supervised</span>
                  <span class="px-3 py-1 rounded-full text-xs font-semibold bg-slate-100 text-slate-700">
                    {{ asset.custom_fields.is_supervised ? 'Yes' : 'No' }}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <!-- Right Column - Detailed Information -->
          <div class="lg:col-span-2 space-y-6">
            <!-- Hardware Specifications -->
            <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
              <h3 class="text-lg font-bold text-primary-dark mb-6 flex items-center gap-2">
                <svg class="w-5 h-5 text-accent-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z" />
                </svg>
                Hardware Specifications
              </h3>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-4">
                <InfoField label="Manufacturer" :value="asset.make" />
                <InfoField label="Model" :value="asset.model" />
                <InfoField label="Operating System" :value="asset.os_info" />
                <InfoField label="Category" :value="asset.category" />
                <InfoField
                  v-if="asset.custom_fields?.total_storage_gb"
                  label="Total Storage"
                  :value="`${asset.custom_fields.total_storage_gb} GB`"
                />
                <InfoField
                  v-if="asset.custom_fields?.free_storage_gb"
                  label="Free Storage"
                  :value="`${asset.custom_fields.free_storage_gb} GB (${100 - (asset.custom_fields.storage_used_percent || 0)}% free)`"
                />
                <InfoField
                  v-if="asset.custom_fields?.physical_memory_gb"
                  label="RAM"
                  :value="`${asset.custom_fields.physical_memory_gb} GB`"
                />
                <InfoField
                  v-if="asset.custom_fields?.wifi_mac_address"
                  label="WiFi MAC"
                  :value="asset.custom_fields.wifi_mac_address"
                  monospace
                />
              </div>
            </div>

            <!-- Description -->
            <div v-if="asset.description" class="bg-gradient-to-br from-slate-50 to-white rounded-2xl shadow-sm border border-slate-200 p-6">
              <h3 class="text-lg font-bold text-primary-dark mb-3">Description</h3>
              <p class="text-slate-700 leading-relaxed">{{ asset.description }}</p>
            </div>

            <!-- Enrollment & Management (from Intune) -->
            <div v-if="asset.custom_fields?.enrollment_type || asset.custom_fields?.ownership" class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
              <h3 class="text-lg font-bold text-primary-dark mb-6 flex items-center gap-2">
                <svg class="w-5 h-5 text-accent-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
                Enrollment & Management
              </h3>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-4">
                <InfoField label="Enrollment Type" :value="asset.custom_fields.enrollment_type" />
                <InfoField label="Ownership" :value="asset.custom_fields.ownership" />
                <InfoField label="Management State" :value="asset.custom_fields.management_state" />
                <InfoField label="Registration State" :value="asset.custom_fields.device_registration_state" />
                <InfoField
                  v-if="asset.custom_fields.enrolled_date"
                  label="Enrolled Date"
                  :value="formatDate(asset.custom_fields.enrolled_date)"
                />
                <InfoField
                  v-if="asset.custom_fields.azure_ad_registered"
                  label="Azure AD"
                  :value="asset.custom_fields.azure_ad_registered ? 'Registered' : 'Not Registered'"
                />
              </div>
            </div>

            <!-- Network Information -->
            <div v-if="hasNetworkInfo" class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
              <h3 class="text-lg font-bold text-primary-dark mb-6 flex items-center gap-2">
                <svg class="w-5 h-5 text-accent-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.111 16.404a5.5 5.5 0 017.778 0M12 20h.01m-7.08-7.071c3.904-3.905 10.236-3.905 14.141 0M1.394 9.393c5.857-5.857 15.355-5.857 21.213 0" />
                </svg>
                Network Information
              </h3>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-4">
                <InfoField
                  v-if="asset.custom_fields?.wifi_mac_address"
                  label="WiFi MAC Address"
                  :value="asset.custom_fields.wifi_mac_address"
                  monospace
                />
                <InfoField
                  v-if="asset.custom_fields?.ethernet_mac_address"
                  label="Ethernet MAC"
                  :value="asset.custom_fields.ethernet_mac_address"
                  monospace
                />
                <InfoField label="IMEI" :value="asset.custom_fields?.imei" monospace />
                <InfoField label="Phone Number" :value="asset.custom_fields?.phone_number" />
                <InfoField label="Carrier" :value="asset.custom_fields?.subscriber_carrier" />
              </div>
            </div>

            <!-- Additional Custom Fields (show any remaining) -->
            <div v-if="hasAdditionalFields" class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
              <div class="flex items-center justify-between mb-6">
                <h3 class="text-lg font-bold text-primary-dark">Additional Information</h3>
                <button
                  v-if="additionalFieldsCount > 5"
                  @click="toggleAdditionalFields"
                  class="text-sm font-medium text-accent-blue hover:text-accent-blue-hover flex items-center gap-1 transition-colors"
                >
                  <span>{{ showAllAdditionalFields ? 'Show less' : `Show all (${additionalFieldsCount})` }}</span>
                  <svg
                    class="w-4 h-4 transition-transform"
                    :class="{ 'rotate-180': showAllAdditionalFields }"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                  </svg>
                </button>
              </div>
              <div class="space-y-6">
                <template v-for="(value, key, index) in getAdditionalFields()" :key="key">
                  <DataField
                    v-if="showAllAdditionalFields || index < 5"
                    :label="formatFieldName(key)"
                    :value="value"
                  />
                </template>
              </div>
              <div
                v-if="!showAllAdditionalFields && additionalFieldsCount > 5"
                class="mt-4 text-center"
              >
                <button
                  @click="toggleAdditionalFields"
                  class="text-sm text-slate-500 hover:text-accent-blue transition-colors"
                >
                  + {{ additionalFieldsCount - 5 }} more fields
                </button>
              </div>
            </div>

            <!-- Metadata -->
            <div class="bg-slate-50 rounded-2xl border border-slate-200 p-6">
              <h3 class="text-sm font-semibold text-slate-500 uppercase tracking-wide mb-4">Metadata</h3>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 text-sm">
                <div>
                  <p class="text-slate-500 mb-1">Created</p>
                  <p class="text-slate-900 font-medium">{{ formatDateTime(asset.inserted_at) }}</p>
                </div>
                <div>
                  <p class="text-slate-500 mb-1">Last Updated</p>
                  <p class="text-slate-900 font-medium">{{ formatDateTime(asset.updated_at) }}</p>
                </div>
                <div v-if="asset.custom_fields?.intune_id">
                  <p class="text-slate-500 mb-1">Intune ID</p>
                  <p class="text-slate-900 font-mono text-xs">{{ asset.custom_fields.intune_id }}</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Transactions Tab Content -->
        <div v-show="activeTab === 'transactions'" class="space-y-6">
          <!-- Loading state -->
          <div v-if="loadingTransactions" class="flex items-center justify-center py-12">
            <div class="text-center">
              <div class="animate-spin rounded-full h-12 w-12 border-b-4 border-accent-blue mx-auto mb-3"></div>
              <p class="text-slate-600">Loading transaction history...</p>
            </div>
          </div>

          <!-- Empty state -->
          <div v-else-if="transactions.length === 0" class="bg-white rounded-2xl shadow-sm border border-slate-200 p-12 text-center">
            <svg class="w-16 h-16 text-slate-300 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
            </svg>
            <h3 class="text-lg font-semibold text-slate-700 mb-2">No transaction history</h3>
            <p class="text-slate-500">This asset has no recorded transactions yet.</p>
          </div>

          <!-- Transactions Timeline -->
          <div v-else class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
            <h3 class="text-lg font-bold text-primary-dark mb-6 flex items-center gap-2">
              <svg class="w-5 h-5 text-accent-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              Transaction History
              <span class="ml-auto text-sm font-normal text-slate-500">{{ transactions.length }} {{ transactions.length === 1 ? 'transaction' : 'transactions' }}</span>
            </h3>

            <!-- Timeline -->
            <div class="relative">
              <!-- Timeline line -->
              <div class="absolute left-4 top-0 bottom-0 w-0.5 bg-slate-200"></div>

              <!-- Transaction items -->
              <div class="space-y-6">
                <div v-for="transaction in transactions" :key="transaction.id" class="relative pl-12">
                  <!-- Timeline dot -->
                  <div
                    class="absolute left-0 w-8 h-8 rounded-full flex items-center justify-center"
                    :class="`bg-${getTransactionColor(transaction.transaction_type)}-100`"
                  >
                    <svg class="w-4 h-4" :class="`text-${getTransactionColor(transaction.transaction_type)}-600`" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" :d="getTransactionIcon(transaction.transaction_type)" />
                    </svg>
                  </div>

                  <!-- Transaction card -->
                  <div class="bg-slate-50 rounded-xl border border-slate-200 p-4 hover:shadow-md transition-shadow">
                    <div class="flex items-start justify-between gap-4 mb-2">
                      <div class="flex-1">
                        <h4 class="font-semibold text-primary-dark">{{ formatTransactionType(transaction.transaction_type) }}</h4>
                        <p v-if="transaction.description" class="text-sm text-slate-600 mt-1">{{ transaction.description }}</p>
                      </div>
                      <span class="text-xs text-slate-500 whitespace-nowrap">{{ formatDateTime(transaction.performed_at) }}</span>
                    </div>

                    <!-- Transaction details -->
                    <div class="mt-3 space-y-2 text-sm">
                      <!-- Employee info -->
                      <div v-if="transaction.employee" class="flex items-center gap-2 text-slate-700">
                        <svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                        </svg>
                        <span>{{ transaction.employee.first_name }} {{ transaction.employee.last_name }}</span>
                      </div>

                      <!-- Transfer info -->
                      <div v-if="transaction.from_employee && transaction.to_employee" class="flex items-center gap-2 text-slate-700">
                        <svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
                        </svg>
                        <span>
                          {{ transaction.from_employee.first_name }} {{ transaction.from_employee.last_name }}
                          <span class="text-slate-400 mx-1">→</span>
                          {{ transaction.to_employee.first_name }} {{ transaction.to_employee.last_name }}
                        </span>
                      </div>

                      <!-- Status change -->
                      <div v-if="transaction.from_status && transaction.to_status" class="flex items-center gap-2 text-slate-700">
                        <svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                        </svg>
                        <span>
                          <span class="px-2 py-0.5 bg-slate-200 text-slate-700 rounded text-xs">{{ formatStatus(transaction.from_status) }}</span>
                          <span class="text-slate-400 mx-1">→</span>
                          <span class="px-2 py-0.5 bg-teal-100 text-teal-700 rounded text-xs">{{ formatStatus(transaction.to_status) }}</span>
                        </span>
                      </div>

                      <!-- Notes -->
                      <div v-if="transaction.notes" class="mt-2 p-3 bg-white rounded-lg border border-slate-200">
                        <p class="text-xs text-slate-600">{{ transaction.notes }}</p>
                      </div>

                      <!-- Performed by -->
                      <div v-if="transaction.performed_by" class="text-xs text-slate-500 mt-2">
                        Performed by {{ transaction.performed_by }}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </MainLayout>
</template>

<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, computed, h, Teleport, type VNode } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useToast } from '@/composables/useToast'
import MainLayout from '@/components/MainLayout.vue'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()
const toast = useToast()

const assetId = route.params.id as string  // UUID string, not number
const isLoading = ref(false)
const error = ref<string | null>(null)
const asset = ref<any>(null)
const showActionsMenu = ref(false)
const actionsButtonRef = ref<HTMLElement | null>(null)
const activeTab = ref('details')
const transactions = ref<any[]>([])
const loadingTransactions = ref(false)
const showAllAdditionalFields = ref(false)

// Info Field Component (functional component using Vue's h())
const InfoField = (props: { label: string; value?: string | number | boolean; monospace?: boolean }): VNode | null => {
  const { label, value, monospace = false } = props

  if (!value && value !== 0 && value !== false) return null

  return h('div', {}, [
    h('p', { class: 'text-xs font-medium text-slate-500 mb-1' }, label),
    h('p', {
      class: `text-sm text-primary-dark ${monospace ? 'font-mono' : 'font-medium'}`
    }, typeof value === 'boolean' ? (value ? 'Yes' : 'No') : String(value))
  ])
}

// Data Field Component - Renders complex data structures
const DataField = (props: { label: string; value: any }): VNode | null => {
  const { label, value } = props

  if (value === null || value === undefined) return null

  const renderValue = (val: any, depth: number = 0): VNode | VNode[] => {
    // Skip jamf_raw_data as it's too large
    if (label.toLowerCase().includes('raw_data')) {
      return h('div', { class: 'text-sm text-slate-500 italic' }, 'Raw data available (collapsed for readability)')
    }

    // Handle arrays
    if (Array.isArray(val)) {
      if (val.length === 0) return h('span', { class: 'text-sm text-slate-500 italic' }, 'Empty')

      // For arrays of objects (like applications)
      if (typeof val[0] === 'object' && val[0] !== null) {
        return h('ul', { class: 'space-y-2' }, val.slice(0, 10).map((item: any, idx: number) =>
          h('li', {
            key: idx,
            class: 'bg-slate-50 rounded-lg p-3 border border-slate-200'
          }, [
            h('div', { class: 'grid grid-cols-2 gap-2 text-sm' }, Object.entries(item).map(([k, v]: [string, any]) =>
              h('div', { key: k }, [
                h('span', { class: 'text-slate-500 font-medium' }, `${k}: `),
                h('span', { class: 'text-primary-dark' }, String(v))
              ])
            ))
          ])
        ))
      }

      // For simple arrays
      return h('ul', { class: 'list-disc list-inside space-y-1' }, val.slice(0, 20).map((item: any, idx: number) =>
        h('li', {
          key: idx,
          class: 'text-sm text-primary-dark'
        }, String(item))
      ))
    }

    // Handle objects
    if (typeof val === 'object' && val !== null) {
      return h('div', { class: 'space-y-2' }, Object.entries(val).map(([k, v]: [string, any]) =>
        h('div', {
          key: k,
          class: 'flex gap-2 text-sm'
        }, [
          h('span', { class: 'text-slate-500 font-medium min-w-[120px]' }, `${formatFieldName(k)}:`),
          h('span', { class: 'text-primary-dark flex-1' }, typeof v === 'object' ? renderValue(v, depth + 1) : String(v))
        ])
      ))
    }

    // Handle booleans
    if (typeof val === 'boolean') {
      return h('span', {
        class: `inline-flex items-center px-2 py-1 rounded text-xs font-semibold ${
          val ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-600'
        }`
      }, val ? 'Yes' : 'No')
    }

    // Handle primitives
    return h('span', { class: 'text-sm text-primary-dark' }, String(val))
  }

  return h('div', { class: 'border-b border-slate-100 pb-4 last:border-0' }, [
    h('h4', { class: 'text-sm font-semibold text-slate-700 mb-2' }, label),
    renderValue(value)
  ])
}

// Computed properties
const hasNetworkInfo = computed(() => {
  return asset.value?.custom_fields?.wifi_mac_address ||
         asset.value?.custom_fields?.ethernet_mac_address ||
         asset.value?.custom_fields?.imei ||
         asset.value?.custom_fields?.phone_number ||
         asset.value?.custom_fields?.subscriber_carrier
})

const hasAdditionalFields = computed(() => {
  return Object.keys(getAdditionalFields()).length > 0
})

const additionalFieldsCount = computed(() => {
  return Object.keys(getAdditionalFields()).length
})

const toggleAdditionalFields = () => {
  showAllAdditionalFields.value = !showAllAdditionalFields.value
}

const actionsMenuPosition = computed(() => {
  if (!actionsButtonRef.value) {
    return { top: '0px', left: '0px' }
  }

  const rect = actionsButtonRef.value.getBoundingClientRect()
  const dropdownWidth = 192 // w-48 = 12rem = 192px

  // Position below button, aligned to the right
  let top = rect.bottom + 8
  let left = rect.right - dropdownWidth

  // Ensure dropdown doesn't go off-screen
  if (left < 8) {
    left = 8
  }
  if (left + dropdownWidth > window.innerWidth - 8) {
    left = window.innerWidth - dropdownWidth - 8
  }

  return {
    top: `${top}px`,
    left: `${left}px`
  }
})

// Load asset data
const loadAsset = async () => {
  isLoading.value = true
  error.value = null

  try {
    const tenantId = authStore.user?.tenant_id || import.meta.env.VITE_DEFAULT_TENANT || 'acme'

    const response = await fetch(`${import.meta.env.VITE_API_URL}/api/v1/assets/${assetId}`, {
      headers: {
        'Authorization': `Bearer ${authStore.token}`,
        'X-Tenant-ID': tenantId
      }
    })

    if (!response.ok) {
      throw new Error(`Failed to load asset: ${response.statusText}`)
    }

    const data = await response.json()
    asset.value = data.data
  } catch (err: any) {
    console.error('Failed to load asset:', err)
    error.value = err.message || 'An unexpected error occurred'
  } finally {
    isLoading.value = false
  }
}

// Load transactions for this asset
const loadTransactions = async () => {
  loadingTransactions.value = true

  try {
    const tenantId = authStore.user?.tenant_id || import.meta.env.VITE_DEFAULT_TENANT || 'acme'

    const response = await fetch(`${import.meta.env.VITE_API_URL}/api/v1/assets/${assetId}/transactions`, {
      headers: {
        'Authorization': `Bearer ${authStore.token}`,
        'X-Tenant-ID': tenantId
      }
    })

    if (!response.ok) {
      throw new Error(`Failed to load transactions: ${response.statusText}`)
    }

    const data = await response.json()
    transactions.value = data.data
  } catch (err: any) {
    console.error('Failed to load transactions:', err)
    toast.error('Failed to load transaction history')
  } finally {
    loadingTransactions.value = false
  }
}

const getEmployeeName = (): string => {
  if (asset.value?.custom_fields?.user_display_name) {
    return asset.value.custom_fields.user_display_name
  }
  return 'Unknown'
}

const formatStatus = (status: string): string => {
  const statusMap: Record<string, string> = {
    in_stock: 'Available',
    assigned: 'Assigned',
    maintenance: 'In Maintenance',
    retired: 'Retired',
    available: 'Available'
  }
  return statusMap[status] || status.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
}

const getStatusBadgeClass = (status: string): string => {
  const classMap: Record<string, string> = {
    in_stock: 'bg-teal-500/20 text-teal-100 border border-teal-400/30',
    assigned: 'bg-blue-500/20 text-blue-100 border border-blue-400/30',
    maintenance: 'bg-amber-500/20 text-amber-100 border border-amber-400/30',
    retired: 'bg-slate-500/20 text-slate-100 border border-slate-400/30',
    available: 'bg-teal-500/20 text-teal-100 border border-teal-400/30'
  }
  return classMap[status] || 'bg-slate-500/20 text-slate-100 border border-slate-400/30'
}

const formatDate = (dateString?: string): string => {
  if (!dateString) return 'N/A'
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })
}

const formatDateTime = (dateString: string): string => {
  if (!dateString) return 'N/A'
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

const formatRelativeTime = (dateString: string): string => {
  const date = new Date(dateString)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffMins = Math.floor(diffMs / 60000)
  const diffHours = Math.floor(diffMs / 3600000)
  const diffDays = Math.floor(diffMs / 86400000)

  if (diffMins < 1) return 'just now'
  if (diffMins < 60) return `${diffMins} min ago`
  if (diffHours < 24) return `${diffHours} hour${diffHours > 1 ? 's' : ''} ago`
  if (diffDays < 7) return `${diffDays} day${diffDays > 1 ? 's' : ''} ago`

  return formatDate(dateString)
}

const formatFieldName = (key: string): string => {
  return key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
}

const formatFieldValue = (value: any): string => {
  if (value === null || value === undefined) return 'N/A'
  if (typeof value === 'boolean') return value ? 'Yes' : 'No'
  if (typeof value === 'object') return JSON.stringify(value)
  return String(value)
}

// Image handling functions
const getImageUrl = (url: string): string => {
  if (!url) return ''
  // If it's a relative URL (starts with /uploads), prepend the API base URL
  if (url.startsWith('/uploads')) {
    return `${import.meta.env.VITE_API_URL}${url}`
  }
  // Otherwise return the URL as-is (for S3 URLs)
  return url
}

const handleImageError = (event: Event) => {
  // Hide broken image on error
  const img = event.target as HTMLImageElement
  img.style.display = 'none'
}

// Get additional custom fields that aren't already displayed
const getAdditionalFields = () => {
  if (!asset.value?.custom_fields) return {}

  const displayedFields = new Set([
    'intune_id', 'azure_ad_device_id', 'managed_device_name',
    'user_display_name', 'user_principal_name', 'user_id',
    'compliance_state', 'management_state', 'device_registration_state',
    'is_encrypted', 'is_supervised', 'jailbroken_status',
    'ownership', 'enrollment_type', 'enrolled_date', 'enrollment_profile',
    'total_storage_gb', 'free_storage_gb', 'storage_used_percent', 'physical_memory_gb',
    'wifi_mac_address', 'ethernet_mac_address', 'imei', 'meid',
    'phone_number', 'subscriber_carrier',
    'partner_threat_state', 'azure_ad_registered',
    'iccid', 'udid', 'android_security_patch', 'device_category'
  ])

  const additional: Record<string, any> = {}

  for (const [key, value] of Object.entries(asset.value.custom_fields)) {
    if (!displayedFields.has(key) && value !== null && value !== undefined && value !== '') {
      additional[key] = value
    }
  }

  return additional
}

// Transaction formatting helpers
const getTransactionIcon = (type: string): string => {
  const iconMap: Record<string, string> = {
    assignment: 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z',
    return: 'M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6',
    transfer: 'M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4',
    status_change: 'M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15',
    repair_start: 'M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z',
    repair_complete: 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z',
    purchase: 'M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z',
    retire: 'M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4',
    lost: 'M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z',
    stolen: 'M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z',
    audit: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4',
    location_change: 'M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z',
    maintenance: 'M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z',
    other: 'M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z'
  }
  return (iconMap[type] || iconMap.other)!
}

const getTransactionColor = (type: string): string => {
  const colorMap: Record<string, string> = {
    assignment: 'blue',
    return: 'teal',
    transfer: 'purple',
    status_change: 'amber',
    repair_start: 'orange',
    repair_complete: 'teal',
    purchase: 'green',
    retire: 'slate',
    lost: 'red',
    stolen: 'red',
    audit: 'indigo',
    location_change: 'cyan',
    maintenance: 'orange',
    other: 'slate'
  }
  return (colorMap[type] || colorMap.other)!
}

const formatTransactionType = (type: string): string => {
  const typeMap: Record<string, string> = {
    assignment: 'Assignment',
    return: 'Return',
    transfer: 'Transfer',
    status_change: 'Status Change',
    repair_start: 'Repair Started',
    repair_complete: 'Repair Completed',
    purchase: 'Purchase',
    retire: 'Retired',
    lost: 'Lost',
    stolen: 'Stolen',
    audit: 'Audit',
    location_change: 'Location Change',
    maintenance: 'Maintenance',
    other: 'Other'
  }
  return typeMap[type] || type.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
}

// Actions menu management
const toggleActionsMenu = () => {
  showActionsMenu.value = !showActionsMenu.value
}

const closeActionsMenu = () => {
  showActionsMenu.value = false
}

// Handle delete asset
const handleDeleteAsset = async () => {
  closeActionsMenu()

  if (!confirm(`Are you sure you want to delete "${asset.value?.name}"?`)) {
    return
  }

  try {
    const tenantId = authStore.user?.tenant_id || import.meta.env.VITE_DEFAULT_TENANT || 'acme'

    const response = await fetch(`${import.meta.env.VITE_API_URL}/api/v1/assets/${assetId}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${authStore.token}`,
        'X-Tenant-ID': tenantId
      }
    })

    if (!response.ok) {
      throw new Error('Failed to delete asset')
    }

    toast.success('Asset deleted successfully')
    router.push('/assets')
  } catch (err: any) {
    console.error('Failed to delete asset:', err)
    toast.error('Failed to delete asset. Please try again.')
  }
}

// Close dropdown when clicking outside
const handleClickOutside = (event: MouseEvent) => {
  const target = event.target as HTMLElement
  // Don't close if clicking the button or inside the dropdown
  if (!target.closest('button') && !target.closest('[class*="fixed"]')) {
    closeActionsMenu()
  }
}

onMounted(() => {
  loadAsset()
  loadTransactions()
  document.addEventListener('click', handleClickOutside)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>
