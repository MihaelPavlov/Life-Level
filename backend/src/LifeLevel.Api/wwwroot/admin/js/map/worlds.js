// Worlds CRUD + render.

(function () {
  const M = window.MapAdmin;
  let editingId = null;

  async function load() {
    try {
      const worlds = await M.api.get('/worlds');
      M.state.worlds = worlds;
      render();
    } catch (e) {
      M.toast('Failed to load worlds: ' + e.message, 'err');
    }
  }

  function render() {
    const grid = document.getElementById('worldsGrid');
    grid.innerHTML = '';
    if (!M.state.worlds.length) {
      grid.innerHTML = '<div class="empty-state">No worlds yet. Click "+ New world" to create one.</div>';
      return;
    }
    for (const w of M.state.worlds) {
      const el = document.createElement('div');
      el.className = 'card' + (w.id === M.state.currentWorldId ? ' selected' : '') + (w.isActive ? ' is-active' : '');
      el.innerHTML = `
        <div class="title">
          <span>${escapeHtml(w.name)}</span>
          ${w.isActive ? '<span class="active-tag">ACTIVE</span>' : ''}
        </div>
        <div class="sub">${w.regionCount} regions · ${w.zoneCount} zones</div>
        <div class="actions">
          <button class="sm secondary" data-edit="${w.id}">Edit</button>
          <button class="sm danger"    data-delete="${w.id}">Del</button>
        </div>`;
      el.addEventListener('click', ev => {
        if (ev.target.closest('button')) return;
        select(w.id);
      });
      el.querySelector('[data-edit]').addEventListener('click', () => openEdit(w));
      el.querySelector('[data-delete]').addEventListener('click', () => remove(w));
      grid.appendChild(el);
    }
  }

  function select(id) {
    M.state.currentWorldId = id;
    M.state.currentRegionId = null;
    M.state.regions = [];
    M.state.zones = [];
    M.state.edges = [];
    render();
    MapAdminRegions.load();
    MapAdminZones.clear();
    MapAdminEdges.clear();
  }

  function openNew() {
    editingId = null;
    document.getElementById('worldModalTitle').textContent = 'New world';
    document.getElementById('worldNameInput').value = '';
    document.getElementById('worldActiveInput').checked = false;
    M.openModal('worldModal');
  }

  function openEdit(world) {
    editingId = world.id;
    document.getElementById('worldModalTitle').textContent = 'Edit world';
    document.getElementById('worldNameInput').value = world.name;
    document.getElementById('worldActiveInput').checked = world.isActive;
    M.openModal('worldModal');
  }

  async function save() {
    const body = {
      name: document.getElementById('worldNameInput').value.trim(),
      isActive: document.getElementById('worldActiveInput').checked,
    };
    if (!body.name) { M.toast('Name is required', 'err'); return; }
    try {
      if (editingId) {
        await M.api.put('/worlds/' + editingId, body);
        M.toast('World updated', 'ok');
      } else {
        await M.api.post('/worlds', body);
        M.toast('World created', 'ok');
      }
      M.closeModal('worldModal');
      await load();
    } catch (e) {
      M.toast(e.message, 'err');
    }
  }

  async function remove(world) {
    const ok = await M.confirmDialog(
      'Delete world?',
      `«${world.name}» — this will fail if it has regions or user progress.`,
      'Delete');
    if (!ok) return;
    try {
      await M.api.delete('/worlds/' + world.id);
      M.toast('World deleted', 'ok');
      if (M.state.currentWorldId === world.id) {
        M.state.currentWorldId = null;
        MapAdminRegions.clear();
        MapAdminZones.clear();
        MapAdminEdges.clear();
      }
      await load();
    } catch (e) {
      M.toast(e.message, 'err');
    }
  }

  function escapeHtml(s) { return (s ?? '').toString().replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }

  window.MapAdminWorlds = { load, openNew, save };
})();
