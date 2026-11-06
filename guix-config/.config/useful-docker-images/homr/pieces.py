"""pieces.py book.pdf outdir [first [last]]: the pieces of music in a book
where the music is mixed with text, pictures and boxes (a piano method,
say), for homr to read one at a time. It runs in homr's container.

Each page, drawn at 300 dpi as homr draws a PDF, keeps only its staves
printed on the page itself, with the ink about them (notes, lyrics,
fingering, dynamics), on white. Staves in boxes (an example in a tinted
box, a teacher's duet in a grey one), staves less than half as long as the
longest, and all else go.

A piece starts at a system (a staff, or staves joined by a line down their
left edge) with a heading above it, and runs on, over pages, to the next.
A heading is a line of text in larger type than about it: a title, or a
smaller one (an exercise's) where the gap above the system is wider than
the page's others, or the system is the first on its page. The heading is
kept for homr to read the piece's title from.

Each piece goes to outdir/NNN[-K].pdf, NNN the page it starts on and K its
place there, with a page for each page it is on; outdir/pieces.tsv lists
them, a piece a line: its name and pages. Pages from first to last (all
by default) are looked at; outdir/debug/pNNN.png shows each page's staves
(green kept, blue not), boxes (red) and headings (orange).
"""

import os
import sys

import cv2
import numpy as np
import pypdfium2 as pdfium
from PIL import Image

DPI = 300
TITLE, HEADING = 40, 29  # median letter heights, in pixels at 300 dpi


def box_regions(img, gray, bg):
    """Where the boxes are: tinted (tan, gold) or a darker grey than the
    page, closed and filled in."""
    b, g, r = (img[..., k].astype(int) for k in range(3))
    tinted = ((np.max([b, g, r], axis=0) - np.min([b, g, r], axis=0)) > 30) & (gray > 100)
    # A grey fill, not the grey edges of ink: what a median keeps.
    smooth = cv2.medianBlur(gray, 31)
    darker = (smooth > 150) & (smooth < bg - 10)
    mask = cv2.morphologyEx((tinted | darker).astype(np.uint8), cv2.MORPH_CLOSE,
                            np.ones((25, 25), np.uint8))
    filled = np.zeros_like(mask)
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    for c in contours:
        x, y, cw, ch = cv2.boundingRect(c)
        if cw * ch > 0.005 * mask.size and cw > 100 and ch > 60:
            cv2.drawContours(filled, [c], -1, 1, thickness=cv2.FILLED)
    return filled.astype(bool)


def line_segments(ink):
    """Long thin horizontal runs of ink: (y, x0, x1)."""
    k = max(40, ink.shape[1] // 14)
    lines = cv2.morphologyEx(ink.astype(np.uint8), cv2.MORPH_OPEN,
                             cv2.getStructuringElement(cv2.MORPH_RECT, (k, 1)))
    n, _, stats, _ = cv2.connectedComponentsWithStats(lines)
    segs = []
    for i in range(1, n):
        x, y, cw, ch, _ = stats[i]
        if ch <= 10:
            segs.append([y + ch / 2, x, x + cw])
    # Pieces of one line, broken by a gap, are one.
    merged = []
    for seg in sorted(segs, key=lambda t: t[1]):
        for m in merged:
            if abs(m[0] - seg[0]) <= 3 and seg[1] - m[2] < 60:
                m[2] = max(m[2], seg[2])
                break
        else:
            merged.append(seg)
    return sorted(tuple(m) for m in merged)


def overlap(a0, a1, b0, b1):
    return min(a1, b1) - max(a0, b0)


def find_staves(segs):
    """Five lines equally spaced, one above the other:
    [(top, bottom, x0, x1, space)]."""
    used = set()
    staves = []
    for i, (y, x0, x1) in enumerate(segs):
        if i in used:
            continue
        for j in range(i + 1, len(segs)):
            d = segs[j][0] - y
            if d < 10:
                continue
            if d > 60:
                break
            picked = [i, j]
            for m in (2, 3, 4):
                want = y + m * d
                found = None
                for k in range(j + 1, len(segs)):
                    yk, a, b = segs[k]
                    if yk > want + 0.2 * d:
                        break
                    if abs(yk - want) <= 0.2 * d and overlap(a, b, x0, x1) > 0.5 * min(b - a, x1 - x0):
                        found = k
                        break
                if found is None:
                    break
                picked.append(found)
            if len(picked) == 5:
                ls = [segs[k] for k in picked]
                staff = (ls[0][0], ls[4][0], min(s[1] for s in ls), max(s[2] for s in ls), d)
                # Lines a pixel or two apart can make the same staff twice.
                if not any(overlap(s[0], s[1], staff[0], staff[1]) > 0
                           and overlap(s[2], s[3], staff[2], staff[3]) > 0 for s in staves):
                    staves.append(staff)
                used.update(picked)
                break
    return sorted(staves)


def systems_of(staves, ink):
    """Staves joined by a line down their left edge are one system."""
    def joined(a, b):
        x = int(min(a[2], b[2]))
        col = ink[int(a[1]):int(b[0]), max(0, x - 4):x + 5].any(axis=1)
        return col.size > 0 and col.mean() > 0.9

    systems = []
    for s in staves:
        if systems and joined(systems[-1][-1], s):
            systems[-1].append(s)
        else:
            systems.append([s])
    return systems


def headings(ink, lo, hi):
    """The lines of text between rows lo and hi, split at empty rows and
    where their letters are far apart: [(median letter height, (x0, y0,
    x1, y1))], of three letters or more."""
    lo, hi = max(0, int(lo)), int(hi)
    if hi - lo < 10:
        return []
    n, _, stats, _ = cv2.connectedComponentsWithStats(ink[lo:hi].astype(np.uint8))
    letters = [s for s in stats[1:] if 8 <= s[3] <= 150 and s[2] <= 200 and s[4] > 15]
    rows = np.zeros(hi - lo, bool)
    for s in letters:
        rows[s[1]:s[1] + s[3]] = True
    found = []
    y = 0
    while y < len(rows):
        if not rows[y]:
            y += 1
            continue
        e = y
        while e < len(rows) and rows[e]:
            e += 1
        line = sorted((s for s in letters if s[1] >= y and s[1] + s[3] <= e), key=lambda s: s[0])
        if line:
            gap = 4 * np.median([s[3] for s in line])
            run = [line[0]]
            for s in line[1:] + [None]:
                if s is not None and s[0] - (run[-1][0] + run[-1][2]) < gap:
                    run.append(s)
                    continue
                if len(run) >= 3:
                    med = float(np.median([r[3] for r in run]))
                    x0, x1 = run[0][0], max(r[0] + r[2] for r in run)
                    if x1 - x0 >= 3 * med:
                        found.append((med, (x0, lo + y, x1, lo + e)))
                run = [s]
        y = e
    return found


def read_page(img):
    """A page's systems, each with the heading above it that starts a
    piece, if one does: [(staves, heading box or None)]; and its boxes."""
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    bg = int(np.bincount(gray[gray > 150]).argmax())
    boxes = box_regions(img, gray, bg)
    ink = gray < 140
    staves = find_staves(line_segments(ink))
    widest = max((s[3] - s[2] for s in staves), default=0)
    kept = [s for s in staves
            if not boxes[int((s[0] + s[1]) / 2), int((s[2] + s[3]) / 2)] and s[3] - s[2] >= 0.5 * widest]
    systems = systems_of(kept, ink)
    gaps = [b[0][0] - a[-1][1] for a, b in zip(systems, systems[1:])]
    typical = float(np.median(gaps)) if gaps else 0
    out = []
    text = ink & ~boxes
    for i, sy in enumerate(systems):
        d = sy[0][4]
        above = sy[0][0] - 2.5 * d
        lo = systems[i - 1][-1][1] + 2.5 * d if i else 0
        lines = headings(text, lo, above)
        big = max(lines, default=None)
        start = None
        if big and (big[0] >= TITLE or
                    big[0] >= HEADING and (i == 0 or gaps[i - 1] > 1.3 * typical)):
            start = big[1]
        out.append((sy, start))
    return out, staves, kept, boxes, gray


def music_of(gray, boxes, systems, heading):
    """The page with only these systems' music, and the heading, on white,
    cropped."""
    h, w = gray.shape
    keep = np.zeros_like(gray, dtype=bool)
    for sy in systems:
        d = sy[0][4]
        x0, x1 = min(s[2] for s in sy), max(s[3] for s in sy)
        keep[max(0, int(sy[0][0] - 3.5 * d)):min(h, int(sy[-1][1] + 3.5 * d)),
             max(0, int(x0 - 3 * d)):min(w, int(x1 + d))] = True
    if heading:
        x0, y0, x1, y1 = heading
        keep[max(0, y0 - 10):y1 + 10, max(0, x0 - 10):x1 + 10] = True
    keep &= ~boxes
    page = np.full_like(gray, 255)
    ink = keep & (gray < 200)
    page[ink] = gray[ink]
    ys, xs = np.nonzero(keep)
    m = 40
    return page[max(0, ys.min() - m):ys.max() + m, max(0, xs.min() - m):xs.max() + m]


def main():
    book, outdir = sys.argv[1], sys.argv[2]
    pdf = pdfium.PdfDocument(book)
    first = int(sys.argv[3]) if len(sys.argv) > 3 and sys.argv[3] else 1
    last = int(sys.argv[4]) if len(sys.argv) > 4 and sys.argv[4] else len(pdf)
    os.makedirs(f"{outdir}/debug", exist_ok=True)
    pieces = []  # [name, pages, pictures]
    for p in range(first, last + 1):
        rgb = np.array(pdf[p - 1].render(scale=DPI / 72).to_pil().convert("RGB"))
        img = cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR)
        found, staves, kept, boxes, gray = read_page(img)

        dbg = img.copy()
        dbg[boxes] = (dbg[boxes] * 0.5 + np.array([0, 0, 255]) * 0.5).astype(np.uint8)
        for s in staves:
            cv2.rectangle(dbg, (int(s[2]), int(s[0])), (int(s[3]), int(s[1])),
                          (0, 160, 0) if s in kept else (255, 0, 0), 8)
        for _, start in found:
            if start:
                cv2.rectangle(dbg, start[:2], start[2:], (0, 140, 255), 8)
        cv2.imwrite(f"{outdir}/debug/p{p:03}.png", cv2.resize(dbg, None, fx=0.3, fy=0.3))

        # The systems in runs, a run to each piece on the page.
        runs = []
        for sy, start in found:
            if start or not runs:
                runs.append([[sy], start, bool(start)])
            else:
                runs[-1][0].append(sy)
        k = 0
        for systems, start, new in runs:
            picture = Image.fromarray(music_of(gray, boxes, systems, start))
            if new or not pieces:
                k += 1
                pieces.append([f"{p:03}" + (f"-{k}" if k > 1 else ""), [p], [picture]])
            else:
                pieces[-1][1].append(p)  # carried on from the page before
                pieces[-1][2].append(picture)
        print(f"page {p}: {len(staves)} staves, {len(kept)} kept, {len(found)} systems, "
              f"{sum(1 for r in runs if r[2])} pieces start", flush=True)

    with open(f"{outdir}/pieces.tsv", "w") as tsv:
        for name, pages, pictures in pieces:
            pictures[0].save(f"{outdir}/{name}.pdf", "PDF", resolution=DPI, quality=95,
                             save_all=True, append_images=pictures[1:])
            span = f"{pages[0]}" if len(pages) == 1 else f"{pages[0]}-{pages[-1]}"
            tsv.write(f"{name}\t{span}\n")


main()
