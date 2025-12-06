/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        'poppins': ['Poppins', 'sans-serif'],
        'open-sans': ['Open Sans', 'sans-serif'],
        sans: ['Open Sans', 'sans-serif'],
      },
      colors: {
        'primary-dark': '#0f1629',
        'primary-navy': '#1a2342',
        'accent-blue': '#2d7dd2',
        'accent-cyan': '#00d4ff',
        'accent-light-blue': '#4a9eff',
        'accent-deep-blue': '#1e5aa8',
        'text-dark': '#2c3e50',
        'text-light': '#6c7a8a',
        'light-bg': '#f5f8fc',
        'border-light': '#e1e8ef',
      },
      spacing: {
        '4.5': '1.125rem',
        '7.5': '1.875rem',
        '15': '3.75rem',
        '70': '17.5rem',
        'touch': '2.75rem',
      },
      borderRadius: {
        'sm': '0.375rem',
        'md': '0.5rem',
        'lg': '0.75rem',
        'xl': '1rem',
        '2xl': '1.5rem',
      },
      boxShadow: {
        'subtle': '0 2px 10px rgba(0,0,0,0.05)',
        'soft': '0 4px 20px -2px rgba(0, 0, 0, 0.05)', // New soft shadow
        'card': '0 20px 50px rgba(45, 125, 210, 0.15)',
        'button': '0 10px 30px rgba(45, 125, 210, 0.4)',
      },
      animation: {
        'slide-up': 'slideUp 0.6s ease',
        'fade-in': 'fadeIn 0.6s ease',
      },
      keyframes: {
        slideUp: {
          '0%': {
            opacity: '0',
            transform: 'translateY(30px)',
          },
          '100%': {
            opacity: '1',
            transform: 'translateY(0)',
          },
        },
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
      },
    },
  },
  plugins: [],
}
