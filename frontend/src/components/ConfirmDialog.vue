<template>
  <div
    v-if="isOpen"
    class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
    @click.self="handleCancel"
  >
    <div class="bg-white border border-border-light rounded-lg max-w-md w-full p-6 animate-fade-in shadow-subtle">
      <!-- Icon -->
      <div class="flex items-center justify-center w-12 h-12 mx-auto mb-4 rounded-full bg-red-100 border border-red-200">
        <svg class="w-6 h-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
          />
        </svg>
      </div>

      <!-- Title -->
      <h3 class="text-lg font-display font-bold text-primary-dark text-center mb-2">
        {{ title }}
      </h3>

      <!-- Message -->
      <p class="text-sm text-slate-600 text-center mb-6">
        {{ message }}
      </p>

      <!-- Actions -->
      <div class="flex gap-3">
        <button
          @click="handleCancel"
          class="flex-1 btn-secondary"
          :disabled="isProcessing"
        >
          {{ cancelText }}
        </button>
        <button
          @click="handleConfirm"
          class="flex-1 bg-red-600 text-white px-4 py-2 rounded-3xl font-bold border border-slate-200 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          :disabled="isProcessing"
        >
          <span v-if="!isProcessing">{{ confirmText }}</span>
          <span v-else>{{ processingText }}</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'

interface Props {
  title?: string
  message?: string
  confirmText?: string
  cancelText?: string
  processingText?: string
}

const props = withDefaults(defineProps<Props>(), {
  title: 'Confirm action',
  message: 'Are you sure you want to proceed?',
  confirmText: 'Confirm',
  cancelText: 'Cancel',
  processingText: 'Processing...',
})

const emit = defineEmits<{
  confirm: []
  cancel: []
}>()

const isOpen = ref(false)
const isProcessing = ref(false)

const open = () => {
  isOpen.value = true
  isProcessing.value = false
}

const close = () => {
  isOpen.value = false
  isProcessing.value = false
}

const handleConfirm = () => {
  isProcessing.value = true
  emit('confirm')
}

const handleCancel = () => {
  if (!isProcessing.value) {
    emit('cancel')
    close()
  }
}

defineExpose({
  open,
  close,
})
</script>

<style scoped>
@keyframes fade-in {
  from {
    opacity: 0;
    transform: scale(0.95);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

.animate-fade-in {
  animation: fade-in 0.2s ease-out;
}
</style>
