<template>
  <MainLayout>
    <div>
      <!-- Page header -->
      <div class="mb-6">
        <h1 class="text-3xl font-bold text-primary-dark">Transactions</h1>
        <p class="text-slate-500 mt-1">View asset assignment and transfer history</p>
      </div>

      <!-- Filters bar -->
      <div class="flex flex-col sm:flex-row gap-4 mb-6">
        <div class="flex-1">
          <input
            v-model="searchQuery"
            type="search"
            placeholder="Search transactions..."
            class="input-refined w-full"
          />
        </div>
        <select v-model="selectedType" class="input-refined w-full sm:w-auto" @change="loadTransactions">
          <option value="">All types</option>
          <option value="assignment">Assignment</option>
          <option value="return">Return</option>
          <option value="transfer">Transfer</option>
          <option value="maintenance">Maintenance</option>
          <option value="status_change">Status Change</option>
          <option value="repair_start">Repair Start</option>
          <option value="repair_complete">Repair Complete</option>
        </select>
      </div>

      <!-- Loading State -->
      <div v-if="isLoading" class="bg-white border border-border-light rounded-lg p-12 text-center shadow-subtle">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-accent-blue mx-auto mb-4"></div>
        <p class="text-slate-500">Loading transactions...</p>
      </div>

      <!-- Transactions table -->
      <div v-else class="bg-white border border-border-light rounded-lg shadow-subtle">
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-light-bg border-b border-slate-200">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Date
                </th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Type
                </th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Asset
                </th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Employee
                </th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Status
                </th>
                <th class="px-4 py-3 text-left text-xs font-bold font-mono text-primary-dark uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody v-if="filteredTransactions.length > 0" class="bg-white divide-y divide-slate-200">
              <tr v-for="transaction in filteredTransactions" :key="transaction.id" class="hover:bg-light-bg transition-colors">
                <td class="px-4 py-3 whitespace-nowrap text-sm text-primary-dark">
                  {{ formatDate(transaction.performed_at) }}
                </td>
                <td class="px-4 py-3 whitespace-nowrap">
                  <span
                    class="px-2 py-1 text-xs font-medium rounded-full"
                    :class="getTypeClass(transaction.transaction_type)"
                  >
                    {{ formatType(transaction.transaction_type) }}
                  </span>
                </td>
                <td class="px-4 py-3 whitespace-nowrap">
                  <div v-if="transaction.asset" class="text-sm">
                    <div class="font-medium text-primary-dark">{{ transaction.asset.name }}</div>
                    <div class="text-slate-600">{{ transaction.asset.asset_tag || transaction.asset.serial_number }}</div>
                  </div>
                  <div v-else class="text-sm text-slate-500">N/A</div>
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-primary-dark">
                  <span v-if="transaction.to_employee">
                    {{ transaction.to_employee.first_name }} {{ transaction.to_employee.last_name }}
                  </span>
                  <span v-else-if="transaction.from_employee">
                    {{ transaction.from_employee.first_name }} {{ transaction.from_employee.last_name }}
                  </span>
                  <span v-else-if="transaction.employee">
                    {{ transaction.employee.first_name }} {{ transaction.employee.last_name }}
                  </span>
                  <span v-else class="text-slate-500">N/A</span>
                </td>
                <td class="px-4 py-3 whitespace-nowrap">
                  <span
                    class="px-2 py-1 text-xs font-medium rounded-full"
                    :class="getStatusClass(transaction.to_status)"
                  >
                    {{ transaction.to_status ? formatStatus(transaction.to_status) : 'Completed' }}
                  </span>
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm">
                  <div class="relative inline-block text-left">
                    <button
                      @click="toggleDropdown(transaction.id, $event)"
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
                        v-if="openDropdownId === transaction.id"
                        :style="dropdownPosition"
                        class="fixed z-[9999] w-48 rounded-lg bg-white shadow-xl ring-1 ring-black ring-opacity-5 focus:outline-none"
                        @click.stop
                      >
                        <div class="py-1">
                          <button
                            @click="viewTransaction(transaction)"
                            class="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 flex items-center gap-2"
                          >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                            </svg>
                            View details
                          </button>
                        </div>
                      </div>
                    </Teleport>
                  </div>
                </td>
              </tr>
            </tbody>
            <tbody v-else>
              <tr>
                <td colspan="6" class="px-4 py-6 text-center text-slate-500">
                  {{ searchQuery ? 'No transactions found matching your search.' : 'No transactions found. Transactions will appear here when assets are assigned or transferred.' }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Transaction Detail Modal -->
      <div v-if="selectedTransaction" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4" @click.self="selectedTransaction = null">
        <div class="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
          <div class="p-6">
            <div class="flex justify-between items-start mb-4">
              <h2 class="text-2xl font-bold text-primary-dark">Transaction Details</h2>
              <button @click="selectedTransaction = null" class="text-slate-400 hover:text-slate-600">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <div class="space-y-4">
              <div>
                <label class="text-xs font-bold text-slate-500 uppercase tracking-wider">Type</label>
                <p class="text-slate-900">{{ formatType(selectedTransaction.transaction_type) }}</p>
              </div>

              <div v-if="selectedTransaction.asset">
                <label class="text-xs font-bold text-slate-500 uppercase tracking-wider">Asset</label>
                <p class="text-slate-900">{{ selectedTransaction.asset.name }}</p>
                <p class="text-slate-600 text-sm">{{ selectedTransaction.asset.asset_tag }}</p>
              </div>

              <div v-if="selectedTransaction.to_employee">
                <label class="text-xs font-bold text-slate-500 uppercase tracking-wider">To Employee</label>
                <p class="text-slate-900">{{ selectedTransaction.to_employee.first_name }} {{ selectedTransaction.to_employee.last_name }}</p>
                <p class="text-slate-600 text-sm">{{ selectedTransaction.to_employee.email }}</p>
              </div>

              <div v-if="selectedTransaction.from_employee">
                <label class="text-xs font-bold text-slate-500 uppercase tracking-wider">From Employee</label>
                <p class="text-slate-900">{{ selectedTransaction.from_employee.first_name }} {{ selectedTransaction.from_employee.last_name }}</p>
                <p class="text-slate-600 text-sm">{{ selectedTransaction.from_employee.email }}</p>
              </div>

              <div v-if="selectedTransaction.description">
                <label class="text-xs font-bold text-slate-500 uppercase tracking-wider">Description</label>
                <p class="text-slate-900">{{ selectedTransaction.description }}</p>
              </div>

              <div v-if="selectedTransaction.notes">
                <label class="text-xs font-bold text-slate-500 uppercase tracking-wider">Notes</label>
                <p class="text-slate-900">{{ selectedTransaction.notes }}</p>
              </div>

              <div v-if="selectedTransaction.performed_by">
                <label class="text-xs font-bold text-slate-500 uppercase tracking-wider">Performed By</label>
                <p class="text-slate-900">{{ selectedTransaction.performed_by }}</p>
              </div>

              <div>
                <label class="text-xs font-bold text-slate-500 uppercase tracking-wider">Date</label>
                <p class="text-slate-900">{{ formatDateTime(selectedTransaction.performed_at) }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </MainLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount, Teleport } from 'vue'
import MainLayout from '@/components/MainLayout.vue'
import { transactionsService, type Transaction } from '@/services/transactions'

const transactions = ref<Transaction[]>([])
const isLoading = ref(true)
const searchQuery = ref('')
const selectedType = ref('')
const selectedTransaction = ref<Transaction | null>(null)
const openDropdownId = ref<string | null>(null)
const dropdownPosition = ref({ top: '0px', left: '0px' })

const filteredTransactions = computed(() => {
  let filtered = transactions.value

  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(t =>
      t.asset?.name?.toLowerCase().includes(query) ||
      t.asset?.asset_tag?.toLowerCase().includes(query) ||
      t.to_employee?.first_name?.toLowerCase().includes(query) ||
      t.to_employee?.last_name?.toLowerCase().includes(query) ||
      t.to_employee?.email?.toLowerCase().includes(query) ||
      t.from_employee?.first_name?.toLowerCase().includes(query) ||
      t.from_employee?.last_name?.toLowerCase().includes(query) ||
      t.description?.toLowerCase().includes(query)
    )
  }

  return filtered
})

const loadTransactions = async () => {
  isLoading.value = true
  try {
    const params = selectedType.value ? { transaction_type: selectedType.value } : undefined
    transactions.value = await transactionsService.getAll(params)
  } catch (error) {
    console.error('Failed to load transactions:', error)
  } finally {
    isLoading.value = false
  }
}

const formatDate = (dateString: string) => {
  if (!dateString) return 'N/A'
  return new Date(dateString).toLocaleDateString()
}

const formatDateTime = (dateString: string) => {
  if (!dateString) return 'N/A'
  return new Date(dateString).toLocaleString()
}

const formatType = (type: string) => {
  return type.split('_').map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(' ')
}

const formatStatus = (status: string) => {
  return status.split('_').map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(' ')
}

const getTypeClass = (type: string) => {
  const typeMap: Record<string, string> = {
    assignment: 'bg-blue-100 text-blue-800',
    return: 'bg-teal-100 text-teal-800',
    transfer: 'bg-purple-100 text-purple-800',
    maintenance: 'bg-orange-100 text-orange-800',
    status_change: 'bg-amber-100 text-amber-800',
    repair_start: 'bg-red-100 text-red-800',
    repair_complete: 'bg-green-100 text-green-800'
  }
  return typeMap[type] || 'bg-slate-100 text-slate-800'
}

const getStatusClass = (status?: string) => {
  if (!status) return 'bg-teal-50 text-teal-700 border border-teal-200'

  const statusMap: Record<string, string> = {
    assigned: 'bg-blue-50 text-blue-700 border border-blue-200',
    in_stock: 'bg-teal-50 text-teal-700 border border-teal-200',
    maintenance: 'bg-orange-50 text-orange-700 border border-orange-200',
    retired: 'bg-slate-50 text-slate-700 border border-slate-200'
  }
  return statusMap[status] || 'bg-teal-50 text-teal-700 border border-teal-200'
}

const viewTransaction = (transaction: Transaction) => {
  closeDropdown()
  selectedTransaction.value = transaction
}

// Dropdown management
const getDropdownPosition = (event: MouseEvent) => {
  const buttonEl = event.currentTarget as HTMLElement
  if (!buttonEl) {
    return { top: '0px', left: '0px' }
  }

  const rect = buttonEl.getBoundingClientRect()
  const dropdownWidth = 192 // w-48 = 12rem = 192px
  const dropdownHeight = 120 // Approximate height

  // Calculate position: below button, aligned to the right
  let top = rect.bottom + 8 // 8px gap below button
  let left = rect.right - dropdownWidth

  // If dropdown would go off bottom of screen, show above button
  if (top + dropdownHeight > window.innerHeight) {
    top = rect.top - dropdownHeight - 8
  }

  // Ensure dropdown doesn't go off-screen horizontally
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

const toggleDropdown = (transactionId: string, event: MouseEvent) => {
  if (openDropdownId.value === transactionId) {
    openDropdownId.value = null
  } else {
    openDropdownId.value = transactionId
    // Calculate position based on the clicked button
    dropdownPosition.value = getDropdownPosition(event)
  }
}

const closeDropdown = () => {
  openDropdownId.value = null
}

// Close dropdown when clicking outside
const handleClickOutside = (event: MouseEvent) => {
  const target = event.target as HTMLElement
  if (!target.closest('[class*="relative"]') && !target.closest('[class*="fixed"]')) {
    closeDropdown()
  }
}

onMounted(() => {
  loadTransactions()
  document.addEventListener('click', handleClickOutside)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>
