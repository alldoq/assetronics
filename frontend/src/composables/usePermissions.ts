import { computed } from 'vue'
import { useAuthStore } from '@/stores/auth'

/**
 * Composable for checking user permissions based on role.
 *
 * Role hierarchy:
 * - super_admin: Full system access across all tenants
 * - admin: Full access within their tenant
 * - manager: Can manage employees, assets, and workflows
 * - employee: Can view assigned assets and complete workflows
 * - viewer: Read-only access to resources
 */
export function usePermissions() {
  const authStore = useAuthStore()

  const userRole = computed(() => authStore.userRole)

  /**
   * Check if user has a specific role
   */
  const hasRole = (role: string | string[]) => {
    if (!userRole.value) return false

    if (Array.isArray(role)) {
      return role.includes(userRole.value)
    }

    return userRole.value === role
  }

  /**
   * Check if user is an admin (super_admin or admin)
   */
  const isAdmin = computed(() => {
    return hasRole(['super_admin', 'admin'])
  })

  /**
   * Check if user is manager or higher
   */
  const isManagerOrHigher = computed(() => {
    return hasRole(['super_admin', 'admin', 'manager'])
  })

  /**
   * Check if user can view tenant settings
   */
  const canViewTenantSettings = computed(() => {
    return isAdmin.value
  })

  /**
   * Check if user can update tenant settings
   */
  const canUpdateTenantSettings = computed(() => {
    return isAdmin.value
  })

  /**
   * Check if user can view notification preferences
   */
  const canViewNotificationPreferences = computed(() => {
    return !!userRole.value // All authenticated users
  })

  /**
   * Check if user can update notification preferences
   */
  const canUpdateNotificationPreferences = computed(() => {
    return !!userRole.value // All authenticated users
  })

  return {
    userRole,
    hasRole,
    isAdmin,
    isManagerOrHigher,
    canViewTenantSettings,
    canUpdateTenantSettings,
    canViewNotificationPreferences,
    canUpdateNotificationPreferences,
  }
}
