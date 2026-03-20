import fs from 'fs/promises';
import path from 'path';

type Role = 'public' | 'user' | 'vendor' | 'admin';

type Endpoint = {
  id: string;
  method: 'GET' | 'POST' | 'PATCH' | 'DELETE';
  path: string;
  role: Role;
  expectedStatuses?: number[];
  fullUrl?: string;
  body?: Record<string, unknown>;
  query?: Record<string, string | number | boolean | undefined>;
};

type Result = {
  id: string;
  role: Role;
  method: string;
  path: string;
  url: string;
  status: number;
  ok: boolean;
  durationMs: number;
  requestBody?: Record<string, unknown>;
  responseBody: unknown;
  error?: string;
};

type DemoCredential = {
  email: string;
  password: string;
  role: 'user' | 'vendor' | 'admin';
};

type RuntimeContext = {
  vendorId?: string;
  menuItemId?: string;
  orderId?: string;
  addressId?: string;
  notificationId?: string;
  buildingId?: string;
  zoneId?: string;
  classSessionId?: string;
};

const SITE_URL = process.env.LIVE_SITE_URL ?? 'https://swift-campus.vercel.app';
const API_BASE = process.env.LIVE_API_BASE ?? `${SITE_URL}/api/v1`;
const REQUEST_TIMEOUT_MS = Number(process.env.API_TEST_TIMEOUT_MS ?? 20000);

const credentialsFile = path.join(__dirname, '..', 'demo-credentials.json');

function withQuery(pathname: string, query?: Record<string, string | number | boolean | undefined>) {
  if (!query) return pathname;
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(query)) {
    if (value === undefined || value === null) continue;
    params.set(key, String(value));
  }
  const qs = params.toString();
  return qs ? `${pathname}?${qs}` : pathname;
}

async function parseBodySafe(response: Response): Promise<unknown> {
  const text = await response.text();
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch {
    return { raw: text };
  }
}

async function fetchWithTimeout(url: string, init: RequestInit) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
  try {
    return await fetch(url, { ...init, signal: controller.signal });
  } finally {
    clearTimeout(timer);
  }
}

async function callEndpoint(ep: Endpoint, tokenByRole: Partial<Record<Role, string>>): Promise<Result> {
  const endpointPath = withQuery(ep.path, ep.query);
  const url = ep.fullUrl ?? `${API_BASE}${endpointPath}`;
  const headers: Record<string, string> = {};

  const token = tokenByRole[ep.role];
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }

  if (ep.body) {
    headers['Content-Type'] = 'application/json';
  }

  const started = Date.now();
  try {
    const response = await fetchWithTimeout(url, {
      method: ep.method,
      headers,
      body: ep.body ? JSON.stringify(ep.body) : undefined,
    });

    const responseBody = await parseBodySafe(response);
    const expectedStatuses = ep.expectedStatuses && ep.expectedStatuses.length > 0
      ? ep.expectedStatuses
      : [];
    const ok = expectedStatuses.length > 0
      ? expectedStatuses.includes(response.status)
      : response.ok;

    return {
      id: ep.id,
      role: ep.role,
      method: ep.method,
      path: endpointPath,
      url,
      status: response.status,
      ok,
      durationMs: Date.now() - started,
      requestBody: ep.body,
      responseBody,
    };
  } catch (error: any) {
    return {
      id: ep.id,
      role: ep.role,
      method: ep.method,
      path: endpointPath,
      url,
      status: 0,
      ok: false,
      durationMs: Date.now() - started,
      requestBody: ep.body,
      responseBody: null,
      error: error?.message ?? 'Unknown request error',
    };
  }
}

function pickFirstId<T extends Record<string, any>>(list: unknown, field = 'id'): string | undefined {
  if (!Array.isArray(list) || list.length === 0) return undefined;
  const first = list[0] as T;
  const raw = first?.[field];
  return raw ? String(raw) : undefined;
}

async function login(role: 'user' | 'vendor' | 'admin', creds: DemoCredential[]) {
  const found = creds.find((c) => c.role === role);
  if (!found) return undefined;

  const url = `${API_BASE}/auth/session`;
  const response = await fetchWithTimeout(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: found.email, password: found.password }),
  });
  const data = await parseBodySafe(response) as any;

  return {
    ok: response.ok,
    status: response.status,
    token: data?.session?.access_token as string | undefined,
    body: data,
  };
}

async function main() {
  const startedAt = new Date().toISOString();
  const credsRaw = await fs.readFile(credentialsFile, 'utf8');
  const credentials = JSON.parse(credsRaw) as DemoCredential[];

  const tokenByRole: Partial<Record<Role, string>> = {};
  const results: Result[] = [];
  const context: RuntimeContext = {};

  const userLogin = await login('user', credentials);
  const vendorLogin = await login('vendor', credentials);
  const adminLogin = await login('admin', credentials);

  if (userLogin?.token) tokenByRole.user = userLogin.token;
  if (vendorLogin?.token) tokenByRole.vendor = vendorLogin.token;
  if (adminLogin?.token) tokenByRole.admin = adminLogin.token;

  results.push({
    id: 'auth.login.user',
    role: 'public',
    method: 'POST',
    path: '/auth/session',
    url: `${API_BASE}/auth/session`,
    status: userLogin?.status ?? 0,
    ok: userLogin?.ok ?? false,
    durationMs: 0,
    responseBody: userLogin?.body ?? null,
  });
  results.push({
    id: 'auth.login.vendor',
    role: 'public',
    method: 'POST',
    path: '/auth/session',
    url: `${API_BASE}/auth/session`,
    status: vendorLogin?.status ?? 0,
    ok: vendorLogin?.ok ?? false,
    durationMs: 0,
    responseBody: vendorLogin?.body ?? null,
  });
  results.push({
    id: 'auth.login.admin',
    role: 'public',
    method: 'POST',
    path: '/auth/session',
    url: `${API_BASE}/auth/session`,
    status: adminLogin?.status ?? 0,
    ok: adminLogin?.ok ?? false,
    durationMs: 0,
    responseBody: adminLogin?.body ?? null,
  });

  const baseEndpoints: Endpoint[] = [
    { id: 'health', method: 'GET', path: '/health', fullUrl: `${SITE_URL}/api/health`, role: 'public' },
    { id: 'contracts.registry', method: 'GET', path: '/contracts/registry', role: 'public' },
    { id: 'contracts.changelog', method: 'GET', path: '/contracts/changelog', role: 'public' },
    { id: 'contracts.flags', method: 'GET', path: '/contracts/flags', role: 'public' },
    { id: 'public.vendors', method: 'GET', path: '/public/vendors', role: 'public' },
    { id: 'public.search', method: 'GET', path: '/public/search', role: 'public', query: { q: 'rice' } },
    { id: 'public.recommendations', method: 'GET', path: '/public/recommendations', role: 'public', query: { limit: 10 } },
    { id: 'public.buildings', method: 'GET', path: '/public/buildings', role: 'public' },
    { id: 'public.zones', method: 'GET', path: '/public/zones', role: 'public' },
    { id: 'auth.me.user', method: 'GET', path: '/auth/me', role: 'user' },
    { id: 'auth.me.vendor', method: 'GET', path: '/auth/me', role: 'vendor' },
    { id: 'auth.me.admin', method: 'GET', path: '/auth/me', role: 'admin' },
    { id: 'orders.slots', method: 'GET', path: '/orders/slots', role: 'user' },
    { id: 'orders.me', method: 'GET', path: '/orders/me', role: 'user' },
    { id: 'addresses.list', method: 'GET', path: '/addresses', role: 'user' },
    { id: 'notifications.list', method: 'GET', path: '/notifications', role: 'user' },
    { id: 'promos.active', method: 'GET', path: '/promos/active', role: 'user' },
    { id: 'class-sessions.list', method: 'GET', path: '/class-sessions', role: 'user' },
    { id: 'vendor-ops.profile', method: 'GET', path: '/vendor-ops/profile', role: 'vendor' },
    { id: 'vendor-ops.menu', method: 'GET', path: '/vendor-ops/menu', role: 'vendor' },
    { id: 'vendor-ops.orders', method: 'GET', path: '/vendor-ops/orders', role: 'vendor' },
    { id: 'vendor-ops.stats', method: 'GET', path: '/vendor-ops/stats', role: 'vendor' },
    { id: 'admin.stats', method: 'GET', path: '/admin/stats', role: 'admin' },
    { id: 'admin.dashboard.summary', method: 'GET', path: '/admin/dashboard/summary', role: 'admin' },
    { id: 'admin.charts', method: 'GET', path: '/admin/charts', role: 'admin' },
    { id: 'admin.finance.summary', method: 'GET', path: '/admin/finance/summary', role: 'admin' },
    { id: 'admin.finance.payouts', method: 'GET', path: '/admin/finance/payouts', role: 'admin' },
    { id: 'admin.promos', method: 'GET', path: '/admin/promos', role: 'admin' },
    { id: 'admin.audit', method: 'GET', path: '/admin/audit', role: 'admin' },
    { id: 'admin.settings', method: 'GET', path: '/admin/settings', role: 'admin' },
    { id: 'admin.orders', method: 'GET', path: '/admin/orders', role: 'admin' },
    { id: 'admin.users', method: 'GET', path: '/admin/users', role: 'admin' },
    { id: 'admin.vendors.pending', method: 'GET', path: '/admin/vendors/pending', role: 'admin' },
    { id: 'admin.campus.buildings', method: 'GET', path: '/admin/campus/buildings', role: 'admin' },
    { id: 'admin.campus.zones', method: 'GET', path: '/admin/campus/zones', role: 'admin' },
  ];

  for (const ep of baseEndpoints) {
    const result = await callEndpoint(ep, tokenByRole);
    results.push(result);

    if (ep.id === 'public.vendors' && result.ok) {
      context.vendorId = pickFirstId(result.responseBody);
    }
    if (ep.id === 'public.buildings' && result.ok) {
      context.buildingId = pickFirstId(result.responseBody);
    }
    if (ep.id === 'public.zones' && result.ok) {
      context.zoneId = pickFirstId(result.responseBody);
    }
    if (ep.id === 'notifications.list' && result.ok) {
      context.notificationId = pickFirstId(result.responseBody);
    }
    if (ep.id === 'addresses.list' && result.ok) {
      context.addressId = pickFirstId(result.responseBody);
    }
  }

  if (context.vendorId) {
    const vendorMenu = await callEndpoint(
      { id: 'menus.vendor', method: 'GET', path: `/menus/vendor/${context.vendorId}`, role: 'public' },
      tokenByRole,
    );
    results.push(vendorMenu);

    if (vendorMenu.ok && Array.isArray(vendorMenu.responseBody) && vendorMenu.responseBody.length > 0) {
      const firstMenu = vendorMenu.responseBody[0] as any;
      const menuItems = (firstMenu?.menu_items as any[]) ?? [];
      if (menuItems.length > 0 && menuItems[0]?.id) {
        context.menuItemId = String(menuItems[0].id);
      }
    }

    const reviews = await callEndpoint(
      { id: 'reviews.vendor', method: 'GET', path: `/reviews/vendor/${context.vendorId}`, role: 'public' },
      tokenByRole,
    );
    results.push(reviews);
  }

  if (context.vendorId && context.menuItemId) {
    const createOrderBody: Record<string, unknown> = {
      vendor_id: context.vendorId,
      total_amount: 100,
      items: [
        {
          id: context.menuItemId,
          quantity: 1,
          price: 100,
        },
      ],
    };

    if (context.buildingId) {
      createOrderBody.delivery_mode = 'class';
      createOrderBody.delivery_building_id = context.buildingId;
      createOrderBody.delivery_room = 'A-101';
      if (context.zoneId) {
        createOrderBody.delivery_zone_id = context.zoneId;
      }
    }

    const createOrder = await callEndpoint(
      { id: 'orders.create', method: 'POST', path: '/orders', role: 'user', body: createOrderBody },
      tokenByRole,
    );
    results.push(createOrder);

    if (createOrder.ok && (createOrder.responseBody as any)?.id) {
      context.orderId = String((createOrder.responseBody as any).id);
    }

    const promoValidate = await callEndpoint(
      {
        id: 'promos.validate',
        method: 'POST',
        path: '/promos/validate',
        role: 'user',
        expectedStatuses: [200],
        body: { code: 'WELCOME10', order_total: 100 },
      },
      tokenByRole,
    );
    results.push(promoValidate);

    const paymentCreate = await callEndpoint(
      {
        id: 'payments.create-order',
        method: 'POST',
        path: '/payments/create-order',
        role: 'user',
        body: { amount: 100 },
      },
      tokenByRole,
    );
    results.push(paymentCreate);

    if (context.orderId) {
      const deliveryLocation = await callEndpoint(
        { id: 'delivery.location.get', method: 'GET', path: `/delivery/${context.orderId}/location`, role: 'user' },
        tokenByRole,
      );
      results.push(deliveryLocation);

      const cancelOrder = await callEndpoint(
        { id: 'orders.cancel', method: 'PATCH', path: `/orders/${context.orderId}/cancel`, role: 'user' },
        tokenByRole,
      );
      results.push(cancelOrder);
    }
  }

  const notificationRegister = await callEndpoint(
    {
      id: 'notifications.device.register',
      method: 'POST',
      path: '/notifications/device',
      role: 'user',
      body: {
        token: `live-test-${Date.now()}`,
        platform: 'android',
      },
    },
    tokenByRole,
  );
  results.push(notificationRegister);

  if (context.notificationId) {
    const markRead = await callEndpoint(
      { id: 'notifications.read', method: 'PATCH', path: `/notifications/${context.notificationId}/read`, role: 'user' },
      tokenByRole,
    );
    results.push(markRead);
  }

  const passed = results.filter((r) => r.ok).length;
  const failed = results.filter((r) => !r.ok).length;

  const report = {
    generatedAt: new Date().toISOString(),
    startedAt,
    baseUrl: API_BASE,
    siteUrl: SITE_URL,
    timeoutMs: REQUEST_TIMEOUT_MS,
    summary: {
      total: results.length,
      passed,
      failed,
      passRate: results.length ? Number(((passed / results.length) * 100).toFixed(2)) : 0,
    },
    context,
    results,
  };

  const outputDir = path.join(__dirname, '..', 'reports');
  await fs.mkdir(outputDir, { recursive: true });

  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const reportPath = path.join(outputDir, `live-api-responses-${stamp}.json`);
  const latestPath = path.join(outputDir, 'live-api-responses-latest.json');

  await fs.writeFile(reportPath, JSON.stringify(report, null, 2), 'utf8');
  await fs.writeFile(latestPath, JSON.stringify(report, null, 2), 'utf8');

  console.log(`Live API test complete. Passed: ${passed}, Failed: ${failed}, Total: ${results.length}`);
  console.log(`Report: ${reportPath}`);
  console.log(`Latest: ${latestPath}`);

  if (failed > 0) {
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error('Live API test failed with fatal error:', error);
  process.exit(1);
});
