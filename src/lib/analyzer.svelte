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

 function description(lst){

   var fields = [
     "Manufacturer Code",
     "Device Class",
     "Device Function"
   ]
   
   for (var k in lst) {
     var m = lst[k];
     if (m.pgn == 60928) {
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
   return "no desc";
 }

 function badPgn(pgn) {
   return pgn == 126993;
 }

</script>

<h2>Sensor {sensorName}</h2>
{#if query.current.error}
  {query.current.error.message}
{:else}
  <ul>
    {#each Object.entries(dataBySource()) as [src,lst]}
      <li>
        {src} - {description(lst)}
        <ul>
          {#each lst as m}
            {#if !badPgn(m.pgn)}
              <li>
                {m.pgn} - {m.description} - {m.timestamp}
                <ul>
                  {#each Object.entries(cleanFields(m)) as [k,v]}
                    <li>{k} - {JSON.stringify(v)}</li>
                  {/each}
                </ul>
              </li>
            {/if}
          {/each}
        </ul>
      </li>
    {/each}
  </ul>
{/if}

