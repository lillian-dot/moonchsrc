///|
async fn probe_source(
  source : @moonchsrc.Source,
  timeout_ms : Int,
) -> @moonchsrc.Measurement {
  let started = @async.now()
  try
    @async.with_timeout_opt(timeout_ms, () => {
      let (response, stream) = @http.get_stream(source.url)
      defer stream.close()
      response.code
    })
  catch {
    _ =>
      {
        mirror_id: source.mirror_id,
        url: source.url,
        latency_ms: None,
        http_status: None,
      }
  } noraise {
    Some(status) =>
      {
        mirror_id: source.mirror_id,
        url: source.url,
        latency_ms: Some(@async.now() - started),
        http_status: Some(status),
      }
    None =>
      {
        mirror_id: source.mirror_id,
        url: source.url,
        latency_ms: None,
        http_status: None,
      }
  }
}

///|
/// Probe all sources for a target concurrently, with a per-source timeout.
pub async fn target(
  target_name : StringView,
  timeout_ms? : Int = 3000,
) -> Array[@moonchsrc.Measurement] {
  let target = match @moonchsrc.find_target(target_name) {
    Some(target) => target
    None => raise @moonchsrc.PlanError::UnknownTarget(target_name.to_owned())
  }
  let tasks = target.sources.map(source => {
    () => probe_source(source, timeout_ms)
  })
  @moonchsrc.rank_measurements(@async.all(tasks, max_concurrent=4))
}
