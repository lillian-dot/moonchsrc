///|
pub fn Measurement::is_reachable(self : Measurement) -> Bool {
  self.latency_ms is Some(_)
}

///|
/// Rank reachable mirrors by latency and keep failed probes last. Insertion
/// sorting intentionally preserves recipe order when two results tie.
pub fn rank_measurements(
  measurements : ArrayView[Measurement],
) -> Array[Measurement] {
  let ranked : Array[Measurement] = []
  for measurement in measurements {
    let mut insert_at = ranked.length()
    for index, current in ranked {
      let comes_first = match (measurement.latency_ms, current.latency_ms) {
        (Some(left), Some(right)) => left < right
        (Some(_), None) => true
        (None, _) => false
      }
      if comes_first {
        insert_at = index
        break
      }
    }
    ranked.insert(insert_at, measurement)
  }
  ranked
}

///|
pub fn fastest_reachable(measurements : ArrayView[Measurement]) -> Measurement? {
  let ranked = rank_measurements(measurements)
  match ranked.search_by(measurement => measurement.is_reachable()) {
    Some(index) => Some(ranked[index])
    None => None
  }
}
