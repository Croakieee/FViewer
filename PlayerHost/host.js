(() => {
  const post = (message) => window.webkit?.messageHandlers?.avfx?.postMessage(message);
  const player = AvfxPlayer.create(document.getElementById('canvas'), { files: 'avfx://app/game' });
  window.avfxHost = player;

  let scenario = [];
  let stops = [];
  let playback = { start: 0, end: 0, loop: true, loopDelay: 0, lockSeed: true };
  let patchedProto = null;
  const fired = new WeakMap();
  const DENSITY_FRAMES = 900;
  const DENSITY_SEND_MS = 400;
  let density = new Map();
  let densityDirty = false;
  let lastStates = '';
  const characters = new Map();

  const loadCharacter = async (glbUrl, eidUrl) => {
    const [glb, eid] = await Promise.all([
      fetch(glbUrl).then((r) => {
        if (!r.ok) throw new Error(`model ${r.status}`);
        return r.arrayBuffer();
      }),
      eidUrl ? fetch(eidUrl).then((r) => (r.ok ? r.arrayBuffer() : null)) : null,
    ]);
    return AvfxPlayer.loadCharacterModel(glb, eid ? new Uint8Array(eid) : null);
  };

  const record = (effect) => {
    const frame = Math.floor(effect.time);
    if (effect !== player.effect || frame < 0 || frame >= DENSITY_FRAMES) return;
    const counts = { '*': effect.particles.length };
    for (const p of effect.particles) {
      const key = 'e' + p.emitter.schema.index;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    for (const key of new Set([...density.keys(), ...Object.keys(counts)])) {
      if (!density.has(key)) density.set(key, []);
      density.get(key)[frame] = counts[key] ?? 0;
    }
    densityDirty = true;
  };

  const clearDensity = () => {
    density = new Map();
    densityDirty = true;
  };

  const timelineStates = (effect) => {
    const live = new Set([...(effect.emitters ?? []).map((e) => e.timeline), ...effect.particles.map((p) => p.emitter.timeline)]);
    const states = {};
    for (const index of live) {
      if (index < 0) continue;
      if (effect.kill || effect.timelineKills?.has(index)) states[index] = 'fading';
      else if (effect.released) states[index] = 'released';
      else if (effect.settled) states[index] = 'held';
      else states[index] = 'playing';
    }
    return states;
  };

  setInterval(() => {
    if (!densityDirty) return;
    densityDirty = false;
    const series = {};
    for (const [key, values] of density) series[key] = Array.from(values, (value) => value ?? 0);
    post({ v: AvfxPlayer.PROTOCOL, type: 'density', series });
  }, DENSITY_SEND_MS);

  const patch = () => {
    const effect = player.effect;
    if (!effect) return;
    const proto = Object.getPrototypeOf(effect);
    if (patchedProto === proto) return;
    patchedProto = proto;
    const update = proto.update;
    proto.update = function (dt, camera) {
      const before = this.time;
      if (this.playing && stops.length) {
        const done = fired.get(this) ?? new Set();
        fired.set(this, done);
        const next = this.time + dt * this.fps;
        stops.forEach((frame, i) => {
          if (!done.has(i) && frame <= next) {
            done.add(i);
            this.resetInstances();
            this.kill = null;
            this.killed = true;
          }
        });
      }
      const out = update.call(this, dt, camera);
      if (this.time < before) fired.set(this, new Set());
      if (this.time !== before) record(this);
      return out;
    };
  };

  const ranged = () => playback.end > playback.start;

  const atEnd = (effect) => {
    if (ranged()) return effect.time >= playback.end - 0.01;
    return !playback.loop && effect.finished && effect.time > 2;
  };

  const rewind = () => {
    const effect = player.effect;
    if (!effect) return;
    fired.set(effect, new Set());
    if (playback.start > 0) {
      player.seek(0);
      player.seek(playback.start);
      player.play();
      return;
    }
    if (playback.lockSeed) player.restart();
    else {
      effect.restart();
      player.stage.stage.time = 0;
    }
  };

  const replay = () => {
    const effect = player.effect;
    if (!effect) return;
    const time = effect.time;
    const playing = effect.playing;
    fired.set(effect, new Set());
    clearDensity();
    player.playScenario(scenario);
    if (time > 0) player.seek(time);
    if (playing) player.play();
    else player.pause();
  };

  player.on((event) => {
    if (event.type === 'loaded') {
      patch();
      clearDensity();
      if (player.effect && JSON.stringify(player.effect.scenario) !== JSON.stringify(scenario)) replay();
    }
    if (event.type === 'frame' && player.effect) {
      const states = JSON.stringify(timelineStates(player.effect));
      if (states !== lastStates) {
        lastStates = states;
        post({ v: AvfxPlayer.PROTOCOL, type: 'timelines', states: JSON.parse(states) });
      }
    }
    if (event.type === 'frame' && event.playing && player.effect) {
      const effect = player.effect;
      if (atEnd(effect)) {
        if (ranged() && playback.loop) rewind();
        else {
          player.pause();
          post({ v: AvfxPlayer.PROTOCOL, type: 'ended' });
        }
      } else if (playback.start > 0 && effect.time < playback.start - 0.5) {
        player.seek(playback.start);
        player.play();
      }
    }
    post({ v: AvfxPlayer.PROTOCOL, ...event });
  });

  window.fvHost = {
    setEvents(list) {
      const played = (list ?? []).filter((e) => !e.muted);
      const nextScenario = played
        .filter((e) => e.kind === 'trigger' || e.kind === 'release')
        .map((e) => ({ frame: e.frame, action: e.kind, index: e.index ?? 0 }))
        .sort((a, b) => a.frame - b.frame);
      const nextStops = played.filter((e) => e.kind === 'stop').map((e) => e.frame);
      const changed = JSON.stringify([nextScenario, nextStops]) !== JSON.stringify([scenario, stops]);
      scenario = nextScenario;
      stops = nextStops;
      patch();
      if (changed) replay();
    },
    setPlayback(next) {
      playback = { ...playback, ...next };
      player.setView({ loop: playback.loop && !ranged(), loopDelay: playback.loopDelay });
    },
    setSeed(seed) {
      if (player.stage.seed === seed) return;
      player.stage.seed = seed;
      replay();
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
    async setCharacter(glbUrl, eidUrl) {
      const effect = player.effect;
      const time = effect?.time ?? 0;
      const playing = effect?.playing ?? true;
      let info = { clips: [], points: 0 };
      if (glbUrl) {
        if (!characters.has(glbUrl)) characters.set(glbUrl, loadCharacter(glbUrl, eidUrl));
        let model;
        try {
          model = await characters.get(glbUrl);
        } catch (error) {
          characters.delete(glbUrl);
          throw error;
        }
        player.stage.setCharacterModel(model);
        info = { clips: model.clips.map((c) => ({ name: c.name, frames: Math.round(c.duration * 30) })), points: model.character.bindPoints.size };
      } else {
        player.stage.setCharacterModel(null);
      }
      if (player.effect) {
        player.playScenario(scenario);
        if (time > 0) player.seek(time);
        if (playing) player.play();
        else player.pause();
      }
      return info;
    },
    setFacing(degrees) {
      const stage = player.stage;
      if (stage.stage.facing === degrees) return;
      const effect = player.effect;
      const time = effect?.time ?? 0;
      const playing = effect?.playing ?? true;
      stage.setFacing(degrees);
      if (!effect) return;
      player.playScenario(scenario);
      if (time > 0) player.seek(time);
      if (playing) player.play();
      else player.pause();
    },
    setPose(name, frame, play) {
      const stage = player.stage.stage;
      stage.pose = name ?? '';
      stage.poseFrame = Math.max(0, Math.round(frame ?? 0));
      stage.posePlay = !!play;
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
