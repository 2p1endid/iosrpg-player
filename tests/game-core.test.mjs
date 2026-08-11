import test from "node:test";
import assert from "node:assert/strict";
import { detectEngine, safeRelativePath, mimeTypeForPath } from "../shared/game-core.mjs";

test("detects RPG Maker MV from core script", () => {
  assert.equal(
    detectEngine(["index.html", "js/rpg_core.js", "js/rpg_managers.js", "data/System.json"]),
    "mv",
  );
});

test("detects RPG Maker MZ from core script", () => {
  assert.equal(
    detectEngine(["index.html", "js/rmmz_core.js", "js/rmmz_managers.js", "data/System.json"]),
    "mz",
  );
});

test("rejects an incomplete web game", () => {
  assert.equal(detectEngine(["index.html", "data/System.json"]), null);
});

test("normalizes a safe relative resource path", () => {
  assert.equal(safeRelativePath("img/characters/Actor1.png"), "img/characters/Actor1.png");
  assert.equal(safeRelativePath("./audio/bgm/Theme.ogg"), "audio/bgm/Theme.ogg");
});

test("rejects path traversal and absolute paths", () => {
  for (const candidate of ["../secret", "img/../../secret", "/etc/passwd", "C:/Windows/win.ini", "C:\\Windows\\win.ini"]) {
    assert.throws(() => safeRelativePath(candidate));
  }
});

test("returns WebKit-friendly MIME types", () => {
  assert.equal(mimeTypeForPath("index.html"), "text/html; charset=utf-8");
  assert.equal(mimeTypeForPath("js/rmmz_core.js"), "text/javascript; charset=utf-8");
  assert.equal(mimeTypeForPath("data/System.json"), "application/json; charset=utf-8");
  assert.equal(mimeTypeForPath("audio/bgm/theme.ogg"), "audio/ogg");
  assert.equal(mimeTypeForPath("fonts/gamefont.woff2"), "font/woff2");
  assert.equal(mimeTypeForPath("unknown.bin"), "application/octet-stream");
});
