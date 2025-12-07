import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      redirect: '/login',
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/LoginView.vue'),
      meta: { requiresGuest: true, title: 'Sign in' },
    },
    {
      path: '/register',
      name: 'register',
      component: () => import('../views/RegisterView.vue'),
      meta: { requiresGuest: true, title: 'Create account' },
    },
    {
      path: '/forgot-password',
      name: 'forgot-password',
      component: () => import('../views/ForgotPasswordView.vue'),
      meta: { requiresGuest: true, title: 'Forgot password' },
    },
    {
      path: '/reset-password/:token',
      name: 'reset-password',
      component: () => import('../views/ResetPasswordView.vue'),
      meta: { requiresGuest: true, title: 'Reset password' },
    },
    {
      path: '/dashboard',
      name: 'dashboard',
      component: () => import('../views/DashboardView.vue'),
      meta: { requiresAuth: true, title: 'Dashboard' },
    },
    {
      path: '/assets',
      name: 'assets',
      component: () => import('../views/AssetsView.vue'),
      meta: { requiresAuth: true, title: 'Assets' },
    },
    {
      path: '/assets/add',
      name: 'add-asset',
      component: () => import('../views/AddAssetView.vue'),
      meta: { requiresAuth: true, title: 'Add Asset' },
    },
    {
      path: '/assets/:id',
      name: 'view-asset',
      component: () => import('../views/ViewAssetView.vue'),
      meta: { requiresAuth: true, title: 'View Asset' },
    },
    {
      path: '/assets/:id/edit',
      name: 'edit-asset',
      component: () => import('../views/EditAssetView.vue'),
      meta: { requiresAuth: true, title: 'Edit Asset' },
    },
    {
      path: '/employees',
      name: 'employees',
      component: () => import('../views/EmployeesView.vue'),
      meta: { requiresAuth: true, title: 'Employees' },
    },
    {
      path: '/employees/add',
      name: 'add-employee',
      component: () => import('../views/AddEmployeeView.vue'),
      meta: { requiresAuth: true, title: 'Add Employee' },
    },
    {
      path: '/employees/:id',
      name: 'view-employee',
      component: () => import('../views/ViewEmployeeView.vue'),
      meta: { requiresAuth: true, title: 'View Employee' },
    },
    {
      path: '/employees/:id/edit',
      name: 'edit-employee',
      component: () => import('../views/EditEmployeeView.vue'),
      meta: { requiresAuth: true, title: 'Edit Employee' },
    },
    {
      path: '/transactions',
      name: 'transactions',
      component: () => import('../views/TransactionsView.vue'),
      meta: { requiresAuth: true, title: 'Transactions' },
    },
    {
      path: '/settings',
      name: 'settings',
      component: () => import('../views/SettingsView.vue'),
      meta: { requiresAuth: true, title: 'Settings' },
    },
    {
      path: '/settings/integrations',
      name: 'settings-integrations',
      component: () => import('../views/settings/IntegrationsView.vue'),
      meta: { requiresAuth: true, title: 'Integrations' },
    },
    {
      path: '/software',
      name: 'software',
      component: () => import('../views/SoftwareView.vue'),
      meta: { requiresAuth: true, title: 'Software Licenses' },
    },
    {
      path: '/software/add',
      name: 'add-software',
      component: () => import('../views/AddSoftwareView.vue'),
      meta: { requiresAuth: true, title: 'Add Software License' },
    },
    {
      path: '/software/:id',
      name: 'view-software',
      component: () => import('../views/ViewSoftwareView.vue'),
      meta: { requiresAuth: true, title: 'View License' },
    },
    {
      path: '/software/:id/edit',
      name: 'edit-software',
      component: () => import('../views/EditSoftwareView.vue'),
      meta: { requiresAuth: true, title: 'Edit License' },
    },
    {
      path: '/workflows',
      name: 'workflows',
      component: () => import('../views/WorkflowsView.vue'),
      meta: { requiresAuth: true, title: 'Workflows' },
    },
    {
      path: '/workflows/:id',
      name: 'workflow-detail',
      component: () => import('../views/WorkflowDetailView.vue'),
      meta: { requiresAuth: true, title: 'Workflow Details' },
    },
    {
      path: '/reports/license-reclamation',
      name: 'report-license-reclamation',
      component: () => import('../views/reports/ReportView.vue'),
      meta: { requiresAuth: true, title: 'License Reclamation Report' },
    },
    {
      path: '/settings/categories',
      name: 'settings-categories',
      component: () => import('../views/settings/CategoriesView.vue'),
      meta: { requiresAuth: true, title: 'Asset Categories' },
    },
    {
      path: '/settings/statuses',
      name: 'settings-statuses',
      component: () => import('../views/settings/StatusesView.vue'),
      meta: { requiresAuth: true, title: 'Asset Statuses' },
    },
    {
      path: '/settings/users',
      name: 'settings-users',
      component: () => import('../views/settings/UsersView.vue'),
      meta: { requiresAuth: true, title: 'User Management' },
    },
    {
      path: '/settings/roles',
      name: 'settings-roles',
      component: () => import('../views/settings/RolesView.vue'),
      meta: { requiresAuth: true, title: 'Roles & Permissions' },
    },
    {
      path: '/settings/organizations',
      name: 'settings-organizations',
      component: () => import('../views/settings/OrganizationsView.vue'),
      meta: { requiresAuth: true, title: 'Organizations' },
    },
    {
      path: '/settings/departments',
      name: 'settings-departments',
      component: () => import('../views/settings/DepartmentsView.vue'),
      meta: { requiresAuth: true, title: 'Departments' },
    },
    {
      path: '/settings/locations',
      name: 'settings-locations',
      component: () => import('../views/settings/LocationsView.vue'),
      meta: { requiresAuth: true, title: 'Locations' },
    },
    {
      path: '/settings/vendors',
      name: 'settings-vendors',
      component: () => import('../views/SettingsView.vue'),
      meta: { requiresAuth: true, title: 'Vendors' },
    },
    {
      path: '/settings/general',
      name: 'settings-general',
      component: () => import('../views/settings/GeneralSettingsView.vue'),
      meta: { requiresAuth: true, title: 'General Settings' },
    },
    {
      path: '/settings/notifications',
      name: 'settings-notifications',
      component: () => import('../views/settings/NotificationsView.vue'),
      meta: { requiresAuth: true, title: 'Notifications' },
    },
  ],
})

// Navigation guards
router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()

  // Update page title
  const baseTitle = 'Assetronics'
  if (to.meta.title) {
    document.title = `${to.meta.title} - ${baseTitle}`
  } else {
    document.title = baseTitle
  }

  // Load user from storage on first navigation
  if (!authStore.token) {
    authStore.loadUserFromStorage()
  }

  // Check if route requires authentication
  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    next({ name: 'login', query: { redirect: to.fullPath } })
  }
  // Check if route requires guest (not authenticated)
  else if (to.meta.requiresGuest && authStore.isAuthenticated) {
    next({ name: 'dashboard' })
  }
  // Proceed normally
  else {
    next()
  }
})

export default router
