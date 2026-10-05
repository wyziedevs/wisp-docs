<table class="tally">
  <thead><tr><th scope="col">Stack</th><th scope="col"><span class="sr">Relative size</span></th><th scope="col" class="num">Tokens</th><th scope="col" class="num">Files</th></tr></thead>
  <tbody>
    {#each site::TOKENS.0.iter() as (name, share, tokens, files)}
      <tr class:us={*name == "Wisp"}>
        <th scope="row">{name}</th>
        <td class="meter" aria-hidden="true"><span style={format!("--v: {share:.3}")}></span></td>
        <td class="num">{tokens}</td>
        <td class="num">{files}</td>
      </tr>
    {/each}
  </tbody>
</table>

{#if !site::TOKENS.1.is_empty()}
  <p>A bigger app with sign in, posts, uploads, live refresh and a component: {site::TOKENS.1.iter().map(|(s, t)| format!("{s} {t}")).collect::<Vec<_>>().join(", ")} tokens.</p>
{/if}
