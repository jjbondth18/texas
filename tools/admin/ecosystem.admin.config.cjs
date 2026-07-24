const fs = require("node:fs");
const path = require("node:path");

const adminDir = __dirname;
const envPath = process.env.ADMIN_ENV_FILE || path.join(adminDir, ".env.server");
if (!fs.existsSync(envPath)) throw new Error(`Missing ${envPath}`);
const env = {};
for (const raw of fs.readFileSync(envPath, "utf8").split(/\r?\n/)) {
  const line = raw.trim();
  if (!line || line.startsWith("#")) continue;
  const separator = line.indexOf("=");
  if (separator > 0) env[line.slice(0, separator).trim()] = line.slice(separator + 1).trim();
}

module.exports = {
  apps: [{
    name: "texas-admin",
    cwd: path.resolve(adminDir, "../..", "server"),
    script: "dist/admin/index.js",
    env,
    autorestart: true,
    max_restarts: 10,
    min_uptime: "10s",
  }],
};
