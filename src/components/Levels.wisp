{@props work: &str}
{#each site::LEVELS.iter().filter(|l| l.0 == work) as (_, conns, rows)}
  <div class="table-wrap">
    <table class="grid">
      <thead><tr><th scope="col">Contender</th>{#each conns.iter() as c}<th scope="col" class="num">{c}</th>{/each}</tr></thead>
      <tbody>
        {#each rows.iter() as (name, cells)}
          <tr class:us={*name == "Wisp"}>
            <th scope="row">{name}</th>
            {#each cells.iter() as cell}<td class="num">{cell}</td>{/each}
          </tr>
        {/each}
      </tbody>
    </table>
  </div>
{/each}
