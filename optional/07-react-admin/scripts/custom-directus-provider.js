// Custom Directus data provider for react-admin
// Maps Directus API responses to react-admin's expected format
// Usage: import directusDataProvider from './custom-directus-provider';
//        const dataProvider = directusDataProvider(DIRECTUS_URL, TOKEN);

import { fetchUtils } from 'react-admin';

export default function directusDataProvider(baseUrl, token) {
  const httpClient = (url, options = {}) => {
    if (!options.headers) options.headers = new Headers({ Accept: 'application/json' });
    options.headers.set('Authorization', `Bearer ${token}`);
    return fetchUtils.fetchJson(url, options);
  };

  return {
    getList: async (resource, params) => {
      const { page, perPage } = params.pagination || { page: 1, perPage: 25 };
      const { field, order } = params.sort || { field: 'id', order: 'ASC' };
      const query = new URLSearchParams({
        page,
        limit: perPage,
        sort: `${order === 'DESC' ? '-' : ''}${field}`,
        meta: '*',
      });
      const { json } = await httpClient(`${baseUrl}/items/${resource}?${query}`);
      return {
        data: json.data || [],
        total: json.meta?.total_count || (json.data || []).length,
      };
    },

    getOne: async (resource, params) => {
      const { json } = await httpClient(`${baseUrl}/items/${resource}/${params.id}`);
      return { data: json.data };
    },

    create: async (resource, params) => {
      const { json } = await httpClient(`${baseUrl}/items/${resource}`, {
        method: 'POST',
        body: JSON.stringify(params.data),
      });
      return { data: json.data };
    },

    update: async (resource, params) => {
      const { json } = await httpClient(`${baseUrl}/items/${resource}/${params.id}`, {
        method: 'PATCH',
        body: JSON.stringify(params.data),
      });
      return { data: json.data };
    },

    delete: async (resource, params) => {
      await httpClient(`${baseUrl}/items/${resource}/${params.id}`, { method: 'DELETE' });
      return { data: params.previousData || { id: params.id } };
    },

    getMany: async (resource, params) => {
      const ids = params.ids.map(id => `filter[id][_in]=${id}`).join('&');
      const { json } = await httpClient(`${baseUrl}/items/${resource}?${ids}`);
      return { data: json.data || [] };
    },

    getManyReference: async (resource, params) => {
      const query = new URLSearchParams({
        filter: JSON.stringify({ [params.target]: params.id }),
        page: params.pagination?.page || 1,
        limit: params.pagination?.perPage || 25,
      });
      const { json } = await httpClient(`${baseUrl}/items/${resource}?${query}`);
      return {
        data: json.data || [],
        total: json.meta?.total_count || (json.data || []).length,
      };
    },
  };
}
