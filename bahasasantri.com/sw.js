const CACHE_NAME = 'bahasasantri-v6';
const STATIC_CACHE = 'static-v6';
const DYNAMIC_CACHE = 'dynamic-v6';

// Static assets - cached on install
const STATIC_ASSETS = [
    './',
    './index.html',
    './css/styles.css',
    './js/app.js',
    './js/config.js',
    './js/state.js',
    './js/ui.js',
    './js/audio.js',
    './js/quiz.js',
    './js/admin.js',
    './js/math.js',
    './images/icon-512.png',
    'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css',
    'https://cdn.jsdelivr.net/npm/canvas-confetti@1.6.0/dist/confetti.browser.min.js'
];

// ========================================
// INSTALL EVENT
// ========================================
self.addEventListener('install', (event) => {
    console.log('[SW] Installing new version...');
    event.waitUntil(
        caches.open(STATIC_CACHE)
            .then((cache) => cache.addAll(STATIC_ASSETS))
            .then(() => self.skipWaiting()) // Activate immediately
    );
});

// ========================================
// ACTIVATE EVENT
// ========================================
self.addEventListener('activate', (event) => {
    console.log('[SW] Activating new version...');
    event.waitUntil(
        caches.keys().then((cacheNames) => {
            return Promise.all(
                cacheNames.map((key) => {
                    // Delete old caches
                    if (key !== STATIC_CACHE && key !== DYNAMIC_CACHE) {
                        console.log('[SW] Deleting old cache:', key);
                        return caches.delete(key);
                    }
                })
            );
        }).then(() => self.clients.claim()) // Take control immediately
    );
});

// ========================================
// FETCH EVENT - Smart Caching Strategy
// ========================================
self.addEventListener('fetch', (event) => {
    const url = new URL(event.request.url);

    // Skip non-GET requests
    if (event.request.method !== 'GET') return;

    // Firebase/API requests: Network First with Cache Fallback
    if (url.hostname.includes('firebaseio') ||
        url.hostname.includes('googleapis') ||
        url.hostname.includes('firestore')) {
        event.respondWith(networkFirstStrategy(event.request));
        return;
    }

    // Static assets: Cache First
    if (STATIC_ASSETS.some(asset => event.request.url.includes(asset.replace('./', '')))) {
        event.respondWith(cacheFirstStrategy(event.request));
        return;
    }

    // Everything else: Stale While Revalidate
    event.respondWith(staleWhileRevalidate(event.request));
});

// ========================================
// CACHING STRATEGIES
// ========================================

// Cache First - Fast for static assets
async function cacheFirstStrategy(request) {
    const cached = await caches.match(request);
    if (cached) return cached;

    try {
        const response = await fetch(request);
        if (response.ok) {
            const cache = await caches.open(STATIC_CACHE);
            cache.put(request, response.clone());
        }
        return response;
    } catch (e) {
        console.log('[SW] Cache first failed, returning offline page');
        return new Response('Offline', { status: 503 });
    }
}

// Network First - Fresh data, fallback to cache
async function networkFirstStrategy(request) {
    try {
        const response = await fetch(request);
        // Cache successful API responses
        if (response.ok) {
            const cache = await caches.open(DYNAMIC_CACHE);
            cache.put(request, response.clone());
        }
        return response;
    } catch (e) {
        // Fall back to cache
        const cached = await caches.match(request);
        if (cached) {
            console.log('[SW] Serving from cache:', request.url);
            return cached;
        }
        return new Response(JSON.stringify({ error: 'offline' }), {
            status: 503,
            headers: { 'Content-Type': 'application/json' }
        });
    }
}

// Stale While Revalidate - Fast + Fresh
async function staleWhileRevalidate(request) {
    const cache = await caches.open(DYNAMIC_CACHE);
    const cached = await cache.match(request);

    const fetchPromise = fetch(request).then((response) => {
        if (response.ok) {
            cache.put(request, response.clone());
        }
        return response;
    }).catch(() => {
        // If fetch fails and no cache, return offline
        if (!cached) {
            return new Response('Offline', { status: 503 });
        }
    });

    // Return cached if available, otherwise wait for network
    return cached || fetchPromise;
}

// ========================================
// MESSAGE HANDLING (for vocab caching)
// ========================================
self.addEventListener('message', (event) => {
    if (event.data && event.data.type === 'CACHE_VOCAB') {
        const vocab = event.data.vocab;
        caches.open(DYNAMIC_CACHE).then((cache) => {
            // Store vocab as a special JSON response
            const response = new Response(JSON.stringify(vocab), {
                headers: { 'Content-Type': 'application/json' }
            });
            cache.put('/vocab-cache', response);
            console.log('[SW] Vocab cached for offline use');
        });
    }

    if (event.data && event.data.type === 'GET_CACHED_VOCAB') {
        caches.open(DYNAMIC_CACHE).then(async (cache) => {
            const cached = await cache.match('/vocab-cache');
            if (cached) {
                const vocab = await cached.json();
                event.source.postMessage({ type: 'VOCAB_FROM_CACHE', vocab });
            }
        });
    }
});
