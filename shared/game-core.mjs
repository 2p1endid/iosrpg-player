import path from "node:path";

const MIME_TYPES = new Map([
  [".html", "text/html; charset=utf-8"],
  [".htm", "text/html; charset=utf-8"],
  [".js", "text/javascript; charset=utf-8"],
  [".mjs", "text/javascript; charset=utf-8"],
  [".json", "application/json; charset=utf-8"],
  [".css", "text/css; charset=utf-8"],
  [".png", "image/png"],
  [".jpg", "image/jpeg"],
  [".jpeg", "image/jpeg"],
  [".webp", "image/webp"],
  [".gif", "image/gif"],
  [".svg", "image/svg+xml"],
  [".ogg", "audio/ogg"],
  [".oga", "audio/ogg"],
  [".m4a", "audio/mp4"],
  [".mp3", "audio/mpeg"],
  [".wav", "audio/wav"],
  [".mp4", "video/mp4"],
  [".webm", "video/webm"],
  [".woff", "font/woff"],
  [".woff2", "font/woff2"],
  [".ttf", "font/ttf"],
  [".otf", "font/otf"],
]);

function normalizedSet(paths) {
  return new Set(paths.map((item) => item.replaceAll("\\", "/").replace(/^\.\//, "").toLowerCase()));
}

export function detectEngine(paths) {
  const files = normalizedSet(paths);
  if (!files.has("index.html") || !files.has("data/system.json")) return null;
  if (files.has("js/rmmz_core.js") && files.has("js/rmmz_managers.js")) return "mz";
  if (files.has("js/rpg_core.js") && files.has("js/rpg_managers.js")) return "mv";
  return null;
}

export function safeRelativePath(candidate) {
  if (typeof candidate !== "string" || candidate.length === 0 || candidate.includes("\0")) {
    throw new Error("Resource path is empty or invalid");
  }

  const slashPath = candidate.replaceAll("\\", "/");
  if (slashPath.startsWith("/") || /^[a-zA-Z]:\//.test(slashPath)) {
    throw new Error("Absolute resource paths are not allowed");
  }

  const normalized = path.posix.normalize(slashPath).replace(/^\.\//, "");
  if (normalized === ".." || normalized.startsWith("../") || normalized.split("/").includes("..")) {
    throw new Error("Resource path escapes the game root");
  }
  return normalized;
}

export function mimeTypeForPath(resourcePath) {
  const extension = path.posix.extname(resourcePath).toLowerCase();
  return MIME_TYPES.get(extension) ?? "application/octet-stream";
}
