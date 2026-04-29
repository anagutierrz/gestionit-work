// Gestión IT Marketing OS — Service Worker v1
const CACHE = 'gestionit-v1';
const OFFLINE_URL = '/';

// Install — cache shell
self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(c => c.addAll([OFFLINE_URL]))
  );
  self.skipWaiting();
});

// Activate — clean old caches
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// Fetch — network first, cache fallback
self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  if (e.request.url.includes('supabase.co')) return; // Never cache API calls
  e.respondWith(
    fetch(e.request)
      .then(res => {
        const clone = res.clone();
        caches.open(CACHE).then(c => c.put(e.request, clone));
        return res;
      })
      .catch(() => caches.match(e.request).then(r => r || caches.match(OFFLINE_URL)))
  );
});

// Push notification received
self.addEventListener('push', e => {
  let data = { title: 'Gestión IT', body: 'Tienes una notificación nueva', icon: '/icon-192.png' };
  try { data = { ...data, ...e.data.json() }; } catch(_) {}
  e.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.body,
      icon: data.icon || '/icon-192.png',
      badge: '/icon-192.png',
      tag: data.tag || 'gestionit',
      data: { url: data.url || '/' },
      vibrate: [100, 50, 100],
      requireInteraction: false,
    })
  );
});

// Notification click — open app
self.addEventListener('notificationclick', e => {
  e.notification.close();
  const url = e.notification.data?.url || '/';
  e.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(list => {
      const existing = list.find(c => c.url.includes(self.location.origin));
      if (existing) { existing.focus(); existing.navigate(url); }
      else clients.openWindow(url);
    })
  );
});

// Message from app — trigger local notification
self.addEventListener('message', e => {
  if (e.data?.type === 'NOTIFY') {
    self.registration.showNotification(e.data.title || 'Gestión IT', {
      body: e.data.body || '',
      icon: '/icon-192.png',
      tag: e.data.tag || 'local',
      data: { url: e.data.url || '/' },
      vibrate: [100, 50, 100],
    });
  }
});
