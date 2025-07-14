<script lang="ts">
 import { createResourceClient, createResourceQuery, useResourceNames } from '@viamrobotics/svelte-sdk';
 import { SensorClient } from '@viamrobotics/sdk';
 import Analyzer from "./analyzer.svelte"
 
 let {
   partID,
   ...rest
 }: Props = $props();

 let sensorName = $state("all-pgn");

 function theList() {
   const resources = useResourceNames(() => partID);
   const lst = resources.current;
   lst.sort((a,b) => {
     return a.name.localeCompare(b.name);
   });
   console.log(lst.length);
   return lst
 }
 
</script>

Sensor
<select bind:value={sensorName}>
  {#each theList() as r}
    <option selected={r.name === "all-pgn"}>
      {r.name}
    </option>
  {/each}
</select>
{sensorName}
<Analyzer partID="xxx" sensorName={sensorName}/>

