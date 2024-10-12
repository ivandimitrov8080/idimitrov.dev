<script lang="ts">
  import { page } from "$app/stores";
  import { faChevronRight } from "@fortawesome/free-solid-svg-icons";
  import { FontAwesomeIcon } from "@fortawesome/svelte-fontawesome";

  const p = $page.url.pathname;
  const path = p === "/" ? [] : $page.url.pathname.split("/");
  const isLast = (i: number) => i === path.length - 1;
</script>

<div class="flex flex-row gap-4">
  {#each path as p, i}
    {#if p === ""}
      <a href="/">Home</a>
    {:else if isLast(i)}
      <span class="capitalize">{p}</span>
    {:else}
      <a href={path.slice(0, i + 1).join("/")} class="capitalize">{p}</a>
    {/if}
    {#if !isLast(i)}
      <FontAwesomeIcon class="w-4 h-4 my-auto" icon={faChevronRight} />
    {/if}
  {/each}
</div>
