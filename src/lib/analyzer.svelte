<script lang="ts">
 import { createResourceClient, createResourceQuery } from '@viamrobotics/svelte-sdk';
 import { SensorClient } from '@viamrobotics/sdk';

 let {
   partID,
   sensorName,
   refetchInterval = 5000,
   ...rest
 }: Props = $props();

 const allPgnClient = createResourceClient(
   SensorClient,
   () => partID,
   () => sensorName
 );

 const query = createResourceQuery(allPgnClient, 'getReadings', () => ({
   refetchInterval,
 }));

 const data = $derived(query.current.data)

 let activeTab = $state('all');

 function dataBySource() {
   var r = {};

   for (var k in data) {
     var d = data[k];

     var old = r[d.src];
     if (old) {
       old.push(d);
       old.sort((a, b) => a.pgn - b.pgn);

     } else {
       r[d.src] = [d];
     }
   }

   return r;
 }

 function findMsg(lst, pgn) {
   for (var i = 0; i < lst.length; i++) {
     if (lst[i].pgn == pgn) return lst[i];
   }
   return null;
 }

 function getField(lst, pgns, field) {
   for (var i = 0; i < pgns.length; i++) {
     var m = findMsg(lst, pgns[i]);
     if (m && m[field] !== undefined && m[field] !== null) return m[field];
   }
   return null;
 }

 function fmtNum(v, digits) {
   if (v === null || v === undefined) return '';
   if (typeof v === 'number') return v.toFixed(digits);
   return String(v);
 }

 function fmtVal(v) {
   if (v === null || v === undefined) return '';
   return String(v);
 }

 function ageMs(ts) {
   if (!ts) return null;
   var t = typeof ts === 'number' ? ts : Date.parse(ts);
   if (isNaN(t)) return null;
   return Date.now() - t;
 }

 function newestTimestamp(lst, pgns) {
   var newest = null;
   for (var i = 0; i < pgns.length; i++) {
     var m = findMsg(lst, pgns[i]);
     if (m && m.timestamp) {
       var t = typeof m.timestamp === 'number' ? m.timestamp : Date.parse(m.timestamp);
       if (!isNaN(t) && (newest === null || t > newest)) newest = t;
     }
   }
   return newest;
 }

 const movementPgns = [129025, 129029, 129026, 127250, 127257];

 function fmtAge(ms) {
   if (ms === null || ms === undefined) return '';
   if (ms < 1000) return ms + 'ms';
   if (ms < 60000) return (ms / 1000).toFixed(1) + 's';
   return (ms / 60000).toFixed(1) + 'm';
 }
 
 function cleanFields(m) {
   var n = {};

   var badFields = {
     "pgn" : true,
     "src" : true,
     "description" : true,
     "timestamp" : true
   };
   
   for (var k in m) {
     if (k in badFields) {
       continue
     }
     n[k] = m[k];
   }
   
   return n;
 }

 function findfields(lst,pgn,fields) {
   for (var k in lst) {
     var m = lst[k];
     if (m.pgn == pgn) {
       var d = "";
       for (var kk in fields) {
         var vv = fields[kk];
         if (vv in m) {
           d += m[vv] + " ";
         }
       }
       return d;
     }
   }
   return "";
 }

 function description(lst) {

   var fields = [
     "Manufacturer Code",
     "Device Class"
   ]
   
   var prodinfofields = [
     "Model ID",
     "Software Version Code"
   ]

   var desc  = findfields(lst, 60928, fields) + findfields(lst, 126996, prodinfofields)
   if (desc == "") {
     return "No description";
   }
   return desc;
 }

 function badPgn(pgn) {
   return pgn == 126993;
 }

 let mapEl: HTMLDivElement | null = $state(null);
 let mapInstance: any = null;
 let markersLayer: any = null;
 let leafletLoaded = $state(false);

 function loadLeaflet() {
   if (typeof window === 'undefined') return;
   if ((window as any).L) {
     leafletLoaded = true;
     return;
   }
   if (!document.querySelector('link[data-leaflet]')) {
     const link = document.createElement('link');
     link.rel = 'stylesheet';
     link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
     link.setAttribute('data-leaflet', 'true');
     document.head.appendChild(link);
   }
   const existing = document.querySelector('script[data-leaflet]') as HTMLScriptElement | null;
   if (existing) {
     if ((window as any).L) leafletLoaded = true;
     else existing.addEventListener('load', () => { leafletLoaded = true; });
     return;
   }
   const script = document.createElement('script');
   script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
   script.setAttribute('data-leaflet', 'true');
   script.onload = () => { leafletLoaded = true; };
   document.head.appendChild(script);
 }

 function getPositions() {
   var positions = [];
   var bySrc = dataBySource();
   for (var src in bySrc) {
     var lst = bySrc[src];
     var lat = getField(lst, [129029, 129025], 'Latitude');
     var lon = getField(lst, [129029, 129025], 'Longitude');
     if (typeof lat === 'number' && typeof lon === 'number' && !isNaN(lat) && !isNaN(lon)) {
       positions.push({ src: src, lat: lat, lon: lon, desc: description(lst) });
     }
   }
   return positions;
 }

 $effect(() => {
   if (activeTab === 'movement') {
     loadLeaflet();
   }
 });

 $effect(() => {
   if (activeTab !== 'movement') {
     if (mapInstance) {
       mapInstance.remove();
       mapInstance = null;
       markersLayer = null;
     }
     return;
   }
   if (!leafletLoaded || !mapEl) return;
   const L = (window as any).L;
   if (!mapInstance || mapInstance._container !== mapEl) {
     if (mapInstance) {
       mapInstance.remove();
       mapInstance = null;
       markersLayer = null;
     }
     mapInstance = L.map(mapEl).setView([0, 0], 2);
     L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
       attribution: '© OpenStreetMap',
       maxZoom: 19
     }).addTo(mapInstance);
     markersLayer = L.layerGroup().addTo(mapInstance);
   }
   markersLayer.clearLayers();
   var positions = getPositions();
   var bounds: any[] = [];
   positions.forEach((p) => {
     var marker = L.marker([p.lat, p.lon]).addTo(markersLayer);
     marker.bindTooltip(String(p.src), { permanent: true, direction: 'top', className: 'src-label' });
     marker.bindPopup('<strong>Src ' + p.src + '</strong><br>' + p.desc + '<br>' + p.lat.toFixed(6) + ', ' + p.lon.toFixed(6));
     bounds.push([p.lat, p.lon]);
   });
   if (bounds.length === 1) {
     mapInstance.setView(bounds[0], 13);
   } else if (bounds.length > 1) {
     mapInstance.fitBounds(bounds, { padding: [40, 40] });
   }
   setTimeout(() => { if (mapInstance) mapInstance.invalidateSize(); }, 50);
 });
</script>

<h2>Sensor {sensorName}</h2>

<div class="tabs">
  <button
    class="tab"
    class:active={activeTab === 'all'}
    on:click={() => (activeTab = 'all')}
  >All PGNs</button>
  <button
    class="tab"
    class:active={activeTab === 'movement'}
    on:click={() => (activeTab = 'movement')}
  >Movement</button>
</div>

{#if query.current.error}
  {query.current.error.message}
{:else if activeTab === 'all'}
  {#each Object.entries(dataBySource()) as [src, lst]}
    <details class="collapsible">
      <summary class="collapsible-summary">
        <strong>{src}</strong> - {description(lst)}
      </summary>

      <table class="table table-messages">
        <thead>
          <tr>
            <th>PGN</th>
            <th>Description</th>
            <th>Timestamp</th>
          </tr>
        </thead>
        <tbody>
          {#each lst as m}
            {#if !badPgn(m.pgn)}
              <tr>
                <td>{m.pgn}</td>
                <td>{m.description}</td>
                <td>{m.timestamp}</td>
              </tr>
              <tr class="fields-row">
                <td colspan="1"></td>
                <td colspan="2">
                  <details class="fields-collapsible">
                    <summary>Fields</summary>
                    <table class="table table-fields">
                      <thead>
                        <tr>
                          <th>Field</th>
                          <th>Value</th>
                        </tr>
                      </thead>
                      <tbody>
                        {#each Object.entries(cleanFields(m)) as [k, v]}
                          <tr>
                            <td>{k}</td>
                            <td><pre class="value-pre">{JSON.stringify(v, null, 0)}</pre></td>
                          </tr>
                        {/each}
                      </tbody>
                    </table>
                  </details>
                </td>
              </tr>
            {/if}
          {/each}
        </tbody>
      </table>
    </details>
  {/each}
{:else if activeTab === 'movement'}
  <p class="movement-note">
    Fields used by
    <a href="https://github.com/viam-labs/viamboat/blob/main/movementsensor.go" target="_blank" rel="noopener">viamboat movementsensor</a>.
    PGNs 129025 / 129029 (position), 129026 (COG/SOG), 127250 (heading), 127257 (attitude).
  </p>
  <div class="map-container" bind:this={mapEl}></div>
  <div class="movement-scroll">
    <table class="table table-movement">
      <thead>
        <tr>
          <th rowspan="2">Src</th>
          <th rowspan="2">Description</th>
          <th colspan="4">Position (129025 / 129029)</th>
          <th colspan="3">COG/SOG (129026)</th>
          <th colspan="2">Heading (127250)</th>
          <th colspan="3">Attitude (127257)</th>
          <th rowspan="2">Newest age</th>
        </tr>
        <tr>
          <th>Latitude</th>
          <th>Longitude</th>
          <th>HDOP</th>
          <th>#SVs</th>
          <th>COG</th>
          <th>SOG</th>
          <th>COG Ref</th>
          <th>Heading</th>
          <th>Hdg Ref</th>
          <th>Roll</th>
          <th>Pitch</th>
          <th>Yaw</th>
        </tr>
      </thead>
      <tbody>
        {#each Object.entries(dataBySource()) as [src, lst]}
          {@const newest = newestTimestamp(lst, movementPgns)}
          {@const age = newest === null ? null : Date.now() - newest}
          {#if findMsg(lst, 129025) || findMsg(lst, 129029) || findMsg(lst, 129026) || findMsg(lst, 127250) || findMsg(lst, 127257)}
            <tr>
              <td><strong>{src}</strong></td>
              <td>{description(lst)}</td>
              <td>{fmtNum(getField(lst, [129029, 129025], 'Latitude'), 6)}</td>
              <td>{fmtNum(getField(lst, [129029, 129025], 'Longitude'), 6)}</td>
              <td>{fmtNum(getField(lst, [129029], 'HDOP'), 2)}</td>
              <td>{fmtVal(getField(lst, [129029], 'Number of SVs'))}</td>
              <td>{fmtNum(getField(lst, [129026], 'COG'), 1)}</td>
              <td>{fmtNum(getField(lst, [129026], 'SOG'), 2)}</td>
              <td>{fmtVal(getField(lst, [129026], 'COG Reference'))}</td>
              <td>{fmtNum(getField(lst, [127250], 'Heading'), 1)}</td>
              <td>{fmtVal(getField(lst, [127250], 'Reference'))}</td>
              <td>{fmtNum(getField(lst, [127257], 'Roll'), 2)}</td>
              <td>{fmtNum(getField(lst, [127257], 'Pitch'), 2)}</td>
              <td>{fmtNum(getField(lst, [127257], 'Yaw'), 2)}</td>
              <td>{fmtAge(age)}</td>
            </tr>
          {/if}
        {/each}
      </tbody>
    </table>
  </div>
{/if}

<style>
  .collapsible { margin: 0.75rem 0; border: 1px solid #ddd; border-radius: 0.5rem; padding: 0.5rem 0.75rem; }
  .collapsible-summary { cursor: pointer; font-size: 1.05rem; }
  .table { width: 100%; border-collapse: collapse; margin-top: 0.5rem; }
  .table th, .table td { border: 1px solid #e5e7eb; padding: 0.5rem; vertical-align: top; }
  .table thead th { text-align: left; }
  .fields-row { background: rgba(127, 127, 127, 0.1); }
  .fields-collapsible summary { cursor: pointer; font-weight: 600; }
  .value-pre { margin: 0; white-space: pre-wrap; word-break: break-word; }
  .tabs { display: flex; gap: 0.25rem; margin: 0.5rem 0; border-bottom: 1px solid #ddd; }
  .tab {
    background: transparent;
    border: 1px solid #ddd;
    border-bottom: none;
    padding: 0.4rem 0.9rem;
    border-radius: 0.4rem 0.4rem 0 0;
    cursor: pointer;
    font-size: 0.95rem;
    color: inherit;
    margin-bottom: -1px;
  }
  .tab.active { background: rgba(127, 127, 127, 0.15); font-weight: 600; }
  .movement-note { font-size: 0.85rem; opacity: 0.8; margin: 0.5rem 0; }
  .movement-scroll { overflow-x: auto; }
  .table-movement { font-size: 0.9rem; }
  .table-movement th, .table-movement td { white-space: nowrap; }
  .map-container { height: 400px; width: 100%; margin: 0.5rem 0 0.75rem; border: 1px solid #ddd; border-radius: 0.4rem; }
  :global(.leaflet-tooltip.src-label) { font-weight: 600; background: rgba(255, 255, 255, 0.9); color: #111; padding: 2px 6px; }
</style>
