// JoyMini PWA Service Worker
// Handles: offline fallback, asset caching, SW update lifecycle
// Note: Flutter's flutter_service_worker.js handles Flutter asset caching.
//       This SW handles the offline fallback page & app shell caching.
//       Firebase messaging uses its own scope: /firebase-cloud-messaging-push-scope

const CACHE_NAME = 'joymini-shell-v1';
const OFFLINE_URL = '/offline.html';

// App shell resources to pre-cache on install
const PRECACHE_URLS = [
    '/',
    '/offline.html',
    '/manifest.json',
    '/favicon.png',
    '/icons/Icon-192.png',
    '/icons/Icon-512.png',
    '/icons/Icon-maskable-192.png',
    '/icons/Icon-maskable-512.png',
    '/app_icon.png',
];

// ── Install: pre-cache app shell ──────────────────────────────────────────────
self.addEventListener('install', (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME).then((cache) => {
            console.log('[SW] Pre-caching app shell');
            return cache.addAll(PRECACHE_URLS);
        }).then(() => self.skipWaiting())
    );
});

// ── Activate: clean up old caches ─────────────────────────────────────────────
self.addEventListener('activate', (event) => {
    event.waitUntil(
        caches.keys().then((cacheNames) => {
            return Promise.all(
                cacheNames
                    .filter((name) => name !== CACHE_NAME && name.startsWith('joymini-'))
                    .map((name) => {
                        console.log('[SW] Deleting old cache:', name);
                        return caches.delete(name);
                    })
            );
        }).then(() => self.clients.claim())
    );
});

// ── Fetch: Network-first with offline fallback ────────────────────────────────
self.addEventListener('fetch', (event) => {
    // Only handle GET requests
    if (event.request.method !== 'GET') return;

    const url = new URL(event.request.url);

    // Skip cross-origin requests
    if (url.origin !== self.location.origin) return;

    // Skip Flutter's own service worker to avoid conflicts
    if (url.pathname.includes('flutter_service_worker')) return;

    // Skip Firebase messaging scope
    if (url.pathname.includes('firebase-cloud-messaging')) return;

    // For navigation requests: network-first, fallback to offline page
    if (event.request.mode === 'navigate') {
        event.respondWith(
            fetch(event.request).catch(() => {
                return caches.match(OFFLINE_URL);
            })
        );
        return;
    }

    // For icons/images in cache: cache-first
    if (
        url.pathname.startsWith('/icons/') ||
        url.pathname === '/favicon.png' ||
        url.pathname === '/app_icon.png'
    ) {
        event.respondWith(
            caches.match(event.request).then((cached) => {
                return cached || fetch(event.request).then((response) => {
                    if (response.ok) {
                        const clone = response.clone();
                        caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
                    }
                    return response;
                });
            })
        );
        return;
    }

    // Everything else: network-first (let Flutter's SW handle Flutter assets)
});

// ── Push Notifications (delegate to Firebase SW) ─────────────────────────────
// Firebase messaging is registered at its own scope, no handling needed here.

