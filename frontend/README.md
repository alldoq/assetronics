# Assetronics Frontend

Modern, mobile-first Vue 3 frontend for the Assetronics asset management platform.

## Tech Stack

- **Vue 3** - Progressive JavaScript framework
- **TypeScript** - Type safety and better DX
- **Vite** - Lightning fast build tool
- **Tailwind CSS 3** - Utility-first CSS framework (stable production version)
- **Vue Router** - Client-side routing
- **Pinia** - State management
- **Axios** - HTTP client

## Features

### ✨ Mobile-First Design
- Clean, minimalistic UI with professional color scheme
- Touch-optimized interface (44px minimum touch targets)
- Responsive breakpoints for all screen sizes
- Safe area inset support for notched devices

### 🔐 Authentication
- Login page with email/password
- Registration page with validation
- Forgot password flow with email verification
- Reset password with token validation
- JWT token management
- Route guards for protected pages
- Persistent sessions with localStorage

### 🎨 Design System
- Professional emerald accent colors
- Neutral gray palette for clean appearance
- Custom touch-target utilities
- Consistent spacing and typography

## Project Setup

### Prerequisites
- Node.js 18+
- npm or yarn
- Backend API running on `http://localhost:4000`

### Installation

```bash
# Install dependencies
npm install --legacy-peer-deps

# Environment variables are already configured in .env
VITE_API_BASE_URL=http://localhost:4000/api/v1
VITE_DEFAULT_TENANT=acme
```

### Development

```bash
# Start development server
npm run dev

# Server will be available at http://localhost:5173 (or 5174 if 5173 is in use)
```

### Build for Production

```bash
# Build optimized production bundle
npm run build

# Preview production build
npm run preview
```

## Project Structure

```
src/
├── assets/          # CSS, images, fonts
│   └── main.css    # Tailwind CSS configuration
├── components/      # Reusable Vue components
├── router/          # Vue Router configuration
│   └── index.ts    # Routes and navigation guards
├── stores/          # Pinia stores
│   └── auth.ts     # Authentication store
├── services/        # API clients and utilities
│   └── api.ts      # Axios client and API methods
├── views/           # Page components
│   ├── LoginView.vue
│   ├── RegisterView.vue
│   ├── ForgotPasswordView.vue
│   ├── ResetPasswordView.vue
│   └── DashboardView.vue
├── App.vue          # Root component
└── main.ts          # Application entry point
```

## API Integration

The frontend connects to the Elixir/Phoenix backend API:

- **Base URL**: `http://localhost:4000/api/v1`
- **Tenant Header**: `X-Tenant-ID: acme`
- **Auth Header**: `Authorization: Bearer <token>`

### Available API Endpoints

- `POST /auth/login` - User login
- `POST /auth/register` - User registration
- `POST /auth/logout` - User logout
- `GET /auth/me` - Get current user
- `POST /auth/forgot-password` - Request password reset
- `POST /auth/reset-password` - Reset password with token
- `GET /auth/validate-reset-token/:token` - Validate reset token

## Authentication Flow

1. User submits login/register form
2. API request sent with credentials
3. JWT token received and stored in localStorage
4. User data stored in Pinia store
5. Token attached to all subsequent API requests
6. Navigation guards protect authenticated routes

## Mobile-First Utilities

### Touch Targets
```vue
<!-- Minimum 44px touch target -->
<button class="touch-target">Click me</button>
```

### Safe Area Insets
```vue
<!-- Respect device notches and safe areas -->
<div class="safe-area-inset">Content</div>
```

## Color Palette

### Primary (Emerald)
- `primary-50` to `primary-950` - Main accent colors
- Used for CTAs, links, active states

### Neutral (Gray)
- `neutral-50` to `neutral-950` - Text and backgrounds
- Creates clean, professional appearance

## Development Notes

### Form Validation
- Client-side validation before API calls
- Real-time error display
- Field-level error clearing on focus

### State Management
- Pinia composition API pattern
- Reactive user authentication state
- Persistent login sessions

### Type Safety
- TypeScript for all components and services
- Typed API responses
- IntelliSense support

## Testing Credentials

When backend is seeded with test data:

```
Admin:    admin@acme.com / Admin123!
Manager:  manager@acme.com / Manager123!
Employee: employee@acme.com / Employee123!
Viewer:   viewer@acme.com / Viewer123!
```

## Recommended IDE Setup

[VS Code](https://code.visualstudio.com/) + [Vue (Official)](https://marketplace.visualstudio.com/items?itemName=Vue.volar)

## Browser Support

- Chrome/Edge (latest)
- Firefox (latest)
- Safari (latest)
- Mobile browsers (iOS Safari, Chrome Mobile)

## License

Proprietary - © 2025 Assetronics
