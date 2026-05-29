const BASE = 'https://mundo-limpio-backend.onrender.com/api/v1';

let TOKEN;

async function req(method, path, body) {
  const opts = { method, headers: { 'Content-Type': 'application/json' } };
  if (TOKEN) opts.headers['Authorization'] = `Bearer ${TOKEN}`;
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(`${BASE}${path}`, opts);
  const text = await res.text();
  let data;
  try { data = JSON.parse(text); } catch { data = text; }
  if (!res.ok) {
    const parsed = typeof data === 'object' ? JSON.stringify(data) : data;
    throw new Error(`HTTP ${res.status} on ${method} ${path}: ${parsed}`);
  }
  return data;
}

function pad(s, n) { return String(s).padEnd(n); }

function asArray(d) {
  if (Array.isArray(d)) return d;
  if (d && d.data) return Array.isArray(d.data) ? d.data : [d.data];
  if (d && d.content) return d.content;
  return [];
}

const reportLines = [];
function r(line) { reportLines.push(line); }

async function createOrGet(existing, items, factoryFn) {
  const result = {};
  for (const item of items) {
    const found = existing.find(e => e.name === item.name);
    if (found) {
      result[item.name] = found;
      r(`  (ya existía) ${item.name} → ID ${found.id}`);
    } else {
      const res = await factoryFn(item);
      result[item.name] = res;
      r(`  ✓ Creado: ${item.name} → ID ${res.id}`);
    }
  }
  return result;
}

async function main() {
  r('============================================================');
  r('  REPORTE — FLUJO DE PRODUCCIÓN');
  r('============================================================\n');

  // 1. Login
  r('## 1. Login');
  const loginRes = await req('POST', '/auth/login', {
    email: 'zotelsigel@gmail.com', password: '123456',
  });
  TOKEN = loginRes.accessToken || loginRes.data?.accessToken || loginRes.token;
  if (!TOKEN) throw new Error(`No token: ${JSON.stringify(loginRes)}`);
  r(`✓ Login OK. Token (primeros 20): ${TOKEN.slice(0, 20)}...\n`);

  // Fetch existing data
  r('## 2. Bulk Products');
  const existingBulk = asArray(await req('GET', '/bulk-products'));
  const bulkDefs = [
    { name: 'Base para Detergente',   currentStockLiters: 20,  costPerLiter: 2.5,  conversionRatio: 3.0,  active: true },
    { name: 'Cloro Concentrado',      currentStockLiters: 20,  costPerLiter: 1.8,  conversionRatio: 4.0,  active: true },
    { name: 'Esencia para Desodorante', currentStockLiters: 1, costPerLiter: 15.0, conversionRatio: 81.0, active: true },
    { name: 'Jabón Líquido Base',     currentStockLiters: 160, costPerLiter: 3.2,  conversionRatio: 1.0,  active: true },
  ];
  const bulkMap = await createOrGet(existingBulk, bulkDefs, item => req('POST', '/bulk-products', item));
  for (const b of Object.values(bulkMap)) {
    r(`     Stock: ${b.currentStockLiters}L | Costo: $${b.costPerLiter} | Ratio: ${b.conversionRatio}`);
  }

  r('\n## 3. Productos Terminados');
  const existingProds = asArray(await req('GET', '/products'));
  const prodDefs = [
    { sku: 'DETERGENTE-001',    name: 'Detergente',        minPrice: 15.0, active: true },
    { sku: 'LAVANDINA-001',     name: 'Lavandina',         minPrice: 12.0, active: true },
    { sku: 'DESODORANTE-001',   name: 'Desodorante para Piso', minPrice: 18.0, active: true },
    { sku: 'JABON-LIQUIDO-001', name: 'Jabón Líquido',     minPrice: 22.0, active: true },
  ];
  const prodMap = await createOrGet(existingProds, prodDefs, item => req('POST', '/products', item));
  for (const p of Object.values(prodMap)) {
    r(`     SKU: ${p.sku} | Precio min: $${p.minPrice}`);
  }

  r('\n## 4. Production Batches');
  const existingBatches = asArray(await req('GET', '/production-batches'));
  const batchDefs = [
    { bulk: 'Base para Detergente',   prod: 'Detergente',        qty: 20,  ratio: 3.0,  expected: '60L' },
    { bulk: 'Cloro Concentrado',      prod: 'Lavandina',         qty: 20,  ratio: 4.0,  expected: '80L' },
    { bulk: 'Esencia para Desodorante', prod: 'Desodorante para Piso', qty: 1, ratio: 81.0, expected: '81L' },
    { bulk: 'Jabón Líquido Base',     prod: 'Jabón Líquido',     qty: 160, ratio: 1.0,  expected: '160L' },
  ];
  const batchResults = [];
  for (const b of batchDefs) {
    const bulkId = bulkMap[b.bulk].id;
    const prodId = prodMap[b.prod].id;
    // Check if this exact batch already exists
    const exists = existingBatches.find(x =>
      x.bulkProductId === bulkId && x.productId === prodId &&
      Number(x.rawQuantityUsed) === b.qty
    );
    if (exists) {
      batchResults.push(exists);
      r(`  (ya existía) Batch #${exists.id}: ${b.qty}L ${b.bulk} → ${b.expected} ${b.prod}`);
      continue;
    }
    const res = await req('POST', '/production-batches', {
      bulkProductId: bulkId,
      productId: prodId,
      rawQuantityUsed: b.qty,
    });
    batchResults.push(res);
    r(`  ✓ Batch #${res.id}: ${b.qty}L ${b.bulk} → ${b.expected} ${b.prod}`);
  }

  r('\n## 5. Verificación');
  const finalBulk = asArray(await req('GET', '/bulk-products'));
  const finalProd = asArray(await req('GET', '/products'));
  const finalBatch = asArray(await req('GET', '/production-batches'));
  r(`✓ GET /bulk-products → ${finalBulk.length} items total`);
  r(`✓ GET /products → ${finalProd.length} items total`);
  r(`✓ GET /production-batches → ${finalBatch.length} items total`);

  // Verify our specific items exist
  const ourBulkNames = bulkDefs.map(b => b.name);
  const ourProdNames = prodDefs.map(p => p.name);
  const foundBulks = finalBulk.filter(b => ourBulkNames.includes(b.name)).length;
  const foundProds = finalProd.filter(p => ourProdNames.includes(p.name)).length;
  const foundBatches = finalBatch.filter(b =>
    batchResults.some(br => br.id === b.id)
  ).length;
  r(`✓ Nuestros bulk products: ${foundBulks}/4 encontrados`);
  r(`✓ Nuestros finished products: ${foundProds}/4 encontrados`);
  r(`✓ Nuestros batches: ${foundBatches}/${batchResults.length} encontrados`);

  r('\n============================================================');
  r('  RESUMEN');
  r('============================================================');
  r(`${pad('Producto', 25)} | ${pad('Bulk usado', 22)} | Cant. | Ratio | Obtenido`);
  r('-'.repeat(80));
  for (const b of batchDefs) {
    r(`${pad(b.prod, 25)} | ${pad(b.bulk, 22)} | ${String(b.qty).padStart(4)}L | ${String(b.ratio).padStart(4)} | ${b.expected}`);
  }
  r('');
  r('IDs de Bulk Products:');
  for (const b of Object.values(bulkMap)) {
    r(`  • ID ${String(b.id).padStart(2)}: ${b.name}`);
  }
  r('IDs de Finished Products:');
  for (const p of Object.values(prodMap)) {
    r(`  • ID ${String(p.id).padStart(2)}: ${p.name} (${p.sku})`);
  }
  r('IDs de Production Batches:');
  for (const br of batchResults) {
    r(`  • ID ${String(br.id).padStart(2)}: ${br.bulkProductName} → ${br.productName}`);
  }

  r('\n============================================================');
  r('  FLUJO COMPLETO EXITOSO');
  r('============================================================');

  return reportLines.join('\n');
}

main()
  .then(report => console.log(report))
  .catch(err => { console.error('\nERROR:', err.message); process.exit(1); });
