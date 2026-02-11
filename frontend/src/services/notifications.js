let permissionGranted = false;

export async function requestPermission() {
  if (!('Notification' in window)) return false;
  if (Notification.permission === 'granted') {
    permissionGranted = true;
    return true;
  }
  if (Notification.permission === 'denied') return false;

  const result = await Notification.requestPermission();
  permissionGranted = result === 'granted';
  return permissionGranted;
}

export function showNotification(title, body) {
  if (!permissionGranted || !document.hidden) return;

  new Notification(title, {
    body,
    icon: '/icons/icon-192.png',
    badge: '/icons/icon-192.png',
    tag: 'opencord-message',
  });
}
