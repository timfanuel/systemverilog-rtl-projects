// Optional: node sim/render-waveform.mjs, after simulation. Reads actual VCD events.
import fs from 'node:fs';
const text=fs.readFileSync('build/uart_tx.vcd','utf8');
if(!/\$timescale\s+1ps\s+\$end/.test(text)) throw Error('Expected 1ps VCD');
const tracks=[];
for(const line of text.split(/\r?\n/)) {
  const m=line.match(/^\$var \w+ (\d+) (\S+) (\w+)/);
  if(m) tracks.push({width:Number(m[1]),id:m[2],name:m[3],events:[]});
}
let time=0;
for(const line of text.split(/\r?\n/)) {
  if(line.startsWith('#')) time=Number(line.slice(1))/1000;
  const m=line.match(/^(?:b([01xz]+)\s+(\S+)|([01xz])(\S+))$/);
  if(m) {const t=tracks.find(t=>t.id===(m[2]??m[4]));if(t)t.events.push([time,m[1]??m[3]]);}
}
const at=(track,t)=>track.events.filter(e=>e[0]<=t).at(-1)?.[1];
const data=tracks.find(t=>t.name==='tx_data'),valid=tracks.find(t=>t.name==='tx_valid'),ready=tracks.find(t=>t.name==='tx_ready');
const accept=data.events.find(([t,v])=>parseInt(v,2)===0xa5&&at(valid,t)==='1'&&at(ready,t)==='1');
if(!accept) throw Error('No A5 acceptance found');
const start=accept[0]-20,end=start+900,left=150,right=1140;
const x=t=>left+(t-start)*(right-left)/(end-start);
let svg='<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="345" viewBox="0 0 1200 345"><rect width="1200" height="345" fill="white"/><g font-family="sans-serif" fill="#14283d"><text x="24" y="28" font-size="19">UART TX: captured 0xA5 frame, 8 clocks per bit</text><text x="24" y="49" font-size="12">Actual ModelSim 10.5b VCD · 10 ns clock · 8N1, LSB first · time relative to excerpt in ns</text>';
for(let t=0;t<=900;t+=100)svg+=`<path d="M ${x(start+t)} 75 V 308" stroke="#e0e7ee"/><text x="${x(start+t)}" y="70" text-anchor="middle" font-size="11">${t}</text>`;
tracks.forEach((track,i)=>{
  const y=94+i*39;
  svg+=`<text x="24" y="${y+5}" font-size="13">${track.name}</text>`;
  track.events.forEach(([t,v],j)=>{
    const until=Math.min(track.events[j+1]?.[0]??end,end);
    if(t>=end||until<=start||until<=t)return;
    const a=x(Math.max(t,start)),b=x(until);
    if(track.width===1){const yy=y+(v==='1'?-9:9);svg+=`<path d="M ${a} ${yy} H ${b}" stroke="#186e56" stroke-width="2"/>`;if(t>start&&j>0&&track.events[j-1][1]!==v)svg+=`<path d="M ${a} ${y-9} V ${y+9}" stroke="#186e56"/>`;}
    else {svg+=`<rect x="${a}" y="${y-10}" width="${b-a}" height="20" fill="#edf3fa" stroke="#356b9c"/>`;if(b-a>26)svg+=`<text x="${(a+b)/2}" y="${y+4}" text-anchor="middle" font-size="11">0x${parseInt(v,2).toString(16).toUpperCase()}</text>`;}
  });
});
svg+='<text x="24" y="330" font-size="12">Payload bits: 1,0,1,0,0,1,0,1. Input changes to 0x5A while busy; latched A5 is retained.</text></g></svg>';
fs.mkdirSync('docs',{recursive:true});fs.writeFileSync('docs/uart_tx_waveform.svg',svg);
