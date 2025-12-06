<template>
  <MainLayout>
    <div>
      <!-- Page header -->
      <div class="mb-6">
        <div class="flex items-center gap-2 text-sm text-slate-500 mb-2">
          <router-link to="/settings" class="hover:text-primary-dark">Settings</router-link>
          <span>/</span>
          <span>Roles & Permissions</span>
        </div>
        <h1 class="text-3xl font-bold text-primary-dark">Roles & Permissions</h1>
        <p class="text-slate-500 mt-1">View role hierarchy and permission matrix</p>
      </div>

      <!-- Info banner -->
      <div class="alert-info mb-6">
        <div class="flex items-start gap-3">
          <svg class="w-5 h-5 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
          </svg>
          <div class="flex-1">
            <p class="font-medium">System-defined roles</p>
            <p class="text-sm mt-1 opacity-90">Roles and permissions are defined at the system level and cannot be modified. To change a user's role, edit the user in User Management.</p>
          </div>
        </div>
      </div>

      <!-- Organizational Hierarchy -->
      <div class="mb-8">
        <h2 class="text-lg font-bold text-primary-dark mb-4">Organizational Hierarchy</h2>
        <div class="bg-white border border-slate-200 rounded-lg p-6 shadow-subtle">
          <p class="text-sm text-slate-600 mb-6">
            Understanding how organizations, departments, and locations relate to each other in the system:
          </p>

          <!-- Hierarchy Diagram -->
          <div class="space-y-6">
            <!-- Level 1: Organization -->
            <div class="relative">
              <div class="flex items-start gap-4">
                <div class="flex-shrink-0 w-10 h-10 rounded-lg bg-purple-100 border-2 border-purple-300 flex items-center justify-center">
                  <span class="text-lg font-bold text-purple-700">1</span>
                </div>
                <div class="flex-1">
                  <div class="flex items-center gap-3 mb-2">
                    <div class="p-2 bg-purple-50 rounded-lg border border-purple-200">
                      <svg class="w-5 h-5 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                      </svg>
                    </div>
                    <h3 class="text-base font-bold text-primary-dark">Organization (Tenant)</h3>
                  </div>
                  <p class="text-sm text-slate-600 mb-2">
                    Top-level entity representing your company or organization. All data is isolated per organization in a multi-tenant architecture.
                  </p>
                  <div class="flex flex-wrap gap-2 text-xs">
                    <span class="px-2 py-1 bg-purple-50 text-purple-700 rounded font-medium">Primary entity</span>
                    <span class="px-2 py-1 bg-slate-100 text-slate-600 rounded">Contains: Departments, Locations, Users, Assets</span>
                  </div>
                </div>
              </div>

              <!-- Connector line -->
              <div class="absolute left-5 top-12 w-0.5 h-8 bg-slate-300"></div>
            </div>

            <!-- Level 2: Departments & Locations -->
            <div class="ml-6 space-y-4">
              <!-- Departments -->
              <div class="relative">
                <div class="flex items-start gap-4">
                  <div class="flex-shrink-0 w-10 h-10 rounded-lg bg-blue-100 border-2 border-blue-300 flex items-center justify-center">
                    <span class="text-lg font-bold text-blue-700">2</span>
                  </div>
                  <div class="flex-1">
                    <div class="flex items-center gap-3 mb-2">
                      <div class="p-2 bg-blue-50 rounded-lg border border-blue-200">
                        <svg class="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                        </svg>
                      </div>
                      <h3 class="text-base font-bold text-primary-dark">Departments</h3>
                    </div>
                    <p class="text-sm text-slate-600 mb-2">
                      Functional divisions within your organization (e.g., Engineering, Sales, HR). Employees and assets can be assigned to departments.
                    </p>
                    <div class="flex flex-wrap gap-2 text-xs">
                      <span class="px-2 py-1 bg-blue-50 text-blue-700 rounded font-medium">Organizational unit</span>
                      <span class="px-2 py-1 bg-slate-100 text-slate-600 rounded">Used for: Employees, Assets, Reporting</span>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Locations -->
              <div class="relative">
                <div class="flex items-start gap-4">
                  <div class="flex-shrink-0 w-10 h-10 rounded-lg bg-teal-100 border-2 border-teal-300 flex items-center justify-center">
                    <span class="text-lg font-bold text-teal-700">2</span>
                  </div>
                  <div class="flex-1">
                    <div class="flex items-center gap-3 mb-2">
                      <div class="p-2 bg-teal-50 rounded-lg border border-teal-200">
                        <svg class="w-5 h-5 text-teal-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                        </svg>
                      </div>
                      <h3 class="text-base font-bold text-primary-dark">Locations</h3>
                    </div>
                    <p class="text-sm text-slate-600 mb-2">
                      Physical sites or offices where assets and employees are based (e.g., HQ, Branch Office, Warehouse). Track asset distribution geographically.
                    </p>
                    <div class="flex flex-wrap gap-2 text-xs">
                      <span class="px-2 py-1 bg-teal-50 text-teal-700 rounded font-medium">Physical entity</span>
                      <span class="px-2 py-1 bg-slate-100 text-slate-600 rounded">Used for: Assets, Employees, Inventory</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Relationship Summary -->
          <div class="mt-6 pt-6 border-t border-slate-200">
            <h4 class="text-sm font-bold text-primary-dark mb-3">Key Relationships</h4>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-3 text-sm">
              <div class="flex items-start gap-2">
                <svg class="w-5 h-5 text-accent-blue flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                </svg>
                <span class="text-slate-700"><strong>Users</strong> belong to an Organization and can be assigned to Departments</span>
              </div>
              <div class="flex items-start gap-2">
                <svg class="w-5 h-5 text-accent-blue flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                </svg>
                <span class="text-slate-700"><strong>Employees</strong> belong to Organizations and can have Department & Location assignments</span>
              </div>
              <div class="flex items-start gap-2">
                <svg class="w-5 h-5 text-accent-blue flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                </svg>
                <span class="text-slate-700"><strong>Assets</strong> belong to Organizations and are tracked by Department & Location</span>
              </div>
              <div class="flex items-start gap-2">
                <svg class="w-5 h-5 text-accent-blue flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                </svg>
                <span class="text-slate-700"><strong>Roles</strong> apply across the entire Organization (tenant-scoped)</span>
              </div>
            </div>
          </div>

          <!-- Navigation to Management -->
          <div class="mt-6 pt-6 border-t border-slate-200">
            <h4 class="text-sm font-bold text-primary-dark mb-3">Manage Organizational Entities</h4>
            <div class="flex flex-wrap gap-2">
              <router-link to="/settings/organizations" class="btn-brand-secondary text-xs">
                <svg class="w-4 h-4 mr-1.5 inline-block" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                </svg>
                Organizations
              </router-link>
              <router-link to="/settings/departments" class="btn-brand-secondary text-xs">
                <svg class="w-4 h-4 mr-1.5 inline-block" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                </svg>
                Departments
              </router-link>
              <router-link to="/settings/locations" class="btn-brand-secondary text-xs">
                <svg class="w-4 h-4 mr-1.5 inline-block" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
                Locations
              </router-link>
            </div>
          </div>
        </div>
      </div>

      <!-- Role Cards -->
      <div class="mb-8">
        <h2 class="text-lg font-bold text-primary-dark mb-4">Role Hierarchy</h2>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <div
            v-for="role in roles"
            :key="role.value"
            class="bg-white border-2 border-slate-200 rounded-lg p-6 hover:border-accent-blue transition-all duration-200 cursor-pointer"
            @click="selectedRole = role"
          >
            <div class="flex items-start justify-between mb-3">
              <div
                class="px-3 py-1 rounded-2xl text-xs font-mono font-bold uppercase tracking-wider"
                :class="role.badgeClass"
              >
                {{ role.name }}
              </div>
              <div class="text-slate-500 text-xs font-mono">
                Level {{ role.level }}
              </div>
            </div>
            <p class="text-sm text-slate-700 mb-4">{{ role.description }}</p>
            <div class="flex items-center text-xs text-slate-600">
              <svg class="w-4 h-4 mr-1 text-teal-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
              </svg>
              {{ getPermissionCount(role.value) }} permissions
            </div>
          </div>
        </div>
      </div>

      <!-- Permissions Matrix -->
      <div class="mb-8">
        <h2 class="text-lg font-bold text-primary-dark mb-4">Permission Matrix</h2>

        <!-- Filter -->
        <div class="mb-4">
          <select v-model="selectedCategory" class="input-refined w-full sm:w-auto">
            <option value="all">All Permissions</option>
            <option value="users">User Management</option>
            <option value="assets">Asset Management</option>
            <option value="employees">Employee Management</option>
            <option value="workflows">Workflow Management</option>
            <option value="settings">Settings & Configuration</option>
          </select>
        </div>

        <!-- Mobile card view -->
        <div class="lg:hidden space-y-4">
          <div v-for="permission in filteredPermissions" :key="permission.action" class="bg-white border border-border-light rounded-lg p-4 shadow-subtle">
            <div class="mb-3 pb-3 border-b border-slate-200">
              <div class="font-semibold text-sm text-primary-dark">{{ permission.name }}</div>
              <div class="text-xs text-slate-500 mt-1">{{ permission.description }}</div>
            </div>
            <div class="space-y-2">
              <div v-for="role in roles" :key="role.value" class="flex items-center justify-between py-1">
                <span class="text-xs font-mono font-bold uppercase tracking-wider text-slate-600">
                  {{ role.name }}
                </span>
                <div v-if="hasPermission(role.value, permission.action)" class="flex justify-center">
                  <div class="w-6 h-6 rounded-full bg-teal-600 flex items-center justify-center">
                    <svg class="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 20 20">
                      <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                    </svg>
                  </div>
                </div>
                <div v-else class="flex justify-center">
                  <div class="w-6 h-6 rounded-full bg-slate-200 flex items-center justify-center">
                    <svg class="w-4 h-4 text-slate-400" fill="currentColor" viewBox="0 0 20 20">
                      <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
                    </svg>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Desktop table view -->
        <div class="hidden lg:block bg-white border border-border-light rounded-lg overflow-hidden shadow-subtle">
          <div class="overflow-x-auto">
            <table class="w-full">
              <thead class="bg-light-bg border-b border-slate-200">
                <tr>
                  <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider sticky left-0 bg-light-bg z-10">
                    Permission
                  </th>
                  <th
                    v-for="role in roles"
                    :key="role.value"
                    class="px-4 py-3 text-center text-xs font-bold font-mono text-primary-dark uppercase tracking-wider"
                  >
                    {{ role.name }}
                  </th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-slate-200">
                <tr v-for="permission in filteredPermissions" :key="permission.action" class="hover:bg-light-bg transition-colors">
                  <td class="px-4 py-3 sticky left-0 bg-white hover:bg-light-bg transition-colors">
                    <div class="font-medium text-sm text-primary-dark">{{ permission.name }}</div>
                    <div class="text-xs text-slate-500 mt-0.5">{{ permission.description }}</div>
                  </td>
                  <td
                    v-for="role in roles"
                    :key="`${permission.action}-${role.value}`"
                    class="px-4 py-3 text-center"
                  >
                    <div v-if="hasPermission(role.value, permission.action)" class="flex justify-center">
                      <div class="w-6 h-6 rounded-full bg-teal-600 flex items-center justify-center">
                        <svg class="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 20 20">
                          <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                        </svg>
                      </div>
                    </div>
                    <div v-else class="flex justify-center">
                      <div class="w-6 h-6 rounded-full bg-slate-200 flex items-center justify-center">
                        <svg class="w-4 h-4 text-slate-400" fill="currentColor" viewBox="0 0 20 20">
                          <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
                        </svg>
                      </div>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Role Details Modal -->
      <Modal v-model="showRoleDetails" size="lg">
        <template #title>{{ selectedRole?.name }} Role</template>
        <div v-if="selectedRole" class="space-y-6">
          <!-- Role Info -->
          <div>
            <div class="data-label mb-2">Description</div>
            <p class="data-value">{{ selectedRole.description }}</p>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <div class="data-label mb-2">Access Level</div>
              <div class="data-value">Level {{ selectedRole.level }} of 5</div>
            </div>
            <div>
              <div class="data-label mb-2">Permission Count</div>
              <div class="data-value">{{ getPermissionCount(selectedRole.value) }} permissions</div>
            </div>
          </div>

          <!-- Capabilities -->
          <div>
            <div class="data-label mb-3">Key Capabilities</div>
            <ul class="space-y-2">
              <li v-for="capability in selectedRole.capabilities" :key="capability" class="flex items-start gap-2">
                <svg class="w-5 h-5 text-teal-600 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                </svg>
                <span class="text-sm text-slate-700">{{ capability }}</span>
              </li>
            </ul>
          </div>

          <!-- Typical Use Cases -->
          <div>
            <div class="data-label mb-3">Typical Use Cases</div>
            <ul class="space-y-2">
              <li v-for="useCase in selectedRole.useCases" :key="useCase" class="flex items-start gap-2">
                <div class="w-1.5 h-1.5 rounded-full bg-teal-600 flex-shrink-0 mt-2"></div>
                <span class="text-sm text-slate-700">{{ useCase }}</span>
              </li>
            </ul>
          </div>

          <!-- Permissions List -->
          <div>
            <div class="data-label mb-3">Granted Permissions</div>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
              <div
                v-for="permission in getRolePermissions(selectedRole.value)"
                :key="permission.action"
                class="flex items-center gap-2 text-xs bg-light-bg px-3 py-2 rounded-2xl border border-slate-200"
              >
                <svg class="w-4 h-4 text-teal-600" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                </svg>
                <span class="font-mono">{{ permission.name }}</span>
              </div>
            </div>
          </div>
        </div>
      </Modal>
    </div>
  </MainLayout>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import MainLayout from '@/components/MainLayout.vue'
import Modal from '@/components/Modal.vue'

interface Role {
  value: string
  name: string
  level: number
  description: string
  badgeClass: string
  textClass: string
  capabilities: string[]
  useCases: string[]
}

interface Permission {
  action: string
  name: string
  description: string
  category: string
  roles: string[]
}

const selectedCategory = ref('all')
const selectedRole = ref<Role | null>(null)
const showRoleDetails = computed({
  get: () => selectedRole.value !== null,
  set: (value: boolean) => {
    if (!value) selectedRole.value = null
  }
})

// Role definitions
const roles: Role[] = [
  {
    value: 'super_admin',
    name: 'Super Admin',
    level: 5,
    description: 'Full system access across all tenants with ability to manage system-wide settings.',
    badgeClass: 'bg-purple-100 text-purple-800 border border-purple-200',
    textClass: 'text-purple-800',
    capabilities: [
      'Access all tenants',
      'Manage system configuration and settings',
      'Full user and asset management',
      'Configure integrations and notifications',
      'System-wide reporting and analytics',
    ],
    useCases: [
      'Platform administrators',
      'System maintenance personnel',
      'Top-level executives with cross-organization visibility',
    ],
  },
  {
    value: 'admin',
    name: 'Admin',
    level: 4,
    description: 'Full access within their tenant including user management and all asset operations.',
    badgeClass: 'bg-red-100 text-red-800 border border-red-200',
    textClass: 'text-red-800',
    capabilities: [
      'Create and manage users and roles',
      'Full asset management',
      'Manage tenant settings and configuration',
      'Configure integrations and notifications',
      'Access to all reports and analytics',
    ],
    useCases: [
      'IT Managers',
      'Operations Managers',
      'Department Heads',
    ],
  },
  {
    value: 'manager',
    name: 'Manager',
    level: 3,
    description: 'Can manage employees, assets, and workflows within their department or team.',
    badgeClass: 'bg-blue-100 text-blue-800 border border-blue-200',
    textClass: 'text-blue-800',
    capabilities: [
      'Manage assets and assignments',
      'View and manage employee data',
      'Create and manage workflows',
      'Manage personal notification preferences',
      'Generate department reports',
    ],
    useCases: [
      'Team Leads',
      'Department Supervisors',
      'Project Managers',
    ],
  },
  {
    value: 'employee',
    name: 'Employee',
    level: 2,
    description: 'Can view assigned assets and complete assigned workflows. Limited write access.',
    badgeClass: 'bg-emerald-100 text-emerald-800 border border-emerald-200',
    textClass: 'text-emerald-800',
    capabilities: [
      'View assigned assets',
      'Complete assigned workflows',
      'Update own profile and notification preferences',
      'Request asset assignments',
    ],
    useCases: [
      'Regular staff members',
      'Individual contributors',
      'Team members',
    ],
  },
  {
    value: 'viewer',
    name: 'Viewer',
    level: 1,
    description: 'Read-only access to resources. Cannot make any changes to the system.',
    badgeClass: 'bg-gray-100 text-gray-800 border border-gray-200',
    textClass: 'text-gray-800',
    capabilities: [
      'View assets',
      'View reports (limited)',
      'View employee directory',
      'No write access',
    ],
    useCases: [
      'Auditors',
      'External consultants',
      'Read-only stakeholders',
    ],
  },
]

// Permission definitions based on backend policies
const permissions: Permission[] = [
  // User Management
  { action: 'list_users', name: 'List Users', description: 'View all users in the system', category: 'users', roles: ['super_admin', 'admin', 'manager'] },
  { action: 'show_user', name: 'View User', description: 'View user profile details', category: 'users', roles: ['super_admin', 'admin', 'manager', 'employee', 'viewer'] },
  { action: 'create_user', name: 'Create User', description: 'Add new users to the system', category: 'users', roles: ['super_admin', 'admin'] },
  { action: 'update_user', name: 'Update User', description: 'Edit user profile information', category: 'users', roles: ['super_admin', 'admin'] },
  { action: 'delete_user', name: 'Delete User', description: 'Remove users from the system', category: 'users', roles: ['super_admin', 'admin'] },
  { action: 'update_role', name: 'Update Role', description: 'Change user role assignments', category: 'users', roles: ['super_admin', 'admin'] },
  { action: 'update_status', name: 'Update Status', description: 'Activate or deactivate users', category: 'users', roles: ['super_admin', 'admin'] },
  { action: 'unlock_user', name: 'Unlock Account', description: 'Unlock locked user accounts', category: 'users', roles: ['super_admin', 'admin'] },

  // Asset Management
  { action: 'list_assets', name: 'List Assets', description: 'View all assets in inventory', category: 'assets', roles: ['super_admin', 'admin', 'manager', 'employee', 'viewer'] },
  { action: 'show_asset', name: 'View Asset', description: 'View detailed asset information', category: 'assets', roles: ['super_admin', 'admin', 'manager', 'employee', 'viewer'] },
  { action: 'create_asset', name: 'Create Asset', description: 'Add new assets to inventory', category: 'assets', roles: ['super_admin', 'admin', 'manager'] },
  { action: 'update_asset', name: 'Update Asset', description: 'Edit asset details', category: 'assets', roles: ['super_admin', 'admin', 'manager'] },
  { action: 'delete_asset', name: 'Delete Asset', description: 'Remove assets from inventory', category: 'assets', roles: ['super_admin', 'admin'] },
  { action: 'assign_asset', name: 'Assign Asset', description: 'Assign assets to employees', category: 'assets', roles: ['super_admin', 'admin', 'manager'] },
  { action: 'unassign_asset', name: 'Unassign Asset', description: 'Unassign assets from employees', category: 'assets', roles: ['super_admin', 'admin', 'manager'] },
  { action: 'bulk_import', name: 'Bulk Import', description: 'Import multiple assets at once', category: 'assets', roles: ['super_admin', 'admin', 'manager'] },
  { action: 'export_assets', name: 'Export Assets', description: 'Export asset data', category: 'assets', roles: ['super_admin', 'admin', 'manager'] },

  // Employee Management
  { action: 'list_employees', name: 'List Employees', description: 'View all employees', category: 'employees', roles: ['super_admin', 'admin', 'manager', 'employee', 'viewer'] },
  { action: 'show_employee', name: 'View Employee', description: 'View employee details', category: 'employees', roles: ['super_admin', 'admin', 'manager', 'employee', 'viewer'] },
  { action: 'create_employee', name: 'Create Employee', description: 'Add new employees', category: 'employees', roles: ['super_admin', 'admin', 'manager'] },
  { action: 'update_employee', name: 'Update Employee', description: 'Edit employee information', category: 'employees', roles: ['super_admin', 'admin', 'manager'] },
  { action: 'delete_employee', name: 'Delete Employee', description: 'Remove employees', category: 'employees', roles: ['super_admin', 'admin'] },

  // Workflow Management
  { action: 'list_workflows', name: 'List Workflows', description: 'View all workflows', category: 'workflows', roles: ['super_admin', 'admin', 'manager', 'employee'] },
  { action: 'create_workflow', name: 'Create Workflow', description: 'Create new workflows', category: 'workflows', roles: ['super_admin', 'admin', 'manager'] },
  { action: 'update_workflow', name: 'Update Workflow', description: 'Modify workflow settings', category: 'workflows', roles: ['super_admin', 'admin', 'manager'] },
  { action: 'delete_workflow', name: 'Delete Workflow', description: 'Remove workflows', category: 'workflows', roles: ['super_admin', 'admin'] },
  { action: 'execute_workflow', name: 'Execute Workflow', description: 'Run and complete workflows', category: 'workflows', roles: ['super_admin', 'admin', 'manager', 'employee'] },

  // Settings & Configuration
  { action: 'view_tenant_settings', name: 'View Tenant Settings', description: 'Access general system settings (workflow defaults, security, quiet hours)', category: 'settings', roles: ['super_admin', 'admin'] },
  { action: 'update_tenant_settings', name: 'Update Tenant Settings', description: 'Modify tenant-wide system configuration', category: 'settings', roles: ['super_admin', 'admin'] },
  { action: 'view_notification_preferences', name: 'View Notification Preferences', description: 'View personal notification settings', category: 'settings', roles: ['super_admin', 'admin', 'manager', 'employee', 'viewer'] },
  { action: 'update_notification_preferences', name: 'Update Notification Preferences', description: 'Modify personal notification preferences (email, in-app, SMS, push)', category: 'settings', roles: ['super_admin', 'admin', 'manager', 'employee', 'viewer'] },
]

// Filtered permissions based on category
const filteredPermissions = computed(() => {
  if (selectedCategory.value === 'all') {
    return permissions
  }
  return permissions.filter(p => p.category === selectedCategory.value)
})

// Check if a role has a specific permission
const hasPermission = (roleValue: string, action: string): boolean => {
  const permission = permissions.find(p => p.action === action)
  return permission ? permission.roles.includes(roleValue) : false
}

// Get count of permissions for a role
const getPermissionCount = (roleValue: string): number => {
  return permissions.filter(p => p.roles.includes(roleValue)).length
}

// Get all permissions for a role
const getRolePermissions = (roleValue: string): Permission[] => {
  return permissions.filter(p => p.roles.includes(roleValue))
}
</script>
