<template>
  <div class="min-h-screen bg-salt relative overflow-hidden">
    <!-- Organic blob backgrounds -->
    <div class="blob-bg -top-32 -left-32"></div>
    <div class="blob-bg top-1/2 -right-40 bg-[radial-gradient(circle,_rgba(6,78,59,0.08)_0%,_rgba(255,255,255,0)_70%)]"></div>

    <RouterView />

    <!-- Toast notifications -->
    <ToastContainer />
  </div>
</template>

<script setup lang="ts">
import { RouterView } from 'vue-router'
import ToastContainer from '@/components/ToastContainer.vue'
</script>
