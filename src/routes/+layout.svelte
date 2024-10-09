<script lang="ts">
	import '../app.css';
	import Stars from '../components/stars.svelte';
</script>

<svelte:head>
	<title>Ivan Dimitrov</title>
	<meta name="description" content="Freelance Software Developer" />
</svelte:head>

<main>
	<Stars />
	<slot />
</main>
