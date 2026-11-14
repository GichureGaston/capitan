#!/usr/bin/env python3
"""
Fetch freely licensed photos for each species in your JSON from Wikimedia Commons.

Usage:
    python fetch_species_images.py species.json
    python fetch_species_images.py species.json --download   # also save files to ./images

Outputs:
    species.with-images.json  (adds image, imageSource, imageCredit, imageLicense)
    <input-name>-credits.csv  (attribution list; review this before publishing)
    assets/images/<id>.jpg    (only with --download; change with --outdir)

Only images whose licence is public domain, CC0, CC BY or CC BY-SA are accepted.
CC BY / BY-SA require you to show the credit text somewhere in your app.
"""
import argparse, csv, html, json, pathlib, re, sys, time
import urllib.parse, urllib.request

# Wikimedia asks for a descriptive User-Agent with contact info. Edit this.
UA = "CapitanReefGuide/1.0 (https://github.com/capitan; hello@capitan.app)"
WIDTH = 600  # Keep downloaded photos small enough for mobile app assets.

OK_LICENSE = re.compile(r"^(CC0|CC BY|Public domain|PD)", re.I)


def api(base, **params):
    params["format"] = "json"
    url = f"{base}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def lead_image_filename(title):
    """Name of the main image on the English Wikipedia article for `title`."""
    data = api("https://en.wikipedia.org/w/api.php", action="query", prop="pageimages",
               piprop="name", redirects=1, titles=title)
    for page in data.get("query", {}).get("pages", {}).values():
        if "pageimage" in page:
            return page["pageimage"]
    return None


def commons_info(filename):
    data = api("https://commons.wikimedia.org/w/api.php", action="query",
               titles=f"File:{filename}", prop="imageinfo",
               iiprop="url|extmetadata", iiurlwidth=WIDTH)
    for page in data.get("query", {}).get("pages", {}).values():
        info = (page.get("imageinfo") or [None])[0]
        if not info:
            return None
        meta = info.get("extmetadata", {})
        clean = lambda k: html.unescape(re.sub(r"<[^>]+>", "", meta.get(k, {}).get("value", ""))).strip()
        return {
            "url": (info.get("thumburl") or info["url"]).split("?", 1)[0],
            "source": info.get("descriptionurl", ""),
            "license": clean("LicenseShortName"),
            "author": clean("Artist") or "Unknown",
        }
    return None


def download(url, dest, tries=4):
    """Download with retries and backoff. Returns True on success."""
    if dest.exists() and dest.stat().st_size > 0:
        return True  # already have it, so reruns resume
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=60) as r:
                dest.write_bytes(r.read())
            return True
        except urllib.error.HTTPError as e:
            print(f"  ! download HTTP {e.code} (attempt {i + 1}/{tries})", file=sys.stderr)
            wait = int(e.headers.get("Retry-After", 0) or 0) or 3 * (i + 1)
            time.sleep(wait)
        except Exception as e:
            print(f"  ! download error: {e} (attempt {i + 1}/{tries})", file=sys.stderr)
            time.sleep(3 * (i + 1))
    return False


def find_image(sp):
    sci = re.sub(r"\s+spp?\.?$", "", sp["scientificName"]).strip()
    for title in (sci, sp["name"]):
        try:
            fn = lead_image_filename(title)
            if not fn:
                continue
            info = commons_info(fn)
            if info and OK_LICENSE.match(info["license"]):
                return info
        except Exception as e:
            print(f"  ! {title}: {e}", file=sys.stderr)
        time.sleep(0.3)
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("path")
    ap.add_argument("--download", action="store_true")
    ap.add_argument("--outdir", default="assets/images", help="where to save images (default: assets/images)")
    args = ap.parse_args()

    src = pathlib.Path(args.path)
    species = json.loads(src.read_text(encoding="utf-8"))
    rows, missing = [], []

    if args.download:
        pathlib.Path(args.outdir).mkdir(parents=True, exist_ok=True)

    for sp in species:
        print(f"{sp['name']} ({sp['scientificName']})")
        info = find_image(sp)
        if not info:
            missing.append(sp["id"])
            print("  -> no suitable free image found")
            continue

        image = info["url"]
        if args.download:
            dest = pathlib.Path(args.outdir) / f"{sp['id']}.jpg"
            if not download(info["url"], dest):
                missing.append(sp["id"])
                print("  -> download failed, skipping")
                continue
            image = dest.as_posix()

        sp["image"] = image
        sp["imageSource"] = info["source"]
        sp["imageCredit"] = info["author"]
        sp["imageLicense"] = info["license"]
        rows.append([sp["id"], sp["name"], info["author"], info["license"], info["source"]])
        print(f"  -> {info['license']} by {info['author'][:50]}")
        time.sleep(1)

    out = src.with_name(src.stem + ".with-images.json")
    out.write_text(json.dumps(species, indent=2, ensure_ascii=False), encoding="utf-8")
    credits = f"{src.stem}-credits.csv"
    with open(credits, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["id", "name", "author", "license", "source"])
        w.writerows(rows)

    print(f"\nDone: {len(rows)} found, {len(missing)} missing")
    if missing:
        print("Missing (try the sources below):", ", ".join(missing))


if __name__ == "__main__":
    main()
