<script lang="ts">
  import "../app.css";
  import Stars from "$lib/components/stars.svelte";
  import Navbar from "$lib/components/navbar.svelte";
  import { MetaTags, type MetaTagsProps } from "svelte-meta-tags";
  import { page } from "$app/stores";
  import Breadcrumbs from "$lib/components/breadcrumbs.svelte";
  import extend from "just-extend";
  export let data;
  $: metaTags = extend(true, {}, data.baseMetaTags, $page.data.pageMetaTags) as MetaTagsProps;
</script>

<MetaTags {...metaTags} />

<main>
  <Stars />
  <div class="p-3 lg:p-12 flex flex-col gap-10 w-full h-full bg-transparent">
    <Navbar />
    <Breadcrumbs title={metaTags.title} />
    <slot />
  </div>
</main>
