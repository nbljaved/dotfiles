"""fixxml.py in.musicxml out.musicxml out.json: the first pass of pdf2ly.

It mends MusicXML (homr's most of all) for LilyPond's musicxml2ly, and
writes what musicxml2ly isn't given to out.json, for fixly.py to put into
the .ly that musicxml2ly makes. MusicXML that is right as it is (from
MuseScore, say) goes through as it came, but for its repeats; in.musicxml
may be zipped (.mxl).

- Bars without notes in any part are dropped. homr finds them about repeat
  signs, double bar lines and the ends of volta brackets; the marks at
  their end go to the bar before, the rest to the bar after.
- <attributes> side by side are made one: a second one in a bar that
  starts with an upbeat crashed musicxml2ly.
- The tuplet and tremolo marks on the other notes of a chord go to its
  first: homr puts them on every note.
- A tuplet runs from its start over the notes of its voice scaled as its
  first is (<time-modification>); where homr left out its stop, one is put
  after the last of them. Stops with no tuplet open are dropped. Tuplets
  musicxml2ly couldn't place crashed it.
- A two-note tremolo must stop on the next note of its voice, or is
  dropped: musicxml2ly put all the notes between into it.
- A bar holding more than its time signature gets a time signature of its
  own length, not printed. musicxml2ly let such a bar run on into the
  next, and every bar line after it was out. A time signature the bar
  gave is printed in the next, if that keeps to it.
- A first bar ends where its longest voice does: musicxml2ly took one
  whose last voice ended early for an upbeat.
- Repeat signs and volta brackets are taken out, and their structure goes
  to out.json: musicxml2ly hung on ones it couldn't make sense of.

out.json holds
  "bars": each bar's length in whole notes ("3/8"), as LilyPond will have
      it, to the end of the longest part;
  "implicit": the bars that carry on the bar before them, with no bar
      line between: a bar split at a repeat sign, say;
  "upbeat": whether the first bar is an upbeat, shorter than its time
      signature;
  "repeats": [{"from": bar, "to": bar, "times": 2,
               "endings": [{"numbers": [1], "from": bar, "to": bar}, ...]}],
      bars counted from 1, each ending following the one before;
  "changes": what was changed, to tell.
"""

import copy
import html.entities
import json
import math
import re
import sys
import xml.etree.ElementTree as ET
import zipfile
from fractions import Fraction

changes = []


def read(path):
    """The MusicXML in path, zipped (.mxl) or not."""
    if zipfile.is_zipfile(path):
        with zipfile.ZipFile(path) as z:
            container = ET.fromstring(z.read("META-INF/container.xml"))
            root = next(e for e in container.iter() if e.tag.endswith("rootfile"))
            raw = z.read(root.get("full-path"))
    else:
        with open(path, "rb") as f:
            raw = f.read()
    # Entities only the DTD would define (&nbsp;): musicxml2ly's parser lets
    # them by, and ElementTree's wants them named.
    parser = ET.XMLParser()
    for name in {n.decode() for n in re.findall(rb"&([A-Za-z][\w.-]*);", raw)}:
        if name not in ("lt", "gt", "amp", "quot", "apos"):
            parser.entity[name] = html.entities.html5.get(name + ";", "")
    parser.feed(raw)
    return ET.ElementTree(parser.close())

# Barline marks that belong to the end of a bar, and so to the bar before
# when a bar is dropped; the others (a forward repeat, an ending's start)
# belong to the bar after.
END_MARKS = {"bar-style", "segno", "coda", "fermata", "wavy-line", "footnote", "level"}


def is_end_mark(el):
    if el.tag == "repeat":
        return el.get("direction") == "backward"
    if el.tag == "ending":
        return el.get("type") != "start"
    return el.tag in END_MARKS


def barline(measure, location):
    """measure's barline at location ("left" or "right"), made if need be.
    One before the notes is at the left end, whatever its location says:
    homr marks the forward repeat that starts a bar as on its right."""
    seen_note = False
    for b in measure:
        if b.tag in ("note", "forward"):
            seen_note = True
        elif b.tag == "barline" and b.get("location", "right") == location:
            if location == "left" or seen_note:
                return b
    b = ET.Element("barline", {"location": location})
    if location == "left":
        measure.insert(0, b)
    else:
        measure.append(b)
    return b


def add_mark(b, el):
    if el.tag not in {c.tag for c in b}:
        b.append(el)


def is_empty(m):
    return m.find("note") is None and m.find("forward") is None


def drop_empty_bars(parts):
    bars = [p.findall("measure") for p in parts]
    if len({len(b) for b in bars}) != 1:
        counts = ", ".join(str(len(b)) for b in bars)
        changes.append(f"the parts have different numbers of bars ({counts}); none left out")
        return
    dropped = False
    for i in range(len(bars[0])):
        if not all(is_empty(b[i]) for b in bars):
            continue
        dropped = True
        changes.append(f"bar {bars[0][i].get('number')}: no notes, so left out")
        for part, measures in zip(parts, bars):
            m = measures[i]
            before = next((x for x in reversed(measures[:i]) if x in list(part)), None)
            after = measures[i + 1] if i + 1 < len(measures) else None
            moving = []
            for el in list(m):
                if el.tag == "barline":
                    for mark in list(el):
                        if is_end_mark(mark) and before is not None:
                            add_mark(barline(before, "right"), mark)
                        elif not is_end_mark(mark) and after is not None:
                            add_mark(barline(after, "left"), mark)
                elif not (el.tag == "print" and after is not None and after.find("print") is not None):
                    moving.append(el)
            if after is not None:
                kids = list(after)
                at = 1 if kids and kids[0].tag == "barline" else 0
                for el in reversed(moving):
                    after.insert(at, el)
            part.remove(m)
    if dropped:
        for part in parts:
            for n, m in enumerate(part.findall("measure"), start=1):
                m.set("number", str(n))


def merge_attributes(measure):
    kids = list(measure)
    for a, b in zip(kids, kids[1:]):
        if a.tag == b.tag == "attributes":
            for c in list(b):
                same = [x for x in a if x.tag == c.tag and x.get("number") == c.get("number")]
                if same:
                    a.remove(same[0])
                a.append(c)
            measure.remove(b)
            return merge_attributes(measure)


def marks(note, kind):
    """note's tuplet or two-note tremolo marks: [(element, parent)]."""
    found = []
    for n in note.findall("notations"):
        if kind == "tuplet":
            found += [(t, n) for t in n.findall("tuplet")]
        else:
            found += [(t, o) for o in n.findall("ornaments") for t in o.findall("tremolo")
                      if t.get("type") in ("start", "stop")]
    return found


def notations(note):
    n = note.find("notations")
    if n is None:
        n = ET.SubElement(note, "notations")
    return n


def is_head(note):
    """Whether note is a chord's first note (or alone), and no grace note."""
    return note.find("chord") is None and note.find("grace") is None


def chords_to_heads(part):
    """The tuplet and tremolo marks of a chord's other notes go to its first."""
    head = {}
    for note in part.iter("note"):
        voice = note.findtext("voice") or "1"
        if is_head(note):
            head[voice] = note
            continue
        if note.find("chord") is None or voice not in head:
            continue
        for kind in ("tuplet", "tremolo"):
            have = {t.get("type") for t, _ in marks(head[voice], kind)}
            for t, parent in marks(note, kind):
                parent.remove(t)
                if t.get("type") in have:
                    continue
                if kind == "tuplet":
                    notations(head[voice]).append(t)
                else:
                    o = notations(head[voice]).find("ornaments")
                    if o is None:
                        o = ET.SubElement(notations(head[voice]), "ornaments")
                    o.append(t)
                have.add(t.get("type"))


def scaling(note):
    tm = note.find("time-modification")
    if tm is None:
        return None
    return (tm.findtext("actual-notes"), tm.findtext("normal-notes"))


def mend_tuplets(part):
    opened = {}  # voice -> [its scaling, its last note so far]
    added = dropped = 0

    def drop(mark):
        nonlocal dropped
        mark[1].remove(mark[0])
        dropped += 1

    def close(voice):
        nonlocal added
        _, last = opened.pop(voice)
        notations(last).append(ET.Element("tuplet", {"type": "stop"}))
        added += 1

    for note in part.iter("note"):
        if not is_head(note):
            continue
        voice = note.findtext("voice") or "1"
        here = marks(note, "tuplet")
        starts = [m for m in here if m[0].get("type") == "start"]
        stops = [m for m in here if m[0].get("type") == "stop"]
        for m in starts[1:] + stops[1:]:
            drop(m)
        starts, stops = starts[:1], stops[:1]
        if starts and scaling(note) is None and not stops:
            drop(starts[0])  # a tuplet of unscaled notes: where would it end?
            starts = []
        if voice in opened:
            if starts or (not stops and scaling(note) != opened[voice][0]):
                close(voice)
            else:
                opened[voice][1] = note
        if starts:
            if not stops:
                opened[voice] = [scaling(note), note]
        elif stops:
            if voice in opened:
                del opened[voice]
            else:
                drop(stops[0])
    for voice in list(opened):
        close(voice)
    if added or dropped:
        changes.append(f"tuplets: {added} stops put in, {dropped} marks dropped")


def mend_tremolos(part):
    opened = {}  # voice -> the start mark of the note before
    dropped = 0
    for note in part.iter("note"):
        if not is_head(note):
            continue
        voice = note.findtext("voice") or "1"
        here = marks(note, "tremolo")
        stops = [m for m in here if m[0].get("type") == "stop"]
        starts = [m for m in here if m[0].get("type") == "start"]
        if voice in opened:
            start = opened.pop(voice)
            if stops:
                stops = stops[1:]
            else:
                stops = [start]
        for t, parent in stops + starts[1:]:
            parent.remove(t)
            dropped += 1
        if starts:
            opened[voice] = starts[0]
    for t, parent in opened.values():
        parent.remove(t)
        dropped += 1
    if dropped:
        changes.append(f"two-note tremolos: {dropped} marks without their other half dropped")


def read_time(t):
    """A <time> as (beats, beat type), or None if it isn't a plain one, as
    3+2/8 and 3/8+2/4 aren't."""
    beats, types = t.findall("beats"), t.findall("beat-type")
    try:
        if len(beats) == len(types) == 1:
            return (int(beats[0].text), int(types[0].text))
    except (TypeError, ValueError):
        pass
    return None


def time_length(t):
    """How long a bar of <time> t is, in whole notes, as musicxml2ly reckons
    it (3+2/8 is 5/8); None for senza misura."""
    try:
        return sum(Fraction(sum(int(b) for b in beats.text.split("+")), int(bt.text))
                   for beats, bt in zip(t.findall("beats"), t.findall("beat-type"))) or None
    except (AttributeError, ValueError, ZeroDivisionError):
        return None


def first_attributes(m):
    """Bar m's <attributes> before its first note, made if need be."""
    kids = list(m)
    at = next((k for k, el in enumerate(kids) if el.tag in ("note", "backup", "forward")), len(kids))
    for el in kids[:at]:
        if el.tag == "attributes":
            return el
    a = ET.Element("attributes")
    m.insert(at, a)
    return a


def extent(m, divisions):
    """Where bar m's longest voice ends, and where its last element does, as
    musicxml2ly reckons them."""
    pos = most = Fraction(0)
    for el in m:
        d = el.findtext("duration")
        if el.tag not in ("note", "forward", "backup") or not d:
            continue
        d = Fraction(int(d), 4 * divisions)
        if el.tag == "backup":
            pos = max(Fraction(0), pos - d)
        elif el.tag == "forward" or is_head(el):
            pos += d
        most = max(most, pos)
    return most, pos


def fit_bars(parts):
    """Gives each bar the time signature musicxml2ly is to count it by, the
    same in every part, and returns the bars' lengths, those that are
    implicit, and whether the first is an upbeat."""
    plans = []  # per part: [[measure, its <time> or None, sig, its length, divisions, most, end]]
    for part in parts:
        divisions, sig, length = 1, (4, 4), Fraction(1)  # musicxml2ly's defaults
        plan = []
        for m in part.findall("measure"):
            given = None
            for a in m.findall("attributes"):
                for t in a.findall("divisions"):
                    divisions = int(t.text)
                for t in a.findall("time"):
                    given, sig, length = t, read_time(t), time_length(t)
            most, end = extent(m, divisions)
            plan.append([m, given, sig, length, divisions, most, end])
        plans.append(plan)

    n = max(len(p) for p in plans)
    # Each bar's plans, of the parts that have it: homr can give the parts
    # different numbers of bars.
    rows = [[p[i] for p in plans if i < len(p)] for i in range(n)]
    # An implicit bar carries on the one before: a bar split at a repeat
    # sign, say. homr writes none.
    implicit = [i > 0 and rows[i][0][0].get("implicit") == "yes" for i in range(n)]
    lengths = []
    upbeat = False
    fitted = []  # (bar, what it holds, its time signature)
    prev = None  # the time signature musicxml2ly counts by, if known
    hidden = None  # a <time> given in a fitted bar, to show in the next

    def put_time(row, want, shown=None):
        """Gives row's bars the time signature want: the <time> a bar gives,
        if that is want, or shown (a copy), if that is, or one not printed;
        none where want is in effect already and the bar gives none."""
        for m, given, *_ in row:
            # The <time> given go, and the one wanted is put in its place.
            for a in m.findall("attributes"):
                for t in a.findall("time"):
                    a.remove(t)
            if want == prev and given is None:
                continue
            a = first_attributes(m)
            if given is not None and read_time(given) == want:
                t = given
            elif shown is not None and read_time(shown) == want:
                t = copy.deepcopy(shown)
            else:
                t = ET.Element("time", {"print-object": "no"})
                ET.SubElement(t, "beats").text = str(want[0])
                ET.SubElement(t, "beat-type").text = str(want[1])
            # In the place the schema gives it, after <divisions> and <key>.
            at = sum(1 for c in a if c.tag in ("footnote", "level", "divisions", "key"))
            a.insert(at, t)

    for i in range(n):
        row = rows[i]
        sig = row[0][2]
        most = max(r[5] for r in row)
        final = i + 1 == n  # musicxml2ly pads every bar but the last
        shown, hidden = hidden, None
        if implicit[i] or (not final and implicit[i + 1]):
            # A part of a split bar. musicxml2ly pads only the last part, to
            # the bar's length.
            if not final and implicit[i + 1]:
                length = max(r[6] for r in row)
            else:
                head = i
                while implicit[head]:
                    head -= 1
                length = most if final else max(most, (row[0][3] or most) - sum(lengths[head:i]))
            lengths.append(length)
            if not implicit[i] and sig is not None and all(r[2] == sig for r in row):
                # Its first part has its time signature, not a fitted one
                # from the bar before.
                put_time(row, sig, shown)
                prev = sig
            elif any(r[1] is not None for r in row):
                prev = None
            continue
        if sig is None or any(r[2] != sig for r in row):
            # A time signature that isn't a plain one, or the parts disagree:
            # left as it is, but that a bar giving none counts by its own
            # rather than a fitted one before it.
            lengths.append(most if final else max([most] + [r[3] for r in row if r[3]]))
            if prev is not None:
                for r in row:
                    if r[1] is None and r[2] is not None:
                        put_time([r], r[2])
            prev = None
            continue
        bar = Fraction(*sig)
        want = sig
        if most > bar:
            unit = math.lcm(sig[1], most.denominator)
            want = (int(most * unit), unit)
            bar = most
            fitted.append((i + 1, most, sig))
        if i == 0:
            # musicxml2ly takes the first bar for an upbeat if it ends short
            # of its time signature where the bar's last voice does, and
            # makes it as long as that voice: let that be the longest.
            for m, _, _, _, divisions, _, end in row:
                notes = [el for el in m if el.tag == "note"]
                if end < most and notes:
                    fwd = ET.Element("forward")
                    ET.SubElement(fwd, "duration").text = str(int((most - end) * 4 * divisions))
                    for tag in ("voice", "staff"):
                        if notes[-1].find(tag) is not None:
                            ET.SubElement(fwd, tag).text = notes[-1].findtext(tag)
                    # Before the bar's closing bar lines: musicxml2ly leaves
                    # out a forward after them.
                    kids = list(m)
                    at = len(kids)
                    while at and kids[at - 1].tag == "barline":
                        at -= 1
                    m.insert(at, fwd)
            if most < bar:
                bar = most
                upbeat = True
        lengths.append(most if final else bar)

        if want == sig:
            put_time(row, want, shown)
        else:
            # A time signature given here, put out for the fitted one, is
            # shown in the next bar, if it counts there: one the bars after
            # overrun too is likely misread.
            put_time(row, want)
            hidden = next((r[1] for r in row if r[1] is not None), None)
        prev = want
    # Told in runs of bars alike.
    k = 0
    while k < len(fitted):
        first, most, sig = fitted[k]
        last = first
        while k + 1 < len(fitted) and fitted[k + 1] == (last + 1, most, sig):
            k += 1
            last += 1
        bars = f"bar {first} holds" if first == last else f"bars {first}-{last} hold"
        changes.append(f"{bars} {most}, more than {sig[0]}/{sig[1]}; counted so, not shown")
        k += 1
    return [str(x) for x in lengths], [i + 1 for i in range(n) if implicit[i]], upbeat


def take_repeats(parts):
    """Takes the repeat signs and volta brackets out of all parts, and
    returns the structure of the first part's."""
    measures = parts[0].findall("measure")
    n = len(measures)
    fwd = [False] * n    # a repeat starts with this bar
    bwd = [None] * n     # how often a repeat is played, if it ends with this bar
    est = [None] * n     # an ending's numbers, if one starts with this bar
    estop = [False] * n  # an ending stops with this bar
    for i, m in enumerate(measures):
        seen_note = False
        for b in m:
            if b.tag in ("note", "forward"):
                seen_note = True
            if b.tag != "barline":
                continue
            # Where a barline is in its bar says which end it is at, not its
            # location: homr marks the forward repeat that starts a bar as on
            # its right, and the volta bracket that ends the bar before too.
            left = not seen_note
            rep, end = b.find("repeat"), b.find("ending")
            if rep is not None and rep.get("direction") == "forward":
                if i + (not left) < n:
                    fwd[i + (not left)] = True
            elif rep is not None and rep.get("direction") == "backward":
                times = rep.get("times") or ""
                if i - left >= 0:
                    bwd[i - left] = int(times) if times.isdigit() and int(times) > 0 else 2
            if end is not None and end.get("type") == "start":
                if i + (not left) < n:
                    est[i + (not left)] = [int(x) for x in re.findall(r"\d+", end.get("number") or "")]
            elif end is not None and i - left >= 0:
                estop[i - left] = True

    repeats = []
    body = 0  # where the music to repeat starts, if no forward repeat says
    opened = None  # the forward repeat nothing has gone back to yet

    def dangling():
        if opened is not None:
            changes.append(f"bar {opened + 1}: a repeat sign that nothing goes back to; left out")

    i = 0
    while i < n:
        if fwd[i]:
            dangling()
            body = opened = i
        if est[i] is not None and i == body:
            changes.append(f"bar {i + 1}: a volta bracket with nothing before it to repeat; left out")
        elif est[i] is not None:
            endings = []
            j = i
            while True:
                # An ending runs to its stop, or the repeat back, or the start
                # of the next ending or repeat; one with no end of its own (a
                # last ending homr didn't see stop) is as long as the one
                # before it.
                k = j
                while k + 1 < n and not (bwd[k] or estop[k] or est[k + 1] is not None or fwd[k + 1]):
                    k += 1
                if endings and not (bwd[k] or estop[k] or (k + 1 < n and est[k + 1] is not None)):
                    before = endings[-1]["to"] - endings[-1]["from"] + 1
                    k = min(k, j + before - 1)
                used = [x for e in endings for x in e["numbers"]]
                nums = est[j] or [max([0] + used) + 1]
                if endings and nums == endings[-1]["numbers"]:
                    endings[-1]["to"] = k + 1  # the same ending, marked again
                else:
                    endings.append({"numbers": nums, "from": j + 1, "to": k + 1})
                # Another ending follows one that goes back, or that runs into
                # the next one's start.
                if k + 1 < n and not fwd[k + 1] and (bwd[k] or est[k + 1] is not None):
                    j = k + 1
                    continue
                break
            if len(endings) == 1 and not bwd[k]:
                changes.append(f"bar {i + 1}: a volta bracket that doesn't lead back; left out")
                i += 1
                continue
            times = max(2, sum(len(e["numbers"]) for e in endings))
            repeats.append({"from": body + 1, "to": i, "times": times, "endings": endings})
            body = i = k + 1
            opened = None
            continue
        if bwd[i] is not None:
            if bwd[i] > 1:  # times="1": played once, so no repeat
                repeats.append({"from": body + 1, "to": i + 1, "times": bwd[i], "endings": []})
            body = i + 1
            opened = None
        i += 1
    dangling()

    for part in parts:
        for m in part.findall("measure"):
            for b in m.findall("barline"):
                had_repeat = b.find("repeat") is not None
                for el in list(b):
                    # A repeat's own bar line comes with the repeat.
                    if el.tag in ("repeat", "ending") or (had_repeat and el.tag == "bar-style"):
                        b.remove(el)
                if len(b) == 0:
                    m.remove(b)
    return repeats


def main():
    tree = read(sys.argv[1])
    parts = tree.getroot().findall("part")
    bars, implicit, upbeat, repeats = [], [], False, []
    if parts:
        drop_empty_bars(parts)
        for part in parts:
            for m in part.findall("measure"):
                merge_attributes(m)
            chords_to_heads(part)
            mend_tuplets(part)
            mend_tremolos(part)
        bars, implicit, upbeat = fit_bars(parts)
        repeats = take_repeats(parts)
    tree.write(sys.argv[2], encoding="UTF-8", xml_declaration=True)
    with open(sys.argv[3], "w") as f:
        json.dump({"bars": bars, "implicit": implicit, "upbeat": upbeat, "repeats": repeats,
                   "changes": changes},
                  f, indent=1)


main()
