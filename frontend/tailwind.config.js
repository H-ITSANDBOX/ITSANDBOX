/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#fef5f1',
          100: '#fde9e1',
          200: '#fbc7b2',
          300: '#f8a583',
          400: '#f58354',
          500: '#FF6B35', // メインのオレンジ
          600: '#e55a2b',
          700: '#cc4921',
          800: '#b23817',
          900: '#99270d',
        },
        secondary: {
          50: '#f4f6f7',
          100: '#e9edef',
          200: '#c8d2d7',
          300: '#a7b7bf',
          400: '#869ca7',
          500: '#2C3E50', // メインのネイビー
          600: '#253546',
          700: '#1e2c3c',
          800: '#172332',
          900: '#101a28',
        },
        accent: {
          50: '#f0f9f4',
          100: '#e1f3e9',
          200: '#b4e7c8',
          300: '#87dba7',
          400: '#5acf86',
          500: '#27AE60', // メインのグリーン
          600: '#229d56',
          700: '#1d8c4c',
          800: '#187b42',
          900: '#136a38',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
      animation: {
        'fade-in': 'fadeIn 0.5s ease-in-out',
        'slide-up': 'slideUp 0.5s ease-out',
        'pulse-slow': 'pulse 3s infinite',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { transform: 'translateY(20px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
      },
    },
  },
  plugins: [],
}