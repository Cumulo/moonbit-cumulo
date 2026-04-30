const fs = require("fs");
const path = require("path");

const projectRoot = path.resolve(__dirname, "..");
const sourcePath = path.join(projectRoot, "_build/js/debug/build/cmd/client/client.js");
const targetDir = path.join(projectRoot, "public/static");
const targetPath = path.join(targetDir, "client.js");

if (!fs.existsSync(sourcePath)) {
  console.error(`Missing MoonBit client bundle: ${sourcePath}`);
  process.exit(1);
}

fs.mkdirSync(targetDir, { recursive: true });
fs.copyFileSync(sourcePath, targetPath);
console.log(`Synced ${path.relative(projectRoot, targetPath)}`);