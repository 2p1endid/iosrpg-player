import { createServer } from "node:http";
import { readFile, stat } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { mimeTypeForPath, safeRelativePath } from "../shared/game-core.mjs";

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDirectory, "../Resources/TestGame");
const port = Number(process.env.PORT || 4173);

const server = createServer(async (request, response) => {
  try {
    const requestURL = new URL(request.url || "/", `http://${request.headers.host || "localhost"}`);
    const requested = requestURL.pathname === "/" ? "index.html" : requestURL.pathname.slice(1);
    const relative = safeRelativePath(decodeURIComponent(requested));
    const filePath = path.resolve(root, relative);
    if (filePath !== root && !filePath.startsWith(root + path.sep)) throw new Error("Path traversal");
    const info = await stat(filePath);
    if (!info.isFile()) throw new Error("Not a file");
    const body = await readFile(filePath);
    response.writeHead(200, {
      "Content-Type": mimeTypeForPath(relative),
      "Content-Length": body.length,
      "Cache-Control": "no-store"
    });
    response.end(body);
  } catch (error) {
    response.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
    response.end(`Not found: ${error.message}`);
  }
});

server.listen(port, "127.0.0.1", () => {
  console.log(`Test game: http://127.0.0.1:${port}`);
});
