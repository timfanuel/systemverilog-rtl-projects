// Render an actual VCD excerpt; Node.js is needed only for this optional step.
// Run from the repository root: node sim/render-waveform.mjs
import fs from 'node:fs';
const text = fs.readFileSync('build/round_robin_arbiter.vcd', 'utf8');
const tracks = [];
for (const line of text.split(/\r?\n/)) {
  const m = line.match(/^\$var \w+ (\d+) (\S+) (\w+)/);
  if (m) tracks.push({width: Number(m[1]), id: m[2], name: m[3], events: []});
}
if (!/\$timescale\s+1ps\s+\$end/.test(text)) throw Error('Expected 1ps VCD');
let time = 0;
for (const line of text.split(/\r?\n/)) {
  if (line.startsWith('#')) time = Number(line.slice(1)) / 1000;
  const m = line.match(/^(?:b([01xz]+)\s+(\S+)|([01xz])(\S+))$/);
  if (m) {
    const track = tracks.find(t => t.id === (m[2] ?? m[4]));
    if (track) track.events.push([time, m[1] ?? m[3]]);
  }
}
const start = 1930, end = 2110, left = 150, right = 1140;
const x = t => left + (t - start) * (right - left) / (end - start);
const esc = s => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
let svg = '<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="440" viewBox="0 0 1200 440"><rect width="1200" height="440" fill="#fff"/><g font-family="sans-serif" fill="#14283d"><text x="24" y="28" font-size="19">Round-robin arbiter: captured full-contention rotation</text><text x="24" y="49" font-size="12">Four requesters, SEED=1 · ModelSim 10.5b · values after each event · time in ns</text>';
for (let t = start; t <= end; t += 20) svg += `<path d="M ${x(t)} 75 V 383" stroke="#e0e7ee"/><text x="${x(t)}" y="70" text-anchor="middle" font-size="11">${t}</text>`;
tracks.forEach((track, i) => {
  const y = 94 + i * 39;
  svg += `<text x="24" y="${y+5}" font-size="13">${esc(track.name)}</text>`;
  const events = track.events.filter(e => e[0] <= end);
  for (let j = 0; j < events.length; j++) {
    const [t, value] = events[j], until = Math.min(events[j+1]?.[0] ?? end, end);
    if (until <= start || until <= t) continue;
    const a = x(Math.max(t, start)), b = x(until);
    if (track.width === 1) {
      const yy = y + (value === '1' ? -9 : 9);
      svg += `<path d="M ${a} ${yy} H ${b}" fill="none" stroke="${/[xz]/.test(value) ? '#a33' : '#186e56'}" stroke-width="2"/>`;
      if (j > 0 && events[j-1][1] !== value) svg += `<path d="M ${a} ${y-9} V ${y+9}" stroke="#186e56"/>`;
    } else {
      svg += `<path d="M ${a} ${y} L ${a+2} ${y-10} H ${Math.max(a+2,b-2)} L ${b} ${y} L ${Math.max(a+2,b-2)} ${y+10} H ${a+2} Z" fill="#edf3fa" stroke="#356b9c"/>`;
      if (b-a > 25) svg += `<text x="${(a+b)/2}" y="${y+4}" text-anchor="middle" font-size="11">${/[xz]/.test(value) ? value : '0x'+parseInt(value,2).toString(16).toUpperCase()}</text>`;
    }
  }
});
svg += '<text x="24" y="414" font-size="12">With req=0xF, pre-edge service rotates 0,1,2,3. Combinational grant advances after each rising edge.</text></g></svg>';
fs.mkdirSync('docs', {recursive:true});
fs.writeFileSync('docs/round_robin_arbiter_waveform.svg', svg);
