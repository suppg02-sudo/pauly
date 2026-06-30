import { createDirectus, rest, readItems } from '@directus/sdk';

// ── All connection details from env — nothing hardcoded ─────────────────────
// In Docker: DIRECTUS_URL is set to http://directus:8055 (internal network)
// In dev:    DIRECTUS_URL defaults to http://localhost:8056 (host port)
const DIRECTUS_URL =
  (import.meta as any).env?.DIRECTUS_URL ||
  process.env.DIRECTUS_URL ||
  `http://localhost:${process.env.PORT_DIRECTUS || '8056'}`;

const DIRECTUS_TOKEN =
  (import.meta as any).env?.DIRECTUS_TOKEN ||
  process.env.DIRECTUS_TOKEN ||
  'docs-api-token-change-me';

export interface Page {
  id: number;
  title: string;
  slug: string;
  status: string;
  content: string;
  excerpt: string | null;
  order: number;
  category: string | null;
  tags: string[] | null;
  date_published: string | null;
  date_updated: string | null;
  featured_image: string | null;
}

interface DirectusSchema {
  pages: Page[];
}

const client = createDirectus<DirectusSchema>(DIRECTUS_URL).with(rest());

export async function fetchPages(): Promise<Page[]> {
  try {
    const response = await client.request(
      readItems('pages', {
        filter: { status: { _eq: 'published' } },
        sort: ['category', 'order'],
        fields: [
          'id', 'title', 'slug', 'status', 'excerpt',
          'order', 'category', 'tags', 'date_published', 'date_updated',
        ],
      })
    );
    const pages = (response as unknown as Page[]) || [];
    return pages.filter((p) => p.date_published);
  } catch (err) {
    console.error('[directus] fetchPages error:', err);
    return [];
  }
}

export async function fetchPageBySlug(slug: string): Promise<Page | null> {
  try {
    const response = await client.request(
      readItems('pages', {
        filter: { slug: { _eq: slug }, status: { _eq: 'published' } },
        limit: 1,
      })
    );
    const pages = ((response as unknown as Page[]) || []).filter(
      (p) => p.date_published
    );
    return pages[0] || null;
  } catch (err) {
    console.error('[directus] fetchPageBySlug error:', err);
    return null;
  }
}

export function formatDate(dateStr: string | null): string {
  if (!dateStr) return '';
  try {
    return new Date(dateStr).toLocaleDateString('en-GB', {
      day: 'numeric', month: 'long', year: 'numeric',
    });
  } catch {
    return dateStr;
  }
}
