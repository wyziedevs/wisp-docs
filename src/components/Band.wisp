{@props id: &str, title: &str, lead: &str, flip: bool = false}
<section class="sec band" id={id}>
  <div class="wrap split" class:flip={flip}>
    <div class="claim">
      <h2>{title}</h2>
      <p>{lead}</p>
    </div>
    <div class="sample">{@render children()}</div>
  </div>
</section>
