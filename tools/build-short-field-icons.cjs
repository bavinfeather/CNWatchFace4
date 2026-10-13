const fs = require('fs');
const path = require('path');
const sharp = require('C:/Users/bavin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root = path.resolve(__dirname, '..');
const src = path.join(root, 'assets/lucide-short-fields');
const out = path.join(root, 'resources/drawables/short-fields');
fs.mkdirSync(out, {recursive:true});
(async () => {
  const names = JSON.parse(fs.readFileSync(path.join(src, 'source.json'))).icons;
  for (const name of names) {
    const svg = fs.readFileSync(path.join(src, name+'.svg'), 'utf8').replace(/currentColor/g, '#C4D1DB');
    await sharp(Buffer.from(svg)).resize(32,32).png().toFile(path.join(out,name+'.png'));
  }
})();
