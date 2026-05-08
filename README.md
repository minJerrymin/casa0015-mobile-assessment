# MatchPint

**MatchPint** is an Android mobile app that helps football fans find the right pub for the right match.

Instead of starting with a generic list of pubs, MatchPint starts with the user's real match-day intention: *which game do I want to watch, and where should I go to watch it?* The app connects fixtures, nearby venues, map-based discovery, pub features, user preferences and community comments into one match-night planning experience.

- **Download APK:** <https://github.com/minJerrymin/casa0015-mobile-assessment/releases/latest>
- **Landing page:** <https://minjerrymin.github.io/casa0015-mobile-assessment/>
- **Source repository:** <https://github.com/minJerrymin/casa0015-mobile-assessment>

---

## The story behind MatchPint

Watching football in a pub is not only about finding a screen. It is about finding the right social setting.

A fan may want a loud pub for a derby, a calmer place to watch alone, a venue with food, or simply somewhere nearby that is likely to show the match. Existing search tools often treat pubs as static places, while the real decision is more situational: the same venue can feel different depending on the fixture, the crowd, the time and the user's mood.

MatchPint was designed around that moment of uncertainty before a match:

> "I know the game I want to watch, but I don't know where I should go."

The app turns this into a fixture-first mobile journey. Users begin with football matches, compare recommended pubs, check location and venue details, and save their own match-night experience afterwards.

---

## Who the app is for

MatchPint is aimed at football fans in London who want to plan a pub-based match night with more confidence.

It is especially useful for:

- fans looking for a pub that is likely to show a specific fixture;
- people watching alone who want a comfortable or calmer venue;
- groups comparing pubs by atmosphere, food, screens and distance;
- users planning ahead in another area of the city;
- students or visitors who do not already know the local football pub scene.

---

## How to install the app

MatchPint is distributed as an Android APK through GitHub Releases.

1. Open the latest release page:  
   <https://github.com/minJerrymin/casa0015-mobile-assessment/releases/latest>

2. Scroll to **Assets**.

3. Download the `.apk` file.

4. Open the APK on an Android phone.

5. If Android asks for permission, allow your browser or file manager to **install unknown apps**.

6. Complete installation and open **MatchPint**.

> Do not use **Code → Download ZIP** if you only want to install the app. That downloads the source code, not the Android installer.

---

## User guide

### 1. Create an account or sign in

Open the app and create a MatchPint account. The account system supports Firebase Authentication when the released APK is correctly configured.

After signing in, the app guides the user through onboarding and preference setup.

### 2. Set your match-night preferences

During onboarding, choose preferences that shape recommendations, such as:

- favourite team;
- calmer or louder atmosphere;
- solo-friendly viewing;
- food availability.

These preferences influence how pubs are ranked and presented.

### 3. Start with the match

The **Matches** page lets users browse football fixtures. Instead of choosing a pub first, users can start with the match they actually care about.

Selecting a match opens venue recommendations related to that fixture.

### 4. Compare recommended pubs

The **Pubs** page and recommendation cards help users compare possible venues by:

- location and area;
- distance;
- screen and atmosphere suitability;
- food and comfort signals;
- feature tags;
- match-related fit.

Users can refresh based on current location or choose another area manually.

### 5. Open a pub detail page

Each pub page brings together the information needed for a match-night decision:

- map location;
- pub feature tags;
- predicted match suitability;
- experience metrics;
- community comment summary;
- action to add the pub and fixture to a match night.

### 6. Use comments to improve venue evidence

Users can add a comment for a pub and match, including whether the pub is showing the game, screen quality, crowd level, noise, food rating and an optional note.

These reports contribute to a Firestore-backed venue summary when Firebase is available.

### 7. Sample the live atmosphere with the microphone

In **Match mode**, users can tap the microphone button to take a short live noise sample. MatchPint turns this into an estimated dB value so the user can record whether the pub atmosphere is calm, comfortable or loud.

The app uses this as a lightweight environmental sensing feature: it helps describe the real match-night atmosphere without saving raw audio.

### 8. Save a match-night experience

After choosing a pub and fixture, users can save a match-night record. This creates a lightweight "passport" of past football-watching experiences, including venue tags, notes and the latest dB estimate.

---

## Screenshots

The screenshots below show the submitted MatchPint prototype.

| Login / register | Onboarding | Home |
|---|---|---|
| ![Login and register screens](docs/screenshots/01-login-register.jpg) | ![Onboarding flow](docs/screenshots/02-onboarding.jpg) | ![Home screen](docs/screenshots/03-home.jpg) |

| Matches | Pub search | Pub detail |
|---|---|---|
| ![Matches screen](docs/screenshots/04-matches.jpg) | ![Pubs search screen](docs/screenshots/05-pubs-search.jpg) | ![Pub detail screen](docs/screenshots/06-pub-detail.jpg) |

| Map | Experience record | Settings |
|---|---|---|
| ![Map screen](docs/screenshots/07-map.jpg) | ![Experience record screen](docs/screenshots/08-experience-record.jpg) | ![Settings screen](docs/screenshots/09-settings.jpg) |

---

## Core features

### Fixture-first planning

The app begins with fixtures because the user's real goal is usually to watch a specific match. This makes the experience more purposeful than a generic venue list.

### Recommended pubs

MatchPint recommends pubs that are suitable for football viewing and presents them with compact, decision-friendly information.

### Location-aware search

The app can use the user's current location to search nearby pubs, while also allowing manual area selection for planning ahead.

### Pub detail and map support

The pub detail page combines venue information, feature tags and map location so users can move from browsing to action.

### Community comments

Users can submit match-specific venue comments. When Firebase is available, these comments update Firestore collections and feed into aggregated venue evidence.

### Match-night record

Users can save match-night experiences, giving the app a sense of continuity rather than being a one-off search tool.

### Live dB atmosphere sampling

MatchPint uses the phone microphone in Match mode to sample the venue atmosphere and estimate a live dB value. This supports the app's goal of describing not only where a pub is, but what it feels like during a match.

Raw audio is not saved; only the estimated noise level is used as part of the match-night record and venue feedback.

---

## Connected Environments concept

MatchPint treats the city as a connected match-day environment.

The app links digital match information with physical pub spaces, mobile location, maps, microphone-based atmosphere sensing, user preferences and community feedback. In this sense, the app is not only a pub directory. It is a small connected system that helps users interpret urban leisure spaces through the context of live football.

The project explores how mobile systems can support decisions that happen between online information and real-world social places.

---

## Data and functionality notes

- Firebase Authentication is used for account registration and login when the released APK is configured correctly.
- Firestore is used for venue comments and aggregated pub-match reports.
- The microphone is used in Match mode to estimate live noise level in dB; raw audio is not stored.
- Some app content uses fallback/mock data so the prototype remains usable even when live services are unavailable.
- Preferences and saved match-night records are stored locally on the device in this prototype.
- If the app is uninstalled, local-only preferences and saved records may be removed by Android.

---

## Technology overview

MatchPint was built with **Flutter** and **Dart** for Android.

Key technologies used in the prototype include:

| Area | Implementation |
|---|---|
| Mobile framework | Flutter / Dart |
| Authentication | Firebase Authentication |
| Cloud comments | Cloud Firestore |
| Live atmosphere sensing | Microphone sampling through the Record package |
| Local persistence | Shared Preferences |
| Location | Geolocator |
| Maps | Flutter Map and LatLong2 |
| External actions | URL Launcher |
| UI | Material components and custom app styling |

---

## Future improvements

With more development time, MatchPint could be improved through:

- stronger live fixture and venue data sources;
- verified pub-owner information about which matches are shown;
- richer community moderation for comments;
- cloud synchronisation for saved match-night history;
- better recommendation logic based on repeated user behaviour;
- accessibility testing across screen sizes and assistive technologies;
- push notifications for upcoming fixtures and saved match nights.

---


## GitHub Pages landing page

The landing page is published from the `docs/` folder through GitHub Pages.

URL: <https://minjerrymin.github.io/casa0015-mobile-assessment/>

---

## Author

**Tianrui Min**  
CASA0015: Mobile Systems and Interactions  
University College London

---

## Declaration

This repository contains the source code and supporting files for the CASA0015 final mobile application assessment. Third-party packages, APIs, documentation and external resources used in the project are acknowledged in `submission-file.md` and through the project dependency files.
