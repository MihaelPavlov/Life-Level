// Bootstrap: load enums, wire buttons, pull initial data.

(function () {
  const M = window.MapAdmin;

  document.addEventListener('DOMContentLoaded', async () => {
    // Token input wiring.
    const tokenInput = document.getElementById('tokenInput');
    tokenInput.value = M.getToken();
    document.getElementById('tokenSaveBtn').addEventListener('click', () => {
      M.setToken(tokenInput.value.trim());
      M.toast('Token saved', 'ok');
      boot();
    });

    // Modal close buttons.
    document.querySelectorAll('[data-close-modal]').forEach(btn => {
      btn.addEventListener('click', () => M.closeModal(btn.getAttribute('data-close-modal')));
    });

    // Header buttons.
    document.getElementById('newWorldBtn').addEventListener('click', () => MapAdminWorlds.openNew());
    document.getElementById('newRegionBtn').addEventListener('click', () => MapAdminRegions.openNew());
    document.getElementById('newZoneBtn').addEventListener('click', () => MapAdminZones.openNew());
    document.getElementById('toggleEdgesBtn').addEventListener('click', () => MapAdminEdges.toggle());
    document.getElementById('newEdgeBtn').addEventListener('click', () => MapAdminEdges.openNew());
    document.getElementById('addFloorBtn').addEventListener('click', () => MapAdminFloors.openNew());

    // Save buttons.
    document.getElementById('worldSaveBtn').addEventListener('click', () => MapAdminWorlds.save());
    document.getElementById('regionSaveBtn').addEventListener('click', () => MapAdminRegions.save());
    document.getElementById('zoneSaveBtn').addEventListener('click', () => MapAdminZones.save());
    document.getElementById('floorSaveBtn').addEventListener('click', () => MapAdminFloors.save());
    document.getElementById('edgeSaveBtn').addEventListener('click', () => MapAdminEdges.save());

    // Zone type change re-renders conditional fieldsets.
    document.getElementById('zoneTypeInput').addEventListener('change', () => {
      MapAdminZones.updateTypeVisibility();
    });
    // Live-update the Boss HP/XP/timer preview as related inputs change.
    ['zoneTierInput','zoneXpInput','zoneBossTimerInput','zoneBossSuppressInput'].forEach(id => {
      document.getElementById(id).addEventListener('input', () => MapAdminZones.updateTypeVisibility());
      document.getElementById(id).addEventListener('change', () => MapAdminZones.updateTypeVisibility());
    });

    boot();
  });

  // Expose boot globally so the base-URL switcher can re-run it without a full reload.
  window.MapAdminBoot = boot;

  async function fetchAdminConfig() {
    try {
      const res = await fetch(M.getBaseUrl() + '/api/admin/config');
      if (!res.ok) return null;
      return await res.json();
    } catch {
      return null;
    }
  }

  async function devLogin(email, password) {
    try {
      const res = await fetch(M.getBaseUrl() + '/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });
      if (!res.ok) return false;
      const data = await res.json();
      const token = data?.token;
      if (!token) return false;
      M.setToken(token);
      document.getElementById('tokenInput').value = token;
      return true;
    } catch {
      return false;
    }
  }

  async function tryEnums() {
    try {
      M.state.enums = await M.api.get('/enums');
      return true;
    } catch {
      return false;
    }
  }

  async function boot() {
    // 1) Try whatever token is already in localStorage.
    if (M.getToken() && await tryEnums()) {
      await MapAdminWorlds.load();
      return;
    }
    // 2) Stale or missing — fetch credentials from the target API and auto-login.
    M.setToken('');
    const cfg = await fetchAdminConfig();
    if (cfg) {
      const loggedIn = await devLogin(cfg.email, cfg.password);
      if (loggedIn && await tryEnums()) {
        await MapAdminWorlds.load();
        return;
      }
    }
    M.toast('Auto-login failed — paste an Admin JWT manually and click Save.', 'err');
  }
})();
