<template>
  <div class="relative">
    <button
      @click="dropdownOpen = !dropdownOpen"
      class="flex items-center space-x-3 w-full px-3 py-2 rounded-2xl hover:bg-white transition-colors touch-target"
    >
      <!-- User initials avatar -->
      <div
        class="flex items-center justify-center w-10 h-10 rounded-full bg-primary-dark text-accent-blue font-bold text-sm shadow-md"
      >
        {{ userInitials }}
      </div>

      <!-- User info (hidden on mobile in sidebar) -->
      <div class="flex-1 text-left hidden lg:block">
        <p class="text-sm font-medium text-primary-dark truncate">{{ authStore.userName }}</p>
        <p class="text-xs text-slate-600 truncate">{{ authStore.user?.email }}</p>
      </div>

      <!-- Dropdown icon -->
      <svg
        class="w-4 h-4 text-slate-600 transition-transform hidden lg:block"
        :class="{ 'rotate-180': dropdownOpen }"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
      </svg>
    </button>

    <!-- Dropdown menu -->
    <transition
      enter-active-class="transition ease-out duration-100"
      enter-from-class="transform opacity-0 scale-95"
      enter-to-class="transform opacity-100 scale-100"
      leave-active-class="transition ease-in duration-75"
      leave-from-class="transform opacity-100 scale-100"
      leave-to-class="transform opacity-0 scale-95"
    >
      <div
        v-if="dropdownOpen"
        class="absolute bottom-full left-0 mb-2 w-full bg-white rounded-2xl shadow-subtle border border-slate-200 py-1 z-50"
      >
        <router-link
          to="/settings"
          @click="dropdownOpen = false"
          class="flex items-center px-4 py-2.5 text-sm text-slate-600 hover:bg-slate-50 hover:text-primary-dark transition-colors touch-target rounded-2xl"
        >
          <svg class="w-4 h-4 mr-3 text-text-light" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
            />
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
            />
          </svg>
          Settings
        </router-link>

        <button
          @click="handleLogout"
          class="flex items-center w-full px-4 py-2.5 text-sm text-red-700 hover:bg-red-50 transition-colors touch-target"
        >
          <svg class="w-4 h-4 mr-3 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"
            />
          </svg>
          Sign out
        </button>
      </div>
    </transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()
const dropdownOpen = ref(false)

// Compute user initials
const userInitials = computed(() => {
  if (!authStore.user) return '??'
  const firstInitial = authStore.user.first_name?.charAt(0).toUpperCase() || ''
  const lastInitial = authStore.user.last_name?.charAt(0).toUpperCase() || ''
  return `${firstInitial}${lastInitial}`
})

const handleLogout = async () => {
  dropdownOpen.value = false
  await authStore.logout()
  router.push('/login')
}

// Close dropdown when clicking outside
if (typeof window !== 'undefined') {
  window.addEventListener('click', (e) => {
    const target = e.target as HTMLElement
    if (!target.closest('.relative')) {
      dropdownOpen.value = false
    }
  })
}
</script>
