private func wrap(_ age: Double, _ loop: LoopSection) -> Double {
    let span = loop.end - loop.start
    if span <= 0 || age < loop.end { return age }
    return loop.start + (age - loop.start).truncatingRemainder(dividingBy: span)
}

func loopedAge(_ time: Double, _ born: Double, _ loop: LoopSection?, _ released: Double?) -> Double {
    let age = time - born
    guard let loop else { return age }
    guard let released, time > released else { return wrap(age, loop) }
    let at = max(released, born)
    return wrap(at - born, loop) + (time - at)
}
