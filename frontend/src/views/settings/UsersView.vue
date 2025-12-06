<template>
  <MainLayout>
    <div>
      <!-- Page header -->
      <div class="mb-6">
        <div class="flex items-center gap-2 text-sm text-slate-500 mb-2">
          <router-link to="/settings" class="hover:text-primary-dark">Settings</router-link>
          <span>/</span>
          <span>Users</span>
        </div>
        <h1 class="text-3xl font-bold text-primary-dark">User Management</h1>
        <p class="text-slate-500 mt-1">Manage user accounts, roles, and permissions</p>
      </div>

      <!-- Success message -->
      <div v-if="successMessage" class="alert-success mb-6">
        {{ successMessage }}
      </div>

      <!-- Error message -->
      <div v-if="errorMessage" class="alert-error mb-6">
        {{ errorMessage }}
      </div>

      <!-- Actions bar -->
      <div class="flex flex-col gap-4 mb-6">
        <!-- Search input - full width on mobile -->
        <input
          v-model="searchQuery"
          type="search"
          placeholder="Search users by email..."
          class="input-refined w-full"
        />

        <!-- Filters and button row -->
        <div class="flex flex-col sm:flex-row gap-4">
          <div class="flex gap-4 flex-1">
            <select v-model="roleFilter" class="input-refined flex-1 sm:w-auto">
              <option value="">All roles</option>
              <option value="admin">Admin</option>
              <option value="manager">Manager</option>
              <option value="employee">Employee</option>
              <option value="viewer">Viewer</option>
            </select>
            <select v-model="statusFilter" class="input-refined flex-1 sm:w-auto">
              <option value="">All statuses</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
              <option value="locked">Locked</option>
            </select>
          </div>
          <button @click="showAddModal = true" class="px-6 py-3 btn-brand-primary whitespace-nowrap">
            <svg class="w-5 h-5 mr-2 inline-block" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Add User
          </button>
        </div>
      </div>

      <!-- Mobile card view -->
      <div class="lg:hidden space-y-4">
        <div v-if="isLoading" class="bg-white border border-border-light rounded-lg p-6 text-center text-slate-500">
          Loading users...
        </div>
        <div v-else-if="filteredUsers.length === 0" class="bg-white border border-border-light rounded-lg p-6 text-center text-slate-500">
          {{ searchQuery || roleFilter || statusFilter ? 'No users found matching your filters.' : 'No users found. Click "Add User" to get started.' }}
        </div>
        <div v-else v-for="user in filteredUsers" :key="user.id" class="bg-white border border-border-light rounded-lg p-4 shadow-subtle">
          <div class="flex items-start justify-between mb-3">
            <div class="flex items-center gap-3">
              <div class="flex-shrink-0 h-12 w-12">
                <div v-if="getUserAvatar(user)" class="h-12 w-12 rounded-full overflow-hidden border-2 border-slate-200">
                  <img :src="getUserAvatar(user)" :alt="user.first_name" class="h-full w-full object-cover" />
                </div>
                <div v-else class="h-12 w-12 rounded-full bg-accent-blue/10 border-2 border-accent-blue flex items-center justify-center">
                  <span class="text-sm font-bold text-primary-dark">
                    {{ user.first_name[0] }}{{ user.last_name[0] }}
                  </span>
                </div>
              </div>
              <div>
                <div class="text-sm font-bold text-primary-dark">
                  {{ user.first_name }} {{ user.last_name }}
                </div>
                <div class="text-xs text-slate-500 font-mono">{{ user.email }}</div>
              </div>
            </div>
            <div class="relative inline-block text-left">
              <button
                @click.stop="toggleDropdown(user.id)"
                class="text-slate-500 hover:text-primary-dark p-1 rounded transition-colors"
                type="button"
              >
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM18 10a2 2 0 11-4 0 2 2 0 014 0z" />
                </svg>
              </button>
              <div
                v-if="activeDropdown === user.id"
                @click.stop
                class="absolute right-0 w-48 rounded-2xl shadow-subtle bg-white border border-slate-200 z-10 origin-top-right top-full mt-2"
              >
                <div class="py-1">
                  <button
                    @click="handleEditUser(user)"
                    class="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-light-bg hover:text-primary-dark flex items-center gap-2 transition-colors"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                    </svg>
                    Edit
                  </button>
                  <button
                    v-if="user.locked"
                    @click="handleUnlockUser(user)"
                    class="w-full text-left px-4 py-2 text-sm text-teal-600 hover:bg-teal-50 flex items-center gap-2 transition-colors"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 11V7a4 4 0 118 0m-4 8v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2z" />
                    </svg>
                    Unlock Account
                  </button>
                  <button
                    @click="handleDeleteUser(user)"
                    class="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50 flex items-center gap-2 transition-colors"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                    </svg>
                    Delete
                  </button>
                </div>
              </div>
            </div>
          </div>
          <div class="space-y-2">
            <div class="flex items-center justify-between">
              <span class="text-xs font-mono font-bold text-slate-500 uppercase">Role</span>
              <span
                class="px-2 py-1 text-xs font-mono font-bold rounded border"
                :class="getRoleClass(user.role)"
              >
                {{ formatRole(user.role) }}
              </span>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-xs font-mono font-bold text-slate-500 uppercase">Status</span>
              <div class="flex items-center gap-2">
                <span
                  class="px-2 py-1 text-xs font-mono font-bold rounded border"
                  :class="getStatusClass(user.status, user.locked)"
                >
                  {{ formatStatus(user.status, user.locked) }}
                </span>
                <span v-if="user.email_verified" class="text-teal-600" title="Email verified">
                  <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M6.267 3.455a3.066 3.066 0 001.745-.723 3.066 3.066 0 013.976 0 3.066 3.066 0 001.745.723 3.066 3.066 0 012.812 2.812c.051.643.304 1.254.723 1.745a3.066 3.066 0 010 3.976 3.066 3.066 0 00-.723 1.745 3.066 3.066 0 01-2.812 2.812 3.066 3.066 0 00-1.745.723 3.066 3.066 0 01-3.976 0 3.066 3.066 0 00-1.745-.723 3.066 3.066 0 01-2.812-2.812 3.066 3.066 0 00-.723-1.745 3.066 3.066 0 010-3.976 3.066 3.066 0 00.723-1.745 3.066 3.066 0 012.812-2.812zm7.44 5.252a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                  </svg>
                </span>
              </div>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-xs font-mono font-bold text-slate-500 uppercase">Last Login</span>
              <span class="text-xs text-slate-700">{{ formatLastLogin(user.last_login_at) }}</span>
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
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  User
                </th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Role
                </th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Status
                </th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Last Login
                </th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-slate-200">
              <tr v-if="isLoading">
                <td colspan="5" class="px-4 py-6 text-center text-slate-500">
                  Loading users...
                </td>
              </tr>
              <tr v-else-if="filteredUsers.length === 0">
                <td colspan="5" class="px-4 py-6 text-center text-slate-500">
                  {{ searchQuery || roleFilter || statusFilter ? 'No users found matching your filters.' : 'No users found. Click "Add User" to get started.' }}
                </td>
              </tr>
              <tr v-else v-for="user in filteredUsers" :key="user.id" class="hover:bg-light-bg transition-colors">
                <td class="px-4 py-3 whitespace-nowrap">
                  <div class="flex items-center">
                    <div class="flex-shrink-0 h-10 w-10">
                      <div v-if="getUserAvatar(user)" class="h-10 w-10 rounded-full overflow-hidden border-2 border-slate-200">
                        <img :src="getUserAvatar(user)" :alt="user.first_name" class="h-full w-full object-cover" />
                      </div>
                      <div v-else class="h-10 w-10 rounded-full bg-accent-blue/10 border-2 border-accent-blue flex items-center justify-center">
                        <span class="text-sm font-bold text-primary-dark">
                          {{ user.first_name[0] }}{{ user.last_name[0] }}
                        </span>
                      </div>
                    </div>
                    <div class="ml-4">
                      <div class="text-sm font-bold text-primary-dark">
                        {{ user.first_name }} {{ user.last_name }}
                      </div>
                      <div class="text-sm text-slate-500 font-mono">{{ user.email }}</div>
                    </div>
                  </div>
                </td>
                <td class="px-4 py-3 whitespace-nowrap">
                  <span
                    class="px-2 py-1 text-xs font-mono font-bold rounded border"
                    :class="getRoleClass(user.role)"
                  >
                    {{ formatRole(user.role) }}
                  </span>
                </td>
                <td class="px-4 py-3 whitespace-nowrap">
                  <div class="flex items-center gap-2">
                    <span
                      class="px-2 py-1 text-xs font-mono font-bold rounded border"
                      :class="getStatusClass(user.status, user.locked)"
                    >
                      {{ formatStatus(user.status, user.locked) }}
                    </span>
                    <span v-if="user.email_verified" class="text-teal-600" title="Email verified">
                      <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M6.267 3.455a3.066 3.066 0 001.745-.723 3.066 3.066 0 013.976 0 3.066 3.066 0 001.745.723 3.066 3.066 0 012.812 2.812c.051.643.304 1.254.723 1.745a3.066 3.066 0 010 3.976 3.066 3.066 0 00-.723 1.745 3.066 3.066 0 01-2.812 2.812 3.066 3.066 0 00-1.745.723 3.066 3.066 0 01-3.976 0 3.066 3.066 0 00-1.745-.723 3.066 3.066 0 01-2.812-2.812 3.066 3.066 0 00-.723-1.745 3.066 3.066 0 010-3.976 3.066 3.066 0 00.723-1.745 3.066 3.066 0 012.812-2.812zm7.44 5.252a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                      </svg>
                    </span>
                  </div>
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-slate-700">
                  {{ formatLastLogin(user.last_login_at) }}
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm">
                  <div class="relative inline-block text-left">
                    <button
                      @click.stop="toggleDropdown(user.id)"
                      class="text-slate-500 hover:text-primary-dark p-1 rounded transition-colors"
                      type="button"
                    >
                      <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                        <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM18 10a2 2 0 11-4 0 2 2 0 014 0z" />
                      </svg>
                    </button>
                    <div
                      v-if="activeDropdown === user.id"
                      @click.stop
                      class="absolute right-0 w-48 rounded-2xl shadow-subtle bg-white border border-slate-200 z-10 origin-top-right top-full mt-2"
                    >
                      <div class="py-1">
                        <button
                          @click="handleEditUser(user)"
                          class="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-light-bg hover:text-primary-dark flex items-center gap-2 transition-colors"
                        >
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                          </svg>
                          Edit
                        </button>
                        <button
                          v-if="user.locked"
                          @click="handleUnlockUser(user)"
                          class="w-full text-left px-4 py-2 text-sm text-teal-600 hover:bg-teal-50 flex items-center gap-2 transition-colors"
                        >
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 11V7a4 4 0 118 0m-4 8v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2z" />
                          </svg>
                          Unlock Account
                        </button>
                        <button
                          @click="handleDeleteUser(user)"
                          class="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50 flex items-center gap-2 transition-colors"
                        >
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                          </svg>
                          Delete
                        </button>
                      </div>
                    </div>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Add User Modal -->
    <Modal v-model="showAddModal">
      <template #title>Add New User</template>
      <form @submit.prevent="handleCreateUser" class="space-y-4">
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="form-label">First Name</label>
            <input
              v-model="newUser.first_name"
              type="text"
              required
              class="input-refined"
              placeholder="John"
            />
          </div>
          <div>
            <label class="form-label">Last Name</label>
            <input
              v-model="newUser.last_name"
              type="text"
              required
              class="input-refined"
              placeholder="Doe"
            />
          </div>
        </div>

        <div>
          <label class="form-label">Email</label>
          <input
            v-model="newUser.email"
            type="email"
            required
            class="input-refined"
            placeholder="john.doe@company.com"
          />
        </div>

        <div>
          <label class="form-label">Password</label>
          <input
            v-model="newUser.password"
            type="password"
            required
            class="input-refined"
            placeholder="••••••••"
            minlength="8"
          />
          <p class="helper-text">Must be at least 8 characters with uppercase, lowercase, and a number</p>
        </div>

        <div>
          <label class="form-label">Role</label>
          <select v-model="newUser.role" class="input-refined">
            <option value="employee">Employee</option>
            <option value="manager">Manager</option>
            <option value="admin">Admin</option>
            <option value="viewer">Viewer</option>
          </select>
        </div>

        <div>
          <EmployeeAutocomplete
            v-model="newUser.employee_id"
            :employees="employees"
            label="Link to employee (optional)"
            placeholder="Search employees..."
            :show-special-options="false"
          />
          <p class="helper-text">Link this user account to an existing employee record</p>
        </div>

        <div>
          <label class="form-label">Phone (optional)</label>
          <input
            v-model="newUser.phone"
            type="tel"
            class="input-refined"
            placeholder="+1234567890"
          />
        </div>

        <div class="flex justify-end gap-3 pt-4">
          <button type="button" @click="closeAddModal" class="btn-brand-secondary">
            Cancel
          </button>
          <button type="submit" :disabled="isCreating" class="btn-brand-primary">
            {{ isCreating ? 'Creating...' : 'Create User' }}
          </button>
        </div>
      </form>
    </Modal>

    <!-- Confirm Dialog -->
    <ConfirmDialog
      ref="confirmDialog"
      :title="confirmDialogData.title"
      :message="confirmDialogData.message"
      confirm-text="Delete"
      cancel-text="Cancel"
      @confirm="confirmDelete"
      @cancel="cancelDelete"
    />

    <!-- Edit User Modal -->
    <Modal v-model="showEditModal">
      <template #title>Edit User</template>
      <form v-if="editingUser" @submit.prevent="handleUpdateUser" class="space-y-4">
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="form-label">First Name</label>
            <input
              v-model="editingUser.first_name"
              type="text"
              required
              class="input-refined"
            />
          </div>
          <div>
            <label class="form-label">Last Name</label>
            <input
              v-model="editingUser.last_name"
              type="text"
              required
              class="input-refined"
            />
          </div>
        </div>

        <div>
          <label class="form-label">Email</label>
          <input
            v-model="editingUser.email"
            type="email"
            disabled
            class="input-refined opacity-60 cursor-not-allowed"
          />
          <p class="helper-text">Email cannot be changed</p>
        </div>

        <div>
          <label class="form-label">Role</label>
          <select v-model="editingUser.role" class="input-refined">
            <option value="viewer">Viewer</option>
            <option value="employee">Employee</option>
            <option value="manager">Manager</option>
            <option value="admin">Admin</option>
            <option value="super_admin">Super Admin</option>
          </select>
        </div>

        <div>
          <label class="form-label">Status</label>
          <select v-model="editingUser.status" class="input-refined">
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
          </select>
        </div>

        <div>
          <label class="form-label">Phone</label>
          <input
            v-model="editingUser.phone"
            type="tel"
            class="input-refined"
            placeholder="+1234567890"
          />
        </div>

        <div class="flex justify-end gap-3 pt-4">
          <button type="button" @click="closeEditModal" class="btn-brand-secondary">
            Cancel
          </button>
          <button type="submit" :disabled="isUpdating" class="btn-brand-primary">
            {{ isUpdating ? 'Saving...' : 'Save Changes' }}
          </button>
        </div>
      </form>
    </Modal>
  </MainLayout>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, onBeforeUnmount, computed } from 'vue'
import MainLayout from '@/components/MainLayout.vue'
import Modal from '@/components/Modal.vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import EmployeeAutocomplete from '@/components/EmployeeAutocomplete.vue'
import { usersService, type User, type CreateUserData } from '@/services/users'
import { employeesService, type Employee } from '@/services/employees'

const searchQuery = ref('')
const roleFilter = ref('')
const statusFilter = ref('')
const successMessage = ref('')
const errorMessage = ref('')
const isLoading = ref(false)
const isCreating = ref(false)
const isUpdating = ref(false)
const users = ref<User[]>([])
const employees = ref<Employee[]>([])
const showAddModal = ref(false)
const showEditModal = ref(false)
const editingUser = ref<User | null>(null)
const activeDropdown = ref<string | null>(null)
const confirmDialog = ref<InstanceType<typeof ConfirmDialog>>()
const userToDelete = ref<User | null>(null)

const confirmDialogData = reactive({
  title: '',
  message: '',
})

const newUser = ref<CreateUserData>({
  email: '',
  password: '',
  first_name: '',
  last_name: '',
  role: 'employee',
  phone: '',
  employee_id: '',
})

// Load users from API
const loadUsers = async () => {
  isLoading.value = true
  errorMessage.value = ''
  try {
    users.value = await usersService.getAll()
  } catch (error: any) {
    console.error('Failed to load users:', error)
    errorMessage.value = error.response?.data?.error?.message || 'Failed to load users. Please try again.'
  } finally {
    isLoading.value = false
  }
}

// Load employees from API
const loadEmployees = async () => {
  try {
    employees.value = await employeesService.getAll()
  } catch (error: any) {
    console.error('Failed to load employees:', error)
  }
}

// Filtered users based on search and filters
const filteredUsers = computed(() => {
  return users.value.filter((user) => {
    const matchesSearch = !searchQuery.value ||
      user.email.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      user.first_name.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      user.last_name.toLowerCase().includes(searchQuery.value.toLowerCase())

    const matchesRole = !roleFilter.value || user.role === roleFilter.value
    const matchesStatus = !statusFilter.value ||
      (statusFilter.value === 'locked' ? user.locked : user.status === statusFilter.value)

    return matchesSearch && matchesRole && matchesStatus
  })
})

// Create user
const handleCreateUser = async () => {
  isCreating.value = true
  errorMessage.value = ''
  try {
    await usersService.create(newUser.value)
    await loadUsers()
    closeAddModal()
    successMessage.value = 'User created successfully!'
    setTimeout(() => {
      successMessage.value = ''
    }, 5000)
  } catch (error: any) {
    console.error('Failed to create user:', error)
    errorMessage.value = error.response?.data?.error?.message || 'Failed to create user. Please try again.'
  } finally {
    isCreating.value = false
  }
}

// Toggle dropdown
const toggleDropdown = (userId: string) => {
  activeDropdown.value = activeDropdown.value === userId ? null : userId
}

// Close dropdown when clicking outside
const handleClickOutside = () => {
  activeDropdown.value = null
}

// Edit user
const handleEditUser = (user: User) => {
  activeDropdown.value = null
  editingUser.value = { ...user }
  showEditModal.value = true
}

// Update user
const handleUpdateUser = async () => {
  if (!editingUser.value) return

  isUpdating.value = true
  errorMessage.value = ''
  try {
    // Update basic profile
    await usersService.update(editingUser.value.id, {
      first_name: editingUser.value.first_name,
      last_name: editingUser.value.last_name,
      phone: editingUser.value.phone,
    })

    // Update role if changed
    const originalUser = users.value.find(u => u.id === editingUser.value!.id)
    if (originalUser && originalUser.role !== editingUser.value.role) {
      await usersService.updateRole(editingUser.value.id, editingUser.value.role)
    }

    // Update status if changed
    if (originalUser && originalUser.status !== editingUser.value.status) {
      await usersService.updateStatus(editingUser.value.id, editingUser.value.status)
    }

    await loadUsers()
    closeEditModal()
    successMessage.value = 'User updated successfully!'
    setTimeout(() => {
      successMessage.value = ''
    }, 5000)
  } catch (error: any) {
    console.error('Failed to update user:', error)
    errorMessage.value = error.response?.data?.error?.message || 'Failed to update user. Please try again.'
  } finally {
    isUpdating.value = false
  }
}

// Delete user
const handleDeleteUser = (user: User) => {
  activeDropdown.value = null
  userToDelete.value = user
  confirmDialogData.title = 'Delete User'
  confirmDialogData.message = `Are you sure you want to delete "${user.first_name} ${user.last_name}"? This action cannot be undone.`
  confirmDialog.value?.open()
}

const confirmDelete = async () => {
  if (!userToDelete.value) return

  errorMessage.value = ''
  try {
    await usersService.delete(userToDelete.value.id)
    successMessage.value = `User "${userToDelete.value.first_name} ${userToDelete.value.last_name}" has been deleted successfully.`
    await loadUsers()

    setTimeout(() => {
      successMessage.value = ''
    }, 5000)

    confirmDialog.value?.close()
    userToDelete.value = null
  } catch (error: any) {
    console.error('Failed to delete user:', error)
    confirmDialog.value?.close()
    errorMessage.value = error.response?.data?.error?.message || 'Failed to delete user. Please try again.'
  }
}

const cancelDelete = () => {
  userToDelete.value = null
}

// Unlock user
const handleUnlockUser = async (user: User) => {
  activeDropdown.value = null
  errorMessage.value = ''
  try {
    await usersService.unlock(user.id)
    await loadUsers()
    successMessage.value = `User "${user.first_name} ${user.last_name}" has been unlocked.`
    setTimeout(() => {
      successMessage.value = ''
    }, 5000)
  } catch (error: any) {
    console.error('Failed to unlock user:', error)
    errorMessage.value = error.response?.data?.error?.message || 'Failed to unlock user. Please try again.'
  }
}

// Close modals
const closeAddModal = () => {
  showAddModal.value = false
  newUser.value = {
    email: '',
    password: '',
    first_name: '',
    last_name: '',
    role: 'employee',
    phone: '',
    employee_id: '',
  }
}

const closeEditModal = () => {
  showEditModal.value = false
  editingUser.value = null
}

// Format helpers
const formatRole = (role: string): string => {
  const roleMap: Record<string, string> = {
    super_admin: 'Super Admin',
    admin: 'Admin',
    manager: 'Manager',
    employee: 'Employee',
    viewer: 'Viewer',
  }
  return roleMap[role] || role
}

const formatStatus = (status: string, locked: boolean): string => {
  if (locked) return 'Locked'
  const statusMap: Record<string, string> = {
    active: 'Active',
    inactive: 'Inactive',
  }
  return statusMap[status] || status
}

const formatLastLogin = (lastLogin?: string): string => {
  if (!lastLogin) return 'Never'
  const date = new Date(lastLogin)
  const now = new Date()
  const diff = now.getTime() - date.getTime()
  const days = Math.floor(diff / (1000 * 60 * 60 * 24))

  if (days === 0) return 'Today'
  if (days === 1) return 'Yesterday'
  if (days < 7) return `${days} days ago`
  if (days < 30) return `${Math.floor(days / 7)} weeks ago`
  return date.toLocaleDateString()
}

const getRoleClass = (role: string): string => {
  const classMap: Record<string, string> = {
    super_admin: 'bg-purple-100 text-purple-800 border-purple-200',
    admin: 'bg-red-100 text-red-800 border-red-200',
    manager: 'bg-blue-100 text-blue-800 border-blue-200',
    employee: 'bg-emerald-100 text-emerald-800 border-emerald-200',
    viewer: 'bg-gray-100 text-gray-800 border-gray-200',
  }
  return classMap[role] || 'bg-gray-100 text-gray-800 border-gray-200'
}

const getStatusClass = (status: string, locked: boolean): string => {
  if (locked) return 'bg-red-100 text-red-800 border-red-200'
  const classMap: Record<string, string> = {
    active: 'bg-emerald-100 text-emerald-800 border-emerald-200',
    inactive: 'bg-gray-100 text-gray-800 border-gray-200',
  }
  return classMap[status] || 'bg-gray-100 text-gray-800 border-gray-200'
}

// Get user avatar, preferring employee avatar over user avatar
const getUserAvatar = (user: User): string | undefined => {
  // First try to get avatar from linked employee
  if (user.employee?.avatar_url) {
    return user.employee.avatar_url
  }
  // Fall back to user's own avatar
  return user.avatar_url
}

onMounted(() => {
  loadUsers()
  loadEmployees()
  document.addEventListener('click', handleClickOutside)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>
