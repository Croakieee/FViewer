(() => {
  const post = (message) => window.webkit?.messageHandlers?.avfx?.postMessage(message);
  const player = AvfxPlayer.create(document.getElementById('canvas'), { files: 'avfx://app/game' });
  window.avfxHost = player;

  let events = [];
  let playback = { start: 0, end: 0, loop: true, lockSeed: true };
  let patchedProto = null;
  const fired = new WeakMap();

  const fire = (effect, event) => {
    if (event.kind === 'trigger') effect.trigger(event.index);
    else if (event.kind === 'release') effect.release();
    else if (event.kind === 'stop') effect.stop();
  };

  const pending = (frame) => events.some((e) => e.frame > frame);

  const patch = () => {
    const effect = player.effect;
    if (!effect) return;
    const proto = Object.getPrototypeOf(effect);
    if (patchedProto === proto) return;
    patchedProto = proto;
    const update = proto.update;
    const restart = proto.restart;
    proto.restart = function (seed) {
      fired.set(this, new Set());
      return restart.call(this, seed);
    };
    proto.update = function (dt, camera) {
      const before = this.time;
      if (this.playing && events.length) {
        const done = fired.get(this) ?? new Set();
        fired.set(this, done);
        const next = this.time + dt * this.fps;
        events.forEach((event, i) => {
          if (!done.has(i) && event.frame <= next) {
            done.add(i);
            fire(this, event);
          }
        });
      }
      const out = update.call(this, dt, camera);
      if (this.time < before) fired.set(this, new Set());
      return out;
    };
  };

  const atEnd = (effect) => {
    const t = effect.time;
    if (playback.end > playback.start && t >= playback.end - 0.01) return true;
    return effect.finished && t > 2 && !pending(t);
  };

  const rewind = () => {
    const effect = player.effect;
    if (!effect) return;
    if (playback.start > 0) {
      player.seek(playback.start);
      player.play();
      return;
    }
    if (playback.lockSeed) effect.restart(player.stage.seed);
    else effect.restart();
    player.stage.stage.time = 0;
  };

  player.on((event) => {
    if (event.type === 'loaded') patch();
    if (event.type === 'frame' && event.playing && player.effect && atEnd(player.effect)) {
      if (playback.loop) rewind();
      else {
        player.pause();
        post({ v: AvfxPlayer.PROTOCOL, type: 'ended' });
      }
    }
    post({ v: AvfxPlayer.PROTOCOL, ...event });
  });

  window.fvHost = {
    setEvents(list) {
      const next = (list ?? []).filter((e) => !e.muted).map((e) => ({ frame: e.frame, kind: e.kind, index: e.index ?? 0 }));
      const changed = JSON.stringify(next) !== JSON.stringify(events);
      events = next;
      patch();
      const effect = player.effect;
      if (!effect || !changed || effect.time <= 0) return;
      const playing = effect.playing;
      player.stage.seed = player.stage.seed;
      player.seek(effect.time);
      if (playing) player.play();
    },
    setPlayback(next) {
      playback = { ...playback, ...next };
    },
    setSeed(seed) {
      if (player.stage.seed !== seed) player.stage.seed = seed;
    },
    frame() {
      const stage = player.stage;
      const effect = player.effect;
      const points = [stage.human.position.toArray()];
      if (effect && effect.target) points.push(effect.target.position.toArray());
      const center = [0, 1, 2].map((k) => points.reduce((sum, p) => sum + p[k], 0) / points.length);
      center[1] += 1;
      const span = Math.max(...points.map((p) => Math.hypot(p[0] - center[0], p[2] - center[2])));
      const distance = Math.max(5.5, span * 2.2 + 3);
      const dir = points.length > 1 ? [0.92, 0.42, -0.1] : [0.55, 0.4, 0.73];
      const length = Math.hypot(...dir);
      player.setCamera({ position: center.map((c, k) => c + (dir[k] / length) * distance), target: center, fov: 45 });
    },
    seekTo(frame, play) {
      const reached = player.seek(frame);
      if (play) player.play();
      return reached;
    },
    play() {
      const effect = player.effect;
      if (!effect) return;
      if (atEnd(effect)) rewind();
      player.play();
    },
    build: AvfxPlayer.BUILD,
  };
})();
