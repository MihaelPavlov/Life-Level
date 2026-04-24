// Edges CRUD + render.

(function () {
  const M = window.MapAdmin;
  let editingId = null;

  async function load() {
    if (!M.state.currentRegionId) { clear(); return; }
    try {
      const edges = await M.api.get('/regions/' + M.state.currentRegionId + '/edges');
      M.state.edges = edges;
      render();
    } catch (e) {
      M.toast('Failed to load edges: ' + e.message, 'err');
    }
  }

  function clear() {
    M.state.edges = [];
    document.getElementById('edgesTbody').innerHTML = '';
    document.getElementById('edgesSection').classList.add('hidden');
  }

  function render() {
    const tb = document.getElementById('edgesTbody');
    tb.innerHTML = '';
    const zoneById = new Map(M.state.zones.map(z => [z.id, z]));
    if (!M.state.edges.length) {
      tb.innerHTML = '<tr><td colspan="5" class="empty-state">No edges yet.</td></tr>';
      return;
    }
    for (const e of M.state.edges) {
      const fromZ = zoneById.get(e.fromZoneId);
      const toZ = zoneById.get(e.toZoneId);
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${escapeHtml(fromZ ? (fromZ.emoji + ' ' + fromZ.name) : e.fromZoneId)}</td>
        <td>${escapeHtml(toZ ? (toZ.emoji + ' ' + toZ.name) : e.toZoneId)}</td>
        <td>${e.distanceKm}</td>
        <td>${e.isBidirectional ? '↔' : '→'}</td>
        <td style="text-align:right; white-space:nowrap;">
          <button class="sm secondary" data-edit="${e.id}">Edit</button>
          <button class="sm danger"    data-delete="${e.id}">Del</button>
        </td>`;
      tr.querySelector('[data-edit]').addEventListener('click', () => openEdit(e));
      tr.querySelector('[data-delete]').addEventListener('click', () => remove(e));
      tb.appendChild(tr);
    }
  }

  function toggle() {
    const sec = document.getElementById('edgesSection');
    sec.classList.toggle('hidden');
  }

  function openNew() {
    editingId = null;
    document.getElementById('edgeModalTitle').textContent = 'Add edge';
    fillZoneSelects(null, null);
    document.getElementById('edgeDistanceInput').value = 1.0;
    document.getElementById('edgeBidirectionalInput').checked = true;
    M.openModal('edgeModal');
  }

  function openEdit(e) {
    editingId = e.id;
    document.getElementById('edgeModalTitle').textContent = 'Edit edge';
    fillZoneSelects(e.fromZoneId, e.toZoneId);
    document.getElementById('edgeFromInput').disabled = true;
    document.getElementById('edgeToInput').disabled = true;
    document.getElementById('edgeDistanceInput').value = e.distanceKm;
    document.getElementById('edgeBidirectionalInput').checked = e.isBidirectional;
    M.openModal('edgeModal');
  }

  function fillZoneSelects(fromId, toId) {
    const fromSel = document.getElementById('edgeFromInput');
    const toSel = document.getElementById('edgeToInput');
    fromSel.disabled = false;
    toSel.disabled = false;
    fromSel.innerHTML = '';
    toSel.innerHTML = '';
    for (const z of M.state.zones) {
      const label = (z.emoji || '•') + ' ' + z.name + ' (T' + z.tier + ')';
      const o1 = new Option(label, z.id);
      const o2 = new Option(label, z.id);
      if (z.id === fromId) o1.selected = true;
      if (z.id === toId)   o2.selected = true;
      fromSel.appendChild(o1);
      toSel.appendChild(o2);
    }
  }

  async function save() {
    try {
      if (editingId) {
        const body = {
          distanceKm: parseFloat(document.getElementById('edgeDistanceInput').value || '0'),
          isBidirectional: document.getElementById('edgeBidirectionalInput').checked,
        };
        await M.api.put('/edges/' + editingId, body);
        M.toast('Edge updated', 'ok');
      } else {
        const body = {
          fromZoneId: document.getElementById('edgeFromInput').value,
          toZoneId: document.getElementById('edgeToInput').value,
          distanceKm: parseFloat(document.getElementById('edgeDistanceInput').value || '0'),
          isBidirectional: document.getElementById('edgeBidirectionalInput').checked,
        };
        if (body.fromZoneId === body.toZoneId) { M.toast('From and to must differ', 'err'); return; }
        await M.api.post('/edges', body);
        M.toast('Edge created', 'ok');
      }
      M.closeModal('edgeModal');
      await load();
    } catch (e) {
      M.toast(e.message, 'err');
    }
  }

  async function remove(e) {
    const ok = await M.confirmDialog('Delete edge?', 'Any user progress traveling along this edge will be reset.', 'Delete');
    if (!ok) return;
    try {
      await M.api.delete('/edges/' + e.id);
      M.toast('Edge deleted', 'ok');
      await load();
    } catch (err) {
      M.toast(err.message, 'err');
    }
  }

  function escapeHtml(s) { return (s ?? '').toString().replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }

  window.MapAdminEdges = { load, clear, toggle, openNew, save };
})();
