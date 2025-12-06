<template>
  <MainLayout>
    <div>
      <!-- Page header -->
      <div class="mb-6">
        <h1 class="text-3xl font-bold text-primary-dark">Workflows</h1>
        <p class="text-slate-500 mt-1">Manage onboarding, offboarding, and procurement workflows</p>
      </div>

      <!-- Actions bar -->
      <div class="flex flex-col gap-4 mb-6">
        <!-- Search and Add button -->
        <div class="flex flex-col sm:flex-row gap-4">
          <div class="flex-1">
            <input
              v-model="searchQuery"
              type="search"
              placeholder="Search workflows..."
              class="input-refined w-full"
            />
          </div>
          <button
            @click="showCreateModal = true"
            class="px-6 py-3 btn-brand-primary whitespace-nowrap text-center"
          >
            <svg class="w-5 h-5 mr-2 inline-block" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Create workflow
          </button>
        </div>

        <!-- Filters -->
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div>
            <label class="block text-xs font-medium text-slate-700 mb-1">Type</label>
            <select v-model="filters.workflow_type" class="input-refined w-full">
              <option value="">All types</option>
              <option value="onboarding">Onboarding</option>
              <option value="offboarding">Offboarding</option>
              <option value="procurement">Procurement</option>
              <option value="repair">Repair</option>
              <option value="maintenance">Maintenance</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-medium text-slate-700 mb-1">Status</label>
            <select v-model="filters.status" class="input-refined w-full">
              <option value="">All statuses</option>
              <option value="pending">Pending</option>
              <option value="in_progress">In progress</option>
              <option value="completed">Completed</option>
              <option value="cancelled">Cancelled</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-medium text-slate-700 mb-1">Priority</label>
            <select v-model="filters.priority" class="input-refined w-full">
              <option value="">All priorities</option>
              <option value="low">Low</option>
              <option value="normal">Normal</option>
              <option value="high">High</option>
              <option value="urgent">Urgent</option>
            </select>
          </div>
        </div>
      </div>

      <!-- Desktop Table View (hidden on mobile) -->
      <div class="hidden md:block bg-white border border-border-light rounded-lg shadow-subtle">
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-light-bg border-b border-slate-200">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Workflow
                </th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Type
                </th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Status
                </th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Progress
                </th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Due date
                </th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-slate-200">
              <tr v-if="loading">
                <td colspan="6" class="px-4 py-6 text-center text-slate-500">
                  Loading workflows...
                </td>
              </tr>
              <tr v-else-if="filteredWorkflows.length === 0">
                <td colspan="6" class="px-4 py-6 text-center text-slate-500">
                  {{ searchQuery ? 'No workflows found matching your search.' : 'No workflows found. Click "Create workflow" to get started.' }}
                </td>
              </tr>
              <tr v-else v-for="workflow in filteredWorkflows" :key="workflow.id" class="hover:bg-light-bg transition-colors cursor-pointer" @click="viewWorkflow(workflow.id)">
                <td class="px-4 py-3 whitespace-nowrap">
                  <div class="flex items-center gap-3">
                    <!-- Type icon -->
                    <div class="w-10 h-10 flex-shrink-0 rounded-lg flex items-center justify-center" :class="getTypeColorClass(workflow.workflow_type)">
                      <svg v-if="workflow.workflow_type === 'onboarding'" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
                      </svg>
                      <svg v-else-if="workflow.workflow_type === 'offboarding'" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7a4 4 0 11-8 0 4 4 0 018 0zM9 14a6 6 0 00-6 6v1h12v-1a6 6 0 00-6-6zM21 12h-6" />
                      </svg>
                      <svg v-else-if="workflow.workflow_type === 'procurement'" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
                      </svg>
                      <svg v-else-if="workflow.workflow_type === 'repair'" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                      </svg>
                      <svg v-else class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                      </svg>
                    </div>
                    <!-- Workflow name and employee -->
                    <div>
                      <div class="text-sm font-bold text-primary-dark">{{ workflow.title }}</div>
                      <div class="text-sm text-slate-500">
                        {{ workflow.employee ? `${workflow.employee.first_name} ${workflow.employee.last_name}` : (workflow.asset ? workflow.asset.name : '-') }}
                      </div>
                    </div>
                  </div>
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-slate-600 capitalize">{{ formatType(workflow.workflow_type) }}</td>
                <td class="px-4 py-3 whitespace-nowrap">
                  <span
                    class="px-2 py-1 text-xs font-mono font-bold rounded border"
                    :class="getStatusClass(workflow.status)"
                  >
                    {{ formatStatus(workflow.status) }}
                  </span>
                </td>
                <td class="px-4 py-3 whitespace-nowrap">
                  <div class="flex items-center gap-2">
                    <div class="w-24 bg-slate-200 rounded-full h-2">
                      <div
                        class="bg-accent-blue h-2 rounded-full transition-all"
                        :style="{ width: `${getProgressPercentage(workflow)}%` }"
                      ></div>
                    </div>
                    <span class="text-xs text-slate-500">{{ workflow.current_step }}/{{ workflow.total_steps }}</span>
                  </div>
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm" :class="getDueDateClass(workflow)">
                  {{ workflow.due_date ? formatDate(workflow.due_date) : '-' }}
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm">
                  <div class="relative inline-block text-left" @click.stop>
                    <button
                      @click="toggleDropdown(workflow.id, $event)"
                      class="inline-flex items-center gap-1 px-3 py-1.5 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-accent-blue"
                    >
                      Actions
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                      </svg>
                    </button>

                    <!-- Dropdown menu using Teleport to avoid overflow issues -->
                    <Teleport to="body">
                      <div
                        v-if="openDropdownId === workflow.id"
                        :style="dropdownPosition"
                        class="fixed z-[9999] w-48 rounded-lg bg-white shadow-xl ring-1 ring-black ring-opacity-5 focus:outline-none"
                        @click.stop
                      >
                        <div class="py-1">
                          <button
                            @click="handleViewWorkflow(workflow)"
                            class="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 flex items-center gap-2"
                          >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                            </svg>
                            View details
                          </button>
                          <button
                            v-if="workflow.status === 'pending'"
                            @click="handleStartWorkflow(workflow)"
                            class="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 flex items-center gap-2"
                          >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                            </svg>
                            Start workflow
                          </button>
                          <button
                            v-if="workflow.status === 'in_progress' && workflow.current_step >= workflow.total_steps"
                            @click="handleCompleteWorkflow(workflow)"
                            class="w-full text-left px-4 py-2 text-sm text-teal-700 hover:bg-teal-50 flex items-center gap-2"
                          >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                            </svg>
                            Complete
                          </button>
                          <button
                            v-if="workflow.status === 'in_progress' && workflow.current_step < workflow.total_steps"
                            @click="handleAdvanceWorkflow(workflow)"
                            class="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 flex items-center gap-2"
                          >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7l5 5m0 0l-5 5m5-5H6" />
                            </svg>
                            Advance step
                          </button>
                          <button
                            v-if="workflow.status !== 'completed' && workflow.status !== 'cancelled'"
                            @click="handleCancelWorkflow(workflow)"
                            class="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50 flex items-center gap-2"
                          >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                            </svg>
                            Cancel
                          </button>
                        </div>
                      </div>
                    </Teleport>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Mobile Card View (visible on mobile only) -->
      <div class="md:hidden space-y-4">
        <!-- Loading/Empty states -->
        <div v-if="loading" class="bg-white border border-border-light rounded-lg p-6 text-center text-slate-500">
          Loading workflows...
        </div>
        <div v-else-if="filteredWorkflows.length === 0" class="bg-white border border-border-light rounded-lg p-6 text-center text-slate-500">
          {{ searchQuery ? 'No workflows found matching your search.' : 'No workflows found. Click "Create workflow" to get started.' }}
        </div>

        <!-- Workflow cards -->
        <div v-else v-for="workflow in filteredWorkflows" :key="workflow.id" class="bg-white border border-border-light rounded-lg overflow-hidden shadow-subtle">
          <div class="p-4 space-y-3">
            <!-- Header with icon, name and dropdown -->
            <div class="flex items-start justify-between gap-3">
              <!-- Type icon -->
              <div class="w-12 h-12 flex-shrink-0 rounded-lg flex items-center justify-center" :class="getTypeColorClass(workflow.workflow_type)">
                <svg v-if="workflow.workflow_type === 'onboarding'" class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
                </svg>
                <svg v-else-if="workflow.workflow_type === 'offboarding'" class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7a4 4 0 11-8 0 4 4 0 018 0zM9 14a6 6 0 00-6 6v1h12v-1a6 6 0 00-6-6zM21 12h-6" />
                </svg>
                <svg v-else-if="workflow.workflow_type === 'procurement'" class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
                </svg>
                <svg v-else-if="workflow.workflow_type === 'repair'" class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
                <svg v-else class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                </svg>
              </div>
              <div class="flex-1 min-w-0">
                <h3 class="text-lg font-bold text-primary-dark truncate">{{ workflow.title }}</h3>
                <p class="text-sm text-slate-500">
                  {{ workflow.employee ? `${workflow.employee.first_name} ${workflow.employee.last_name}` : (workflow.asset ? workflow.asset.name : '-') }}
                </p>
              </div>

              <!-- Mobile dropdown -->
              <div class="relative flex-shrink-0">
                <button
                  @click="toggleDropdown(workflow.id, $event)"
                  class="p-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
                  </svg>
                </button>

                <!-- Dropdown menu using Teleport -->
                <Teleport to="body">
                  <div
                    v-if="openDropdownId === workflow.id"
                    :style="dropdownPosition"
                    class="fixed z-[9999] w-48 rounded-lg bg-white shadow-xl ring-1 ring-black ring-opacity-5"
                    @click.stop
                  >
                    <div class="py-1">
                      <button
                        @click="handleViewWorkflow(workflow)"
                        class="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 flex items-center gap-2"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                        </svg>
                        View details
                      </button>
                      <button
                        v-if="workflow.status === 'pending'"
                        @click="handleStartWorkflow(workflow)"
                        class="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 flex items-center gap-2"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        Start workflow
                      </button>
                      <button
                        v-if="workflow.status === 'in_progress' && workflow.current_step >= workflow.total_steps"
                        @click="handleCompleteWorkflow(workflow)"
                        class="w-full text-left px-4 py-2 text-sm text-teal-700 hover:bg-teal-50 flex items-center gap-2"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        Complete
                      </button>
                      <button
                        v-if="workflow.status === 'in_progress' && workflow.current_step < workflow.total_steps"
                        @click="handleAdvanceWorkflow(workflow)"
                        class="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 flex items-center gap-2"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7l5 5m0 0l-5 5m5-5H6" />
                        </svg>
                        Advance step
                      </button>
                      <button
                        v-if="workflow.status !== 'completed' && workflow.status !== 'cancelled'"
                        @click="handleCancelWorkflow(workflow)"
                        class="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50 flex items-center gap-2"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                        Cancel
                      </button>
                    </div>
                  </div>
                </Teleport>
              </div>
            </div>

            <!-- Workflow details -->
            <div class="grid grid-cols-2 gap-3 pt-3 border-t border-slate-200">
              <div>
                <p class="text-xs font-medium text-slate-500 mb-1">Type</p>
                <p class="text-sm text-slate-900 capitalize">{{ formatType(workflow.workflow_type) }}</p>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 mb-1">Status</p>
                <span
                  class="inline-block px-2 py-1 text-xs font-mono font-bold rounded border"
                  :class="getStatusClass(workflow.status)"
                >
                  {{ formatStatus(workflow.status) }}
                </span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 mb-1">Progress</p>
                <div class="flex items-center gap-2">
                  <div class="flex-1 bg-slate-200 rounded-full h-2">
                    <div
                      class="bg-accent-blue h-2 rounded-full transition-all"
                      :style="{ width: `${getProgressPercentage(workflow)}%` }"
                    ></div>
                  </div>
                  <span class="text-xs text-slate-500">{{ workflow.current_step }}/{{ workflow.total_steps }}</span>
                </div>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 mb-1">Due date</p>
                <p class="text-sm" :class="getDueDateClass(workflow)">{{ workflow.due_date ? formatDate(workflow.due_date) : '-' }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Create Workflow Modal -->
    <CreateWorkflowModal
      v-if="showCreateModal"
      @close="showCreateModal = false"
      @created="handleWorkflowCreated"
    />
  </MainLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch, onBeforeUnmount, Teleport } from 'vue'
import { useRouter } from 'vue-router'
import MainLayout from '@/components/MainLayout.vue'
import CreateWorkflowModal from '@/components/workflows/CreateWorkflowModal.vue'
import api from '@/services/api'

interface Workflow {
  id: string
  workflow_type: string
  title: string
  description: string
  status: string
  priority: string
  current_step: number
  total_steps: number
  due_date: string
  employee?: {
    id: string
    first_name: string
    last_name: string
    email: string
  }
  asset?: {
    id: string
    name: string
    asset_tag: string
  }
}

const router = useRouter()

const workflows = ref<Workflow[]>([])
const loading = ref(false)
const showCreateModal = ref(false)
const searchQuery = ref('')
const openDropdownId = ref<string | null>(null)
const dropdownPosition = ref({ top: '0px', left: '0px' })

const filters = ref({
  workflow_type: '',
  status: '',
  priority: ''
})

// Computed filtered workflows based on search
const filteredWorkflows = computed(() => {
  if (!searchQuery.value.trim()) {
    return workflows.value
  }
  const query = searchQuery.value.toLowerCase()
  return workflows.value.filter(workflow => {
    return (
      workflow.title?.toLowerCase().includes(query) ||
      workflow.description?.toLowerCase().includes(query) ||
      workflow.employee?.first_name?.toLowerCase().includes(query) ||
      workflow.employee?.last_name?.toLowerCase().includes(query) ||
      workflow.asset?.name?.toLowerCase().includes(query)
    )
  })
})

const fetchWorkflows = async () => {
  loading.value = true
  try {
    const params: Record<string, string> = {}
    if (filters.value.workflow_type) params.workflow_type = filters.value.workflow_type
    if (filters.value.status) params.status = filters.value.status
    if (filters.value.priority) params.priority = filters.value.priority

    const response = await api.get('/workflows', { params })
    workflows.value = response.data.data || []
  } catch (error) {
    console.error('Error fetching workflows:', error)
  } finally {
    loading.value = false
  }
}

// Watch filters for changes
watch(
  () => [filters.value.workflow_type, filters.value.status, filters.value.priority],
  () => {
    fetchWorkflows()
  }
)

const viewWorkflow = (id: string) => {
  router.push(`/workflows/${id}`)
}

const handleViewWorkflow = (workflow: Workflow) => {
  closeDropdown()
  viewWorkflow(workflow.id)
}

const handleStartWorkflow = async (workflow: Workflow) => {
  closeDropdown()
  await startWorkflow(workflow.id)
}

const handleCompleteWorkflow = async (workflow: Workflow) => {
  closeDropdown()
  await completeWorkflow(workflow.id)
}

const handleAdvanceWorkflow = async (workflow: Workflow) => {
  closeDropdown()
  await advanceWorkflow(workflow.id)
}

const handleCancelWorkflow = async (workflow: Workflow) => {
  closeDropdown()
  if (confirm('Are you sure you want to cancel this workflow?')) {
    await cancelWorkflow(workflow.id)
  }
}

const startWorkflow = async (workflowId: string) => {
  try {
    await api.post(`/workflows/${workflowId}/start`)
    await fetchWorkflows()
  } catch (error) {
    console.error('Error starting workflow:', error)
  }
}

const completeWorkflow = async (workflowId: string) => {
  try {
    await api.post(`/workflows/${workflowId}/complete`)
    await fetchWorkflows()
  } catch (error) {
    console.error('Error completing workflow:', error)
  }
}

const advanceWorkflow = async (workflowId: string) => {
  try {
    await api.post(`/workflows/${workflowId}/advance`)
    await fetchWorkflows()
  } catch (error) {
    console.error('Error advancing workflow:', error)
  }
}

const cancelWorkflow = async (workflowId: string) => {
  try {
    await api.post(`/workflows/${workflowId}/cancel`, { reason: 'Cancelled by user' })
    await fetchWorkflows()
  } catch (error) {
    console.error('Error cancelling workflow:', error)
  }
}

const handleWorkflowCreated = () => {
  showCreateModal.value = false
  fetchWorkflows()
}

// Helper functions
const formatType = (type: string): string => {
  return type.replace(/_/g, ' ')
}

const formatStatus = (status: string): string => {
  const statusMap: Record<string, string> = {
    pending: 'Pending',
    in_progress: 'In progress',
    completed: 'Completed',
    cancelled: 'Cancelled',
  }
  return statusMap[status] || status
}

const getStatusClass = (status: string): string => {
  const classMap: Record<string, string> = {
    pending: 'bg-amber-100 text-amber-800 border-amber-200',
    in_progress: 'bg-blue-100 text-blue-800 border-blue-200',
    completed: 'bg-teal-50 text-teal-700 border-teal-200',
    cancelled: 'bg-slate-100 text-slate-700 border-slate-300',
  }
  return classMap[status] || 'bg-slate-100 text-slate-700 border-slate-300'
}

const getTypeColorClass = (type: string): string => {
  const classMap: Record<string, string> = {
    onboarding: 'bg-blue-100 text-blue-600',
    offboarding: 'bg-orange-100 text-orange-600',
    procurement: 'bg-teal-100 text-teal-600',
    repair: 'bg-purple-100 text-purple-600',
    maintenance: 'bg-yellow-100 text-yellow-600',
  }
  return classMap[type] || 'bg-slate-100 text-slate-600'
}

const getProgressPercentage = (workflow: Workflow): number => {
  if (workflow.total_steps === 0) return 0
  return Math.round((workflow.current_step / workflow.total_steps) * 100)
}

const getDueDateClass = (workflow: Workflow): string => {
  if (!workflow.due_date) return 'text-slate-600'
  const dueDate = new Date(workflow.due_date)
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  const isOverdue = dueDate < today && workflow.status !== 'completed' && workflow.status !== 'cancelled'
  return isOverdue ? 'text-red-600 font-medium' : 'text-slate-600'
}

const formatDate = (dateString: string): string => {
  const date = new Date(dateString)
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  const diffTime = date.getTime() - today.getTime()
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))

  if (diffDays === 0) return 'Today'
  if (diffDays === 1) return 'Tomorrow'
  if (diffDays === -1) return 'Yesterday'
  if (diffDays < 0) return `${Math.abs(diffDays)} days ago`
  if (diffDays < 7) return `In ${diffDays} days`

  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}

// Dropdown management
const getDropdownPosition = (event: MouseEvent) => {
  const buttonEl = event.currentTarget as HTMLElement
  if (!buttonEl) {
    return { top: '0px', left: '0px' }
  }

  const rect = buttonEl.getBoundingClientRect()
  const dropdownWidth = 192
  const dropdownHeight = 160

  let top = rect.bottom + 8
  let left = rect.right - dropdownWidth

  if (top + dropdownHeight > window.innerHeight) {
    top = rect.top - dropdownHeight - 8
  }

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
}

const toggleDropdown = (workflowId: string, event: MouseEvent) => {
  if (openDropdownId.value === workflowId) {
    openDropdownId.value = null
  } else {
    openDropdownId.value = workflowId
    dropdownPosition.value = getDropdownPosition(event)
  }
}

const closeDropdown = () => {
  openDropdownId.value = null
}

const handleClickOutside = (event: MouseEvent) => {
  const target = event.target as HTMLElement
  if (!target.closest('[class*="relative"]') && !target.closest('[class*="fixed"]')) {
    closeDropdown()
  }
}

onMounted(() => {
  fetchWorkflows()
  document.addEventListener('click', handleClickOutside)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>
