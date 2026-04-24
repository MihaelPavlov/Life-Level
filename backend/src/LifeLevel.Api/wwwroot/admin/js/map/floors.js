// Dungeon floors CRUD (nested inside the zone modal).

(function () {
  const M = window.MapAdmin;
  let editingId = null;

  function render(floors) {
    const list = document.getElementById('floorsList');
    list.innerHTML = '';
    if (!floors.length) {
      list.innerHTML = '<div class="floors-empty">No floors yet. Save the zone first, then add floors.</div>';
      return;
    }
    const table = document.createElement('table');
    table.className = 'floors-table';
    table.innerHTML = `
      <thead><tr><th>#</th><th>Name</th><th>Activity</th><th>Target</th><th></th></tr></thead>
      <tbody></tbody>`;
    const tb = table.querySelector('tbody');
    const activityName = v => String(v);
    const isKmTarget = v => String(v) === 'DistanceKm';
    const sorted = [...floors].sort((a,b) => a.ordinal - b.ordinal);
    sorted.forEach((f, idx) => {
      const tr = document.createElement('tr');
      const target = isKmTarget(f.targetKind)
        ? f.targetValue + ' km'
        : f.targetValue + ' min';
      const canUp = idx > 0;
      const canDown = idx < sorted.length - 1;
      tr.innerHTML = `
        <td>${f.ordinal}</td>
        <td>${escapeHtml(f.emoji || '•')} ${escapeHtml(f.name)}</td>
        <td>${activityName(f.activityType)}</td>
        <td>${target}</td>
        <td style="text-align:right; white-space:nowrap;">
          <button class="sm secondary" data-up="${f.id}" ${canUp ? '' : 'disabled'}>↑</button>
          <button class="sm secondary" data-down="${f.id}" ${canDown ? '' : 'disabled'}>↓</button>
          <button class="sm secondary" data-edit="${f.id}">Edit</button>
          <button class="sm danger"    data-delete="${f.id}">Del</button>
        </td>`;
      tr.querySelector('[data-edit]').addEventListener('click', () => openEdit(f));
      tr.querySelector('[data-delete]').addEventListener('click', () => remove(f));
      if (canUp)   tr.querySelector('[data-up]').addEventListener('click',   () => swap(sorted, idx, idx - 1));
      if (canDown) tr.querySelector('[data-down]').addEventListener('click', () => swap(sorted, idx, idx + 1));
      tb.appendChild(tr);
    });
    list.appendChild(table);
  }

  function openNew() {
    if (!M.state.editingZoneId) { M.toast('Save the zone first', 'err'); return; }
    editingId = null;
    document.getElementById('floorModalTitle').textContent = 'Add floor';
    // suggest next ordinal
    const list = document.getElementById('floorsList');
    const existing = list.querySelectorAll('tbody tr').length;
    document.getElementById('floorOrdinalInput').value = existing + 1;
    document.getElementById('floorNameInput').value = '';
    document.getElementById('floorEmojiInput').value = '';
    document.getElementById('floorTargetValueInput').value = '';
    fillEnumSelect('floorActivityInput', 'activityTypes', null);
    fillEnumSelect('floorTargetKindInput', 'dungeonFloorTargetKinds', null);
    M.openModal('floorModal');
  }

  function openEdit(f) {
    editingId = f.id;
    document.getElementById('floorModalTitle').textContent = 'Edit floor';
    document.getElementById('floorOrdinalInput').value = f.ordinal;
    document.getElementById('floorNameInput').value = f.name || '';
    document.getElementById('floorEmojiInput').value = f.emoji || '';
    document.getElementById('floorTargetValueInput').value = f.targetValue;
    fillEnumSelect('floorActivityInput', 'activityTypes', f.activityType);
    fillEnumSelect('floorTargetKindInput', 'dungeonFloorTargetKinds', f.targetKind);
    M.openModal('floorModal');
  }

  async function save() {
    if (!M.state.editingZoneId) { M.toast('No zone context', 'err'); return; }
    const body = {
      ordinal: parseInt(document.getElementById('floorOrdinalInput').value || '1', 10),
      activityType: parseInt(document.getElementById('floorActivityInput').value, 10),
      targetKind: parseInt(document.getElementById('floorTargetKindInput').value, 10),
      targetValue: parseFloat(document.getElementById('floorTargetValueInput').value || '0'),
      name: document.getElementById('floorNameInput').value,
      emoji: document.getElementById('floorEmojiInput').value,
    };
    try {
      if (editingId) {
        await M.api.put('/floors/' + editingId, body);
      } else {
        await M.api.post('/zones/' + M.state.editingZoneId + '/floors', body);
      }
      M.closeModal('floorModal');
      M.toast('Floor saved', 'ok');
      await reloadFloors();
    } catch (e) {
      M.toast(e.message, 'err');
    }
  }

  async function remove(f) {
    const ok = await M.confirmDialog('Delete floor?', `Floor ${f.ordinal} — ${f.name}`, 'Delete');
    if (!ok) return;
    try {
      await M.api.delete('/floors/' + f.id);
      M.toast('Floor deleted', 'ok');
      await reloadFloors();
    } catch (e) {
      M.toast(e.message, 'err');
    }
  }

  async function swap(sorted, i, j) {
    // Two-step to avoid clashing on the unique-ordinal-per-zone constraint:
    // park floor A on a throwaway high ordinal, then swap.
    const a = sorted[i];
    const b = sorted[j];
    const highOrdinal = 100000 + i;
    try {
      await M.api.put('/floors/' + a.id, floorBody({ ...a, ordinal: highOrdinal }));
      await M.api.put('/floors/' + b.id, floorBody({ ...b, ordinal: a.ordinal }));
      await M.api.put('/floors/' + a.id, floorBody({ ...a, ordinal: b.ordinal }));
      await reloadFloors();
    } catch (e) {
      M.toast('Reorder failed: ' + e.message, 'err');
      await reloadFloors();
    }
  }

  function floorBody(f) {
    return {
      ordinal: f.ordinal,
      activityType: f.activityType,
      targetKind: f.targetKind,
      targetValue: f.targetValue,
      name: f.name,
      emoji: f.emoji,
    };
  }

  async function reloadFloors() {
    if (!M.state.editingZoneId) return;
    const floors = await M.api.get('/zones/' + M.state.editingZoneId + '/floors');
    render(floors);
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
  function escapeHtml(s) { return (s ?? '').toString().replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }

  window.MapAdminFloors = { render, openNew, save };
})();
