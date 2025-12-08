<template>
  <Teleport to="body">
    <div
      v-if="modelValue"
      class="print-label-modal fixed inset-0 z-[10000] overflow-y-auto print:fixed print:inset-0"
      @click="$emit('update:modelValue', false)"
    >
      <!-- Backdrop -->
      <div class="fixed inset-0 bg-black bg-opacity-50 print:hidden" @click="$emit('update:modelValue', false)"></div>

      <!-- Modal Content -->
      <div class="flex min-h-full items-center justify-center p-4 print:p-0 print:block">
        <div
          class="relative bg-white rounded-2xl shadow-xl max-w-2xl w-full print:shadow-none print:max-w-none print:rounded-none"
          @click.stop
        >
          <!-- Header - Hidden when printing -->
          <div class="flex items-center justify-between p-6 border-b border-slate-200 print:hidden">
            <h2 class="text-2xl font-bold text-primary-dark">Asset Label</h2>
            <button
              @click="$emit('update:modelValue', false)"
              class="text-slate-400 hover:text-slate-600 transition-colors"
            >
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <!-- Loading State -->
          <div v-if="loading" class="p-12 text-center">
            <div class="animate-spin rounded-full h-12 w-12 border-b-4 border-accent-blue mx-auto mb-4"></div>
            <p class="text-slate-600">Generating label...</p>
          </div>

          <!-- Label Content -->
          <div v-else-if="labelData" class="p-8 print:p-6">
            <!-- Printable Label -->
            <div class="space-y-6">
              <!-- QR Code and Basic Info -->
              <div class="flex items-start gap-6 pb-6 border-b-2 border-slate-200">
                <!-- QR Code -->
                <div class="flex-shrink-0">
                  <img :src="labelData.qr_code" alt="QR Code" class="w-32 h-32" />
                  <p class="text-xs text-center text-slate-500 mt-2">Scan to view asset</p>
                </div>

                <!-- Asset Info -->
                <div class="flex-1 space-y-3">
                  <div>
                    <h3 class="text-2xl font-bold text-primary-dark">{{ labelData.name }}</h3>
                    <p v-if="labelData.make || labelData.model" class="text-lg text-slate-600">
                      {{ labelData.make }} {{ labelData.model }}
                    </p>
                  </div>

                  <div class="grid grid-cols-2 gap-4 text-sm">
                    <div v-if="labelData.asset_tag">
                      <p class="text-slate-500 font-medium">Asset Tag</p>
                      <p class="text-primary-dark font-mono font-bold text-lg">{{ labelData.asset_tag }}</p>
                    </div>
                    <div v-if="labelData.serial_number">
                      <p class="text-slate-500 font-medium">Serial Number</p>
                      <p class="text-primary-dark font-mono">{{ labelData.serial_number }}</p>
                    </div>
                    <div v-if="labelData.category">
                      <p class="text-slate-500 font-medium">Category</p>
                      <p class="text-primary-dark capitalize">{{ labelData.category }}</p>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Footer Info -->
              <div class="text-xs text-slate-500 text-center pt-4 border-t border-slate-100">
                <p>Generated on {{ new Date().toLocaleDateString() }}</p>
                <p class="mt-1">For questions or support, contact IT support</p>
              </div>
            </div>

            <!-- Action Buttons - Hidden when printing -->
            <div class="flex gap-3 mt-6 pt-6 border-t border-slate-200 print:hidden">
              <button
                @click="printLabel"
                class="flex-1 px-6 py-3 bg-accent-blue hover:bg-accent-blue-hover text-primary-dark font-semibold rounded-lg transition-all duration-200 flex items-center justify-center gap-2"
              >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z" />
                </svg>
                Print Label
              </button>
              <button
                @click="$emit('update:modelValue', false)"
                class="px-6 py-3 bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold rounded-lg transition-all duration-200"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { Teleport } from 'vue'

interface LabelData {
  qr_code: string
  asset_tag?: string
  name: string
  serial_number?: string
  make?: string
  model?: string
  category?: string
  asset_id: string
}

interface Props {
  modelValue: boolean
  labelData: LabelData | null
  loading: boolean
}

defineProps<Props>()
defineEmits<{
  (e: 'update:modelValue', value: boolean): void
}>()

const printLabel = () => {
  window.print()
}
</script>

<style>
@media print {
  /* Hide the main app when printing */
  #app {
    display: none !important;
  }

  /* Make sure body has no margin/padding for clean print */
  body {
    margin: 0 !important;
    padding: 0 !important;
  }

  /* Ensure the modal is visible and takes full width */
  .print-label-modal {
    display: block !important;
    position: static !important;
    width: 100% !important;
    max-width: 100% !important;
  }
}
</style>
