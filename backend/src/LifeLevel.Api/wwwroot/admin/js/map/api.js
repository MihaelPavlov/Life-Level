// Shared API helpers + token storage + toast.
// Exposed as window.MapAdmin.*

(function () {
  const TOKEN_KEY = 'll_admin_token';
  const BASE = '/api/admin/map';

  function getToken() {
    return localStorage.getItem(TOKEN_KEY) || '';
  }
  function setToken(t) {
    localStorage.setItem(TOKEN_KEY, t || '');
  }

  async function request(method, path, body) {
    const headers = { 'Content-Type': 'application/json' };
    const tok = getToken();
    if (tok) headers['Authorization'] = 'Bearer ' + tok;
    const res = await fetch(BASE + path, {
      method,
      headers,
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    if (res.status === 204) return null;
    const text = await res.text();
    const data = text ? JSON.parse(text) : null;
    if (!res.ok) {
      const msg = data?.error || data?.title || `${res.status} ${res.statusText}`;
      throw new Error(msg);
    }
    return data;
  }

  const api = {
    get:    (p)    => request('GET',    p),
    post:   (p, b) => request('POST',   p, b),
    put:    (p, b) => request('PUT',    p, b),
    delete: (p)    => request('DELETE', p),
  };

  let toastTimer = null;
  function toast(msg, type) {
    const el = document.getElementById('toast');
    if (!el) return;
    el.textContent = msg;
    el.className = 'show ' + (type === 'err' ? 'err' : 'ok');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => { el.className = ''; }, 3500);
  }

  function openModal(id) {
    const el = document.getElementById(id);
    if (el) el.classList.add('open');
  }
  function closeModal(id) {
    const el = document.getElementById(id);
    if (el) el.classList.remove('open');
  }

  function confirmDialog(title, message, okLabel) {
    return new Promise(resolve => {
      document.getElementById('confirmTitle').textContent = title;
      document.getElementById('confirmMessage').textContent = message;
      const btn = document.getElementById('confirmOkBtn');
      btn.textContent = okLabel || 'Delete';
      openModal('confirmModal');
      const onOk = () => { cleanup(); closeModal('confirmModal'); resolve(true); };
      const onCancel = () => { cleanup(); closeModal('confirmModal'); resolve(false); };
      const cancelBtn = document.querySelector('#confirmModal [data-close-modal="confirmModal"]');
      function cleanup() {
        btn.removeEventListener('click', onOk);
        cancelBtn.removeEventListener('click', onCancel);
      }
      btn.addEventListener('click', onOk);
      cancelBtn.addEventListener('click', onCancel);
    });
  }

  window.MapAdmin = {
    api,
    toast,
    openModal,
    closeModal,
    confirmDialog,
    getToken,
    setToken,
    state: {
      enums: null,       // { worldZoneTypes, regionThemes, ... }
      worlds: [],
      currentWorldId: null,
      regions: [],
      currentRegionId: null,
      zones: [],
      edges: [],
      editingZoneId: null, // for sub-CRUD (floors)
    },
  };
})();
