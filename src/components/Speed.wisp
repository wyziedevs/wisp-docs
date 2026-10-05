<div class="benches">
  {#each site::SPEED as (caption, rows)}
    <div class="bench">
      <table class="tally">
        <caption>{caption}</caption>
        <thead><tr><th scope="col">Framework</th><th scope="col">Built On</th><th scope="col"><span class="sr">Relative speed</span></th><th scope="col" class="num">Req/s</th></tr></thead>
        <tbody>
          {#each rows.iter() as (name, stack, share, rps)}
            <tr class:us={*name == "Wisp"}>
              <th scope="row">{name}</th>
              <td class="stack">{stack}</td>
              <td class="meter" aria-hidden="true">{#if *share > 0.0}<span style={format!("--v: {share:.3}")}></span>{/if}</td>
              <td class="num">{rps}</td>
            </tr>
          {/each}
        </tbody>
      </table>
    </div>
  {/each}
</div>
