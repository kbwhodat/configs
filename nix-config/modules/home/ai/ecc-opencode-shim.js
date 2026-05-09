import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const eccSkillsDir = path.resolve(__dirname, "skills");
const eccOpenCodeDir = path.resolve(__dirname, ".opencode");

function loadEccConfig() {
  const configPath = path.join(eccOpenCodeDir, "opencode.json");
  if (!fs.existsSync(configPath)) return null;
  return JSON.parse(fs.readFileSync(configPath, "utf8"));
}

function resolveFileRefs(obj, baseDir) {
  if (typeof obj === "string") {
    const match = obj.match(/^\{file:(.+)\}$/);
    if (match) {
      const filePath = path.join(baseDir, match[1]);
      if (fs.existsSync(filePath)) return fs.readFileSync(filePath, "utf8");
    }
    return obj;
  }
  if (Array.isArray(obj)) return obj.map(v => resolveFileRefs(v, baseDir));
  if (obj && typeof obj === "object") {
    const out = {};
    for (const [k, v] of Object.entries(obj)) out[k] = resolveFileRefs(v, baseDir);
    return out;
  }
  return obj;
}

export default async ({ client, directory }) => {
  return {
    config: async (config) => {
      config.skills = config.skills || {};
      config.skills.paths = config.skills.paths || [];
      if (fs.existsSync(eccSkillsDir) && !config.skills.paths.includes(eccSkillsDir)) {
        config.skills.paths.push(eccSkillsDir);
      }

      const ecc = loadEccConfig();
      if (!ecc) return;

      if (ecc.agent) {
        config.agent = config.agent || {};
        for (const [name, def] of Object.entries(ecc.agent)) {
          if (name === "build") {
            config.agent["ecc-build"] = resolveFileRefs(def, eccOpenCodeDir);
          } else if (!config.agent[name]) {
            config.agent[name] = resolveFileRefs(def, eccOpenCodeDir);
          }
        }
      }

      if (ecc.command) {
        config.command = config.command || {};
        for (const [name, def] of Object.entries(ecc.command)) {
          if (!config.command[name]) {
            config.command[name] = resolveFileRefs(def, eccOpenCodeDir);
          }
        }
      }
    },
  };
};
