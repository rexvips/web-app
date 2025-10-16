// Service Worker for Daily Routine App
// Provides offline functionality and caching

const CACHE_NAME = 'daily-routine-v1.0.0';
const urlsToCache = [
  '/',
  '/index.html',
  '/styles.css',
  '/app.js',
  '/manifest.json',
  '/icons/icon-192x192.png',
  '/icons/icon-512x512.png'
];

// Install event - cache resources
self.addEventListener('install', (event) => {
  console.log('Service Worker: Installing...');
  
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('Service Worker: Caching files');
        return cache.addAll(urlsToCache);
      })
      .then(() => {
        console.log('Service Worker: Installed successfully');
        return self.skipWaiting();
      })
      .catch((error) => {
        console.error('Service Worker: Installation failed', error);
      })
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('Service Worker: Activating...');
  
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            console.log('Service Worker: Deleting old cache', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    })
    .then(() => {
      console.log('Service Worker: Activated successfully');
      return self.clients.claim();
    })
  );
});

// Fetch event - serve cached content when offline
self.addEventListener('fetch', (event) => {
  // Skip non-GET requests
  if (event.request.method !== 'GET') {
    return;
  }
  
  // Skip chrome-extension requests
  if (event.request.url.startsWith('chrome-extension://')) {
    return;
  }
  
  event.respondWith(
    caches.match(event.request)
      .then((response) => {
        // Return cached version or fetch from network
        if (response) {
          console.log('Service Worker: Serving from cache', event.request.url);
          return response;
        }
        
        console.log('Service Worker: Fetching from network', event.request.url);
        return fetch(event.request)
          .then((response) => {
            // Don't cache non-successful responses
            if (!response || response.status !== 200 || response.type !== 'basic') {
              return response;
            }
            
            // Clone the response
            const responseToCache = response.clone();
            
            // Add to cache for future use
            caches.open(CACHE_NAME)
              .then((cache) => {
                cache.put(event.request, responseToCache);
              });
            
            return response;
          })
          .catch((error) => {
            console.error('Service Worker: Fetch failed', error);
            
            // Return offline page for navigation requests
            if (event.request.destination === 'document') {
              return caches.match('/index.html');
            }
            
            throw error;
          });
      })
  );
});

// Background sync for meditation data
self.addEventListener('sync', (event) => {
  console.log('Service Worker: Background sync', event.tag);
  
  if (event.tag === 'meditation-sync') {
    event.waitUntil(
      syncMeditationData()
    );
  }
});

// Sync meditation data when online
async function syncMeditationData() {
  try {
    // Get stored meditation sessions
    const sessions = await getStoredMeditationSessions();
    
    if (sessions.length > 0) {
      console.log('Service Worker: Syncing meditation data', sessions.length, 'sessions');
      
      // Here you would typically send to your backend API
      // For now, we'll just log it
      console.log('Meditation sessions to sync:', sessions);
      
      // Clear synced sessions from storage
      await clearSyncedSessions();
    }
  } catch (error) {
    console.error('Service Worker: Sync failed', error);
  }
}

// Helper function to get stored sessions
function getStoredMeditationSessions() {
  return new Promise((resolve) => {
    // This would typically read from IndexedDB
    // For simplicity, we'll simulate it
    resolve([]);
  });
}

// Helper function to clear synced sessions
function clearSyncedSessions() {
  return new Promise((resolve) => {
    // This would typically clear from IndexedDB
    resolve();
  });
}

// Push notification handler
self.addEventListener('push', (event) => {
  console.log('Service Worker: Push notification received');
  
  const data = event.data ? event.data.json() : {};
  const title = data.title || 'Daily Routine Reminder';
  const options = {
    body: data.body || 'Time for your meditation session!',
    icon: '/icons/icon-192x192.png',
    badge: '/icons/icon-72x72.png',
    vibrate: [200, 100, 200],
    data: {
      url: data.url || '/'
    },
    actions: [
      {
        action: 'start-meditation',
        title: 'Start Meditation',
        icon: '/icons/icon-96x96.png'
      },
      {
        action: 'dismiss',
        title: 'Dismiss'
      }
    ]
  };
  
  event.waitUntil(
    self.registration.showNotification(title, options)
  );
});

// Notification click handler
self.addEventListener('notificationclick', (event) => {
  console.log('Service Worker: Notification clicked', event.action);
  
  event.notification.close();
  
  if (event.action === 'start-meditation') {
    // Open app to meditation tab
    event.waitUntil(
      self.clients.openWindow('/?tab=meditation')
    );
  } else if (event.action === 'dismiss') {
    // Just close the notification
    return;
  } else {
    // Default action - open the app
    event.waitUntil(
      self.clients.openWindow(event.notification.data.url || '/')
    );
  }
});

// Message handler for communication with main app
self.addEventListener('message', (event) => {
  console.log('Service Worker: Message received', event.data);
  
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  
  if (event.data && event.data.type === 'GET_VERSION') {
    event.ports[0].postMessage({ version: CACHE_NAME });
  }
});

// Periodic background sync (if supported)
if ('periodicSync' in self.registration) {
  self.addEventListener('periodicsync', (event) => {
    console.log('Service Worker: Periodic sync', event.tag);
    
    if (event.tag === 'daily-reminder') {
      event.waitUntil(
        scheduleLocalNotification()
      );
    }
  });
}

// Schedule local notification for meditation reminder
async function scheduleLocalNotification() {
  try {
    const permission = await self.registration.showNotification('Daily Meditation Reminder', {
      body: 'Take a moment to breathe and center yourself.',
      icon: '/icons/icon-192x192.png',
      badge: '/icons/icon-72x72.png',
      vibrate: [200, 100, 200],
      tag: 'daily-reminder',
      requireInteraction: false,
      actions: [
        {
          action: 'start-meditation',
          title: 'Start Now'
        }
      ]
    });
    
    console.log('Service Worker: Local notification scheduled');
  } catch (error) {
    console.error('Service Worker: Failed to schedule notification', error);
  }
}