import tailwindcss from '@tailwindcss/vite';
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vitest/config';
import pkg from './package.json';

export default defineConfig({
	plugins: [sveltekit(), tailwindcss()],
	define: {
		__PKG_VERSION__: JSON.stringify(pkg.version)
	}

});
