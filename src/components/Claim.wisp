{@props id: &str, class: &str = ""}
<section class={format!("sec {class}").trim_end()} id={id}>
  <div class="wrap">
    <div class="claim wide">{@render children()}</div>
  </div>
</section>
