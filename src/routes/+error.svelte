<script>
  import { page } from "$app/stores";
</script>

<div class="grid w-full h-full place-content-center">
  <h1 class="text-9xl">{$page.status} {$page.error?.message}</h1>
</div>
