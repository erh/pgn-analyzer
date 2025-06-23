<script lang="ts">
 import { createResourceClient, createResourceQuery, useResourceNames } from '@viamrobotics/svelte-sdk';
 import { SensorClient } from '@viamrobotics/sdk';
 import Analyzer from "./analyzer.svelte"
 
 let {
   partID,
   ...rest
 }: Props = $props();

 let sensorName = $state("all-pgn");
 
 const resources = useResourceNames(() => partID);
 
</script>

Sensor
<select bind:value={sensorName}>
  {#each resources.current as r}
    <option selected={r.name === "all-pgn"}>
      {r.name}
    </option>
  {/each}
</select>
{sensorName}
<Analyzer partID="xxx" sensorName={sensorName}/>

