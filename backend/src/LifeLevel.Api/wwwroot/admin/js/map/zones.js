// Zones CRUD + render + type-aware form.

(function () {
  const M = window.MapAdmin;
  let editingId = null;
  let editingZoneDraft = null; // full ZoneDetailDto after a save, used to enable floors editor

  async function load() {
    if (!M.state.currentRegionId) { clear(); return; }
    const region = M.state.regions.find(r => r.id === M.state.currentRegionId);
    document.getElementById('zonesTitle').textContent = 'Zones in «' + (region?.name ?? '?') + '»';
    document.getElementById('newZoneBtn').disabled = false;
    document.getElementById('toggleEdgesBtn').disabled = false;
    try {
      const zones = await M.api.get('/regions/' + M.state.currentRegionId + '/zones');
      M.state.zones = zones;
      render();
    } catch (e) {
      M.toast('Failed to load zones: ' + e.message, 'err');
    }
  }

  function clear() {
    document.getElementById('zonesTitle').textContent = 'Zones';
    document.getElementById('zonesList').innerHTML = '';
    document.getElementById('zonesEmpty').classList.remove('hidden');
    document.getElementById('newZoneBtn').disabled = true;
    document.getElementById('toggleEdgesBtn').disabled = true;
    document.getElementById('edgesSection').classList.add('hidden');
    M.state.zones = [];
  }

  function render() {
    const list = document.getElementById('zonesList');
    document.getElementById('zonesEmpty').classList.add('hidden');
    list.innerHTML = '';
    if (!M.state.zones.length) {
      list.innerHTML = '<div class="empty-state">No zones yet in this region.</div>';
      return;
    }
    for (const z of M.state.zones) {
      const row = document.createElement('div');
      row.className = 'zone-row';
      const tName = String(z.type); // API serializes enum as string: "Entry" / "Boss" / ...
      const metaBits = [];
      metaBits.push(`Lv ${z.levelRequirement}`);
      if (z.xpReward) metaBits.push(`${z.xpReward} XP`);
      if (z.distanceKm) metaBits.push(`${z.distanceKm} km`);
      if (tName === 'Chest' && z.chestRewardXp != null) metaBits.push(`Chest ${z.chestRewardXp} XP`);
      if (tName === 'Dungeon') metaBits.push(`${z.floorCount} floors`);
      if (tName === 'Boss') {
        if (z.bossSuppressExpiry) metaBits.push('No timer');
        else if (z.bossTimerDays) metaBits.push(`${z.bossTimerDays}d timer`);
      }
      if (z.isStartZone) metaBits.push('START');
      row.innerHTML = `
        <div class="tier">T${z.tier}</div>
        <div class="main">
          <span class="emoji">${escapeHtml(z.emoji || '•')}</span>
          <span>
            <div class="name">${escapeHtml(z.name)} <span class="badge badge-${tName}">${tName}</span></div>
            <div class="meta">${metaBits.join(' · ')}</div>
          </span>
        </div>
        <div></div>
        <div class="actions">
          <button class="sm secondary" data-edit="${z.id}">Edit</button>
          <button class="sm danger"    data-delete="${z.id}">Del</button>
        </div>`;
      row.querySelector('[data-edit]').addEventListener('click', () => openEdit(z.id));
      row.querySelector('[data-delete]').addEventListener('click', () => remove(z));
      list.appendChild(row);
    }
  }

  function openNew() {
    if (!M.state.currentRegionId) { M.toast('Select a region first', 'err'); return; }
    editingId = null;
    editingZoneDraft = null;
    document.getElementById('zoneModalTitle').textContent = 'New zone';
    fillForm({
      name: '', description: '', emoji: '',
      type: 0, tier: 1, levelRequirement: 1, xpReward: 0, distanceKm: 0,
      isStartZone: false, branchOfId: null,
      loreTotal: null, nodesTotal: null,
      chestRewardXp: null, chestRewardDescription: null,
      dungeonBonusXp: null,
      bossTimerDays: 0, bossSuppressExpiry: true,
      floors: [],
    });
    updateTypeVisibility();
    M.state.editingZoneId = null;
    refreshFloorsList([]);
    M.openModal('zoneModal');
  }

  async function openEdit(id) {
    editingId = id;
    try {
      const zone = await M.api.get('/zones/' + id);
      editingZoneDraft = zone;
      document.getElementById('zoneModalTitle').textContent = 'Edit zone';
      fillForm(zone);
      updateTypeVisibility();
      M.state.editingZoneId = id;
      refreshFloorsList(zone.floors || []);
      M.openModal('zoneModal');
    } catch (e) {
      M.toast(e.message, 'err');
    }
  }

  function fillForm(z) {
    fillEnumSelect('zoneTypeInput', 'worldZoneTypes', z.type);
    document.getElementById('zoneNameInput').value = z.name || '';
    document.getElementById('zoneEmojiInput').value = z.emoji || '';
    document.getElementById('zoneDescInput').value = z.description || '';
    document.getElementById('zoneTierInput').value = z.tier ?? 1;
    document.getElementById('zoneLevelInput').value = z.levelRequirement ?? 1;
    document.getElementById('zoneXpInput').value = z.xpReward ?? 0;
    document.getElementById('zoneDistanceInput').value = z.distanceKm ?? 0;
    document.getElementById('zoneStartInput').checked = !!z.isStartZone;
    document.getElementById('zoneLoreTotalInput').value = z.loreTotal ?? '';
    document.getElementById('zoneNodesTotalInput').value = z.nodesTotal ?? '';
    fillBranchSelect(z.id, z.branchOfId);

    document.getElementById('zoneChestXpInput').value = z.chestRewardXp ?? '';
    document.getElementById('zoneChestDescInput').value = z.chestRewardDescription ?? '';
    document.getElementById('zoneDungeonBonusInput').value = z.dungeonBonusXp ?? '';
    document.getElementById('zoneBossTimerInput').value = z.bossTimerDays ?? 0;
    document.getElementById('zoneBossSuppressInput').checked = z.bossSuppressExpiry !== false;
  }

  function fillBranchSelect(currentZoneId, currentBranchOfId) {
    const sel = document.getElementById('zoneBranchInput');
    sel.innerHTML = '<option value="">— none —</option>';
    for (const z of M.state.zones) {
      if (String(z.type) !== 'Crossroads') continue;
      if (z.id === currentZoneId) continue;
      const opt = document.createElement('option');
      opt.value = z.id;
      opt.textContent = (z.emoji || '•') + ' ' + z.name + '  (T' + z.tier + ')';
      if (z.id === currentBranchOfId) opt.selected = true;
      sel.appendChild(opt);
    }
  }

  function updateTypeVisibility() {
    const type = parseInt(document.getElementById('zoneTypeInput').value, 10);
    document.getElementById('typeEntryPanel').classList.toggle('active', type === 0);
    document.getElementById('typeStandardPanel').classList.toggle('active', type === 1);
    document.getElementById('typeCrossroadsPanel').classList.toggle('active', type === 2);
    document.getElementById('typeBossPanel').classList.toggle('active', type === 3);
    document.getElementById('typeChestPanel').classList.toggle('active', type === 4);
    document.getElementById('typeDungeonPanel').classList.toggle('active', type === 5);

    // Floors editor requires a saved zone (we need the zone id to post floors to).
    const unsaved = !M.state.editingZoneId;
    document.getElementById('floorsUnsavedWarn').classList.toggle('hidden', !unsaved);
    document.getElementById('addFloorBtn').disabled = unsaved;

    if (type === 3) updateBossPreview();
  }

  function updateBossPreview() {
    const tier = parseInt(document.getElementById('zoneTierInput').value || '1', 10);
    const chapter = currentRegionChapter();
    const hp = 500 * Math.max(chapter, 1) + 250 * Math.max(tier, 1);
    const xp = parseInt(document.getElementById('zoneXpInput').value || '0', 10);
    const timer = parseInt(document.getElementById('zoneBossTimerInput').value || '0', 10);
    const suppress = document.getElementById('zoneBossSuppressInput').checked;
    const timerTxt = suppress ? 'no timeout' : (timer > 0 ? timer + '-day timer' : 'no timeout (0 days)');
    const el = document.getElementById('bossPreview');
    if (el) el.innerHTML = `HP <b>${hp}</b> (chapter ${chapter} × 500 + tier ${tier} × 250) · <b>${xp}</b> XP on defeat · ${timerTxt}`;
  }

  function currentRegionChapter() {
    const r = M.state.regions.find(x => x.id === M.state.currentRegionId);
    return r?.chapterIndex || 1;
  }

  function readForm() {
    const branchRaw = document.getElementById('zoneBranchInput').value;
    const loreTotalRaw = document.getElementById('zoneLoreTotalInput').value;
    const nodesTotalRaw = document.getElementById('zoneNodesTotalInput').value;
    const chestXpRaw = document.getElementById('zoneChestXpInput').value;
    const dungeonBonusRaw = document.getElementById('zoneDungeonBonusInput').value;
    const bossTimerRaw = document.getElementById('zoneBossTimerInput').value;
    return {
      name: document.getElementById('zoneNameInput').value.trim(),
      description: document.getElementById('zoneDescInput').value || null,
      emoji: document.getElementById('zoneEmojiInput').value.trim(),
      type: parseInt(document.getElementById('zoneTypeInput').value, 10),
      tier: parseInt(document.getElementById('zoneTierInput').value || '1', 10),
      levelRequirement: parseInt(document.getElementById('zoneLevelInput').value || '1', 10),
      xpReward: parseInt(document.getElementById('zoneXpInput').value || '0', 10),
      distanceKm: parseFloat(document.getElementById('zoneDistanceInput').value || '0'),
      isStartZone: document.getElementById('zoneStartInput').checked,
      branchOfId: branchRaw || null,
      loreTotal: loreTotalRaw === '' ? null : parseInt(loreTotalRaw, 10),
      nodesTotal: nodesTotalRaw === '' ? null : parseInt(nodesTotalRaw, 10),
      chestRewardXp: chestXpRaw === '' ? null : parseInt(chestXpRaw, 10),
      chestRewardDescription: document.getElementById('zoneChestDescInput').value || null,
      dungeonBonusXp: dungeonBonusRaw === '' ? null : parseInt(dungeonBonusRaw, 10),
      bossTimerDays: bossTimerRaw === '' ? 0 : parseInt(bossTimerRaw, 10),
      bossSuppressExpiry: document.getElementById('zoneBossSuppressInput').checked,
    };
  }

  async function save() {
    const body = readForm();
    if (!body.name) { M.toast('Name is required', 'err'); return; }
    try {
      if (editingId) {
        await M.api.put('/zones/' + editingId, body);
        M.toast('Zone updated', 'ok');
      } else {
        const created = await M.api.post('/regions/' + M.state.currentRegionId + '/zones', body);
        editingId = created.id;
        M.state.editingZoneId = created.id;
        document.getElementById('zoneModalTitle').textContent = 'Edit zone';
        M.toast('Zone created', 'ok');
        updateTypeVisibility();
      }
      await load();
      // Keep modal open if it's a dungeon so the user can add floors.
      if (body.type !== 5) {
        M.closeModal('zoneModal');
      } else {
        // re-render floors list after potential save
        const zone = await M.api.get('/zones/' + editingId);
        refreshFloorsList(zone.floors || []);
      }
    } catch (e) {
      M.toast(e.message, 'err');
    }
  }

  async function remove(z) {
    const ok = await M.confirmDialog(
      'Delete zone?',
      `«${z.name}» — edges and dungeon floors will be deleted. Blocked if any user progress points to this zone.`,
      'Delete');
    if (!ok) return;
    try {
      await M.api.delete('/zones/' + z.id);
      M.toast('Zone deleted', 'ok');
      await load();
      MapAdminEdges.load();
    } catch (e) {
      M.toast(e.message, 'err');
    }
  }

  function refreshFloorsList(floors) {
    MapAdminFloors.render(floors);
  }

  function fillEnumSelect(elId, enumKey, currentValue) {
    const el = document.getElementById(elId);
    el.innerHTML = '';
    const opts = (M.state.enums?.[enumKey] || []);
    for (const o of opts) {
      const optEl = document.createElement('option');
      optEl.value = o.value;
      optEl.textContent = o.name;
      // Accept either the numeric enum value or the string name (API serializes enums as strings).
      if (o.value === currentValue || o.name === currentValue) optEl.selected = true;
      el.appendChild(optEl);
    }
  }

  function escapeHtml(s) { return (s ?? '').toString().replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }

  window.MapAdminZones = { load, clear, openNew, save, updateTypeVisibility };
})();
