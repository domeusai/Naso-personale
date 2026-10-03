import { writeFile } from "node:fs/promises";
import { deflateSync } from "node:zlib";

const palette = {
  forest: [23, 60, 48],
  gold: [187, 152, 91],
  paper: [243, 240, 231],
  label: [213, 196, 160]
};

function crc32(buffer) {
  let crc = 0xffffffff;
  for (const byte of buffer) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit += 1) crc = (crc >>> 1) ^ (-(crc & 1) & 0xedb88320);
  }
  return (crc ^ 0xffffffff) >>> 0;
}

function chunk(name, data) {
  const type = Buffer.from(name);
  const length = Buffer.alloc(4);
  length.writeUInt32BE(data.length);
  const checksum = Buffer.alloc(4);
  checksum.writeUInt32BE(crc32(Buffer.concat([type, data])));
  return Buffer.concat([length, type, data, checksum]);
}

function createIcon(size) {
  const pixels = Buffer.alloc(size * size * 4);
  const blend = (x, y, color, alpha = 255) => {
    const offset = (y * size + x) * 4;
    const amount = alpha / 255;
    pixels[offset] = Math.round(pixels[offset] * (1 - amount) + color[0] * amount);
    pixels[offset + 1] = Math.round(pixels[offset + 1] * (1 - amount) + color[1] * amount);
    pixels[offset + 2] = Math.round(pixels[offset + 2] * (1 - amount) + color[2] * amount);
    pixels[offset + 3] = 255;
  };
  const rect = (x, y, width, height, color, radius = 0, stroke = 0) => {
    const left = Math.floor(x * size);
    const top = Math.floor(y * size);
    const right = Math.ceil((x + width) * size);
    const bottom = Math.ceil((y + height) * size);
    const r = radius * size;
    const sw = stroke * size;
    for (let py = Math.max(0, top - 1); py < Math.min(size, bottom + 1); py += 1) {
      for (let px = Math.max(0, left - 1); px < Math.min(size, right + 1); px += 1) {
        const dx = Math.max(left + r - px, 0, px - (right - r - 1));
        const dy = Math.max(top + r - py, 0, py - (bottom - r - 1));
        const distance = Math.hypot(dx, dy) - r;
        const edge = Math.max(0, Math.min(1, 0.5 - distance));
        if (stroke && distance < 0) {
          const innerDistance = Math.hypot(Math.max(left + sw + r - px, 0, px - (right - sw - r - 1)), Math.max(top + sw + r - py, 0, py - (bottom - sw - r - 1))) - r;
          blend(px, py, color, Math.round((innerDistance >= 0 ? 1 : edge) * 255));
        } else if (!stroke && distance < 1) {
          blend(px, py, color, Math.round(edge * 255));
        }
      }
    }
  };

  for (let y = 0; y < size; y += 1) {
    for (let x = 0; x < size; x += 1) blend(x, y, palette.forest);
  }

  const center = size / 2;
  const ringRadius = size * 0.34;
  const ringWidth = Math.max(1, size * 0.004);
  for (let y = Math.floor(center - ringRadius - 1); y <= center + ringRadius + 1; y += 1) {
    for (let x = Math.floor(center - ringRadius - 1); x <= center + ringRadius + 1; x += 1) {
      const distance = Math.abs(Math.hypot(x - center, y - center) - ringRadius);
      if (distance <= ringWidth) blend(x, y, palette.gold, 165);
    }
  }

  rect(0.425, 0.39, 0.15, 0.35, palette.paper, 0.025);
  rect(0.438, 0.355, 0.124, 0.055, palette.gold, 0.006);
  rect(0.414, 0.465, 0.172, 0.202, palette.label, 0.004);
  rect(0.445, 0.52, 0.11, 0.012, palette.forest, 0.005);
  rect(0.474, 0.494, 0.052, 0.012, palette.forest, 0.005);
  rect(0.495, 0.494, 0.012, 0.07, palette.forest, 0.005);

  const rows = Buffer.alloc((size * 4 + 1) * size);
  for (let y = 0; y < size; y += 1) {
    const rowOffset = y * (size * 4 + 1);
    rows[rowOffset] = 0;
    pixels.copy(rows, rowOffset + 1, y * size * 4, (y + 1) * size * 4);
  }

  const header = Buffer.alloc(13);
  header.writeUInt32BE(size, 0);
  header.writeUInt32BE(size, 4);
  header[8] = 8;
  header[9] = 6;
  const png = Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk("IHDR", header),
    chunk("IDAT", deflateSync(rows)),
    chunk("IEND", Buffer.alloc(0))
  ]);
  return png;
}

for (const size of [180, 192, 512]) {
  const filename = size === 180 ? "apple-touch-icon.png" : `icon-${size}.png`;
  await writeFile(new URL(`./${filename}`, import.meta.url), createIcon(size));
  console.log(`Creato icons/${filename}`);
}