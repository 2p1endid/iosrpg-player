(() => {
  const canvas = document.querySelector("#game");
  const context = canvas.getContext("2d");
  const held = new Set();
  const stateKey = "rrppgo-test-position";
  const stored = JSON.parse(localStorage.getItem(stateKey) || "null");
  const player = {
    x: stored?.x ?? 390,
    y: stored?.y ?? 300,
    size: 34,
    speed: 230
  };
  let confirmationCount = Number(localStorage.getItem("rrppgo-confirmations") || 0);
  let lastTime = performance.now();
  let lastSavedAt = 0;

  const bridge = (message) => {
    const handler = window.webkit?.messageHandlers?.gameBridge;
    if (handler) handler.postMessage(message);
    else console.log(`[gameBridge] ${message}`);
  };

  const save = (now) => {
    if (now - lastSavedAt < 300) return;
    localStorage.setItem(stateKey, JSON.stringify({ x: player.x, y: player.y }));
    lastSavedAt = now;
  };

  const onKey = (event, down) => {
    if (["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", "Enter", "Escape"].includes(event.key)) {
      event.preventDefault();
    }
    if (down) held.add(event.key);
    else held.delete(event.key);

    if (down && !event.repeat && event.key === "Enter") {
      confirmationCount += 1;
      localStorage.setItem("rrppgo-confirmations", String(confirmationCount));
      bridge(`A/Enter 已触发 ${confirmationCount} 次`);
    }
    if (down && !event.repeat && event.key === "Escape") {
      player.x = 390;
      player.y = 300;
      save(performance.now() + 1000);
      bridge("B/Escape：位置已重置");
    }
  };

  addEventListener("keydown", (event) => onKey(event, true));
  addEventListener("keyup", (event) => onKey(event, false));
  addEventListener("blur", () => held.clear());

  function update(delta, now) {
    let dx = 0;
    let dy = 0;
    if (held.has("ArrowLeft")) dx -= 1;
    if (held.has("ArrowRight")) dx += 1;
    if (held.has("ArrowUp")) dy -= 1;
    if (held.has("ArrowDown")) dy += 1;
    if (dx && dy) {
      const diagonal = Math.SQRT1_2;
      dx *= diagonal;
      dy *= diagonal;
    }
    player.x = Math.max(18, Math.min(canvas.width - player.size - 18, player.x + dx * player.speed * delta));
    player.y = Math.max(110, Math.min(canvas.height - player.size - 18, player.y + dy * player.speed * delta));
    if (dx || dy) save(now);
  }

  function drawGrid() {
    context.strokeStyle = "rgba(124, 153, 255, 0.10)";
    context.lineWidth = 1;
    for (let x = 0; x <= canvas.width; x += 48) {
      context.beginPath(); context.moveTo(x, 0); context.lineTo(x, canvas.height); context.stroke();
    }
    for (let y = 0; y <= canvas.height; y += 48) {
      context.beginPath(); context.moveTo(0, y); context.lineTo(canvas.width, y); context.stroke();
    }
  }

  function draw() {
    const gradient = context.createLinearGradient(0, 0, canvas.width, canvas.height);
    gradient.addColorStop(0, "#101936");
    gradient.addColorStop(1, "#291449");
    context.fillStyle = gradient;
    context.fillRect(0, 0, canvas.width, canvas.height);
    drawGrid();

    context.fillStyle = "rgba(4, 8, 23, 0.86)";
    context.fillRect(0, 0, canvas.width, 90);
    context.fillStyle = "#ffffff";
    context.font = "bold 26px -apple-system, sans-serif";
    context.fillText("MV/MZ Web Runtime 验证", 28, 38);
    context.fillStyle = "#a9b9ed";
    context.font = "18px -apple-system, sans-serif";
    context.fillText("方向键移动 · A/Enter 计数 · B/Escape 重置 · 位置自动保存", 28, 70);

    context.shadowColor = "rgba(74, 222, 255, 0.75)";
    context.shadowBlur = 18;
    context.fillStyle = "#42dcff";
    context.fillRect(player.x, player.y, player.size, player.size);
    context.shadowBlur = 0;
    context.strokeStyle = "#d9fbff";
    context.lineWidth = 3;
    context.strokeRect(player.x, player.y, player.size, player.size);

    context.fillStyle = "rgba(0,0,0,0.48)";
    context.fillRect(20, canvas.height - 57, 430, 37);
    context.fillStyle = "#dce5ff";
    context.font = "16px ui-monospace, monospace";
    context.fillText(
      `x=${Math.round(player.x)} y=${Math.round(player.y)} confirmations=${confirmationCount}`,
      32,
      canvas.height - 32
    );
  }

  function frame(now) {
    const delta = Math.min(0.05, (now - lastTime) / 1000);
    lastTime = now;
    update(delta, now);
    draw();
    requestAnimationFrame(frame);
  }

  bridge(`runtime-ready:${window.RPGMZRuntime?.engine ?? "unknown"}`);
  requestAnimationFrame(frame);
})();
