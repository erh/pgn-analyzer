<script lang="ts">

 import { ViamProvider } from '@viamrobotics/svelte-sdk';
 
 import type { DialConf } from '@viamrobotics/sdk';
 import Status from "./lib/status.svelte"
 import Analyzer from "./lib/analyzer.svelte"

 let { host, credentials, children } = $props();

 const dialConfigs: Record<string, DialConf> = {
   "xxx": {
     host: host,
     credentials: credentials,
     signalingAddress: 'https://app.viam.com:443',
     disableSessions: false,
   },
 };
 
</script>

<ViamProvider {dialConfigs}>
  <Status name="xxx" display="connection to {host}"/>
  <Analyzer partID="xxx"/>
  {@render children?.()}
</ViamProvider>

