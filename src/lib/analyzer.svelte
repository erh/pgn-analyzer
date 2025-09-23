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
   var fields = [ "Manufacturer Code", "Device Class" ];
   var prodinfofields = [ "Model ID" ];
   
   var desc  = findfields(lst, 60928, fields) + findfields(lst, 126996, prodinfofields);
   if (desc == "") {
     return "No description";
   }
   return desc;
 }

 function swversion(lst) {
   var prodinfofields = [ "Software Version Code" ];

   return findfields(lst, 126996, prodinfofields);
 }

 function badPgn(pgn) {
   return pgn == 126993;
 }
</script>

<h2>Sensor {sensorName}</h2>
{#if query.current.error}
  {query.current.error.message}
{:else}
  {#each Object.entries(dataBySource()) as [src, lst]}
    <details class="collapsible">
      <summary class="collapsible-summary">
        <div class="summary-content">
          <span><strong>{src}</strong> - {description(lst)}</span>
          <span>{swversion(lst)}</span>
        </div>
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
{/if}

<style>
  .collapsible { margin: 0.75rem 0; border: 1px solid #ddd; border-radius: 0.5rem; padding: 0.5rem 0.75rem; }
  .collapsible-summary { cursor: pointer; font-size: 1.05rem; }
  .table { width: 100%; border-collapse: collapse; margin-top: 0.5rem; }
  .table th, .table td { border: 1px solid #e5e7eb; padding: 0.5rem; vertical-align: top; }
  .table thead th { text-align: left; }
  .fields-row { background: #fafafa; }
  
  .fields-collapsible summary {
    cursor: pointer;
    font-weight: 600;
    padding: 0.25rem 0;
  }

  .value-pre {
    margin: 0;
    white-space: pre-wrap;
    word-break: break-word;
    background: var(--pre-bg);
    padding: 0.375rem 0.5rem;
    border-radius: 0.375rem;
  }

  .summary-content {
    display: flex;
    justify-content: space-between; /* Pushes child elements to the edges */
    width: 100%; /* Ensure it fills the entire width */
  }
</style>
