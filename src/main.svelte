<script lang="ts">
  import { ViamProvider } from "@viamrobotics/svelte-sdk";

  import type { DialConf } from "@viamrobotics/sdk";
  import Status from "./lib/status.svelte";
  import Wrap from "./lib/wrap.svelte";

  let { host, credentials, children } = $props();

  const dialConfigs: Record<string, DialConf> = $derived({
    xxx: {
      host: host,
      credentials: credentials,
      signalingAddress: "https://app.viam.com:443",
      disableSessions: false,
    },
  });
</script>

<ViamProvider dialConfigs={$state.snapshot(dialConfigs)}>
  <Status name="xxx" display="connection to {host}" />
  <Wrap partID="xxx" />
  {@render children?.()}
</ViamProvider>

<hr>
V2
