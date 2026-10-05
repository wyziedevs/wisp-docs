<div class="table-wrap">
  <table class="grid">
    <thead><tr><th scope="col">Stack</th>{#each site::FEATURES.0.iter() as f}<th scope="col" class="num">{f}</th>{/each}<th scope="col" class="num">total</th><th scope="col" class="num">chars / 4</th><th scope="col" class="num">files</th></tr></thead>
    <tbody>
      {#each site::FEATURES.1.iter() as (name, by, total, chars, files)}
        <tr class:us={*name == "Wisp"}>
          <th scope="row">{name}</th>
          {#each by.iter() as n}<td class="num">{n}</td>{/each}
          <td class="num">{total}</td><td class="num">{chars}</td><td class="num">{files}</td>
        </tr>
      {/each}
    </tbody>
  </table>
</div>
