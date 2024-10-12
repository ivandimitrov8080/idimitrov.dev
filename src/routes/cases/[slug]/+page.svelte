<script lang="ts">
  import { faCircleUser } from "@fortawesome/free-solid-svg-icons";
  import { FontAwesomeIcon } from "@fortawesome/svelte-fontawesome";

  export let data;
  const { title, published, author, content, headers } = data;
</script>

<div class="overflow-y-auto lg:grid lg:justify-items-center scroll-smooth">
  <div class="lg:grid lg:gap-20 lg:grid-cols-12 lg:w-11/12">
    <div class="lg:col-span-9 p-4">
      <div class="flex flex-col gap-4 lg:pl-24 lg:pt-20">
        <h1 class="text-4xl lg:text-5xl font-bold">{title}</h1>
        <div class="flex flex-row gap-4">
          {#if author && data.published}
            <FontAwesomeIcon class="w-14 h-14 hover:filter-none" icon={faCircleUser} />
            <div class="flex flex-col">
              <h1 class="font-bold text-xl">{author}</h1>
              <span class="text-xs text-neutral-400">Published {published}</span>
            </div>
          {/if}
        </div>
        <div class="ctnt">
          <svelte:component this={content} />
        </div>
      </div>
    </div>
    <div class="hidden lg:block h-screen lg:col-span-3 py-64">
      <div class="fixed grid gap-4 pl-12">
        <span class="text-2xl font-bold">Table of contents</span>
        <div class="circle-gradient w-full h-[1px] top-1/2"></div>
        <div class="flex flex-col">
          {#each headers as h}
            <a href={`#${h.id}`} class="hover:gradient p-2 rounded-md">
              {h.text}
            </a>
          {/each}
        </div>
      </div>
    </div>
  </div>
</div>

<style>
  @import "./case.css";
</style>
