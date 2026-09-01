import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const width = 1290;
const height = 2796;
const output = join(import.meta.dirname, "screenshots-src");

mkdirSync(output, { recursive: true });

const palettes = {
  paper: "#D9D5BF",
  panel: "#E9E5D2",
  green: "#AEB77B",
  ink: "#20251B",
  muted: "#59604A",
  red: "#B43A2B",
  line: "#3D4331",
  tag: "#DD8A48"
};

function escape(value) {
  return value.replaceAll("&", "&amp;").replaceAll("<", "&lt;");
}

function text(x, y, value, size, options = {}) {
  const anchor = options.anchor ?? "start";
  const fill = options.fill ?? palettes.ink;
  const weight = options.weight ?? 700;
  const family = options.family ?? "Menlo, monospace";
  const letterSpacing = options.letterSpacing ?? 0;
  return `<text x="${x}" y="${y}" text-anchor="${anchor}" fill="${fill}" font-family="${family}" font-size="${size}" font-weight="${weight}" letter-spacing="${letterSpacing}">${escape(value)}</text>`;
}

function multiline(x, y, lines, size, options = {}) {
  const leading = options.leading ?? Math.round(size * 1.36);
  return lines.map((line, index) => text(x, y + index * leading, line, size, options)).join("\n");
}

function waveform(x, y, count, activeIndex = -1) {
  const bars = [];
  for (let index = 0; index < count; index += 1) {
    const amplitude = 20 + ((index * 37 + 19) % 115);
    const barX = x + index * 13;
    const color = index === activeIndex ? palettes.red : palettes.ink;
    bars.push(`<rect x="${barX}" y="${y - amplitude / 2}" width="7" height="${amplitude}" fill="${color}"/>`);
  }
  return bars.join("");
}

function appShell(body, options = {}) {
  const title = options.title ?? "RETRO REC";
  const status = options.status ?? "REC";
  const quality = options.quality ?? "48 kHz / 24-bit";
  return `
    <g>
      <rect x="96" y="592" width="1098" height="1780" rx="26" fill="#C8C4AF" stroke="${palettes.ink}" stroke-width="12"/>
      <rect x="118" y="614" width="1054" height="1736" rx="14" fill="${palettes.panel}" stroke="${palettes.line}" stroke-width="5"/>
      <rect x="148" y="652" width="994" height="104" fill="#F5F0DC" stroke="${palettes.ink}" stroke-width="5"/>
      ${text(192, 720, "☷", 37, { family: "Arial" })}
      ${text(645, 718, title, 32, { anchor: "middle", weight: 900, letterSpacing: 2 })}
      ${text(1094, 720, "⚙", 34, { anchor: "end", family: "Arial" })}
      <rect x="148" y="780" width="994" height="84" fill="#F5F0DC" stroke="${palettes.ink}" stroke-width="5"/>
      <rect x="164" y="794" width="306" height="56" fill="none" stroke="${palettes.line}" stroke-width="2"/>
      <rect x="490" y="794" width="306" height="56" fill="none" stroke="${palettes.line}" stroke-width="2"/>
      <rect x="816" y="794" width="310" height="56" fill="none" stroke="${palettes.line}" stroke-width="2"/>
      ${text(177, 815, "INPUT", 12, { fill: palettes.muted, weight: 900 })}
      ${text(177, 839, "iPhone Mic  ▾", 17, { weight: 900 })}
      ${text(503, 815, "NR", 12, { fill: palettes.muted, weight: 900 })}
      ${text(503, 839, "RNNoise  ▾", 17, { weight: 900 })}
      ${text(829, 815, "AEC", 12, { fill: palettes.muted, weight: 900 })}
      ${text(829, 839, "Enabled  ▾", 17, { weight: 900 })}
      <rect x="148" y="890" width="994" height="1058" fill="${palettes.green}" stroke="${palettes.ink}" stroke-width="8"/>
      ${text(182, 940, status, 21, { fill: status === "REC" ? palettes.red : palettes.ink, weight: 900, letterSpacing: 1 })}
      ${text(1105, 940, quality, 18, { anchor: "end", weight: 900 })}
      ${body}
    </g>`;
}

function controls(label = "START RECORDING") {
  return `
    <rect x="148" y="1980" width="994" height="320" fill="#F5F0DC" stroke="${palettes.ink}" stroke-width="5"/>
    <circle cx="645" cy="2128" r="84" fill="${palettes.red}" stroke="${palettes.ink}" stroke-width="12"/>
    <circle cx="645" cy="2128" r="48" fill="#D84F3C"/>
    ${text(645, 2266, label, 24, { anchor: "middle", weight: 900, letterSpacing: 1 })}
  `;
}

function chrome() {
  return `
    <defs>
      <pattern id="grain" width="8" height="8" patternUnits="userSpaceOnUse">
        <rect width="8" height="8" fill="${palettes.paper}"/>
        <circle cx="1" cy="1" r="0.6" fill="#B5B19D" opacity="0.6"/>
        <circle cx="5" cy="6" r="0.5" fill="#F0ECD9" opacity="0.85"/>
      </pattern>
      <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%">
        <feDropShadow dx="0" dy="18" stdDeviation="0" flood-color="#484636" flood-opacity="0.38"/>
      </filter>
    </defs>
    <rect width="${width}" height="${height}" fill="url(#grain)"/>
    <rect x="44" y="44" width="1202" height="2708" fill="none" stroke="${palettes.ink}" stroke-width="8"/>
    <g fill="${palettes.ink}">
      <rect x="70" y="70" width="26" height="26"/><rect x="1194" y="70" width="26" height="26"/>
      <rect x="70" y="2700" width="26" height="26"/><rect x="1194" y="2700" width="26" height="26"/>
    </g>`;
}

function page({ filename, kicker, headline, subhead, body, footer }) {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
    ${chrome()}
    ${text(112, 172, kicker, 22, { fill: palettes.red, weight: 900, letterSpacing: 2 })}
    ${multiline(112, 286, headline, 66, { weight: 900, leading: 88 })}
    ${multiline(112, 468, subhead, 29, { fill: palettes.muted, weight: 700, leading: 42 })}
    <g filter="url(#shadow)">${body}</g>
    ${text(645, 2638, footer, 21, { anchor: "middle", fill: palettes.muted, weight: 900, letterSpacing: 1 })}
  </svg>`;
  writeFileSync(join(output, `${filename}.svg`), svg);
}

page({
  filename: "01-record-in-the-moment",
  kicker: "RETRO RECORDER",
  headline: ["一按即录", "把此刻留下来"],
  subhead: ["像掌上录音机一样直接，", "为声音准备的现代工作台。"],
  footer: "RECORD THE MOMENT",
  body: appShell(`
    ${text(645, 1060, "LIVE INPUT", 27, { anchor: "middle", weight: 900, letterSpacing: 2 })}
    ${waveform(218, 1258, 66, 39)}
    <line x1="645" y1="1078" x2="645" y2="1515" stroke="${palettes.red}" stroke-width="5"/>
    <circle cx="645" cy="1260" r="9" fill="${palettes.red}"/>
    ${text(645, 1640, "00:02:35", 66, { anchor: "middle", weight: 900, letterSpacing: 1 })}
    ${text(192, 1730, "LIVE TEXT", 18, { fill: palettes.muted, weight: 900, letterSpacing: 1 })}
    ${multiline(192, 1782, ["今天的想法先记下来，稍后可以回放、", "转写、标记与分享。"], 21, { weight: 700, leading: 34 })}
    ${controls("RECORDING")}
  `, { status: "REC" })
});

page({
  filename: "02-live-text",
  kicker: "LIVE TEXT",
  headline: ["边说边记", "声音即时成文"],
  subhead: ["实时语音识别持续滚动，", "录音过程中的每个灵感都看得见。"],
  footer: "SPEAK. SEE. SAVE.",
  body: appShell(`
    ${text(182, 1000, "LIVE TEXT", 21, { fill: palettes.muted, weight: 900, letterSpacing: 2 })}
    <rect x="182" y="1040" width="926" height="558" fill="#C9CF93" stroke="${palettes.line}" stroke-width="4"/>
    ${multiline(220, 1116, ["今天的会议先从用户反馈开始。", "第一，录音时可以查看实时文字；", "第二，重要内容在当下打上标签；", "第三，录完就能直接回放或整理。"], 30, { weight: 700, leading: 68 })}
    <rect x="220" y="1530" width="630" height="8" fill="${palettes.ink}" opacity="0.42"/>
    <rect x="220" y="1530" width="408" height="8" fill="${palettes.red}"/>
    ${text(645, 1728, "00:14:08", 64, { anchor: "middle", weight: 900 })}
    ${waveform(258, 1858, 57, 42)}
    ${controls("PAUSE  /  STOP")}
  `, { status: "REC" })
});

page({
  filename: "03-playback-and-tags",
  kicker: "PLAYBACK + TAGS",
  headline: ["回放时，", "直达重要时刻"],
  subhead: ["波形与文字两种视图自由切换，", "每一个标签都能带你回到重点。"],
  footer: "FIND WHAT MATTERS",
  body: appShell(`
    <rect x="182" y="982" width="926" height="514" fill="#C9CF93" stroke="${palettes.line}" stroke-width="4"/>
    ${waveform(202, 1240, 68, 35)}
    <line x1="664" y1="1016" x2="664" y2="1462" stroke="${palettes.red}" stroke-width="5"/>
    <polygon points="432,1050 452,1030 472,1050 452,1070" fill="${palettes.tag}"/>
    <polygon points="760,1374 780,1354 800,1374 780,1394" fill="${palettes.tag}"/>
    ${text(182, 1576, "00:02:35", 52, { weight: 900 })}
    ${text(1108, 1576, "- 05:05", 26, { anchor: "end", weight: 900 })}
    <rect x="182" y="1622" width="926" height="10" fill="#8A8D73"/>
    <rect x="182" y="1622" width="378" height="10" fill="${palettes.ink}"/>
    <rect x="430" y="1609" width="7" height="36" fill="${palettes.tag}"/>
    <rect x="786" y="1609" width="7" height="36" fill="${palettes.tag}"/>
    ${text(280, 1760, "0.5×", 29, { anchor: "middle", weight: 900 })}
    ${text(468, 1760, "↶ 15", 29, { anchor: "middle", weight: 900 })}
    <polygon points="630,1718 630,1796 706,1757" fill="${palettes.ink}"/>
    ${text(840, 1760, "15 ↷", 29, { anchor: "middle", weight: 900 })}
    ${text(1020, 1760, "TAG", 27, { anchor: "middle", fill: palettes.tag, weight: 900 })}
    ${controls("PLAYBACK")}
  `, { title: "FIELD NOTE · 18:20", status: "PLAY", quality: "WAVEFORM" })
});

page({
  filename: "04-your-sound",
  kicker: "YOUR SOUND, YOUR WAY",
  headline: ["选择音源", "让声音更干净"],
  subhead: ["自动发现麦克风；降噪、回声消除、", "采样率与编码格式都由你决定。"],
  footer: "TUNE THE RECORDING",
  body: appShell(`
    ${text(182, 1018, "RECORDING SETUP", 22, { fill: palettes.muted, weight: 900, letterSpacing: 2 })}
    <rect x="182" y="1060" width="926" height="600" fill="#F5F0DC" stroke="${palettes.line}" stroke-width="4"/>
    ${text(226, 1140, "INPUT", 17, { fill: palettes.muted, weight: 900 })}
    ${text(226, 1180, "External USB Microphone", 31, { weight: 900 })}
    <line x1="226" y1="1210" x2="1064" y2="1210" stroke="#8C9078" stroke-width="3"/>
    ${text(226, 1290, "NOISE REDUCTION", 17, { fill: palettes.muted, weight: 900 })}
    ${text(226, 1330, "DeepFilterNet V3", 31, { weight: 900 })}
    <rect x="938" y="1294" width="126" height="48" rx="24" fill="${palettes.ink}"/>
    <circle cx="1036" cy="1318" r="19" fill="#DDE5AA"/>
    <line x1="226" y1="1360" x2="1064" y2="1360" stroke="#8C9078" stroke-width="3"/>
    ${text(226, 1440, "QUALITY", 17, { fill: palettes.muted, weight: 900 })}
    ${text(226, 1480, "WAV  •  48 kHz  •  24-bit", 31, { weight: 900 })}
    <line x1="226" y1="1510" x2="1064" y2="1510" stroke="#8C9078" stroke-width="3"/>
    ${text(226, 1590, "ECHO CANCELLATION", 17, { fill: palettes.muted, weight: 900 })}
    ${text(226, 1630, "Enabled", 31, { weight: 900 })}
    <rect x="938" y="1594" width="126" height="48" rx="24" fill="${palettes.ink}"/>
    <circle cx="1036" cy="1618" r="19" fill="#DDE5AA"/>
    ${controls("START RECORDING")}
  `, { status: "READY" })
});

page({
  filename: "05-history-with-context",
  kicker: "RECORDING HISTORY",
  headline: ["每段声音", "都有来处"],
  subhead: ["按时间、地点与内容回顾录音。", "重要资料安全保存在你的私人 iCloud 中。"],
  footer: "YOUR PRIVATE SOUND ARCHIVE",
  body: appShell(`
    ${text(182, 1008, "RECENT RECORDINGS", 22, { fill: palettes.muted, weight: 900, letterSpacing: 2 })}
    <g>
      <rect x="182" y="1050" width="926" height="228" fill="#F5F0DC" stroke="${palettes.line}" stroke-width="4"/>
      <circle cx="246" cy="1164" r="34" fill="${palettes.red}"/><polygon points="237,1142 237,1186 274,1164" fill="#F5F0DC"/>
      ${text(312, 1128, "中山路 · 2026.09.01 18:20", 25, { weight: 900 })}
      ${text(312, 1174, "12:36  ·  中文  ·  1,428 字", 20, { fill: palettes.muted, weight: 700 })}
      ${text(312, 1220, "会议摘要已经整理完成", 19, { fill: palettes.muted, weight: 700 })}
    </g>
    <g>
      <rect x="182" y="1302" width="926" height="228" fill="#F5F0DC" stroke="${palettes.line}" stroke-width="4"/>
      <circle cx="246" cy="1416" r="34" fill="${palettes.ink}"/><polygon points="237,1394 237,1438 274,1416" fill="#F5F0DC"/>
      ${text(312, 1380, "2026.09.01 09:14", 25, { weight: 900 })}
      ${text(312, 1426, "03:51  ·  English  ·  508 words", 20, { fill: palettes.muted, weight: 700 })}
      ${text(312, 1472, "Morning idea", 19, { fill: palettes.muted, weight: 700 })}
    </g>
    <g>
      <rect x="182" y="1554" width="926" height="228" fill="#F5F0DC" stroke="${palettes.line}" stroke-width="4"/>
      <circle cx="246" cy="1668" r="34" fill="${palettes.ink}"/><polygon points="237,1646 237,1690 274,1668" fill="#F5F0DC"/>
      ${text(312, 1632, "图书馆 · 2026.08.31 16:42", 25, { weight: 900 })}
      ${text(312, 1678, "26:08  ·  中文  ·  2,016 字", 20, { fill: palettes.muted, weight: 700 })}
      ${text(312, 1724, "访谈录音 · 3 个标签", 19, { fill: palettes.muted, weight: 700 })}
    </g>
    ${controls("NEW RECORDING")}
  `, { title: "HISTORY", status: "ARCHIVE", quality: "PRIVATE CLOUD" })
});
