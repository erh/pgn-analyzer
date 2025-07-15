<script lang="ts">
  import {
    createResourceClient,
    createResourceQuery,
    useResourceNames,
  } from "@viamrobotics/svelte-sdk";
  import { ResourceName, SensorClient } from "@viamrobotics/sdk";
  import Analyzer from "./analyzer.svelte";

  let { partID, ...rest }: Props = $props();

  let sensorName = $state("all-pgn");

  const resources = useResourceNames(() => partID);
  const sorted = $derived(
    resources.current.toSorted((a, b) => {
      return a.name.localeCompare(b.name);
    })
  );
</script>

Sensor
<select bind:value={sensorName}>
  {#each sorted as r}
    <option>
      {r.name}
    </option>
  {/each}
</select>
{sensorName}
<Analyzer partID="xxx" {sensorName} />
