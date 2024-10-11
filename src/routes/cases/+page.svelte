<script lang="ts">
  export let data;
  const cases = data.cases;
</script>

<div class="overflow-y-auto">
  <div class="relative grid lg:grid-cols-4 mx-8 lg:mt-44 lg:mx-44 gap-0">
    <div class="absolute hidden lg:block circle-gradient w-[1px] h-full right-1/2"></div>
    <div class="absolute hidden lg:block circle-gradient w-[1px] h-full right-1/4"></div>
    <div class="absolute hidden lg:block circle-gradient w-[1px] h-full left-1/4"></div>
    {#each cases as d, i}
      <div class="aspect-[6/5] hover:gradient">
        <a class="grid w-full h-full gap-4 lg:p-9" href={`${d.path}`}>
          <span class="text-2xl lg:text-3xl line-clamp-3 self-center">{d.meta.title}</span>
          <span class="text-xs text-neutral-400">{d.meta.date}</span>
        </a>
        {#if i % 4 === 0 && i !== cases.length - 1}
          <div class="absolute hidden lg:block circle-gradient w-full h-[1px]"></div>
        {/if}
        {#if i !== cases.length - 1}
          <div class="absolute lg:hidden circle-gradient w-full h-[1px]"></div>
        {/if}
      </div>
    {/each}
  </div>
</div>
