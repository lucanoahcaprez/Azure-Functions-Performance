<script>
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';

	onMount(() => {
		goto('/', { replaceState: true });
	});
</script>

<p>Redirecting...</p>
