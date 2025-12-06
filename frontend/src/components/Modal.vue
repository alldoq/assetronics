<template>
  <teleport to="body">
    <transition
      enter-active-class="transition ease-out duration-200"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition ease-in duration-150"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div
        v-if="modelValue"
        class="fixed inset-0 z-50 overflow-y-auto"
        @click.self="closeOnBackdrop && close()"
        @keydown.esc="close"
      >
        <!-- Backdrop -->
        <div class="fixed inset-0 bg-black bg-opacity-50 transition-opacity"></div>

        <!-- Modal container -->
        <div class="flex min-h-full items-end justify-center p-0 sm:items-center sm:p-4">
          <transition
            enter-active-class="transition ease-out duration-200"
            enter-from-class="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
            enter-to-class="opacity-100 translate-y-0 sm:scale-100"
            leave-active-class="transition ease-in duration-150"
            leave-from-class="opacity-100 translate-y-0 sm:scale-100"
            leave-to-class="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
            @after-enter="handleAfterEnter"
            @after-leave="handleAfterLeave"
          >
            <div
              v-if="modelValue"
              ref="modalRef"
              role="dialog"
              aria-modal="true"
              :aria-labelledby="title ? 'modal-title' : undefined"
              class="bg-white border border-border-light relative w-full transform overflow-hidden rounded-t-lg sm:rounded-lg transition-all sm:my-8 sm:w-full shadow-subtle"
              :class="sizeClasses"
              tabindex="-1"
              @keydown="handleKeydown"
            >
              <!-- Header -->
              <div class="border-b border-slate-200 px-6 py-4">
                <div class="flex items-center justify-between">
                  <h3 id="modal-title" class="text-lg font-display font-bold text-primary-dark">
                    <slot name="title">{{ title }}</slot>
                  </h3>
                  <button
                    ref="closeButtonRef"
                    @click="close"
                    aria-label="Close dialog"
                    class="inline-flex items-center justify-center p-2 rounded-lg text-slate-600 hover:text-primary-dark hover:bg-slate-100 transition-colors"
                  >
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M6 18L18 6M6 6l12 12"
                      />
                    </svg>
                  </button>
                </div>
              </div>

              <!-- Body -->
              <div class="px-6 py-4 max-h-[calc(100vh-12rem)] overflow-y-auto">
                <slot></slot>
              </div>

              <!-- Footer -->
              <div
                v-if="$slots.footer"
                class="border-t border-slate-200 px-6 py-4 bg-light-bg"
              >
                <slot name="footer"></slot>
              </div>
            </div>
          </transition>
        </div>
      </div>
    </transition>
  </teleport>
</template>

<script setup lang="ts">
import { computed, ref, watch, onMounted, onUnmounted } from 'vue'

interface Props {
  modelValue: boolean
  title?: string
  size?: 'sm' | 'md' | 'lg' | 'xl'
  closeOnBackdrop?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  title: '',
  size: 'md',
  closeOnBackdrop: true,
})

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
  opened: []
  closed: []
}>()

const modalRef = ref<HTMLElement | null>(null)
const closeButtonRef = ref<HTMLButtonElement | null>(null)
let previousActiveElement: HTMLElement | null = null

const sizeClasses = computed(() => {
  const sizes = {
    sm: 'sm:max-w-md',
    md: 'sm:max-w-lg',
    lg: 'sm:max-w-2xl',
    xl: 'sm:max-w-4xl',
  }
  return sizes[props.size]
})

const close = () => {
  emit('update:modelValue', false)
}

// Get all focusable elements within modal
const getFocusableElements = (): HTMLElement[] => {
  if (!modalRef.value) return []

  const focusableSelectors = [
    'a[href]',
    'button:not([disabled])',
    'textarea:not([disabled])',
    'input:not([disabled])',
    'select:not([disabled])',
    '[tabindex]:not([tabindex="-1"])',
  ].join(',')

  return Array.from(modalRef.value.querySelectorAll(focusableSelectors))
}

// Focus trap - handle Tab key
const handleKeydown = (event: KeyboardEvent) => {
  if (event.key !== 'Tab') return

  const focusableElements = getFocusableElements()
  if (focusableElements.length === 0) return

  const firstElement = focusableElements[0]!
  const lastElement = focusableElements[focusableElements.length - 1]!

  if (event.shiftKey) {
    // Shift + Tab: going backwards
    if (document.activeElement === firstElement) {
      event.preventDefault()
      lastElement.focus()
    }
  } else {
    // Tab: going forwards
    if (document.activeElement === lastElement) {
      event.preventDefault()
      firstElement.focus()
    }
  }
}

// Handle after modal enters (opened)
const handleAfterEnter = () => {
  // Store the element that triggered the modal
  previousActiveElement = document.activeElement as HTMLElement

  // Focus the first focusable element in the modal
  const focusableElements = getFocusableElements()
  if (focusableElements.length > 0) {
    // Focus first input/textarea/select, or fallback to first focusable element
    const firstInput = focusableElements.find(
      (el) => el.tagName === 'INPUT' || el.tagName === 'TEXTAREA' || el.tagName === 'SELECT'
    )
    if (firstInput) {
      firstInput.focus()
    } else {
      focusableElements[0]!.focus()
    }
  } else if (modalRef.value) {
    // If no focusable elements, focus the modal itself
    modalRef.value.focus()
  }

  emit('opened')
}

// Handle after modal leaves (closed)
const handleAfterLeave = () => {
  // Restore focus to the element that opened the modal
  if (previousActiveElement && previousActiveElement.focus) {
    previousActiveElement.focus()
  }
  previousActiveElement = null

  emit('closed')
}

// Prevent body scroll when modal is open
const updateBodyScroll = (isOpen: boolean) => {
  if (typeof document === 'undefined') return

  if (isOpen) {
    document.body.style.overflow = 'hidden'
  } else {
    document.body.style.overflow = ''
  }
}

// Watch for modelValue changes
watch(
  () => props.modelValue,
  (newValue) => {
    updateBodyScroll(newValue)
  },
  { immediate: true }
)

// Cleanup on unmount
onUnmounted(() => {
  updateBodyScroll(false)
})
</script>
