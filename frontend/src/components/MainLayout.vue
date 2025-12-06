<template>
  <div class="min-h-screen bg-light-bg">
    <!-- Mobile menu button -->
    <div class="lg:hidden fixed top-0 left-0 right-0 z-50 bg-white border-b border-border-light" style="box-shadow: 0 2px 10px rgba(0,0,0,0.05)">
      <div class="flex items-center justify-between px-4 h-16">
        <div class="flex items-center gap-2.5">
          <img src="/logo.png" alt="Assetronics Logo" class="h-10 w-auto" style="background-color: white;">
          <span class="text-xl font-light font-poppins text-accent-blue">assetronics</span>
        </div>
        <button
          @click="mobileMenuOpen = !mobileMenuOpen"
          class="p-2 rounded-lg text-primary-dark hover:bg-light-bg touch-target"
        >
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              v-if="!mobileMenuOpen"
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M4 6h16M4 12h16M4 18h16"
            />
            <path
              v-else
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M6 18L18 6M6 6l12 12"
            />
          </svg>
        </button>
      </div>
    </div>

    <!-- Sidebar -->
    <aside
      :class="[
        'fixed inset-y-0 left-0 z-40 w-64 bg-white border-r border-border-light transform transition-transform duration-200 ease-in-out flex flex-col',
        mobileMenuOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0',
      ]"
      style="box-shadow: 0 2px 10px rgba(0,0,0,0.05)"
    >
      <!-- Logo -->
      <div class="hidden lg:flex items-center justify-center gap-2.5 h-20 px-6 border-b border-border-light flex-shrink-0">
        <img src="/logo.png" alt="Assetronics Logo" class="h-10 w-auto" style="background-color: white;">
        <span class="text-xl font-light font-poppins text-accent-blue">assetronics</span>
      </div>

      <!-- Navigation -->
      <nav class="flex-1 px-4 py-6 space-y-1 overflow-y-auto mt-16 lg:mt-0">
        <router-link
          v-for="item in navigationItems"
          :key="item.name"
          :to="item.path"
          @click="mobileMenuOpen = false"
          class="group relative flex items-center px-4 py-3 text-sm font-medium rounded-md transition-all duration-200 touch-target"
          :class="
            isActiveRoute(item.path)
              ? 'bg-accent-blue/10 text-accent-blue border-l-4 border-accent-blue pl-3'
              : 'text-text-light hover:bg-light-bg hover:text-primary-dark border-l-4 border-transparent pl-3'
          "
        >
          <component
            :is="item.icon"
            class="w-5 h-5 mr-3 transition-transform duration-200"
            :class="isActiveRoute(item.path) ? 'text-accent-blue' : 'text-text-dark'"
          />
          <span class="font-semibold">{{ item.name }}</span>
          <div
            v-if="isActiveRoute(item.path)"
            class="absolute right-3 w-1.5 h-1.5 rounded-full bg-accent-blue"
          ></div>
        </router-link>
      </nav>

      <!-- User Profile at bottom -->
      <div class="border-t border-border-light p-4 flex-shrink-0 mt-auto">
        <UserProfile />
      </div>
    </aside>

    <!-- Overlay for mobile -->
    <div
      v-if="mobileMenuOpen"
      @click="mobileMenuOpen = false"
      class="fixed inset-0 bg-black bg-opacity-50 z-30 lg:hidden"
    ></div>

    <!-- Main content -->
    <div class="lg:pl-64">
      <!-- Page content -->
      <main class="p-4 sm:p-6 lg:p-8">
        <slot />
      </main>
    </div>

    <!-- Scroll to top button -->
    <ScrollToTop />
  </div>
</template>

<script setup lang="ts">
import { ref, h } from 'vue'
import { useRoute } from 'vue-router'
import UserProfile from './UserProfile.vue'
import ScrollToTop from './ScrollToTop.vue'

const route = useRoute()
const mobileMenuOpen = ref(false)

// Navigation items with icons as render functions
const navigationItems = [
  {
    name: 'Dashboard',
    path: '/dashboard',
    icon: () =>
      h(
        'svg',
        { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
        h('path', {
          'stroke-linecap': 'round',
          'stroke-linejoin': 'round',
          'stroke-width': '2',
          d: 'M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6',
        })
      ),
  },
  {
    name: 'Assets',
    path: '/assets',
    icon: () =>
      h(
        'svg',
        { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
        h('path', {
          'stroke-linecap': 'round',
          'stroke-linejoin': 'round',
          'stroke-width': '2',
          d: 'M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z',
        })
      ),
  },
  {
    name: 'Software',
    path: '/software',
    icon: () =>
      h(
        'svg',
        { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
        h('path', {
          'stroke-linecap': 'round',
          'stroke-linejoin': 'round',
          'stroke-width': '2',
          d: 'M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10',
        })
      ),
  },
  {
    name: 'Workflows',
    path: '/workflows',
    icon: () =>
      h(
        'svg',
        { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
        h('path', {
          'stroke-linecap': 'round',
          'stroke-linejoin': 'round',
          'stroke-width': '2',
          d: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4',
        })
      ),
  },
  {
    name: 'Employees',
    path: '/employees',
    icon: () =>
      h(
        'svg',
        { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
        h('path', {
          'stroke-linecap': 'round',
          'stroke-linejoin': 'round',
          'stroke-width': '2',
          d: 'M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z',
        })
      ),
  },
  {
    name: 'Transactions',
    path: '/transactions',
    icon: () =>
      h(
        'svg',
        { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
        h('path', {
          'stroke-linecap': 'round',
          'stroke-linejoin': 'round',
          'stroke-width': '2',
          d: 'M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4',
        })
      ),
  },
  {
    name: 'Settings',
    path: '/settings',
    icon: () =>
      h(
        'svg',
        { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' },
        [
          h('path', {
            'stroke-linecap': 'round',
            'stroke-linejoin': 'round',
            'stroke-width': '2',
            d: 'M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z',
          }),
          h('path', {
            'stroke-linecap': 'round',
            'stroke-linejoin': 'round',
            'stroke-width': '2',
            d: 'M15 12a3 3 0 11-6 0 3 3 0 016 0z',
          })
        ]
      ),
  },
]

const isActiveRoute = (path: string) => {
  return route.path === path || route.path.startsWith(path + '/')
}
</script>
