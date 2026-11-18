import { randomBytes } from "node:crypto";
const token = randomBytes(32).toString("hex");
console.log(token);
console.error("Save this token into your local .env as MCP_TOKEN. Do not share it in chat or commit it.");
