import { MdInline, MdListItem, MdBlock } from './MarkdownTypes';

let mdBlockPool: MdBlock[] = [];
let mdInlinePool: MdInline[] = [];
let mdListItemPool: MdListItem[] = [];

interface ListMarkerInfo {
  type: string;
  start: number;
  contentStart: number;
  markerEnd: number;
}

interface TaskResult {
  checked: boolean;
  textStart: number;
}

interface TableRowResult {
  cells: string[][];
}

interface RawLine {
  text: string;
  indent: number;
  markerInfo: ListMarkerInfo | null;
  isBlank: boolean;
}

function allocBlock(): MdBlock {
  if (mdBlockPool.length > 0) {
    return mdBlockPool.pop() as MdBlock;
  }
  return new MdBlock();
}

function freeBlock(b: MdBlock): void {
  b.type = '';
  b.text = '';
  b.spans = [];
  b.items = [];
  b.ordered = false;
  b.start = 1;
  b.lang = '';
  b.blocks = [];
  b.align = [];
  mdBlockPool.push(b);
}

function allocInline(): MdInline {
  if (mdInlinePool.length > 0) {
    return mdInlinePool.pop() as MdInline;
  }
  return new MdInline();
}

function freeInline(n: MdInline): void {
  n.type = 'text';
  n.text = '';
  n.href = '';
  n.title = '';
  n.children = [];
  mdInlinePool.push(n);
}

function allocListItem(): MdListItem {
  if (mdListItemPool.length > 0) {
    return mdListItemPool.pop() as MdListItem;
  }
  return new MdListItem();
}

function freeListItem(li: MdListItem): void {
  li.text = '';
  li.spans = [];
  li.subItems = [];
  li.taskChecked = false;
  mdListItemPool.push(li);
}

function textInline(t: string): MdInline {
  let n: MdInline = allocInline();
  n.type = 'text';
  n.text = t;
  return n;
}

function makeBlock(type: string): MdBlock {
  let b: MdBlock = allocBlock();
  b.type = type;
  return b;
}

function stripTrailing(text: string, ch: string): string {
  let i: number = text.length;
  while (i > 0 && text.charCodeAt(i - 1) === ch.charCodeAt(0)) {
    i--;
  }
  return text.substring(0, i);
}

function countLeading(text: string, ch: string): number {
  let c: number = 0;
  while (c < text.length && text.charAt(c) === ch) {
    c++;
  }
  return c;
}

function isAsciiPunct(ch: string): boolean {
  let cc: number = ch.charCodeAt(0);
  return (cc >= 33 && cc <= 47) || (cc >= 58 && cc <= 64) ||
    (cc >= 91 && cc <= 96) || (cc >= 123 && cc <= 126);
}

function escapeHtml(s: string): string {
  let r: string = '';
  for (let i: number = 0; i < s.length; i++) {
    let ch: string = s.charAt(i);
    if (ch === '<') { r += '&lt;'; }
    else if (ch === '>') { r += '&gt;'; }
    else if (ch === '&') { r += '&amp;'; }
    else { r += ch; }
  }
  return r;
}

interface CodeSpanResult {
  before: string;
  code: string;
  after: string;
}

function splitCodeSpan(text: string): CodeSpanResult | null {
  let start: number = text.indexOf('`');
  if (start < 0) { return null; }
  let backtickCount: number = 0;
  let j: number = start;
  while (j < text.length && text.charAt(j) === '`') {
    backtickCount++;
    j++;
  }
  let searchEnd: string = '';
  for (let k: number = 0; k < backtickCount; k++) {
    searchEnd += '`';
  }
  let closePos: number = text.indexOf(searchEnd, j);
  if (closePos < 0) { return null; }
  return {
    before: text.substring(0, start),
    code: text.substring(j, closePos),
    after: text.substring(closePos + backtickCount)
  };
}

interface LinkResult {
  before: string;
  alt: string;
  href: string;
  title: string;
  after: string;
}

function parseLink(text: string): LinkResult | null {
  let linkPos: number = text.indexOf('[');
  let imgPos: number = text.indexOf('![');
  let isImage: boolean = false;
  let start: number = -1;
  if (linkPos >= 0 && (imgPos < 0 || linkPos <= imgPos)) {
    start = linkPos;
    isImage = false;
  } else if (imgPos >= 0) {
    start = imgPos;
    isImage = true;
  }
  if (start < 0) { return null; }
  let contentStart: number = start + (isImage ? 2 : 1);
  let depth: number = 1;
  let end: number = contentStart;
  while (end < text.length && depth > 0) {
    if (text.charAt(end) === '[') { depth++; }
    else if (text.charAt(end) === ']') { depth--; }
    if (depth > 0) { end++; }
  }
  if (depth !== 0) { return null; }
  let alt: string = text.substring(contentStart, end);
  let afterBracket: number = end + 1;
  let href: string = '';
  let title: string = '';
  if (afterBracket < text.length && text.charAt(afterBracket) === '(') {
    let parenEnd: number = text.indexOf(')', afterBracket);
    if (parenEnd < 0) { return null; }
    let inside: string = text.substring(afterBracket + 1, parenEnd);
    let parts: string[] = inside.split(/\s+/);
    href = parts[0];
    if (parts.length > 1) {
      let t: string = parts.slice(1).join(' ');
      if ((t.startsWith('"') && t.endsWith('"')) ||
        (t.startsWith("'") && t.endsWith("'")) ||
        (t.startsWith('(') && t.endsWith(')'))) {
        title = t.substring(1, t.length - 1);
      }
    }
    return {
      before: text.substring(0, start),
      alt: alt,
      href: href,
      title: title,
      after: text.substring(parenEnd + 1)
    };
  }
  return null;
}

interface EmphasisResult {
  before: string;
  inner: string;
  delim: string;
  after: string;
}

function parseEmphasis(text: string): EmphasisResult | null {
  let delims: string[] = ['***', '**', '*'];
  for (let di: number = 0; di < delims.length; di++) {
    let d: string = delims[di];
    let start: number = text.indexOf(d);
    if (start < 0) { continue; }
    if (d === '*') {
      if (start > 0 && text.charAt(start - 1) === '*') { continue; }
    }
    let searchFrom: number = start + d.length;
    let closePos: number = -1;
    let ci: number = searchFrom;
    while (ci < text.length) {
      if (ci + d.length <= text.length) {
        let match: boolean = true;
        for (let k: number = 0; k < d.length; k++) {
          if (text.charAt(ci + k) !== d.charAt(k)) { match = false; break; }
        }
        if (match) {
          if (d === '**' && ci + 2 < text.length && text.charAt(ci + 2) === '*') {
            ci += 1;
            continue;
          }
          closePos = ci;
          break;
        }
      }
      ci += 1;
    }
    if (closePos >= 0) {
      return {
        before: text.substring(0, start),
        inner: text.substring(start + d.length, closePos),
        delim: d,
        after: text.substring(closePos + d.length)
      };
    }
  }
  return null;
}

interface StrikethroughResult {
  before: string;
  inner: string;
  after: string;
}

function parseStrikethrough(text: string): StrikethroughResult | null {
  let start: number = text.indexOf('~~');
  if (start < 0) { return null; }
  let closePos: number = text.indexOf('~~', start + 2);
  if (closePos < 0) { return null; }
  return {
    before: text.substring(0, start),
    inner: text.substring(start + 2, closePos),
    after: text.substring(closePos + 2)
  };
}

function unescapeText(text: string): string {
  let r: string = '';
  let i: number = 0;
  while (i < text.length) {
    if (text.charAt(i) === '\\' && i + 1 < text.length && isAsciiPunct(text.charAt(i + 1))) {
      r += text.charAt(i + 1);
      i += 2;
    } else {
      r += text.charAt(i);
      i += 1;
    }
  }
  return r;
}

function parseInlineRec(text: string, topLevel: boolean): MdInline[] {
  let result: MdInline[] = [];
  if (text.length === 0) { return result; }
  let remaining: string = text;
  while (remaining.length > 0) {
    let cs: CodeSpanResult | null = splitCodeSpan(remaining);
    if (cs !== null) {
      if (cs.before.length > 0) {
        let inner: MdInline[] = parseInlineRec(cs.before, topLevel);
        for (let i: number = 0; i < inner.length; i++) {
          result.push(inner[i]);
        }
      }
      let code: MdInline = allocInline();
      code.type = 'code';
      code.text = cs.code;
      result.push(code);
      remaining = cs.after;
      continue;
    }

    if (topLevel) {
      let link: LinkResult | null = parseLink(remaining);
      if (link !== null) {
        if (link.before.length > 0) {
          let inner: MdInline[] = parseInlineRec(link.before, false);
          for (let i: number = 0; i < inner.length; i++) {
            result.push(inner[i]);
          }
        }
        let img: MdInline = allocInline();
        img.type = link.href.length > 0 ? 'link' : 'text';
        img.href = link.href;
        img.title = link.title;
        img.children = parseInlineRec(link.alt, false);
        result.push(img);
        remaining = link.after;
        continue;
      }
    }

    let strike: StrikethroughResult | null = parseStrikethrough(remaining);
    if (strike !== null) {
      if (strike.before.length > 0) {
        let inner: MdInline[] = parseInlineRec(strike.before, topLevel);
        for (let i: number = 0; i < inner.length; i++) {
          result.push(inner[i]);
        }
      }
      let s: MdInline = allocInline();
      s.type = 'strikethrough';
      s.children = parseInlineRec(strike.inner, topLevel);
      result.push(s);
      remaining = strike.after;
      continue;
    }

    let emph: EmphasisResult | null = parseEmphasis(remaining);
    if (emph !== null) {
      if (emph.before.length > 0) {
        let inner: MdInline[] = parseInlineRec(emph.before, topLevel);
        for (let i: number = 0; i < inner.length; i++) {
          result.push(inner[i]);
        }
      }
      let e: MdInline = allocInline();
      if (emph.delim === '***') {
        e.type = 'boldItalic';
      } else if (emph.delim === '**') {
        e.type = 'bold';
      } else {
        e.type = 'italic';
      }
      e.children = parseInlineRec(emph.inner, topLevel);
      result.push(e);
      remaining = emph.after;
      continue;
    }

    let txt: MdInline = textInline(unescapeText(remaining));
    result.push(txt);
    break;
  }
  return result;
}

export function parseInline(text: string): MdInline[] {
  return parseInlineRec(text, true);
}

function isThematicBreak(line: string): boolean {
  let trimmed: string = line.trim();
  if (trimmed.length < 3) { return false; }
  let ch: string = trimmed.charAt(0);
  if (ch !== '-' && ch !== '*' && ch !== '_') { return false; }
  for (let i: number = 1; i < trimmed.length; i++) {
    let c: string = trimmed.charAt(i);
    if (c !== ch && c !== ' ' && c !== '\t') { return false; }
  }
  let count: number = 0;
  for (let i: number = 0; i < trimmed.length; i++) {
    if (trimmed.charAt(i) === ch) { count++; }
  }
  return count >= 3;
}

function isFence(line: string): boolean {
  let trimmed: string = line.trim();
  if (trimmed.length < 3) { return false; }
  let ch: string = trimmed.charAt(0);
  if (ch !== '`' && ch !== '~') { return false; }
  let inFence: boolean = true;
  let fenceCount: number = 0;
  for (let i: number = 0; i < trimmed.length; i++) {
    let c: string = trimmed.charAt(i);
    if (inFence) {
      if (c === ch) {
        fenceCount++;
      } else if (c === ' ' || c === '\t') {
        inFence = false;
      } else {
        return false;
      }
    }
  }
  if (fenceCount < 3) { return false; }
  return true;
}

function fenceChar(line: string): string {
  return line.trim().charAt(0);
}

function fenceLength(line: string): number {
  let trimmed: string = line.trim();
  let ch: string = trimmed.charAt(0);
  let count: number = 0;
  for (let i: number = 0; i < trimmed.length; i++) {
    if (trimmed.charAt(i) === ch) { count++; } else { break; }
  }
  return count;
}

function fenceInfo(line: string): string {
  let trimmed: string = line.trim();
  let ch: string = trimmed.charAt(0);
  let i: number = 0;
  while (i < trimmed.length && trimmed.charAt(i) === ch) { i++; }
  while (i < trimmed.length && (trimmed.charAt(i) === ' ' || trimmed.charAt(i) === '\t')) { i++; }
  return trimmed.substring(i).trim();
}

function isBlockQuote(line: string): boolean {
  return line.trimStart().charAt(0) === '>';
}

function stripBlockQuote(line: string): string {
  let idx: number = 0;
  while (idx < line.length && (line.charAt(idx) === ' ' || line.charAt(idx) === '\t')) {
    idx++;
  }
  if (idx < line.length && line.charAt(idx) === '>') {
    idx++;
    if (idx < line.length && line.charAt(idx) === ' ') { idx++; }
    return line.substring(0, idx) + line.substring(idx);
  }
  return line;
}

function readIndent(line: string): number {
  let n: number = 0;
  for (let i: number = 0; i < line.length; i++) {
    if (line.charAt(i) === ' ') { n++; }
    else if (line.charAt(i) === '\t') { n += 4 - (n % 4); }
    else { break; }
  }
  return n;
}

function listMarker(line: string): ListMarkerInfo | null {
  let i: number = 0;
  while (i < line.length && (line.charAt(i) === ' ' || line.charAt(i) === '\t')) {
    i++;
  }
  if (i > 3) { return null; }
  let rest: string = line.substring(i);
  let orderedMatch: RegExpMatchArray | null = rest.match(/^(\d+)[.)]\s+/);
  if (orderedMatch !== null) {
    let info: ListMarkerInfo = { type: 'ordered', start: parseInt(orderedMatch[1]), contentStart: i + orderedMatch[0].length, markerEnd: i + orderedMatch[0].length };
    return info;
  }
  let unorderedMatch: RegExpMatchArray | null = rest.match(/^[-*+]\s+/);
  if (unorderedMatch !== null) {
    let info: ListMarkerInfo = { type: 'unordered', start: 1, contentStart: i + unorderedMatch[0].length, markerEnd: i + unorderedMatch[0].length };
    return info;
  }
  return null;
}

function taskMatch(line: string, contentStart: number): TaskResult | null {
  let afterMarker: string = line.substring(contentStart);
  let m: RegExpMatchArray | null = afterMarker.match(/^\[([ xX])\]\s*/);
  if (m !== null) {
    let res: TaskResult = { checked: m[1] === 'x' || m[1] === 'X', textStart: contentStart + m[0].length };
    return res;
  }
  return null;
}

function parseSetextHeading(lines: string[], startIdx: number): MdBlock | null {
  if (startIdx <= 0) { return null; }
  let fence: string = lines[startIdx].trim();
  let ch: string = fence.charAt(0);
  if (ch !== '=' && ch !== '-') { return null; }
  for (let i: number = 1; i < fence.length; i++) {
    if (fence.charAt(i) !== ch) { return null; }
  }
  if (fence.length < 1) { return null; }
  let contentLines: string[] = [];
  let idx: number = startIdx - 1;
  while (idx >= 0) {
    let prev: string = lines[idx];
    if (prev.trim().length === 0) { break; }
    let trimmed: string = prev.trimStart();
    if (isThematicBreak(prev)) { break; }
    if (isFence(prev)) { break; }
    if (isBlockQuote(prev)) { break; }
    if (listMarker(prev) !== null) { break; }
    if (/^#{1,6}\s/.test(trimmed)) { break; }
    contentLines.unshift(prev);
    idx--;
  }
  if (contentLines.length === 0) { return null; }
  let raw: string = contentLines.join('\n');
  let block: MdBlock = makeBlock(ch === '=' ? 'h1' : 'h2');
  block.text = raw.trim();
  block.spans = parseInline(block.text);
  return block;
}

function parseATXHeading(line: string): MdBlock | null {
  let trimmed: string = line.trimStart();
  let indent: number = line.length - trimmed.length;
  if (indent > 3) { return null; }
  if (!/^#{1,6}(?:\s|$)/.test(trimmed)) { return null; }
  let level: number = 0;
  while (level < trimmed.length && trimmed.charAt(level) === '#') { level++; }
  if (level > 6) { return null; }
  let content: string = trimmed.substring(level).trim();
  while (/[ \t]+#+\s*$/.test(content)) {
    content = content.replace(/[ \t]+#+\s*$/, '');
  }
  content = content.trim();
  let block: MdBlock = makeBlock('h' + String(level));
  block.text = content;
  block.spans = parseInline(content);
  return block;
}

function parseTableRow(line: string): TableRowResult | null {
  let parts: string[] = line.split('|');
  if (parts.length < 2) { return null; }
  let cells: string[][] = [];
  for (let i: number = 0; i < parts.length; i++) {
    let cellText: string = parts[i].trim();
    if (i === 0 || i === parts.length - 1) {
      if (cellText.length === 0 && (i === 0 || i === parts.length - 1)) {
        continue;
      }
    }
    cells.push([cellText]);
  }
  if (cells.length < 2) { return null; }
  let res: TableRowResult = { cells: cells };
  return res;
}

function parseTableAlign(line: string): string[] | null {
  let parts: string[] = line.split('|');
  let aligns: string[] = [];
  for (let i: number = 0; i < parts.length; i++) {
    let cell: string = parts[i].trim();
    if (cell.length === 0) {
      if (i === 0 || i === parts.length - 1) { continue; }
    }
    let m: RegExpMatchArray | null = cell.match(/^:?-+:?$/);
    if (m === null) { return null; }
    if (cell.startsWith(':') && cell.endsWith(':')) { aligns.push('center'); }
    else if (cell.startsWith(':')) { aligns.push('left'); }
    else if (cell.endsWith(':')) { aligns.push('right'); }
    else { aligns.push('left'); }
  }
  return aligns;
}

export function parseMarkdown(src: string): MdBlock[] {
  let result: MdBlock[] = [];
  if (src.length === 0) { return result; }
  let lines: string[] = src.split('\n');
  let i: number = 0;
  while (i < lines.length) {
    let line: string = lines[i];
    if (line.trim().length === 0) { i++; continue; }

    let setext: MdBlock | null = null;
    if (i > 0 && isThematicBreak(line) && (line.trim().charAt(0) === '-' || line.trim().charAt(0) === '=')) {
      setext = parseSetextHeading(lines, i);
    }
    if (setext !== null) {
      consumeBlocks(setext, result);
      i++;
      continue;
    }

    if (isThematicBreak(line)) {
      let hrBlock: MdBlock = makeBlock('hr');
      result.push(hrBlock);
      i++;
      continue;
    }

    let atx: MdBlock | null = parseATXHeading(line);
    if (atx !== null) {
      result.push(atx);
      i++;
      continue;
    }

    if (isFence(line)) {
      let ch: string = fenceChar(line);
      let len: number = fenceLength(line);
      let lang: string = fenceInfo(line);
      let codeLines: string[] = [];
      i++;
      while (i < lines.length) {
        if (fenceChar(lines[i]) === ch && fenceLength(lines[i]) >= len &&
          lines[i].trim().split(ch).filter(s => s.trim().length === 0).join('').length === 0) {
          i++;
          break;
        }
        codeLines.push(lines[i]);
        i++;
      }
      let codeBlock: MdBlock = makeBlock('code');
      codeBlock.text = codeLines.join('\n');
      codeBlock.lang = lang;
      result.push(codeBlock);
      continue;
    }

    if (isBlockQuote(line)) {
      let quoteLines: string[] = [];
      while (i < lines.length) {
        let raw: string = lines[i];
        let trimmed: string = raw.trim();
        if (trimmed.length === 0) {
          let j: number = i + 1;
          if (j < lines.length && isBlockQuote(lines[j])) {
            quoteLines.push('');
            i++;
            continue;
          }
          break;
        }
        if (!isBlockQuote(raw)) { break; }
        let stripped: string = raw.replace(/^[ \t]*>[ \t]?/, '');
        quoteLines.push(stripped);
        i++;
      }
      let innerSrc: string = quoteLines.join('\n');
      let quoteBlock: MdBlock = makeBlock('blockquote');
      quoteBlock.blocks = parseMarkdown(innerSrc);
      result.push(quoteBlock);
      continue;
    }

    let marker: ListMarkerInfo | null = listMarker(line);
    if (marker !== null) {
      let block: MdBlock = makeBlock('list');
      block.ordered = marker.type === 'ordered';
      block.start = marker.start;
      let markerIndent: number = readIndent(line);

      let firstMarkerIndent: number = markerIndent;
      let rawLines: RawLine[] = [];
      let rl0: RawLine = { text: line, indent: markerIndent, markerInfo: marker, isBlank: false };
      rawLines.push(rl0);

      i++;
      while (i < lines.length) {
        let cur: string = lines[i];
        let curTrimmed: string = cur.trim();
        let curIndent: number = readIndent(cur);
        let curMarker: ListMarkerInfo | null = listMarker(cur);

        if (curTrimmed.length === 0) {
          let blankLine: RawLine = { text: cur, indent: curIndent, markerInfo: null, isBlank: true };
          rawLines.push(blankLine);
          i++;
          continue;
        }

        if (curMarker !== null) {
          let markerLine: RawLine = { text: cur, indent: curIndent, markerInfo: curMarker, isBlank: false };
          rawLines.push(markerLine);
          i++;
          continue;
        }

        if (isThematicBreak(curTrimmed)) { break; }
        if (isFence(cur)) { break; }
        if (/^#{1,6}\s/.test(curTrimmed)) { break; }
        if (isBlockQuote(curTrimmed)) { break; }

        if (curIndent > firstMarkerIndent) {
          let contLine: RawLine = { text: cur, indent: curIndent, markerInfo: null, isBlank: false };
          rawLines.push(contLine);
          i++;
          continue;
        }

        break;
      }

      let items: MdListItem[] = [];
      let itemTexts: string[] = [];
      let itemSubTexts: string[][] = [];
      let itemTasks: boolean[] = [];
      let currentItemIdx: number = -1;

      for (let ri: number = 0; ri < rawLines.length; ri++) {
        let rl: RawLine = rawLines[ri];
        if (rl.isBlank) {
          if (currentItemIdx >= 0) {
            itemTexts[currentItemIdx] += '\n';
          }
          continue;
        }

        let rlMarker: ListMarkerInfo | null = rl.markerInfo;

        if (rlMarker !== null && rl.indent >= markerIndent - 2 && rl.indent <= markerIndent + 3 &&
          !(rl.indent > markerIndent)) {
          let content: string = rl.text.substring(rlMarker.contentStart);
          let taskRes: TaskResult | null = taskMatch(rl.text, rlMarker.contentStart);
          let itemText: string = taskRes !== null ? rl.text.substring(taskRes.textStart) : content;
          itemTexts.push(itemText);
          itemSubTexts.push([]);
          itemTasks.push(taskRes !== null ? taskRes.checked : false);
          currentItemIdx = itemTexts.length - 1;
          continue;
        }

        if (rlMarker !== null && rl.indent > markerIndent) {
          if (currentItemIdx >= 0) {
            itemSubTexts[currentItemIdx].push(rl.text.substring(rlMarker.contentStart));
          }
          continue;
        }

        if (rlMarker === null && rl.indent > markerIndent && currentItemIdx >= 0) {
          if (itemTexts[currentItemIdx].length > 0 &&
            itemTexts[currentItemIdx].charAt(itemTexts[currentItemIdx].length - 1) !== '\n') {
            itemTexts[currentItemIdx] += '\n';
          }
          itemTexts[currentItemIdx] += rl.text.trim();
          continue;
        }
      }

      for (let j: number = 0; j < itemTexts.length; j++) {
        let li: MdListItem = allocListItem();
        li.text = itemTexts[j].replace(/\n+$/, '').trim();
        li.spans = parseInline(li.text);
        li.taskChecked = itemTasks[j];
        for (let sk: number = 0; sk < itemSubTexts[j].length; sk++) {
          let subLi: MdListItem = allocListItem();
          subLi.text = itemSubTexts[j][sk];
          subLi.spans = parseInline(subLi.text);
          li.subItems.push(subLi);
        }
        block.items.push(li);
      }

      result.push(block);
      continue;
    }

    let paraLines: string[] = [];
    let origI: number = i;
    while (i < lines.length) {
      let l: string = lines[i];
      let lt: string = l.trim();
      if (lt.length === 0) {
        if (paraLines.length > 0) { break; }
        i++;
        continue;
      }
      if (isThematicBreak(l)) { break; }
      if (/^=+\s*$/.test(l.trim())) { break; }
      if (isFence(l)) { break; }
      if (/^#{1,6}\s/.test(l.trimStart())) { break; }
      if (isBlockQuote(l)) { break; }
      if (listMarker(l) !== null) { break; }
      if (l.trimStart().length > 0 && l !== l.trimStart() && readIndent(l) >= 4 &&
        isThematicBreak(l)) { break; }
      paraLines.push(l);
      i++;
    }
    if (paraLines.length > 0) {
      if (i < lines.length && paraLines.length > 0) {
        let nextLine: string = lines[i];
        let nextTrimmed: string = nextLine.trim();
        if ((isThematicBreak(nextLine) && nextTrimmed.charAt(0) === '-') ||
          /^=+\s*$/.test(nextTrimmed)) {
          let setextCheck: MdBlock | null = parseSetextHeading(lines, i);
          if (setextCheck !== null) {
            consumeBlocks(setextCheck, result);
            i++;
            continue;
          }
        }
      }
      let paraText: string = paraLines.join('\n');
      let pBlock: MdBlock = makeBlock('p');
      pBlock.text = paraText;
      pBlock.spans = parseInline(paraText);
      result.push(pBlock);
    }
  }
  return result;
}

function consumeBlocks(block: MdBlock, result: MdBlock[]): void {
  let last: MdBlock | null = null;
  if (result.length > 0) {
    last = result[result.length - 1];
  }
  if (last !== null && (last.type === 'p' || last.type === 'h1' || last.type === 'h2')) {
    let combined: string = last.text + '\n' + block.text;
    last.type = block.type;
    last.text = combined.trim();
    last.spans = parseInline(last.text);
  } else {
    result.push(block);
  }
}
