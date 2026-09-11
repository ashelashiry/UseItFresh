"""Anchor a TestFlight build so it can be found again and rolled back to.

    python scripts/release.py 7 --note "what this build is"
    python scripts/release.py 7 --dry-run

Run it straight after FlutterFlow finishes "Deploy to TestFlight", with the
build number you used. It records, in one go:

  * a git tag  build-<n>-ios  on the commit the app was built from, annotated
    with the FlutterFlow commit, the live photo-function version and the date;
  * a FlutterFlow branch  build-<n>-ios  from that same FlutterFlow commit, so
    the project can be reopened exactly as it was;
  * a row in RELEASES.md saying what is in the build and how to go back to it.

Nothing here touches the phone or the App Store: it records what was shipped.
Rolling back means deploying from the tagged FlutterFlow branch again, which
is why the branch matters more than the tag.
"""

import argparse
import json
import pathlib
import re
import subprocess
import sys
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
FUNCTION_URL = ("https://ltdvxdizjrkgwldbmbbf.supabase.co"
                "/functions/v1/recognise-food")


def run(cmd):
    """A command, its output, and a clear failure."""
    done = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True,
                          shell=isinstance(cmd, str))
    if done.returncode != 0:
        raise SystemExit("failed: %s\n%s%s" % (cmd, done.stdout, done.stderr))
    return done.stdout.strip()


def git_commit():
    return run(["git", "rev-parse", "HEAD"])[:7]


def tree_is_clean():
    """Tracked files only: the design folders are deliberately untracked."""
    return run(["git", "status", "--porcelain", "--untracked-files=no"]) == ""


def flutterflow_commit():
    state = json.loads((ROOT / ".flutterflow" / "workspace.json").read_text())
    pushed = state.get("lastRun", {})
    if not pushed.get("pushed"):
        raise SystemExit(
            "the last FlutterFlow run was not pushed: push before releasing")
    return pushed["commitId"]


def function_version():
    """The photo function's own version, from the signed-out reply."""
    request = urllib.request.Request(
        FUNCTION_URL, data=b"{}", method="POST",
        headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(request, timeout=25) as answer:
            body = json.loads(answer.read())
    except urllib.error.HTTPError as refused:      # 401 is the normal answer
        body = json.loads(refused.read())
    except Exception as wrong:                     # offline, DNS, timeout
        return "unknown (%s)" % wrong
    return body.get("version", "none (pre-version copy)")


def app_version():
    """The version the generated app was built with, such as 1.0.0+6."""
    pubspec = (ROOT / "generated_code" / "pubspec.yaml").read_text(
        encoding="utf-8")
    found = re.search(r"^version:\s*(\S+)", pubspec, re.M)
    return found.group(1) if found else "unknown"


def main():
    ask = argparse.ArgumentParser(description="Record a TestFlight build.")
    ask.add_argument("build", type=int, help="the TestFlight build number")
    ask.add_argument("--note", default="", help="one line: what this build is")
    ask.add_argument("--dry-run", action="store_true",
                     help="say what would be recorded, change nothing")
    args = ask.parse_args()

    name = "build-%d-ios" % args.build
    facts = {
        "build": args.build,
        "git commit": git_commit(),
        "FlutterFlow commit": flutterflow_commit(),
        "photo function": function_version(),
        "app version in code": app_version(),
        "date": run(["git", "log", "-1", "--format=%cs"]),
        "note": args.note or "(none given)",
    }
    for key, value in facts.items():
        print("  %-22s %s" % (key, value))

    if args.dry_run:
        print("\ndry run: nothing recorded")
        return

    if not tree_is_clean():
        raise SystemExit("commit your changes first: a tag on a dirty tree "
                         "points at something you cannot get back")
    if name in run(["git", "tag", "-l"]).split():
        raise SystemExit("%s already exists: builds are recorded once" % name)

    message = (
        "Build %d (iOS, TestFlight). %s\n\n"
        "FlutterFlow commit %s, branch %s.\n"
        "Photo function %s.\n"
        "App version in code %s.\n\n"
        "Roll back: flutterflow ai branch checkout %s, then deploy from "
        "FlutterFlow with a HIGHER build number."
        % (args.build, facts["note"], facts["FlutterFlow commit"], name,
           facts["photo function"], facts["app version in code"], name))
    run(["git", "tag", "-a", name, "-m", message])
    print("\ntagged %s" % name)

    # The snapshot that actually matters: the project as it was, in FlutterFlow.
    print(run("flutterflow ai branch create %s --from %s"
              % (name, facts["FlutterFlow commit"])))

    ledger = ROOT / "RELEASES.md"
    row = ("| %d | %s | `%s` | `%s` | `%s` | %s |\n"
           % (args.build, facts["date"], name, facts["FlutterFlow commit"],
              facts["photo function"], args.note or "—"))
    text = ledger.read_text(encoding="utf-8")
    marker = "<!-- releases: newest first -->\n"
    if marker not in text:
        raise SystemExit("RELEASES.md has lost its marker line")
    head, rest = text.split(marker, 1)
    lines = rest.split("\n", 2)            # the table header, its dashes, then rows
    ledger.write_text(head + marker + lines[0] + "\n" + lines[1] + "\n" + row
                      + lines[2], encoding="utf-8")
    print("recorded in RELEASES.md")
    print("\nNow: git push && git push origin %s" % name)


if __name__ == "__main__":
    sys.exit(main())
