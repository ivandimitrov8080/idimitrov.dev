<script lang="ts">
  import "../app.css";
  import Stars from "$lib/components/stars.svelte";
  import Navbar from "$lib/components/navbar.svelte";
  import { MetaTags } from "svelte-meta-tags";
  import { page } from "$app/stores";
</script>

<MetaTags
  title="idimitrov.dev"
  titleTemplate="%s | idimitrov.dev"
  description="Software Development"
  canonical={$page.url.href}
  openGraph={{
    type: "website",
    locale: "en_GB",
    title: "idimitrov.dev",
    description: "Software Development",
    siteName: "idimitrov.dev"
  }}
/>

<svelte:head>
  <title>Ivan Dimitrov</title>
  <meta name="description" content="Freelance Software Developer" />
</svelte:head>

<main>
  <Stars />
  <Navbar />
  <slot />
</main>
