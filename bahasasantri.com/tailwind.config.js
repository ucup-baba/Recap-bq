/** @type {import('tailwindcss').Config} */
module.exports = {
    content: [
        "./*.html",
        "./js/**/*.js"
    ],
    darkMode: ['class', '[data-theme="dark"]'],
    safelist: [
        // Dynamic button classes from quiz.js
        'w-full', 'p-4', 'rounded-2xl', 'font-bold', 'text-left', 'transition-all', 'border-2',
        'bg-white', 'border-gray-100', 'text-gray-600', 'hover:bg-gray-50',
        'bg-brand-secondary/10', 'border-brand-secondary', 'text-brand-secondary',
        'bg-green-100', 'border-green-500', 'text-green-700',
        'bg-red-100', 'border-red-500', 'text-red-700',
        // Practice mode feedback
        'text-green-500', 'text-red-500', 'text-green-600',
        // Admin buttons
        'text-blue-400', 'hover:text-blue-600', 'hover:bg-blue-50',
        'text-orange-400', 'hover:text-orange-600', 'hover:bg-orange-50',
        'text-red-400', 'hover:text-red-600', 'hover:bg-red-50',
        // Math battle
        'text-rose-500', 'bg-rose-500',
        // Leaderboard
        'bg-brand-primary/10', 'border-brand-primary/20',
        // Common utilities
        'hidden', 'flex', 'absolute', 'relative', 'fixed',
        'animate-bounce', 'animate-pulse', 'animate-spin',
    ],
    theme: {
        extend: {
            colors: {
                brand: {
                    primary: '#FF7043',
                    secondary: '#26A69A',
                    dark: '#0F172A'
                },
                cream: '#FFF9E5',
                mint: '#E0F7FA',
                pastel: {
                    orange: '#FFAB91',
                    green: '#A5D6A7',
                    blue: '#90CAF9',
                    purple: '#CE93D8'
                }
            },
            fontFamily: {
                sans: ['Plus Jakarta Sans', 'sans-serif'],
                display: ['Outfit', 'sans-serif'],
                body: ['Outfit', 'sans-serif']
            },
            boxShadow: {
                soft: '0 10px 40px -10px rgba(0,0,0,0.08)',
                'inner-soft': 'inset 0 2px 4px 0 rgba(0, 0, 0, 0.06)'
            },
            borderRadius: {
                '4xl': '2.5rem'
            },
            animation: {
                'float': 'float 6s ease-in-out infinite',
            },
            keyframes: {
                float: {
                    '0%, 100%': { transform: 'translateY(0)' },
                    '50%': { transform: 'translateY(-10px)' },
                }
            }
        },
    },
    plugins: [],
}
