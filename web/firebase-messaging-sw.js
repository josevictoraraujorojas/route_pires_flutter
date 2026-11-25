// A configuração pública é passada pela URL ao registrar este worker.
const options = Object.fromEntries(new URL(self.location.href).searchParams);

// Registrar antes do Firebase para controlar a navegação ao tocar no alerta.
self.addEventListener('notificationclick', (event) => {
  const dados = event.notification.data?.FCM_MSG?.data;
  if (!dados) return;
  event.stopImmediatePropagation();
  event.notification.close();
  event.waitUntil((async () => {
    const paginas = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
    const pagina = paginas.find((client) => client.url.startsWith(self.registration.scope));
    if (pagina) {
      pagina.postMessage({ tipo: 'ROUTEPIRES_NOTIFICACAO', dados });
      await pagina.focus();
    } else {
      const url = new URL(self.registration.scope);
      url.searchParams.set('notificacao', JSON.stringify(dados));
      await self.clients.openWindow(url.href);
    }
  })());
});

importScripts('https://www.gstatic.com/firebasejs/13.1.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/13.1.0/firebase-messaging-compat.js');
if (options.apiKey && options.appId && options.messagingSenderId && options.projectId) {
  firebase.initializeApp(options);
  firebase.messaging();
}
