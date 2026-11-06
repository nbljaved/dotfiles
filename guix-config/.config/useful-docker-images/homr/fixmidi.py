"""fixmidi.py in.midi out.midi [name]: in.midi mended for LilyPond's
midi2ly, which writes a note as long as it finds it (a 16th held a little
short as a64*7 r64, say), and a staff for each track. It says on stderr
what it changed, calling the file name (in.midi by default).

It puts the notes on a grid. MIDI a notation program wrote (LilyPond,
MuseScore) has its notes start on a grid of 32nds and triplet 16ths, nine
in ten at least; then the starts are kept. Such programs may end notes
early, to play them detached (MuseScore does, and LilyPond for some
articulations); then each end goes on to the next point of the grid, as
no note was held long. MIDI played in, on a keyboard, has the starts
anywhere about the beat; then starts and ends both go to the nearest 16th.
A note left with no length is given the grid's next step, and is cut short
where its key is struck again.

And it gives a piano played on one track two hands: when one track holds
all the notes, on one channel, with a piano's sound (or none given) and
notes both sides of middle C, the notes from middle C up go to a track of
their own, the right hand's, and those below to the left hand's. Tempo
and time signatures go to a first track without notes, which midi2ly gives
every staff; key signatures, to both hands.
"""

import shutil
import struct
import sys
from fractions import Fraction
from math import ceil

FINE = [Fraction(1, 8), Fraction(1, 6)]  # 32nds and triplet 16ths, in quarters
COARSE = [Fraction(1, 4)]  # 16ths
PIANOS = range(8)  # General MIDI's programs for pianos
DRUMS = 9  # General MIDI's channel for drums
MIDDLE_C = 60


def number(data, i):
    """A variable-length number at data[i], and where it ends."""
    v = 0
    while True:
        b = data[i]
        i += 1
        v = v << 7 | b & 0x7F
        if b < 0x80:
            return v, i


def encode(v):
    out = [v & 0x7F]
    v >>= 7
    while v:
        out.append(0x80 | v & 0x7F)
        v >>= 7
    return bytes(reversed(out))


def read(path, name):
    """The ticks to a quarter, and the tracks: each a list of events [tick,
    rank, bytes] (rank puts note-offs before note-ons at a tick) and of its
    notes, [on event, off event] pairs."""
    data = open(path, "rb").read()
    if data[:4] != b"MThd":
        sys.exit(f"pdf2ly: {name}: not a MIDI file")
    div = struct.unpack(">H", data[12:14])[0]
    if div & 0x8000:
        sys.exit(f"pdf2ly: {name}: timed in frames a second, not to the beat")
    pos = 8 + struct.unpack(">I", data[4:8])[0]
    tracks = []
    while pos + 8 <= len(data):
        size = struct.unpack(">I", data[pos + 4:pos + 8])[0]
        track = data[pos + 8:pos + 8 + size] if data[pos:pos + 4] == b"MTrk" else b""
        pos += 8 + size
        i = t = status = 0
        events, notes, playing = [], [], {}
        while i < len(track):
            dt, i = number(track, i)
            t += dt
            b = track[i]
            if b == 0xFF:  # meta event
                kind = track[i + 1]
                n, j = number(track, i + 2)
                if kind != 0x2F:  # the end of the track is written again
                    events.append([t, 0, track[i:j + n]])
                i = j + n
                continue
            if b in (0xF0, 0xF7):  # system exclusive
                n, j = number(track, i + 1)
                events.append([t, 0, track[i:j + n]])
                i = j + n
                continue
            if b & 0x80:
                status = b
                i += 1
            kind = status & 0xF0
            n = 1 if kind in (0xC0, 0xD0) else 2
            args = track[i:i + n]
            i += n
            key = (status & 0x0F, args[0])
            if kind == 0x90 and args[1]:
                event = [t, 2, bytes([status]) + args]
                playing.setdefault(key, []).append(event)
            elif kind in (0x80, 0x90):
                event = [t, 1, bytes([status]) + args]
                if playing.get(key):
                    notes.append([playing[key].pop(0), event])
            else:
                event = [t, 0, bytes([status]) + args]
            events.append(event)
        tracks.append((events, notes))
    return div, tracks


def snap(tick, div, grid, how):
    """tick moved to the nearest point of the grid (how is round), or to the
    next (ceil), but for one within a tick of it."""
    best = None
    for step in grid:
        q = Fraction(tick, div) / step
        k = round(q) if abs(q - round(q)) * step * div <= 1 else how(q)
        p = k * step * div
        if best is None or (how is ceil and p < best) or (how is round and abs(p - tick) < abs(best - tick)):
            best = p
    return round(best)


def on_grid(ticks, div):
    """The share of ticks on the fine grid, give or take one."""
    return sum(abs(snap(t, div, FINE, round) - t) <= 1 for t in ticks) / max(len(ticks), 1)


def put_on_grid(tracks, div, grid, starts, ends):
    """Each note's start moved with starts (round, or None to keep it) and
    its end with ends, on grid; see above."""
    for _, ns in tracks:
        for on, off in ns:
            if starts:
                on[0] = snap(on[0], div, grid, starts)
            off[0] = snap(off[0], div, grid, ends)
            if off[0] <= on[0]:
                off[0] = on[0] + round(min(grid) * div)
        # A key struck again before the note ends cuts it short; struck
        # again at once, the two are one.
        last = {}
        for on, off in sorted(ns, key=lambda n: n[0][0]):
            key = (on[2][0] & 0x0F, on[2][1])
            if key in last:
                before_on, before_off = last[key]
                if before_on[0] == on[0]:
                    off[0] = max(off[0], before_off[0])
                    before_on[2] = before_off[2] = None
                elif before_off[0] > on[0]:
                    before_off[0] = on[0]
            last[key] = (on, off)


def hands(tracks):
    """One track of piano as three, tempo and time, the right hand and the
    left (see above); or None, if the tracks aren't that."""
    with_notes = [ns for _, ns in tracks if ns]
    if len(with_notes) != 1:
        return None
    pitches = [on[2][1] for on, _ in with_notes[0] if on[2] is not None]
    channels = {on[2][0] & 0x0F for on, _ in with_notes[0] if on[2] is not None}
    programs = {e[2][1] for events, _ in tracks for e in events
                if e[2] is not None and e[2][0] & 0xF0 == 0xC0 and e[2][0] & 0x0F in channels}
    if (len(channels) != 1 or DRUMS in channels or not programs <= set(PIANOS)
            or min(pitches) >= MIDDLE_C or max(pitches) < MIDDLE_C):
        return None
    control, right, left = [], [], []
    for events, _ in tracks:
        for e in events:
            raw = e[2]
            if raw is None:
                continue
            if 0x80 <= raw[0] < 0xA0:  # a note's start or end
                (right if raw[1] >= MIDDLE_C else left).append(e)
            elif raw[0] < 0xF0 or raw[:2] == b"\xff\x59":  # a key signature, or for the channel
                right.append(e)
                left.append(e)
            elif raw[:2] in (b"\xff\x51", b"\xff\x58"):  # tempo, time signature
                control.append(e)
    return [(control, []), (right, []), (left, [])]


def write(path, div, tracks):
    out = b""
    for events, _ in tracks:
        events.sort(key=lambda e: (e[0], e[1]))
        body, last = b"", 0
        for t, _, raw in events:
            if raw is None:  # a note made one with the next
                continue
            body += encode(t - last) + raw
            last = t
        body += b"\x00\xff\x2f\x00"
        out += b"MTrk" + struct.pack(">I", len(body)) + body
    with open(path, "wb") as f:
        f.write(b"MThd" + struct.pack(">IHHH", 6, 1, len(tracks), div) + out)


def main():
    path, out = sys.argv[1], sys.argv[2]
    name = sys.argv[3] if len(sys.argv) > 3 else path
    div, tracks = read(path, name)
    notes = [n for _, ns in tracks for n in ns]
    if not notes:
        sys.exit(f"pdf2ly: {name}: no notes")
    grid = None
    if on_grid([on[0] for on, _ in notes], div) < 0.9:
        grid, starts, ends = COARSE, round, round
        print(f"pdf2ly: {name}: played in, off the beat: its notes' starts and ends "
              "go to the nearest 16th", file=sys.stderr)
    elif on_grid([off[0] for _, off in notes], div) < 0.9:
        grid, starts, ends = FINE, None, ceil
        print(f"pdf2ly: {name}: notes end early: their ends go on to the next 32nd "
              "or triplet 16th", file=sys.stderr)
    if grid:
        put_on_grid(tracks, div, grid, starts, ends)
    split = hands(tracks)
    if split:
        print(f"pdf2ly: {name}: a piano on one track: the notes from middle C up go to "
              "the right hand's staff, those below to the left's", file=sys.stderr)
    if grid or split:
        write(out, div, split or tracks)
    else:
        shutil.copy(path, out)


main()
