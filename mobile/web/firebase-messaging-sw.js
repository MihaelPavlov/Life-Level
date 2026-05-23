importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyC6CEa41xuKE9Cc7RT9vFoIS3F3xJbZZpc",
  authDomain: "life-level-ae77f.firebaseapp.com",
  projectId: "life-level-ae77f",
  storageBucket: "life-level-ae77f.firebasestorage.app",
  messagingSenderId: "734427785844",
  appId: "1:734427785844:web:8a18ad08a59a403fd0ff21",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = (payload.notification && payload.notification.title) || payload.data.title || 'Life Level';
  const body  = (payload.notification && payload.notification.body)  || payload.data.body  || '';
  self.registration.showNotification(title, { body });
});
