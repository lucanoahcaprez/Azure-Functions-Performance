/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{svelte,js,ts}'],
  theme: {
    extend: {
      fontFamily: {
        display: ['"Space Grotesk"', 'ui-sans-serif', 'system-ui'],
        body: ['"Inter"', 'ui-sans-serif', 'system-ui'],
        mono: ['"IBM Plex Mono"', 'SFMono-Regular', 'Menlo', 'monospace'],
      },
      colors: {
        midnight: '#191e24',
        ink: '#000000',
        neptune: '#27c5ff',
        aurora: '#7c3aed',
      },
      boxShadow: {
        neon: '0 10px 40px rgba(39, 197, 255, 0.25)',
      },
    },
  },
  plugins: [],
};
