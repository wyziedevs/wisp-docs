{@props id: &str, kicker: &str, title: &str, lead: &str, flip: bool = false}
<section class="band" id={id}>
  <div class="wrap split" class:flip={flip}>
    <div class="claim">
      <p class="kicker">{kicker}</p>
      <h2>{title}</h2>
      <p>{lead}</p>
    </div>
    <div class="sample">{@render children()}</div>
  </div>
</section>
