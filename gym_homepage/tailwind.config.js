/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          primary: '#0075de',
          primaryActive: '#005bab',
          secondary: '#213183',
          onPrimary: '#ffffff',
          canvas: '#ffffff',
          canvasSoft: '#f6f5f4',
          surface: '#ffffff',
          ink: '#000000',
          inkSecondary: '#31302e',
          inkMuted: '#615d59',
          inkFaint: '#a39e98',
          hairline: '#e6e6e6',
          success: '#1aae39',
          danger: '#e0393e',
          warning: '#dd5b00',
        },
        sticker: {
          sky: '#62aef0',
          purple: '#d6b6f6',
          purpleDeep: '#391c57',
          pink: '#ff64c8',
          orange: '#dd5b00',
          orangeDeep: '#793400',
          teal: '#2a9d99',
          green: '#1aae39',
          brown: '#523410',
        },
      },
      borderRadius: {
        xs: '4px',
        sm: '5px',
        md: '8px',
        lg: '12px',
        xl: '16px',
      },
      boxShadow: {
        soft:
          '0 0.175px 1.041px rgba(0,0,0,0.01), 0 0.8px 2.925px rgba(0,0,0,0.02), 0 2.025px 7.847px rgba(0,0,0,0.027), 0 4px 18px rgba(0,0,0,0.04)',
        elevated:
          '0 1px 2px rgba(0,0,0,0.02), 0 4px 8px rgba(0,0,0,0.03), 0 10px 20px rgba(0,0,0,0.035), 0 23px 52px rgba(0,0,0,0.05)',
      },
      animation: {
        'fade-in': 'fadeIn 0.3s ease-out',
        'slide-up': 'slideUp 0.3s ease-out',
      },
      keyframes: {
        fadeIn: { '0%': { opacity: 0 }, '100%': { opacity: 1 } },
        slideUp: { '0%': { opacity: 0, transform: 'translateY(8px)' }, '100%': { opacity: 1, transform: 'translateY(0)' } },
      },
    },
  },
  plugins: [],
}
