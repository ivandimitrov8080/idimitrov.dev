<script lang="ts">
  type Star = {
    background: string;
    left: string;
    top: string;
    radius: string;
    containerRadius?: string;
    animation?: string;
  };
  const randInt = (i: number) => Math.round(Math.random() * i);
  const randomRgba = (alpha: number) => {
    return `rgba(${randInt(255)}, ${randInt(255)}, ${randInt(255)}, ${alpha})`;
  };
  const star = (): Star => {
    const r = Math.floor(0.1 + Math.random() * 1337);
    let containerRadius = undefined;
    let animation = undefined;
    if (Math.random() < 0.3) {
      containerRadius = `${r}px`;
      const a = Math.random() > 0.5 ? "spinner" : "spinner-reverse";
      const duration = Math.floor(r) / 100;
      animation = `${a} ${duration}s linear infinite`;
    }
    const radius = `${randInt(7)}px`;
    const x = randInt(100),
      y = randInt(100);
    return {
      background: `radial-gradient(circle, ${randomRgba(0.6)} 0%, ${randomRgba(0)} 100%)`,
      left: `${x}%`,
      top: `${y}%`,
      radius: radius,
      containerRadius: containerRadius,
      animation: animation
    };
  };
  const stars: Star[] = Array.from({ length: 400 }).map(star);
</script>

<div class="absolute w-screen h-screen overflow-hidden">
  {#each stars as star}
    {#if star.containerRadius}
      <div
        class="absolute z-10 max-w-full max-h-full"
        style="width: {star.containerRadius}; height: {star.containerRadius}; animation: {star.animation}; top: {star.top}; left: {star.left}"
      >
        <div
          class="absolute z-10"
          style="width: {star.radius}; height: {star.radius}; background: {star.background};"
        ></div>
      </div>
    {:else}
      <div
        class="absolute z-10"
        style="width: {star.radius}; height: {star.radius}; background: {star.background}; top: {star.top}; left: {star.left};"
      ></div>
    {/if}
  {/each}
</div>
