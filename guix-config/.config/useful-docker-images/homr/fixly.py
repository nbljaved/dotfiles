r"""fixly.py in.ly in.json out.ly: the second pass of pdf2ly.

It puts the repeats fixxml.py took out of the MusicXML into the .ly that
LilyPond's musicxml2ly made of it. They go in a track of their own,
Repeats: spacer rests, bar by bar as long as fixxml.py found the bars, with
\repeat volta and \alternative about them. Each staff is given the track,
in a Devnull context, so its repeats are drawn and followed but it adds
nothing else; the voices themselves aren't touched.
"""

import json
import re
import sys
from fractions import Fraction


def spacer(length):
    if length.denominator == 1:
        return f"s1*{length.numerator}" if length != 1 else "s1"
    return f"s1*{length.numerator}/{length.denominator}"


def track(bars, implicit, upbeat, repeats):
    """The Repeats track, as lines."""
    before = {}  # bar -> what opens before it
    after = {}   # bar -> what closes after it
    for r in repeats:
        before.setdefault(r["from"], []).append(f"\\repeat volta {r['times']} {{")
        if r["endings"]:
            for k, e in enumerate(r["endings"]):
                opening = [f"\\volta {','.join(map(str, e['numbers']))} {{"]
                if k == 0:
                    opening.insert(0, "\\alternative {")
                before.setdefault(e["from"], []).append(opening)
                after.setdefault(e["to"], []).insert(0, "}")
            last = r["endings"][-1]["to"]
            after[last] += ["}", "}"]  # the alternatives, and the repeat
        else:
            after.setdefault(r["to"], []).append("}")

    lines = []
    depth = 1
    out = lambda text: lines.append("  " * depth + text)
    n = 1
    while n <= len(bars):
        for opening in before.get(n, []):
            for text in opening if isinstance(opening, list) else [opening]:
                out(text)
                depth += 1
        # A run of bars as long as each other, up to the next mark.
        length = Fraction(bars[n - 1])
        last = n
        while (last < len(bars) and Fraction(bars[last]) == length
               and last not in after and last + 1 not in before
               and not (upbeat and last == 1)):
            last += 1
        # No bar check where a bar carries on (an implicit one).
        check = "" if last + 1 in implicit else " |"
        if n == 1 and upbeat:
            out(f"\\partial {spacer(length)[1:]} {spacer(length)}{check}  % 1")
        else:
            span = f"{n}" if last == n else f"{n}-{last}"
            out(f"{spacer(length * (last - n + 1))}{check}  % {span}")
        for text in after.get(last, []):
            depth -= 1
            out(text)
        n = last + 1
    return ["% The repeats, as fixxml.py read them: a spacer rest a bar.",
            "Repeats = {"] + lines + ["}", ""]


def main():
    ly = open(sys.argv[1], encoding="utf-8").read()
    found = json.load(open(sys.argv[2]))
    if found["repeats"] and found["bars"]:
        definition = "\n".join(track(found["bars"], found["implicit"], found["upbeat"],
                                      found["repeats"])) + "\n"
        at = ly.find("% The score definition")
        if at < 0:
            at = ly.find("\\score {")
        ly = ly[:at] + definition + ly[at:]
        # One \context Staff ... << for each staff musicxml2ly writes.
        ly = re.sub(r'^([ \t]*)(\\context Staff(?: = "[^"]*")? <<)[ \t]*$',
                    lambda m: f"{m[1]}{m[2]}\n{m[1]}  \\new Devnull \\Repeats",
                    ly, flags=re.M)
    open(sys.argv[3], "w", encoding="utf-8").write(ly)


main()
