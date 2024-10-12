<script lang="ts">
  import "../app.css";
  import Stars from "$lib/components/stars.svelte";
  import Navbar from "$lib/components/navbar.svelte";
</script>

<svelte:head>
  <title>Ivan Dimitrov</title>
  <meta name="description" content="Freelance Software Developer" />
</svelte:head>

<main>
  <Stars />
  <Navbar />
  <slot />
</main>
