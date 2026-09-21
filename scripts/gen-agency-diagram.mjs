#!/usr/bin/env node
/**
 * Generates docs/agency-flow.svg — the Hermes SDD agency orchestration flow.
 *
 * Why a hand-built SVG instead of a mermaid render: mermaid v11 emits <foreignObject>
 * for labels; GitHub strips it, so the diagram renders broken in the repo. This
 * generator emits pure SVG text/tspan nodes with the same palette, so it renders
 * correctly in GitHub, the Hermes preview pane, and any browser. It is the single
 * source of truth for the diagram: if the flow changes, edit THIS file and re-run
 * `node scripts/gen-agency-diagram.mjs`.
 *
 * Usage:  node scripts/gen-agency-diagram.mjs   (writes docs/agency-flow.svg)
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(__dirname, "..", "docs", "agency-flow.svg");

const W = 860; // viewBox width
const CX = 340; // main column center
const BOX_W = 480;
const BOX_H = 56;
const DIAMOND_W = 400;
const DIAMOND_H = 72;

const PALETTE = {
  human: { fill: "#3d3a2e", stroke: "#d4a72c", text: "#f0e6c8" },
  stage: { fill: "#24322b", stroke: "#6ee7b7", text: "#d6f5e8" },
  gate:  { fill: "#3b2733", stroke: "#f0a6c9", text: "#f8dcec" },
  post:  { fill: "#2b2b3d", stroke: "#9aa5f0", text: "#dfe3fb" },
  stop:  { fill: "#3a2424", stroke: "#f08080", text: "#fbdada" },
};
const LINE = "#8b8273";
const SUB = "#b3ab9c";
const BG = "#171512";
const FG = "#e8e2d5";

// ---- data model -----------------------------------------------------------
// kind: "box" | "diamond"; type: palette key
const nodes = [
  { id: "U",   kind: "box",     type: "human", y: 86,  title: "Migue — idea clara + repo" },
  { id: "G0",  kind: "diamond", type: "gate",  y: 188, title: "¿openspec/project.md?", sub: "marca de entrada al loop" },
  { id: "S0",  kind: "box",     type: "stage", y: 282, title: "0 · Initialize", sub: "crea openspec/ + project.md — sin esto nada arranca" },
  { id: "S1",  kind: "box",     type: "stage", y: 370, title: "1 · Discovery", sub: "explora el dominio → PRD" },
  { id: "S2",  kind: "box",     type: "stage", y: 458, title: "2 · Specs (OpenSpec CLI)", sub: "proposal + delta spec con Scenario:" },
  { id: "G1",  kind: "diamond", type: "gate",  y: 566, title: "validate sin ERROR", sub: "+ grep anti-trampas" },
  { id: "S3",  kind: "box",     type: "stage", y: 660, title: "3 · Architecture", sub: "design + ADR si hay decisión costosa" },
  { id: "S4",  kind: "box",     type: "stage", y: 748, title: "4 · Plan", sub: "tasks.md — tareas ≤1 día verificables" },
  { id: "G2",  kind: "diamond", type: "gate",  y: 856, title: "preflight: root + proyecto", sub: "validate + project.md + root ok" },
  { id: "S5",  kind: "box",     type: "stage", y: 950, title: "5 · Build — única etapa que escribe código", sub: "TDD hard rule: RED → GREEN → REFACTOR" },
  { id: "S6",  kind: "box",     type: "stage", y: 1038, title: "6 · Review adversarial", sub: "findings BLOCKER / MAJOR / MINOR" },
  { id: "G3",  kind: "diamond", type: "gate",  y: 1146, title: "¿review approved?", sub: "sin BLOCKER/MAJOR abiertos" },
  { id: "S7",  kind: "box",     type: "stage", y: 1240, title: "7 · QA formal", sub: "escenarios ejecutados contra la app real" },
  { id: "G4",  kind: "diamond", type: "gate",  y: 1348, title: "¿qa pass?", sub: "evidencia = ejecución real, no lectura" },
  { id: "S8",  kind: "box",     type: "stage", y: 1442, title: "8 · Release", sub: "notas + archive + sync specs" },
  { id: "R1",  kind: "box",     type: "stage", y: 1530, title: "Reporte final + git status limpio", sub: "toda etapa cierra con reporte" },
  { id: "PR",  kind: "box",     type: "stage", y: 1618, title: "PR abierto (nunca draft)", sub: "gh pr ready si quedó draft" },
  { id: "G5",  kind: "diamond", type: "gate",  y: 1726, title: "CI verde", sub: "gate post-open: corre DESPUÉS de publicar" },
  { id: "PRR", kind: "box",     type: "post",  y: 1820, title: "9 · pr-review (post-open)", sub: "review de dominio + QA formal obligatorio — no mergea" },
  { id: "AP",  kind: "box",     type: "human", y: 1908, title: "PR approved ✅", sub: "el merge es decisión humana, nunca de la agencia" },
];
const byId = Object.fromEntries(nodes.map((n) => [n.id, n]));

// main chain in order — vertical arrows center to center
const chain = ["U", "G0", "S0", "S1", "S2", "G1", "S3", "S4", "G2", "S5", "S6", "G3", "S7", "G4", "S8", "R1", "PR", "G5", "PRR", "AP"];

// loop-backs: from diamond right edge, up/down the right rail, into target right edge
// path: start id, target id, label, entry offset (px below target center)
const loops = [
  { from: "G1", to: "S2", label: "invalid → repite specs", entryOff: -4 },
  { from: "G3", to: "S5", label: "no → builder (máx 3 ciclos)", entryOff: -10 },
  { from: "G4", to: "S5", label: "fail → builder (máx 3 ciclos)", entryOff: 14 },
];

// G2 → STOP branch (right side)
const stopNode = { kind: "box", type: "stop", x: 690, y: 856, title: "⛔ Stop — no código sin", sub: "change validado" };
const STOP_X = 690, STOP_W = 200, STOP_H = 64;

// ---- helpers --------------------------------------------------------------
const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

function box(n) {
  const x = CX - BOX_W / 2, y = n.y - BOX_H / 2;
  const p = PALETTE[n.type];
  const lines = [`<rect x="${x}" y="${y}" width="${BOX_W}" height="${BOX_H}" rx="12" fill="${p.fill}" stroke="${p.stroke}" stroke-width="1.6"/>`];
  if (n.title) lines.push(`<text x="${CX}" y="${n.y - (n.sub ? 6 : 0)}" text-anchor="middle" font-size="13.5" font-weight="650" fill="${p.text}">${esc(n.title)}</text>`);
  if (n.sub) lines.push(`<text x="${CX}" y="${n.y + 14}" text-anchor="middle" font-size="11" fill="${SUB}">${esc(n.sub)}</text>`);
  return lines.join("\n");
}

function diamond(n) {
  const x = CX - DIAMOND_W / 2, y = n.y - DIAMOND_H / 2;
  const p = PALETTE[n.type];
  const pts = `${CX},${y} ${CX + DIAMOND_W / 2},${n.y} ${CX},${y + DIAMOND_H} ${CX - DIAMOND_W / 2},${n.y}`;
  const lines = [`<polygon points="${pts}" fill="${p.fill}" stroke="${p.stroke}" stroke-width="1.6"/>`];
  lines.push(`<text x="${CX}" y="${n.y - (n.sub ? 4 : 0)}" text-anchor="middle" font-size="12.5" font-weight="650" fill="${p.text}">${esc(n.title)}</text>`);
  if (n.sub) lines.push(`<text x="${CX}" y="${n.y + 14}" text-anchor="middle" font-size="10.5" fill="${SUB}">${esc(n.sub)}</text>`);
  return lines.join("\n");
}

const arrowDown = (x, y1, y2) =>
  `<line x1="${x}" y1="${y1}" x2="${x}" y2="${y2}" stroke="${LINE}" stroke-width="1.6" marker-end="url(#a)"/>`;

const bottomY = (id) => (byId[id].kind === "diamond" ? byId[id].y + DIAMOND_H / 2 : byId[id].y + BOX_H / 2);
const topY    = (id) => (byId[id].kind === "diamond" ? byId[id].y - DIAMOND_H / 2 : byId[id].y - BOX_H / 2);

// ---- compose --------------------------------------------------------------
const parts = [];
parts.push(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${2030}" width="100%" role="img" aria-label="Hermes SDD Agency orchestration flow">`);
parts.push(`<rect width="${W}" height="2030" fill="${BG}"/>`);
parts.push(`<text x="24" y="40" font-size="17" font-weight="700" fill="${FG}">Hermes SDD Agency — flujo de orquestación</text>`);
parts.push(`<text x="24" y="62" font-size="12" fill="${SUB}">Hermes = único bus · OpenSpec dentro del repo del proyecto · solo review y QA pueden bloquear</text>`);
parts.push(`<defs><marker id="a" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="${LINE}"/></marker></defs>`);

// nodes
for (const n of nodes) parts.push(n.kind === "box" ? box(n) : diamond(n));

// G2 fail → stop node
{
  const p = PALETTE.stop;
  const stopY = stopNode.y - STOP_H / 2;
  parts.push(`<rect x="${STOP_X}" y="${stopY}" width="${STOP_W}" height="${STOP_H}" rx="10" fill="${p.fill}" stroke="${p.stroke}" stroke-width="1.6"/>`);
  parts.push(`<text x="${STOP_X + STOP_W / 2}" y="${stopNode.y - 4}" text-anchor="middle" font-size="12.5" font-weight="650" fill="${p.text}">${esc(stopNode.title)}</text>`);
  parts.push(`<text x="${STOP_X + STOP_W / 2}" y="${stopNode.y + 14}" text-anchor="middle" font-size="11" fill="${SUB}">${esc(stopNode.sub)}</text>`);
}

// main chain arrows
for (let i = 0; i < chain.length - 1; i++) {
  const a = chain[i], b = chain[i + 1];
  parts.push(arrowDown(CX, bottomY(a) + 2, topY(b) - 2));
}

// loop-back arrows (right rail at x=640)
const RAIL = CX + BOX_W / 2 + 40; // 340+240+40 = 620
for (const lp of loops) {
  const f = byId[lp.from], t = byId[lp.to];
  const yFrom = f.y, yTo = t.y + lp.entryOff;
  const d = yFrom < yTo ? 1 : -1;
  parts.push(`<path d="M ${CX + DIAMOND_W / 2} ${yFrom} H ${RAIL} V ${yTo} H ${CX + BOX_W / 2}" fill="none" stroke="${LINE}" stroke-width="1.6" marker-end="url(#a)"/>`);
  const lx = RAIL + 8;
  const ly = (yFrom + yTo) / 2;
  const anchor = d === 1 ? "start" : "start";
  // labels: rotated not needed — place horizontally to the right of rail
  void anchor;
  parts.push(`<text x="${lx}" y="${ly}" font-size="10.5" fill="${SUB}">${esc(lp.label)}</text>`);
}

// G2 → stop: horizontal arrow from diamond right edge
parts.push(`<line x1="${CX + DIAMOND_W / 2}" y1="${byId.G2.y}" x2="${STOP_X}" y2="${byId.G2.y}" stroke="${LINE}" stroke-width="1.6" marker-end="url(#a)"/>`);
parts.push(`<text x="${STOP_X - 8}" y="${byId.G2.y - 10}" text-anchor="end" font-size="10.5" fill="${SUB}">fail</text>`);

// legend — two rows so it fits the viewBox
const legend1 = [
  { type: "stage", label: "etapa (un agente por etapa)" },
  { type: "gate", label: "gate — avanza solo verificado en el repo" },
  { type: "post", label: "pr-review = post-open, no mergea" },
];
const legend2 = [
  { type: "stop", label: "hard gate: no código sin change validado" },
  { type: "human", label: "humano — entrada + decisión final" },
];
const drawLegend = (items, yBase) => {
  let lx = 24;
  parts.push(`<text x="${lx}" y="${yBase}" font-size="11" fill="${SUB}">Leyenda:</text>`);
  lx += 60;
  for (const L of items) {
    const p = PALETTE[L.type];
    parts.push(`<rect x="${lx}" y="${yBase - 11}" width="12" height="12" rx="2" fill="${p.fill}" stroke="${p.stroke}" stroke-width="1.2"/>`);
    parts.push(`<text x="${lx + 18}" y="${yBase}" font-size="11" fill="${FG}">${esc(L.label)}</text>`);
    lx += 18 + L.label.length * 5.6 + 26;
  }
};
drawLegend(legend1, 1990);
drawLegend(legend2, 2014);
parts.push(`<text x="${W - 20}" y="2014" text-anchor="end" font-size="10.5" fill="${SUB}">fuente: scripts/gen-agency-diagram.mjs</text>`);

parts.push("</svg>");

fs.writeFileSync(OUT, parts.join("\n") + "\n");
console.log("wrote", OUT, "|", (parts.join("").length).toLocaleString(), "chars");
