// Envía notificación push a todos los dispositivos suscritos al topic
// 'app-updates' usando Firebase Admin SDK.
//
// Requiere la variable de entorno FIREBASE_SERVICE_ACCOUNT con el JSON
// de la service account key de Firebase (configurada como GitHub Secret).
//
// Uso:
//   node scripts/send-update-notification.js
//
// Salida:
//   Exit 0 — notificación enviada o variable no configurada (no bloqueante).
//   Exit 1 — error de parseo del JSON o error de FCM.

const admin = require('firebase-admin');

async function main() {
  // ── Validar variable de entorno ───────────────────────────────────────

  if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
    console.log(
      'FIREBASE_SERVICE_ACCOUNT no está configurada. ' +
        'Saliendo sin enviar notificación (no bloqueante).',
    );
    process.exit(0);
  }

  // ── Parsear service account ───────────────────────────────────────────

  let serviceAccount;
  try {
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  } catch (error) {
    console.error(
      'Error al parsear FIREBASE_SERVICE_ACCOUNT:',
      error.message,
    );
    process.exit(1);
  }

  // ── Inicializar Firebase Admin ────────────────────────────────────────

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  // ── Construir payload ────────────────────────────────────────────────

  const message = {
    topic: 'app-updates',
    notification: {
      title: 'MundoLimpio',
      body: '¡Nueva versión disponible! Actualizá la app para ver los últimos cambios.',
    },
    data: {
      type: 'app_update',
      url: 'market://details?id=com.mundolimpio.app',
    },
    android: {
      notification: {
        channelId: 'app_updates',
        icon: 'ic_notification',
        color: '#1E2238',
      },
    },
  };

  // ── Enviar notificación ──────────────────────────────────────────────

  try {
    const response = await admin.messaging().send(message);
    console.log('Notificación enviada:', response);
  } catch (error) {
    console.error('Error al enviar notificación:', error.message);
    process.exit(1);
  }
}

main();
