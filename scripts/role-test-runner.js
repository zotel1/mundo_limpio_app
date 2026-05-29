#!/usr/bin/env node
/**
 * role-test-runner.js — Test de roles contra la API real de MundoLimpio
 *
 * Cada agente ejecuta este script con un usuario y rol específicos.
 * El script: loguea, ejecuta acciones típicas del rol, y reporta resultados.
 *
 * Uso:
 *   node role-test-runner.js <email> [password]
 *
 * Ejemplo:
 *   node role-test-runner.js zotelsigel@gmail.com 123456
 */

const BASE_URL = 'https://mundo-limpio-backend.onrender.com';

// ──────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────

/** SKU único para datos de prueba — solo mayúsculas, números y guiones */
const skuId = () => `TEST-${Date.now().toString(36).toUpperCase()}-${Math.random().toString(36).slice(2, 6).toUpperCase()}`;

/** Nombre corto para datos de prueba */
const testName = () => `TEST-PROD-${Date.now().toString(36).slice(-4).toUpperCase()}`;

/** Timestamp ISO para medir duración */
const now = () => new Date().toISOString();

/** Ejecuta un request HTTP contra la API */
async function api(method, path, body, token) {
  const url = `${BASE_URL}${path}`;
  const headers = { 'Content-Type': 'application/json', Accept: 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;

  const start = Date.now();
  let res;
  try {
    res = await fetch(url, {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined,
      signal: AbortSignal.timeout(45_000),
    });
  } catch (err) {
    return {
      status: 0,
      duration: Date.now() - start,
      error: err.message,
      data: null,
    };
  }

  const duration = Date.now() - start;
  let data;
  const text = await res.text();
  try {
    data = JSON.parse(text);
  } catch {
    data = text.length > 200 ? text.slice(0, 200) + '…' : text;
  }

  return { status: res.status, duration, data };
}

// ──────────────────────────────────────────────
// Definición de acciones por rol
// ──────────────────────────────────────────────

/** Retorna el set de acciones a ejecutar para un rol dado */
function getActions(role, ids) {
  const sku = skuId();
  const name = testName();

  // Acciones comunes a varios roles
  const listProducts = {
    name: '📋 Listar productos activos',
    method: 'GET',
    path: '/api/v1/products',
  };
  const getProduct = {
    name: '🔍 Ver producto por ID',
    method: 'GET',
    path: '/api/v1/products/1',
  };
  const listAllProducts = {
    name: '📋 Listar TODOS los productos',
    method: 'GET',
    path: '/api/v1/products/all',
  };
  const lowStock = {
    name: '⚠️  Ver inventario con stock bajo',
    method: 'GET',
    path: '/api/v1/inventory/low-stock',
  };
  const getInventory1 = {
    name: '📦 Ver inventario del producto #1',
    method: 'GET',
    path: '/api/v1/inventory/1',
  };

  // Según el rol
  switch (role) {
    case 'ADMIN':
      return [
        listProducts,
        getProduct,
        listAllProducts,
        {
          name: '➕ Crear producto',
          method: 'POST',
          path: '/api/v1/products',
          body: { sku, name, minPrice: 10.5, active: true },
          saveResultAs: 'createdProduct',
        },
        lowStock,
        {
          name: '➕ Crear bulk product',
          method: 'POST',
          path: '/api/v1/bulk-products',
          body: {
            name: `BULK-${testName()}`,
            currentStockLiters: 100,
            costPerLiter: 5.5,
            conversionRatio: 1.0,
            active: true,
          },
          saveResultAs: 'createdBulk',
        },
        {
          name: '📋 Listar bulk products',
          method: 'GET',
          path: '/api/v1/bulk-products',
        },
        {
          name: '📋 Listar production batches',
          method: 'GET',
          path: '/api/v1/production-batches',
        },
        {
          name: '📋 Listar usuarios',
          method: 'GET',
          path: '/api/v1/users',
        },
        {
          name: '💰 Crear venta (si hay stock)',
          method: 'POST',
          path: '/api/v1/sales',
          body: { productId: 1, quantity: 1 },
        },
      ];

    case 'ACCOUNTANT':
      return [
        listProducts,
        getProduct,
        listAllProducts,
        lowStock,
        getInventory1,
        {
          name: '🔒 Intentar crear producto — esperado: 403',
          method: 'POST',
          path: '/api/v1/products',
          body: { sku, name, minPrice: 10.5, active: true },
          expect403: true,
        },
      ];

    case 'STOCK_OPERATOR':
      return [
        listProducts,
        lowStock,
        getInventory1,
        {
          name: '📦 Ajustar stock del producto #1',
          method: 'POST',
          path: '/api/v1/inventory/1/adjust',
          body: { quantity: 5, reason: 'Test desde role-test-runner' },
        },
        {
          name: '🔒 Intentar crear producto — esperado: 403',
          method: 'POST',
          path: '/api/v1/products',
          body: { sku, name, minPrice: 10.5, active: true },
          expect403: true,
        },
      ];

    case 'SALES_CLERK':
      return [
        listProducts,
        getProduct,
        {
          name: '💰 Intentar crear venta',
          method: 'POST',
          path: '/api/v1/sales',
          body: { productId: 1, quantity: 1 },
        },
        {
          name: '🔒 Intentar crear producto — esperado: 403',
          method: 'POST',
          path: '/api/v1/products',
          body: { sku, name, minPrice: 10.5, active: true },
          expect403: true,
        },
      ];

    case 'PRODUCTION_OP':
      return [
        listProducts,
        {
          name: '📋 Listar bulk products',
          method: 'GET',
          path: '/api/v1/bulk-products',
        },
        {
          name: '📋 Listar production batches',
          method: 'GET',
          path: '/api/v1/production-batches',
        },
        {
          name: '🔒 Intentar crear producto — esperado: 403',
          method: 'POST',
          path: '/api/v1/products',
          body: { sku, name, minPrice: 10.5, active: true },
          expect403: true,
        },
      ];

    case 'STOCK_MANAGER':
      return [
        listProducts,
        lowStock,
        getInventory1,
        {
          name: '📦 Ajustar stock del producto #1',
          method: 'POST',
          path: '/api/v1/inventory/1/adjust',
          body: { quantity: 5, reason: 'Test desde role-test-runner' },
        },
        {
          name: '🔒 Intentar crear producto — esperado: 403',
          method: 'POST',
          path: '/api/v1/products',
          body: { sku, name, minPrice: 10.5, active: true },
          expect403: true,
        },
      ];

    case 'CUSTOMER':
      return [
        listProducts,
        getProduct,
        {
          name: '🔒 Intentar crear producto — esperado: 403',
          method: 'POST',
          path: '/api/v1/products',
          body: { sku, name, minPrice: 10.5, active: true },
          expect403: true,
        },
        {
          name: '🔒 Intentar listar usuarios — esperado: 403',
          method: 'GET',
          path: '/api/v1/users',
          expect403: true,
        },
        {
          name: '🔒 Intentar crear venta — esperado: 403',
          method: 'POST',
          path: '/api/v1/sales',
          body: { productId: 1, quantity: 1 },
          expect403: true,
        },
      ];

    default:
      return [];
  }
}

// ──────────────────────────────────────────────
// Main
// ──────────────────────────────────────────────

async function main() {
  const email = process.argv[2];
  const password = process.argv[3] || '123456';

  if (!email) {
    console.error('Uso: node role-test-runner.js <email> [password]');
    process.exit(1);
  }

  const report = {
    testedAt: now(),
    user: email,
    login: null,
    actions: [],
    summary: { total: 0, passed: 0, failed: 0, forbiddenTests: 0, forbiddenPassed: 0, duration: 0 },
  };

  // ── 1. Login ──
  process.stderr.write(`🔑 LOGIN: ${email}... `);
  const loginRes = await api('POST', '/api/v1/auth/login', {
    email,
    password,
  });

  const loginOk = loginRes.status === 200;
  report.login = {
    status: loginRes.status,
    success: loginOk,
    duration: loginRes.duration,
    username: loginOk ? loginRes.data?.username : null,
    roles: loginOk ? loginRes.data?.roles : null,
    error: !loginOk ? (loginRes.data?.message || loginRes.error || `HTTP ${loginRes.status}`) : null,
  };

  if (!loginOk) {
    process.stderr.write(`❌ (HTTP ${loginRes.status})\n`);
    report.summary.duration = loginRes.duration;
    console.log(JSON.stringify(report, null, 2));
    process.exit(0);
  }

  const token = loginRes.data.accessToken;
  process.stderr.write(`✅ — ${loginRes.data.username} (roles: ${loginRes.data.roles?.join(', ')})\n`);

  // ── 2. Descubrir rol del usuario ──
  const userRoles = loginRes.data.roles || [];
  // Usamos el primer rol como principal para elegir acciones
  const primaryRole = userRoles[0] || 'UNKNOWN';
  const actions = getActions(primaryRole, {});

  process.stderr.write(`🎭 Rol detectado: ${primaryRole} — ${actions.length} acciones a ejecutar\n\n`);

  // ── 3. Ejecutar acciones ──
  const startedAt = Date.now();

  for (const action of actions) {
    process.stderr.write(`  ${action.name}... `);

    const result = await api(action.method, action.path, action.body, token);

    const isForbidden = action.expect403 === true;
    const actionOk = isForbidden ? result.status === 403 : result.status >= 200 && result.status < 300;
    const secPassed = isForbidden && result.status === 403;

    const entry = {
      name: action.name,
      method: action.method,
      path: action.path,
      status: result.status,
      duration: result.duration,
      success: actionOk,
      expected403: isForbidden,
      securityPassed: secPassed,
      summary: summarizeResponse(result),
    };

    report.actions.push(entry);
    report.summary.total++;
    if (isForbidden) report.summary.forbiddenTests++;
    if (secPassed) report.summary.forbiddenPassed++;
    if (actionOk) report.summary.passed++;
    else report.summary.failed++;

    if (actionOk) {
      process.stderr.write(`✅ (${result.status} — ${result.duration}ms)\n`);
    } else {
      process.stderr.write(`❌ (${result.status} — ${result.duration}ms)\n`);
    }
  }

  report.summary.duration = Date.now() - startedAt;

  // ── 4. Output final ──
  console.log(JSON.stringify(report, null, 2));
}

/** Resume una respuesta para el reporte */
function summarizeResponse(res) {
  if (!res.data) return res.error || 'Sin respuesta';
  if (typeof res.data === 'string') return res.data;
  if (Array.isArray(res.data)) return `${res.data.length} items`;
  if (res.data.message) return res.data.message;
  if (res.data.error) return res.data.error;
  const keys = Object.keys(res.data);
  if (keys.length === 0) return 'OK';
  return `${keys.slice(0, 4).join(', ')}${keys.length > 4 ? '…' : ''}`;
}

main().catch((err) => {
  console.error(JSON.stringify({ fatal: err.message }, null, 2));
  process.exit(1);
});
