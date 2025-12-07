<template>
  <MainLayout>
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
      <!-- Loading state -->
      <div v-if="isLoading" class="flex items-center justify-center min-h-[60vh]">
        <div class="text-center">
          <div class="animate-spin rounded-full h-16 w-16 border-b-4 border-accent-blue mx-auto mb-4"></div>
          <p class="text-slate-600 text-lg">Loading license...</p>
        </div>
      </div>

      <!-- Error state -->
      <div v-else-if="error" class="max-w-md mx-auto mt-12">
        <div class="bg-red-50 border-2 border-red-200 rounded-xl p-8 text-center">
          <svg class="w-16 h-16 text-red-500 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <h2 class="text-xl font-bold text-red-900 mb-2">Failed to load license</h2>
          <p class="text-red-700 mb-6">{{ error }}</p>
          <button @click="router.push('/software')" class="btn-brand-secondary">
            Back to Licenses
          </button>
        </div>
      </div>

      <!-- License details -->
      <div v-else-if="license" class="space-y-6">
        <!-- Hero Header with gradient background -->
        <div class="relative bg-gradient-to-br from-primary-dark via-primary-navy to-accent-blue rounded-2xl shadow-subtle" style="overflow: visible;">
          <!-- Background pattern -->
          <div class="absolute inset-0 opacity-10 rounded-2xl overflow-hidden">
            <div class="absolute inset-0" style="background-image: url('data:image/svg+xml,%3Csvg width=60 height=60 xmlns=http://www.w3.org/2000/svg%3E%3Cpath d=M0 0h60v60H0z fill=none/%3E%3Cpath d=M30 0v60M0 30h60 stroke=%23fff stroke-width=1/%3E%3C/svg%3E');"></div>
          </div>

          <div class="relative px-6 sm:px-8 lg:px-12 py-8 sm:py-12" style="overflow: visible;">
            <div class="flex flex-col lg:flex-row items-start lg:items-center justify-between gap-6">
              <div class="flex-1">
                <!-- Breadcrumb -->
                <div class="flex items-center gap-2 text-sm text-slate-300 mb-3">
                  <router-link to="/software" class="hover:text-white transition-colors">Software Licenses</router-link>
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                  </svg>
                  <span class="text-white">{{ license.name }}</span>
                </div>

                <!-- License name and info -->
                <h1 class="text-3xl sm:text-4xl lg:text-5xl font-bold text-white mb-3">{{ license.name }}</h1>

                <div class="flex flex-wrap items-center gap-3 text-slate-200">
                  <!-- Status badge -->
                  <span
                    class="inline-flex items-center gap-2 px-4 py-2 rounded-full text-sm font-semibold"
                    :class="getStatusBadgeClass(license.status)"
                  >
                    <span class="w-2 h-2 rounded-full bg-current"></span>
                    {{ formatStatus(license.status) }}
                  </span>

                  <!-- Vendor badge -->
                  <span v-if="license.vendor" class="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/10 backdrop-blur-sm text-white text-sm font-medium">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                    </svg>
                    {{ license.vendor }}
                  </span>

                  <!-- Utilization indicator -->
                  <span v-if="license.total_seats" class="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/10 backdrop-blur-sm text-white text-sm">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                    </svg>
                    {{ getUtilization() }}% utilized
                  </span>
                </div>
              </div>

              <!-- Action buttons -->
              <div class="flex gap-3">
                <!-- Back button -->
                <button @click="router.push('/software')" class="px-4 py-2 bg-white/10 hover:bg-white/20 backdrop-blur-sm text-white rounded-lg transition-all duration-200 border border-white/20">
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
                          :to="`/software/${license.id}/edit`"
                          class="flex items-center gap-2 px-4 py-2 text-sm text-slate-700 hover:bg-slate-50"
                        >
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                          </svg>
                          Edit license
                        </router-link>
                        <button
                          @click="handleDelete"
                          class="w-full flex items-center gap-2 px-4 py-2 text-sm text-red-600 hover:bg-red-50"
                        >
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                          </svg>
                          Delete license
                        </button>
                      </div>
                    </div>
                  </Teleport>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Main Content Grid -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <!-- Left Column - Key Info & Visual -->
          <div class="lg:col-span-1 space-y-6">
            <!-- License Visual Card -->
            <div class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
              <div class="p-6">
                <h3 class="text-sm font-semibold text-slate-500 uppercase tracking-wide mb-4">License</h3>
                <div class="aspect-square bg-gradient-to-br from-blue-50 to-indigo-100 rounded-xl flex items-center justify-center mb-4">
                  <svg class="w-32 h-32 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                  </svg>
                </div>
                <div class="space-y-3">
                  <div>
                    <p class="text-lg font-bold text-primary-dark">{{ license.name }}</p>
                    <p class="text-sm text-slate-600">{{ license.vendor }}</p>
                  </div>
                  <div v-if="license.license_key" class="pt-3 border-t border-slate-100">
                    <p class="text-xs font-medium text-slate-500 mb-1">License key</p>
                    <p class="text-xs font-mono text-primary-dark break-all">{{ maskLicenseKey(license.license_key) }}</p>
                  </div>
                </div>
              </div>
            </div>

            <!-- Seat Utilization Card -->
            <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
              <h3 class="text-sm font-semibold text-slate-500 uppercase tracking-wide mb-4">Seat utilization</h3>
              <div class="space-y-4">
                <!-- Utilization bar -->
                <div>
                  <div class="flex items-center justify-between mb-2">
                    <span class="text-2xl font-bold text-primary-dark">{{ getUtilization() }}%</span>
                    <span class="text-sm text-slate-500">
                      <span class="font-mono">{{ getAssignedSeats() }}</span> / <span class="font-mono">{{ license.total_seats }}</span>
                    </span>
                  </div>
                  <div class="h-3 bg-slate-200 rounded-full overflow-hidden">
                    <div
                      :class="getUtilizationColorClass()"
                      :style="{ width: getUtilization() + '%' }"
                      class="h-full transition-all duration-300"
                    ></div>
                  </div>
                </div>

                <!-- Stats grid -->
                <div class="grid grid-cols-2 gap-3 pt-3">
                  <div class="bg-slate-50 rounded-lg p-3">
                    <p class="text-xs text-slate-500 mb-1">Assigned</p>
                    <p class="text-lg font-bold font-mono text-primary-dark">{{ getAssignedSeats() }}</p>
                  </div>
                  <div class="bg-slate-50 rounded-lg p-3">
                    <p class="text-xs text-slate-500 mb-1">Available</p>
                    <p class="text-lg font-bold font-mono text-teal-600">{{ getAvailableSeats() }}</p>
                  </div>
                </div>
              </div>
            </div>

            <!-- Cost Information -->
            <div v-if="license.annual_cost || license.cost_per_seat" class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
              <h3 class="text-sm font-semibold text-slate-500 uppercase tracking-wide mb-4">Cost</h3>
              <div class="space-y-3">
                <div v-if="license.annual_cost" class="flex items-center justify-between">
                  <span class="text-sm text-slate-600">Annual cost</span>
                  <span class="text-lg font-bold text-primary-dark">${{ formatCurrency(license.annual_cost) }}</span>
                </div>
                <div v-if="license.cost_per_seat" class="flex items-center justify-between">
                  <span class="text-sm text-slate-600">Per seat</span>
                  <span class="text-lg font-bold text-primary-dark">${{ formatCurrency(license.cost_per_seat) }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Right Column - Detailed Information -->
          <div class="lg:col-span-2 space-y-6">
            <!-- License Information -->
            <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
              <h3 class="text-lg font-bold text-primary-dark mb-6 flex items-center gap-2">
                <svg class="w-5 h-5 text-accent-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                License information
              </h3>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-4">
                <InfoField label="Vendor" :value="license.vendor" />
                <InfoField label="Status" :value="formatStatus(license.status)" />
                <InfoField label="Total seats" :value="license.total_seats" monospace />
                <InfoField label="Assigned seats" :value="getAssignedSeats()" monospace />
                <InfoField label="Available seats" :value="getAvailableSeats()" monospace />
                <InfoField label="Utilization rate" :value="getUtilization() + '%'" monospace />
              </div>
            </div>

            <!-- Description -->
            <div v-if="license.description" class="bg-gradient-to-br from-slate-50 to-white rounded-2xl shadow-sm border border-slate-200 p-6">
              <h3 class="text-lg font-bold text-primary-dark mb-3">Description</h3>
              <p class="text-slate-700 leading-relaxed">{{ license.description }}</p>
            </div>

            <!-- Dates & Costs -->
            <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
              <h3 class="text-lg font-bold text-primary-dark mb-6 flex items-center gap-2">
                <svg class="w-5 h-5 text-accent-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                Dates and costs
              </h3>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-4">
                <InfoField label="Purchase date" :value="formatDate(license.purchase_date)" />
                <InfoField label="Expiration date" :value="formatDate(license.expiration_date)" />
                <InfoField label="Annual cost" :value="license.annual_cost ? '$' + formatCurrency(license.annual_cost) : undefined" />
                <InfoField label="Cost per seat" :value="license.cost_per_seat ? '$' + formatCurrency(license.cost_per_seat) : undefined" />
              </div>
            </div>

            <!-- Integration Details -->
            <div v-if="license.sso_app_id || license.integration_id" class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
              <h3 class="text-lg font-bold text-primary-dark mb-6 flex items-center gap-2">
                <svg class="w-5 h-5 text-accent-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                Integration
              </h3>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-4">
                <InfoField label="SSO app ID" :value="license.sso_app_id" monospace />
                <InfoField label="Integration ID" :value="license.integration_id" monospace />
              </div>
            </div>

            <!-- License Assignments -->
            <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
              <div class="flex items-center justify-between mb-6">
                <h3 class="text-lg font-bold text-primary-dark flex items-center gap-2">
                  <svg class="w-5 h-5 text-accent-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                  </svg>
                  Assignments ({{ assignments.length }})
                </h3>
                <button
                  v-if="getAvailableSeats() > 0"
                  @click="showAssignModal = true"
                  class="px-4 py-2 bg-teal-600 hover:bg-teal-700 text-white rounded-lg transition-colors flex items-center gap-2"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                  </svg>
                  Assign to employee
                </button>
                <div v-else class="text-sm text-amber-600 font-medium">
                  No seats available
                </div>
              </div>

              <!-- Loading state -->
              <div v-if="loadingAssignments" class="text-center py-8">
                <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-accent-blue mx-auto mb-2"></div>
                <p class="text-slate-600 text-sm">Loading assignments...</p>
              </div>

              <!-- Empty state -->
              <div v-else-if="assignments.length === 0" class="text-center py-12">
                <svg class="w-16 h-16 text-slate-300 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                </svg>
                <h4 class="text-lg font-medium text-slate-700 mb-2">No assignments yet</h4>
                <p class="text-slate-500 text-sm">This license has not been assigned to any employees.</p>
              </div>

              <!-- Assignments list -->
              <div v-else class="space-y-3">
                <div
                  v-for="assignment in assignments"
                  :key="assignment.id"
                  class="flex items-center justify-between p-4 bg-slate-50 rounded-lg border border-slate-200 hover:border-slate-300 transition-colors"
                >
                  <div class="flex items-center gap-3 flex-1">
                    <div class="w-10 h-10 rounded-full bg-gradient-to-br from-teal-400 to-blue-500 flex items-center justify-center text-white font-semibold">
                      {{ getInitials(assignment.employee) }}
                    </div>
                    <div class="flex-1">
                      <p class="font-medium text-primary-dark">
                        {{ assignment.employee?.first_name }} {{ assignment.employee?.last_name }}
                      </p>
                      <p class="text-sm text-slate-500">{{ assignment.employee?.email }}</p>
                    </div>
                    <div class="text-right">
                      <p class="text-xs text-slate-500">Assigned</p>
                      <p class="text-sm font-medium text-slate-700">{{ formatDate(assignment.assigned_at) }}</p>
                    </div>
                  </div>
                  <button
                    v-if="assignment.status === 'active'"
                    @click="handleRevokeAssignment(assignment)"
                    class="ml-4 px-3 py-1.5 text-sm text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                  >
                    Revoke
                  </button>
                  <span v-else class="ml-4 px-3 py-1.5 text-sm text-slate-500">
                    Revoked
                  </span>
                </div>
              </div>
            </div>

            <!-- Metadata -->
            <div class="bg-slate-50 rounded-2xl border border-slate-200 p-6">
              <h3 class="text-sm font-semibold text-slate-500 uppercase tracking-wide mb-4">Metadata</h3>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 text-sm">
                <div>
                  <p class="text-slate-500 mb-1">Created</p>
                  <p class="text-slate-900 font-medium">{{ formatDateTime(license.created_at) }}</p>
                </div>
                <div>
                  <p class="text-slate-500 mb-1">Last updated</p>
                  <p class="text-slate-900 font-medium">{{ formatDateTime(license.updated_at) }}</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Assign License Modal -->
    <Teleport to="body">
      <div
        v-if="showAssignModal"
        class="fixed inset-0 bg-black/50 flex items-center justify-center z-[10000] p-4"
        @click.self="showAssignModal = false"
      >
        <div class="bg-white rounded-2xl shadow-xl max-w-md w-full">
          <div class="p-6 border-b border-slate-200">
            <h3 class="text-xl font-bold text-primary-dark">Assign license to employee</h3>
            <p class="text-sm text-slate-500 mt-1">Select an employee to assign this license to</p>
          </div>

          <div class="p-6">
            <div class="mb-4">
              <label for="employee-search" class="block text-sm font-medium text-slate-600 mb-2">
                Search employees
              </label>
              <input
                id="employee-search"
                v-model="employeeSearch"
                type="text"
                class="input-refined"
                placeholder="Search by name or email..."
                @input="searchEmployees"
              />
            </div>

            <!-- Loading employees -->
            <div v-if="loadingEmployees" class="text-center py-8">
              <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-accent-blue mx-auto"></div>
            </div>

            <!-- Employee list -->
            <div v-else-if="filteredEmployees.length > 0" class="max-h-64 overflow-y-auto space-y-2">
              <button
                v-for="employee in filteredEmployees"
                :key="employee.id"
                @click="selectedEmployee = employee"
                class="w-full flex items-center gap-3 p-3 rounded-lg border transition-colors text-left"
                :class="selectedEmployee?.id === employee.id ? 'border-teal-600 bg-teal-50' : 'border-slate-200 hover:border-slate-300'"
              >
                <div class="w-10 h-10 rounded-full bg-gradient-to-br from-teal-400 to-blue-500 flex items-center justify-center text-white font-semibold text-sm">
                  {{ employee.first_name?.[0] }}{{ employee.last_name?.[0] }}
                </div>
                <div class="flex-1">
                  <p class="font-medium text-primary-dark text-sm">
                    {{ employee.first_name }} {{ employee.last_name }}
                  </p>
                  <p class="text-xs text-slate-500">{{ employee.email }}</p>
                </div>
                <svg
                  v-if="selectedEmployee?.id === employee.id"
                  class="w-5 h-5 text-teal-600"
                  fill="currentColor"
                  viewBox="0 0 20 20"
                >
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                </svg>
              </button>
            </div>

            <!-- No employees found -->
            <div v-else class="text-center py-8 text-slate-500 text-sm">
              No employees found
            </div>
          </div>

          <div class="p-6 border-t border-slate-200 flex gap-3">
            <button
              @click="showAssignModal = false"
              class="flex-1 px-4 py-2 btn-brand-secondary"
            >
              Cancel
            </button>
            <button
              @click="handleAssignLicense"
              :disabled="!selectedEmployee || isAssigning"
              class="flex-1 px-4 py-2 btn-brand-primary disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <span v-if="!isAssigning">Assign</span>
              <span v-else class="flex items-center justify-center">
                <svg class="animate-spin -ml-1 mr-2 h-5 w-5" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                Assigning...
              </span>
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </MainLayout>
</template>

<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, computed, h, Teleport, watch, type VNode } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import MainLayout from '@/components/MainLayout.vue'
import { softwareService } from '@/services/software'
import { employeesService } from '@/services/employees'

const router = useRouter()
const route = useRoute()

const licenseId = route.params.id as string
const isLoading = ref(false)
const error = ref<string | null>(null)
const license = ref<any>(null)
const showActionsMenu = ref(false)
const actionsButtonRef = ref<HTMLElement | null>(null)

// Assignment related state
const assignments = ref<any[]>([])
const loadingAssignments = ref(false)
const showAssignModal = ref(false)
const employees = ref<any[]>([])
const filteredEmployees = ref<any[]>([])
const loadingEmployees = ref(false)
const employeeSearch = ref('')
const selectedEmployee = ref<any>(null)
const isAssigning = ref(false)

// Info Field Component
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

// Computed properties
const actionsMenuPosition = computed(() => {
  if (!actionsButtonRef.value) {
    return { top: '0px', left: '0px' }
  }

  const rect = actionsButtonRef.value.getBoundingClientRect()
  const dropdownWidth = 192

  let top = rect.bottom + 8
  let left = rect.right - dropdownWidth

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

// Load license data
const loadLicense = async () => {
  isLoading.value = true
  error.value = null

  try {
    license.value = await softwareService.getById(licenseId)
    loadAssignments()
  } catch (err: any) {
    console.error('Failed to load license:', err)
    error.value = err.message || 'An unexpected error occurred'
  } finally {
    isLoading.value = false
  }
}

// Load assignments
const loadAssignments = async () => {
  loadingAssignments.value = true
  try {
    assignments.value = await softwareService.getAssignments(licenseId)
  } catch (err: any) {
    console.error('Failed to load assignments:', err)
  } finally {
    loadingAssignments.value = false
  }
}

// Load employees for assignment modal
const loadEmployees = async () => {
  loadingEmployees.value = true
  try {
    const response = await employeesService.getAll()
    employees.value = response || []
    filteredEmployees.value = employees.value
  } catch (err: any) {
    console.error('Failed to load employees:', err)
  } finally {
    loadingEmployees.value = false
  }
}

// Search/filter employees
const searchEmployees = () => {
  const search = employeeSearch.value.toLowerCase()
  if (!search) {
    filteredEmployees.value = employees.value
    return
  }

  filteredEmployees.value = employees.value.filter((emp: any) => {
    const fullName = `${emp.first_name} ${emp.last_name}`.toLowerCase()
    const email = emp.email?.toLowerCase() || ''
    return fullName.includes(search) || email.includes(search)
  })
}

// Handle assigning license
const handleAssignLicense = async () => {
  if (!selectedEmployee.value) return

  isAssigning.value = true
  try {
    await softwareService.assign(licenseId, {
      employee_id: selectedEmployee.value.id,
      assigned_at: new Date().toISOString(),
      status: 'active'
    })

    // Reload assignments and license data
    await loadAssignments()
    await loadLicense()

    // Close modal and reset
    showAssignModal.value = false
    selectedEmployee.value = null
    employeeSearch.value = ''
  } catch (err: any) {
    console.error('Failed to assign license:', err)
    alert('Failed to assign license. Please try again.')
  } finally {
    isAssigning.value = false
  }
}

// Handle revoking assignment
const handleRevokeAssignment = async (assignment: any) => {
  if (!confirm(`Are you sure you want to revoke this license from ${assignment.employee?.first_name} ${assignment.employee?.last_name}?`)) {
    return
  }

  try {
    await softwareService.revokeAssignment(licenseId, assignment.id)

    // Reload assignments and license data
    await loadAssignments()
    await loadLicense()
  } catch (err: any) {
    console.error('Failed to revoke assignment:', err)
    alert('Failed to revoke assignment. Please try again.')
  }
}

// Watch for modal opening to load employees
const handleModalOpen = () => {
  if (showAssignModal.value && employees.value.length === 0) {
    loadEmployees()
  }
}

// Helper functions
const getInitials = (employee: any): string => {
  if (!employee) return '?'
  const first = employee.first_name?.[0] || ''
  const last = employee.last_name?.[0] || ''
  return (first + last).toUpperCase() || '?'
}

// Seat calculations
const getAssignedSeats = (): number => {
  return license.value?.used_seats || license.value?.assigned_count || 0
}

const getAvailableSeats = (): number => {
  return (license.value?.total_seats || 0) - getAssignedSeats()
}

const getUtilization = (): number => {
  if (!license.value?.total_seats) return 0
  return Math.round((getAssignedSeats() / license.value.total_seats) * 100)
}

const getUtilizationColorClass = (): string => {
  const util = getUtilization()
  if (util >= 90) return 'bg-red-500'
  if (util >= 70) return 'bg-amber-500'
  if (util >= 50) return 'bg-blue-500'
  return 'bg-teal-500'
}

// Formatting helpers
const formatStatus = (status: string): string => {
  const statusMap: Record<string, string> = {
    active: 'Active',
    expired: 'Expired',
    cancelled: 'Cancelled',
    future: 'Future'
  }
  return statusMap[status] || status.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
}

const getStatusBadgeClass = (status: string): string => {
  const classMap: Record<string, string> = {
    active: 'bg-teal-500/20 text-teal-100 border border-teal-400/30',
    expired: 'bg-red-500/20 text-red-100 border border-red-400/30',
    cancelled: 'bg-slate-500/20 text-slate-100 border border-slate-400/30',
    future: 'bg-blue-500/20 text-blue-100 border border-blue-400/30'
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

const formatCurrency = (amount: number): string => {
  return amount.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

const maskLicenseKey = (key: string): string => {
  if (key.length <= 8) return key
  return key.substring(0, 4) + '•'.repeat(Math.min(key.length - 8, 20)) + key.substring(key.length - 4)
}

// Actions menu management
const toggleActionsMenu = () => {
  showActionsMenu.value = !showActionsMenu.value
}

const closeActionsMenu = () => {
  showActionsMenu.value = false
}

// Handle delete license
const handleDelete = async () => {
  closeActionsMenu()

  if (!confirm(`Are you sure you want to delete "${license.value?.name}"?`)) {
    return
  }

  try {
    await softwareService.delete(licenseId)
    router.push('/software')
  } catch (err: any) {
    console.error('Failed to delete license:', err)
    alert('Failed to delete license. Please try again.')
  }
}

// Close dropdown when clicking outside
const handleClickOutside = (event: MouseEvent) => {
  const target = event.target as HTMLElement
  if (!target.closest('button') && !target.closest('[class*="fixed"]')) {
    closeActionsMenu()
  }
}

// Watch for modal changes
watch(showAssignModal, (newValue) => {
  if (newValue && employees.value.length === 0) {
    loadEmployees()
  }
})

onMounted(() => {
  loadLicense()
  document.addEventListener('click', handleClickOutside)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>
