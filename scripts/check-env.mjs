import { execSync } from "node:child_process";
import { existsSync } from "node:fs";

function ver(cmd) {
  try { return execSync(cmd, { encoding: "utf8" }).trim().split("\n")[0]; }
  catch { return null; }
}

const node = ver("node -v");
const npx = ver("npx -v");
const share = process.env.SHARE_DIR || "";
console.log(`node: ${node ?? "MISSING (need 20+)"}`);
console.log(`npx:  ${npx ?? "MISSING"}`);
console.log(`SHARE_DIR: ${share ? (existsSync(share) ? share + " (exists)" : share + " (NOT FOUND)") : "(not set, set it in .env)"}`);
if (!node || !npx) process.exit(1);
console.log("check-env: ok");
