#!/usr/bin/env python3
"""
Fetch freely licensed photos and reference data for Capitán's marine-life guides.

The script reads one of the bundled species JSON files, looks up each entry on
Wikipedia and Wikimedia Commons, and can:

  * add image / imageSource / imageCredit / imageLicense fields,
  * download the photo into assets/images/<id>.jpg,
  * fill a missing conservation status from the article's IUCN taxobox,
  * save a Wikipedia summary extract for reference.

Only public-domain, CC0, CC BY and CC BY-SA images are accepted. CC BY / BY-SA
images require attribution in the app; the fields written here drive that.

Examples
--------
    # Fill every photo that is still missing, in place
    python3 tools/fetch_marine_life.py assets/data/fish.json \
        --in-place --missing-images --download

    # Re-fetch everything and refresh the credits file
    python3 tools/fetch_marine_life.py assets/data/coral.json \
        --in-place --download --credits coral-credits.csv

    # Just collect Wikipedia summaries for the entries that need photos
    python3 tools/fetch_marine_life.py assets/data/fish.json \
        --missing-images --summaries tools/wikipedia-summaries.json
"""
from __future__ import annotations

import argparse
import csv
import html
import json
import pathlib
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

# Wikimedia asks for a descriptive User-Agent. Change the contact before
# running this against the live API from a different project.
UA = "CapitanReefGuide/1.0 (https://github.com/capitan; hello@capitan.app)"
WIDTH = 600  # Keep downloaded photos small enough for mobile app assets.
API_DELAY = 0.5
ENTRY_DELAY = 1.0
OK_LICENSE = re.compile(r"^(CC0|CC BY|Public domain|PD)", re.I)
BAD_FILE_WORDS = re.compile(
    r"(MNHN|skeleton|specimen|holotype|figure|diagram|map|range|skull|jaw|"
    r"otolith|dissection|museum|drawing|illustration|chart|plate|fossil)",
    re.I,
)

# Articles that are genus-level, recently renamed, or only have a useful page
# under the common name. These are tried before the scientific name.
TITLE_OVERRIDES: dict[str, list[str]] = {
    "brain-coral": ["Diploria labyrinthiformis", "Pseudodiploria labyrinthiformis", "Brain coral"],
    "fire-coral": ["Millepora alcicornis", "Fire coral", "Millepora"],
    "sea-fan": ["Gorgonia flabellum", "Gorgonia", "Sea fan"],
    "leather-coral": ["Sarcophyton", "Leather coral"],
    "carnation-coral": ["Dendronephthya", "Carnation coral"],
    "black-coral": ["Antipatharia", "Black coral"],
    "mushroom-coral": ["Fungia fungites", "Cycloseris", "Fungia", "Mushroom coral"],
    "bubble-coral": ["Plerogyra sinuosa", "Plerogyra", "Bubble coral"],
    "organ-pipe-coral": ["Tubipora musica", "Tubipora"],
    "blue-coral": ["Heliopora coerulea", "Heliopora"],
    "rose-coral": ["Manicina areolata", "Rose coral"],
    "porites-boulder": ["Porites lobata", "Porites"],
    "finger-coral": ["Porites porites", "Finger coral"],
    "boulder-star-coral": ["Orbicella annularis", "Montastraea annularis", "Orbicella"],
    "magnificent-anemone": ["Heteractis magnifica", "Magnificent sea anemone"],
    "red-gorgonian": ["Paramuricea clavata", "Red gorgonian"],
    "xenia-coral": ["Xenia (coral)", "Xenia umbellata", "Xenia"],
    "zoanthid": ["Zoanthus", "Zoantharia", "Zoanthid"],
    "green-star-polyps": ["Briareum", "Briareum violaceum"],
    "cuttlefish": ["Sepia latimanus", "Broadclub cuttlefish"],
    "box-jellyfish": ["Chironex fleckeri", "Box jellyfish"],
    "blue-groper": ["Achoerodus viridis", "Blue groper"],
    "elkhorn-coral": ["Acropora palmata"],
}

# Some articles have no suitable lead image. These Commons files are known-good
# replacements (free licence, live animal/colony, correct species).
FILE_OVERRIDES: dict[str, str] = {
    "sea-fan": "Gorgonia flabellum, Bahamas.jpg",
    "mustard-hill-coral": (
        "Porites astreoides (mustard hill coral) "
        "(San Salvador Island, Bahamas) 1 (16097660545).jpg"
    ),
    "pacific-sea-fan": "Muricea californica.jpg",
    # The article lead image is an elegance coral, not this species.
    "duncan-coral": "Duncanopsammia axifuga (whisker coral).jpg",
}

STATUS = {
    "LC": "Least concern",
    "NT": "Near threatened",
    "VU": "Vulnerable",
    "EN": "Endangered",
    "CR": "Critically endangered",
    "DD": "Data deficient",
    "NE": "Not evaluated",
    "EW": "Extinct in the wild",
    "EX": "Extinct",
}


def api(base: str, **params):
    """GET a MediaWiki API endpoint with retries."""
    params["format"] = "json"
    url = f"{base}?{urllib.parse.urlencode(params)}"
    last: Exception | None = None
    for attempt in range(4):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=30) as response:
                return json.load(response)
        except urllib.error.HTTPError as exc:
            last = exc
            wait = int(exc.headers.get("Retry-After", 0) or 0) or 3 * (attempt + 1)
            print(f"  ! HTTP {exc.code}; retrying in {wait}s", file=sys.stderr)
            time.sleep(wait)
        except Exception as exc:  # noqa: BLE001
            last = exc
            wait = 3 * (attempt + 1)
            print(f"  ! {exc}; retrying in {wait}s", file=sys.stderr)
            time.sleep(wait)
    print(f"  ! giving up: {last}", file=sys.stderr)
    return {}


def clean(value: str) -> str:
    return html.unescape(re.sub(r"<[^>]+>", "", value or "")).strip()


def page_data(title: str):
    """Return (lead image filename, wikitext) for an English Wikipedia page."""
    data = api(
        "https://en.wikipedia.org/w/api.php",
        action="query",
        prop="pageimages|revisions",
        piprop="name",
        rvprop="content",
        rvslots="main",
        redirects=1,
        titles=title,
    )
    for page in data.get("query", {}).get("pages", {}).values():
        if "missing" in page:
            return None, None
        image = page.get("pageimage")
        text = ""
        revisions = page.get("revisions") or []
        if revisions:
            text = revisions[0].get("slots", {}).get("main", {}).get("*", "")
        return image, text
    return None, None


def commons_info(filename: str):
    """Return image URL, description page, licence and author for a Commons file."""
    data = api(
        "https://commons.wikimedia.org/w/api.php",
        action="query",
        titles=f"File:{filename}",
        prop="imageinfo",
        iiprop="url|extmetadata",
        iiurlwidth=WIDTH,
    )
    for page in data.get("query", {}).get("pages", {}).values():
        info = (page.get("imageinfo") or [None])[0]
        if not info:
            return None
        meta = info.get("extmetadata", {})
        return {
            "filename": filename,
            "url": (info.get("thumburl") or info["url"]).split("?", 1)[0],
            "source": info.get("descriptionurl", ""),
            "license": clean(meta.get("LicenseShortName", {}).get("value", "")),
            "author": clean(meta.get("Artist", {}).get("value", "")) or "Unknown",
        }
    return None


def usable(info) -> bool:
    return bool(info and OK_LICENSE.match(info["license"]))


def search_commons(query: str):
    """Search Commons for a live-photo fallback, preferring species-named files."""
    data = api(
        "https://commons.wikimedia.org/w/api.php",
        action="query",
        generator="search",
        gsrsearch=f"filetype:bitmap {query}",
        gsrnamespace=6,
        gsrlimit=20,
        prop="imageinfo",
        iiprop="url|size|extmetadata",
        iiurlwidth=WIDTH,
    )
    pages = list(data.get("query", {}).get("pages", {}).values())
    candidates = []
    for page in pages:
        title = page.get("title", "")
        if BAD_FILE_WORDS.search(title):
            continue
        info = (page.get("imageinfo") or [None])[0]
        if not info:
            continue
        meta = info.get("extmetadata", {})
        candidate = {
            "filename": title.removeprefix("File:"),
            "url": (info.get("thumburl") or info["url"]).split("?", 1)[0],
            "source": info.get("descriptionurl", ""),
            "license": clean(meta.get("LicenseShortName", {}).get("value", "")),
            "author": clean(meta.get("Artist", {}).get("value", "")) or "Unknown",
            "area": (info.get("width") or 0) * (info.get("height") or 0),
        }
        if usable(candidate):
            candidates.append(candidate)
    # Prefer files named for the species, then the largest available image.
    candidates.sort(
        key=lambda c: (
            0 if query.lower() in c["filename"].lower() else 1,
            0 if c["area"] >= 800 * 600 else 1,
            -c["area"],
        )
    )
    return candidates[0] if candidates else None


def candidate_titles(entry) -> list[str]:
    scientific = re.sub(r"\s+spp?\.?$", "", entry["scientificName"]).strip()
    titles = (
        TITLE_OVERRIDES.get(entry["id"], [])
        + [scientific, entry["name"], scientific.split()[0]]
    )
    seen, ordered = set(), []
    for title in titles:
        if title and title not in seen:
            seen.add(title)
            ordered.append(title)
    return ordered


def find_image(entry):
    if entry["id"] in FILE_OVERRIDES:
        info = commons_info(FILE_OVERRIDES[entry["id"]])
        if usable(info):
            return info
    for title in candidate_titles(entry):
        try:
            filename, _ = page_data(title)
            if not filename:
                continue
            info = commons_info(filename)
            if usable(info):
                return info
        except Exception as exc:  # noqa: BLE001
            print(f"  ! {title}: {exc}", file=sys.stderr)
        time.sleep(API_DELAY)
    # Last resort: Commons file search, which catches articles without a lead image.
    for query in (entry["scientificName"], entry["name"]):
        info = search_commons(re.sub(r"\s+spp?\.?$", "", query).strip())
        if info:
            return info
        time.sleep(API_DELAY)
    return None


def iucn_status(text: str | None):
    if not text:
        return None
    match = re.search(r"\|\s*status\s*=\s*([A-Z]{2})\b", text)
    return STATUS.get(match.group(1)) if match else None


def wikipedia_summary(title: str):
    url = (
        "https://en.wikipedia.org/api/rest_v1/page/summary/"
        + urllib.parse.quote(title.replace(" ", "_"), safe="")
    )
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            data = json.load(response)
    except Exception as exc:  # noqa: BLE001
        print(f"  ! summary {title}: {exc}", file=sys.stderr)
        return None
    return {
        "title": data.get("title", title),
        "url": (data.get("content_urls", {}).get("desktop", {}).get("page") or ""),
        "extract": data.get("extract", ""),
    }


def download(url: str, dest: pathlib.Path, tries: int = 4, force: bool = False) -> bool:
    if not force and dest.exists() and dest.stat().st_size > 0:
        return True
    for attempt in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=60) as response:
                data = response.read()
            if not data:
                raise ValueError("empty response")
            dest.write_bytes(data)
            return True
        except urllib.error.HTTPError as exc:
            wait = int(exc.headers.get("Retry-After", 0) or 0) or 3 * (attempt + 1)
            print(
                f"  ! download HTTP {exc.code}; retrying in {wait}s",
                file=sys.stderr,
            )
            time.sleep(wait)
        except Exception as exc:  # noqa: BLE001
            wait = 3 * (attempt + 1)
            print(f"  ! download error: {exc}; retrying in {wait}s", file=sys.stderr)
            time.sleep(wait)
    return False


def write_credits(path: pathlib.Path, entries) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["id", "name", "author", "license", "source"])
        for entry in entries:
            if not entry.get("image"):
                continue
            writer.writerow(
                [
                    entry["id"],
                    entry["name"],
                    entry.get("imageCredit", ""),
                    entry.get("imageLicense", ""),
                    entry.get("imageSource", ""),
                ]
            )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", type=pathlib.Path, help="species JSON file")
    parser.add_argument(
        "--out",
        type=pathlib.Path,
        help="output JSON (default: <name>.with-images.json; use --in-place for the input file)",
    )
    parser.add_argument("--in-place", action="store_true", help="write to the input file")
    parser.add_argument(
        "--missing-images",
        action="store_true",
        help="only process entries that do not have an image yet",
    )
    parser.add_argument(
        "--ids",
        help="comma-separated entry ids to process (default: all selected by the other flags)",
    )
    parser.add_argument(
        "--download",
        action="store_true",
        help="download photos into --outdir (default: assets/images)",
    )
    parser.add_argument(
        "--outdir",
        type=pathlib.Path,
        default=pathlib.Path("assets/images"),
        help="image directory (default: assets/images)",
    )
    parser.add_argument(
        "--credits",
        type=pathlib.Path,
        help="write a per-image credits CSV",
    )
    parser.add_argument(
        "--summaries",
        type=pathlib.Path,
        help="write Wikipedia summaries for processed entries to this JSON file",
    )
    parser.add_argument(
        "--update-conservation",
        action="store_true",
        help="overwrite existing conservation values with the article's IUCN status",
    )
    parser.add_argument(
        "--refresh",
        action="store_true",
        help="re-download files even when a local copy already exists",
    )
    args = parser.parse_args()

    entries = json.loads(args.path.read_text(encoding="utf-8"))
    if args.download:
        args.outdir.mkdir(parents=True, exist_ok=True)

    processed = 0
    found = 0
    missing = []
    summaries = {}
    article_titles = {}
    selected_ids = (
        {part.strip() for part in args.ids.split(",") if part.strip()}
        if args.ids
        else None
    )

    for entry in entries:
        if selected_ids is not None and entry["id"] not in selected_ids:
            continue
        existing_image = entry.get("image")
        if args.missing_images and existing_image:
            continue
        processed += 1
        print(f"{entry['name']} ({entry['scientificName']})")

        image = find_image(entry)
        if not image:
            missing.append(entry["id"])
            print("  -> no suitable free image found")
            time.sleep(ENTRY_DELAY)
            continue

        if args.download:
            dest = args.outdir / f"{entry['id']}.jpg"
            if not download(image["url"], dest, force=args.refresh):
                missing.append(entry["id"])
                print("  -> download failed")
                time.sleep(ENTRY_DELAY)
                continue
            entry["image"] = dest.as_posix()
        else:
            entry["image"] = image["url"]

        entry["imageSource"] = image["source"]
        entry["imageCredit"] = image["author"]
        entry["imageLicense"] = image["license"]
        found += 1
        print(f"  -> {image['license']} by {image['author'][:60]}")

        # Use the same article for the IUCN status and the summary. Prefer the
        # scientific name, then the common name, then any title that resolved.
        title = None
        for candidate in candidate_titles(entry):
            _, text = page_data(candidate)
            if text:
                title = candidate
                article_titles[entry["id"]] = title
                status = iucn_status(text)
                if status and (args.update_conservation or not entry.get("conservation")):
                    entry["conservation"] = status
                break
            time.sleep(API_DELAY)

        if args.summaries and title:
            summary = wikipedia_summary(title)
            if summary:
                summaries[entry["id"]] = summary
            time.sleep(API_DELAY)

        time.sleep(ENTRY_DELAY)

    output = args.path if args.in_place else (
        args.out or args.path.with_name(args.path.stem + ".with-images.json")
    )
    output.write_text(
        json.dumps(entries, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"\nWrote {output}")

    if args.credits:
        write_credits(args.credits, entries)
        print(f"Wrote {args.credits}")

    if args.summaries:
        merged = {}
        if args.summaries.exists():
            merged = json.loads(args.summaries.read_text(encoding="utf-8"))
        merged.update(summaries)
        args.summaries.write_text(
            json.dumps(merged, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        print(f"Wrote {args.summaries} ({len(merged)} summaries)")

    print(f"Done: {found} image(s) found, {len(missing)} missing")
    if missing:
        print("Missing:", ", ".join(missing))


if __name__ == "__main__":
    main()
