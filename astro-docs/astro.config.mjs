import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import node from '@astrojs/node';

// ── All config is env-driven — no hardcoded ports or URLs ──────────────────
const SERVER_IP = process.env.SERVER_IP || 'localhost';
const PORT_ASTRO = process.env.PORT_ASTRO || '3003';
const ASTRO_INTERNAL_PORT = process.env.ASTRO_INTERNAL_PORT || '4321';

export default defineConfig({
  site: `http://${SERVER_IP}:${PORT_ASTRO}`,
  output: 'server',
  adapter: node({
    mode: 'standalone',
  }),
  integrations: [
    starlight({
      title: 'My Docs',
      social: {
        github: 'https://github.com/suppg02-sudo/pauly',
      },
      sidebar: [
        {
          label: 'Guides',
          items: [
            { label: 'Getting Started', link: '/guides/getting-started/' },
            { label: 'Installation', link: '/guides/installation/' },
          ],
        },
        {
          label: 'Reference',
          items: [
            { label: 'API', link: '/reference/api/' },
            { label: 'Configuration', link: '/reference/config/' },
          ],
        },
      ],
      customCss: ['./src/styles/custom.css'],
    }),
  ],
  server: {
    host: '0.0.0.0',
    port: Number(ASTRO_INTERNAL_PORT),
  },
  vite: {
    define: {
      // Inject Directus connection details at build/runtime — never hardcoded
      'import.meta.env.DIRECTUS_URL': JSON.stringify(
        process.env.DIRECTUS_URL || `http://localhost:${process.env.PORT_DIRECTUS || '8056'}`
      ),
      'import.meta.env.DIRECTUS_TOKEN': JSON.stringify(
        process.env.DIRECTUS_TOKEN || 'docs-api-token-change-me'
      ),
    },
  },
});
