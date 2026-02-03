/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: '#007b80',
        'background-light': '#f9f7f6',
        'background-dark': '#1c1f22',
        'dashboard-primary': '#155879',
        'dashboard-primary-dark': '#0e3f57',
        'dashboard-accent': '#d97706',
        'dashboard-background-light': '#f1f2f4',
        'dashboard-background-dark': '#121b20',
        'dashboard-surface-light': '#ffffff',
        'dashboard-surface-dark': '#1a262e',
      },
      fontFamily: {
        display: ["'Roboto'", 'sans-serif'],
        sans: ["'Roboto'", 'sans-serif'],
        dashboard: ["'Roboto'", 'sans-serif'],
      },
      borderRadius: {
        lg: '1rem',
        xl: '1.5rem',
      },
      boxShadow: {
        'dashboard-subtle': '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
        'dashboard-sm': '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06)',
        'dashboard-md': '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
        'dashboard-lg': '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',
        'dashboard-xl': '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
      },
      animation: {
        spin: 'spin 1s linear infinite',
      },
      keyframes: {
        spin: {
          '0%': { transform: 'rotate(0deg)' },
          '100%': { transform: 'rotate(360deg)' },
        },
      },
    },
  },
  plugins: [],
};
