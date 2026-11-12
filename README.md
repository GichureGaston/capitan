# Capitán

**Your pocket companion for the sea — conditions, tides, spots, and the reef life you meet.**

Capitán is a Flutter app for snorkellers, freedivers, surfers, and anyone who spends their free time in the water. It answers the questions I kept asking myself before and after every session:

- Is it worth getting in today? What will the wind, waves, and sea temperature feel like?
- When is the tide turning, and how much water is moving?
- Where did I swim last time — and what is that fish I just saw?
- What is safe to touch, and what should I keep my fins away from?
- How long can I stay out before the sun wins?

---

## Inspiration

I have been snorkelling and freediving for about a year now. Somewhere between the first nervous duck-dive and the first proper reef swim, the ocean went from "a nice place to visit" to the thing I plan my weekends around.

But a year in, I noticed something: I kept forgetting things.

I forgot the names of the dive spots I liked. I forgot which fish were harmless and which ones sting. I forgot whether the tide was coming in or going out, whether the wind would make the surface choppy by midday, and whether that bright coral was something I could gently point at — or something that would cut me if I brushed it.

Field guides are beautiful but heavy. Weather apps know the air temperature, not the sea. Tide tables are cryptic until you already understand tides. And none of them tell you, in one glance, *"today is a good day to snorkel here, but keep your hands to yourself."*

So I built Capitán: one small app that gathers the sea conditions, the tide, the local swim spots, and a photo guide to the fish and coral I am likely to see — with an opinionated, plain-language safety read on it all.

The goal is simple: spend less time guessing and more time in the water. And come home with all your fingers, a rough idea of what you saw, and a good story.

---

## What the app does

### 🌊 Now — conditions and activity ratings
A single dashboard for the moment you are about to get in:

- Current air and "feels like" temperature, wind direction, gusts, humidity, and cloud cover.
- Wave height and period, sea-surface temperature, sea level, and whether the tide is rising, falling, or slacking.
- UV index now and today's peak, visibility, and rain chance for the next few hours.
- Sun protection advice that changes with the UV band (SPF, reapplication timing, rash-guard guidance, when to seek shade).
- Sunrise/sunset and a seven-day outlook.
- **Activity ratings for snorkelling, freediving, surfing, and swimming** — Excellent / Good / Fair / Poor / Dangerous, with the reasons behind each score: waves, wind, gusts, currents, sea temperature, and UV.
- **After dark, the app suggests rest instead of a water activity.** Capitán is a daylight companion; night swimming is a different sport with different risks.

### 🌗 Tides & sea
- Sea-level chart for the next 24 hours, 48 hours, or 7 days.
- The next high or low tide, with time and height, plus the trend right now.
- Upcoming tide turns and the tidal range over the next 24 hours.
- Wave and current detail, plus an hourly wind and gust chart.
- A clear reminder that modelled tides are guidance, not navigation data.

### 🏖 Spots — nearby swim spots
- Finds beaches and swimming areas around you using OpenStreetMap data (via Overpass).
- Shows distance, surface type, and — where the data exists — whether a spot is patrolled.
- Pulls weather and marine conditions for each spot and rates swimming there, so you can compare a few options before committing.
- One tap sets the spot as your current location, and Capitán remembers it next time.

### 🐟 Fish guide
- 33 fish species, each with a photo, scientific name, size, diet, habitat, and conservation status.
- **Danger labels in plain language:** Harmless, Sharp / spiny, Stings, Venomous, Bites when provoked, Poisonous to eat.
- A short "what to know" description and a fun fact per species.
- Automatically filters to species typical for the waters around your current location (Caribbean, Indo-Pacific, Red Sea, Mediterranean, and more), with a toggle for the full guide and search by common or scientific name.

### 🪸 Coral guide
- 21 corals and reef-life entries (including anemones, jellies, octopuses, turtles, and sharks), with photos and the same safety framing.
- Calls out fragile, sharp, and stinging reef life — the things to look at from a respectful distance rather than touch.
- Conservation status surfaced next to the danger label, because "don't touch" is both a safety rule and a reef rule.

### 📍 Anywhere you swim
- Search for a beach, town, or bay by name, or use your device location.
- Your chosen location is saved locally, so the app opens where you left off.

All species data and photos are bundled with the app — the fish and coral guides work offline.

---

## Screenshots

> Add screenshots here. Drop the images into `docs/screenshots/` and replace the placeholders below.

| Now dashboard | Tides & sea |
| --- | --- |
| ![Dashboard](docs/screenshots/dashboard.png) | ![Tides](docs/screenshots/tides.png) |

| Swim spots | Fish guide |
| --- | --- |
| ![Spots](docs/screenshots/spots.png) | ![Fish guide](docs/screenshots/fish.png) |

| Coral guide | Species detail |
| --- | --- |
| ![Coral guide](docs/screenshots/coral.png) | ![Species detail](docs/screenshots/species-detail.png) |

---

## Safety, in plain terms

Capitán is a planning aid, not a lifeguard, a tide table, or a substitute for local knowledge.

- **Conditions are modelled.** Weather and marine forecasts can be wrong, especially close to shore and around headlands. Check the water with your own eyes before you commit.
- **Tides are estimates.** Tide heights are modelled above mean sea level (Open-Meteo / Copernicus Marine). Coastal features shift local tides; use official local tide tables for anything navigation-critical.
- **Ratings are heuristics.** The activity scores combine wind, waves, currents, water temperature, and UV. They do not know about your experience, your buddy, the exit, boat traffic, or the local shore break.
- **"Dangerous" means don't.** Thunderstorms, big surf, and strong currents push ratings to Dangerous. Treat that as a stop sign, not a challenge.
- **Look, don't touch.** The fish and coral guides flag sharp, stinging, venomous, biting, and poisonous species. Even "harmless" animals can be stressed or defended by reef rules and local law.
- **Go with a buddy, and go in daylight.** The app deliberately rates every activity as rest after dark.
- **Sun exposure is cumulative.** UV advice is per band, but reflections off the water mean you burn faster than the forecast suggests.

If you are ever unsure: don't get in. The sea will still be there tomorrow.

---

## Data sources and credits

| What | Source |
| --- | --- |
| Weather, forecast, geocoding | [Open-Meteo](https://open-meteo.com/) |
| Waves, sea level, sea temperature, currents | [Open-Meteo Marine API](https://open-meteo.com/en/docs/marine-weather-api) (Copernicus Marine data) |
| Beaches and swimming areas | [OpenStreetMap](https://www.openstreetmap.org/) via the [Overpass API](https://overpass-api.de/) |
| Species photos | [Wikimedia Commons](https://commons.wikimedia.org/) |

Photo licences are limited to public domain, CC0, CC BY, and CC BY-SA. Attribution is stored alongside each species and shown in the detail screen. Per-image credits are also kept in [`fish-credits.csv`](fish-credits.csv) and [`coral-credits.csv`](coral-credits.csv); please keep those files and the in-app attribution if you reuse the images.

The photo-fetching scripts in [`tools/`](tools/) were used to source and record the images. They are development utilities and are not part of the shipped app.

---

## Running the app

Requirements: Flutter with Dart SDK `^3.13.5` (see `pubspec.yaml`).

```bash
flutter pub get
flutter run
```

To run on a device or emulator, pick a target with `flutter devices` and then `flutter run -d <device>`.

### Platform notes

- **Android:** fine location permission is already declared in `android/app/src/main/AndroidManifest.xml`.
- **iOS:** device location requires adding `NSLocationWhenInUseUsageDescription` to `ios/Runner/Info.plist`. Without it, location search and manual spot selection still work.

### Tests

```bash
flutter test
```

The test suite covers the activity-rating rules (including night behaviour), conditions parsing, dashboard night/day states, species metadata, photo attribution, and widget fallbacks.

---

## Under the hood

- **Flutter + Material 3**, with a sea-blue seeded theme and light/dark support.
- **`flutter_bloc`** for app state: location, weather, marine data, loading/errors, and refresh handling.
- **Open-Meteo** for weather, marine, and geocoding APIs; **Overpass** for nearby beaches.
- **`fl_chart`** for the tide, wave, and wind charts.
- **`shared_preferences`** for remembering your last location.
- **`geolocator`** for device location.
- Bundled JSON species data and local image assets, with an emoji fallback when a photo is missing or fails to load.

```
lib/
├── app_bloc.dart          # app-wide state and data loading
├── data/                  # species repository and region filtering
├── models/                # weather, marine, species, ratings, UV
├── screens/               # dashboard, tides, spots, fish/coral, detail
├── services/              # Open-Meteo, Overpass, tides, location
├── utils/                 # geo helpers
└── widgets/               # cards, charts, tiles, compass, species images
assets/
├── data/                  # fish.json and coral.json
└── images/                # licensed species photos
```

---

## What's next

Ideas I would like to add as the app grows:

- A personal log of dives and sightings, so spots and species stick without relying on memory.
- Offline tide snapshots for trips with no signal.
- Locally curated spot notes: entry points, hazards, best state of tide.
- More species, more regions, and seasonal "what you might see now" hints.

Built after a year of fins, salt, and forgetting things — so the next year is spent looking at the reef instead of trying to remember it.
