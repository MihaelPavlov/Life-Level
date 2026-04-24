// Regions CRUD + render.

(function () {
  const M = window.MapAdmin;
  let editingId = null;

  async function load() {
    if (!M.state.currentWorldId) { clear(); return; }
    const world = M.state.worlds.find(w => w.id === M.state.currentWorldId);
    document.getElementById('regionsTitle').textContent = 'Regions in «' + (world?.name ?? '?') + '»';
    document.getElementById('newRegionBtn').disabled = false;
    try {
      const regions = await M.api.get('/worlds/' + M.state.currentWorldId + '/regions');
      M.state.regions = regions;
      render();
    } catch (e) {
      M.toast('Failed to load regions: ' + e.message, 'err');
    }
  }

  function clear() {
    document.getElementById('regionsTitle').textContent = 'Regions';
    document.getElementById('regionsGrid').innerHTML = '';
    document.getElementById('regionsEmpty').classList.remove('hidden');
    document.getElementById('newRegionBtn').disabled = true;
    M.state.regions = [];
  }

  function render() {
    const grid = document.getElementById('regionsGrid');
    document.getElementById('regionsEmpty').classList.add('hidden');
    grid.innerHTML = '';
    if (!M.state.regions.length) {
      grid.innerHTML = '<div class="empty-state">No regions yet in this world.</div>';
      return;
    }
    for (const r of M.state.regions) {
      const el = document.createElement('div');
      el.className = 'card' + (r.id === M.state.currentRegionId ? ' selected' : '');
      el.innerHTML = `
        <div class="title">
          <span>${escapeHtml(r.emoji)} ${escapeHtml(r.name)}</span>
        </div>
        <div class="sub">Ch.${r.chapterIndex} · Lv ${r.levelRequirement} · ${r.zoneCount} zones</div>
        <div class="actions">
          <button class="sm secondary" data-edit="${r.id}">Edit</button>
          <button class="sm danger"    data-delete="${r.id}">Del</button>
        </div>`;
      el.addEventListener('click', ev => {
        if (ev.target.closest('button')) return;
        select(r.id);
      });
      el.querySelector('[data-edit]').addEventListener('click', () => openEdit(r));
      el.querySelector('[data-delete]').addEventListener('click', () => remove(r));
      grid.appendChild(el);
    }
  }

  function select(id) {
    M.state.currentRegionId = id;
    render();
    MapAdminZones.load();
    MapAdminEdges.load();
  }

  function openNew() {
    if (!M.state.currentWorldId) { M.toast('Select a world first', 'err'); return; }
    editingId = null;
    document.getElementById('regionModalTitle').textContent = 'New region';
    fillForm({
      name: '', emoji: '',
      theme: enumFirstValue('regionThemes'),
      chapterIndex: 1, levelRequirement: 1, lore: '', bossName: '',
      bossStatus: enumFirstValue('regionBossStatuses'),
      defaultStatus: enumFirstValue('regionStatuses'),
      pins: [],
    });
    M.openModal('regionModal');
  }

  async function openEdit(regionSummary) {
    editingId = regionSummary.id;
    try {
      const region = await M.api.get('/regions/' + regionSummary.id);
      document.getElementById('regionModalTitle').textContent = 'Edit region';
      fillForm(region);
      M.openModal('regionModal');
    } catch (e) {
      M.toast(e.message, 'err');
    }
  }

  function fillForm(r) {
    fillEnumSelect('regionThemeInput',       'regionThemes',       r.theme);
    fillEnumSelect('regionBossStatusInput',  'regionBossStatuses', r.bossStatus);
    fillEnumSelect('regionDefaultStatusInput','regionStatuses',    r.defaultStatus);
    document.getElementById('regionNameInput').value = r.name || '';
    document.getElementById('regionEmojiInput').value = r.emoji || '';
    document.getElementById('regionChapterInput').value = r.chapterIndex ?? 1;
    document.getElementById('regionLevelInput').value = r.levelRequirement ?? 1;
    document.getElementById('regionLoreInput').value = r.lore || '';
    document.getElementById('regionBossNameInput').value = r.bossName || '';
    document.getElementById('regionPinsInput').value = JSON.stringify(r.pins || [], null, 2);
  }

  function readForm() {
    const pinsRaw = document.getElementById('regionPinsInput').value.trim();
    let pins = [];
    if (pinsRaw) {
      try { pins = JSON.parse(pinsRaw); } catch { throw new Error('Pins must be valid JSON'); }
      if (!Array.isArray(pins)) throw new Error('Pins must be a JSON array');
    }
    return {
      name: document.getElementById('regionNameInput').value.trim(),
      emoji: document.getElementById('regionEmojiInput').value.trim(),
      theme: readEnumValue('regionThemeInput'),
      chapterIndex: parseInt(document.getElementById('regionChapterInput').value || '1', 10),
      levelRequirement: parseInt(document.getElementById('regionLevelInput').value || '1', 10),
      lore: document.getElementById('regionLoreInput').value,
      bossName: document.getElementById('regionBossNameInput').value,
      bossStatus: readEnumValue('regionBossStatusInput'),
      defaultStatus: readEnumValue('regionDefaultStatusInput'),
      pins,
    };
  }

  async function save() {
    let body;
    try { body = readForm(); } catch (e) { M.toast(e.message, 'err'); return; }
    if (!body.name) { M.toast('Name is required', 'err'); return; }
    try {
      if (editingId) {
        await M.api.put('/regions/' + editingId, body);
        M.toast('Region updated', 'ok');
      } else {
        await M.api.post('/worlds/' + M.state.currentWorldId + '/regions', body);
        M.toast('Region created', 'ok');
      }
      M.closeModal('regionModal');
      await load();
    } catch (e) {
      M.toast(e.message, 'err');
    }
  }

  async function remove(r) {
    const ok = await M.confirmDialog(
      'Delete region?',
      `«${r.name}» — this will fail if it has zones.`,
      'Delete');
    if (!ok) return;
    try {
      await M.api.delete('/regions/' + r.id);
      M.toast('Region deleted', 'ok');
      if (M.state.currentRegionId === r.id) {
        M.state.currentRegionId = null;
        MapAdminZones.clear();
        MapAdminEdges.clear();
      }
      await load();
    } catch (e) {
      M.toast(e.message, 'err');
    }
  }

  function fillEnumSelect(elId, enumKey, currentValue) {
    const el = document.getElementById(elId);
    el.innerHTML = '';
    const opts = (M.state.enums?.[enumKey] || []);
    for (const o of opts) {
      const optEl = document.createElement('option');
      optEl.value = o.value;
      optEl.textContent = o.name;
      if (o.value === currentValue || o.name === currentValue) optEl.selected = true;
      el.appendChild(optEl);
    }
  }
  function readEnumValue(elId) {
    const v = document.getElementById(elId).value;
    return parseInt(v, 10);
  }
  function enumFirstValue(key) {
    return (M.state.enums?.[key]?.[0]?.value) ?? 0;
  }
  function escapeHtml(s) { return (s ?? '').toString().replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }

  window.MapAdminRegions = { load, clear, openNew, save };
})();
