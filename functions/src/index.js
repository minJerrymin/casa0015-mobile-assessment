const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const API_FOOTBALL_KEY = defineSecret("API_FOOTBALL_KEY");

const API_BASE_URL = "https://v3.football.api-sports.io/fixtures";
const CACHE_DOC = "matchpint_cache/fixtures_next_3_days_v095";
const CACHE_TTL_MS = 20 * 60 * 1000;
const REGION = "europe-west2";

const COMPETITIONS = [
  { id: 39, name: "Premier League", weight: 90 },
  { id: 2, name: "UEFA Champions League", weight: 98 },
  { id: 3, name: "UEFA Europa League", weight: 92 },
];

function londonDateString(date) {
  // API-Football accepts YYYY-MM-DD. We use UTC dates for predictable backend output.
  return date.toISOString().slice(0, 10);
}

function seasonStartYear(now = new Date()) {
  const month = now.getUTCMonth() + 1;
  const year = now.getUTCFullYear();
  return month >= 7 ? year : year - 1;
}

function addDays(date, days) {
  const out = new Date(date.getTime());
  out.setUTCDate(out.getUTCDate() + days);
  return out;
}

function normaliseTeamName(name) {
  return String(name || "")
    .replace(/ FC$/i, "")
    .replace(/ AFC$/i, "")
    .replace(/ WFC$/i, " Women")
    .trim();
}

function fixtureImportance(competition, homeTeam, awayTeam, baseWeight) {
  let score = baseWeight;
  const joined = `${competition} ${homeTeam} ${awayTeam}`.toLowerCase();
  const bigDraw = ["arsenal", "chelsea", "liverpool", "manchester city", "manchester united", "tottenham", "newcastle"];
  for (const team of bigDraw) {
    if (joined.includes(team)) score += 3;
  }
  return Math.max(0, Math.min(100, Math.round(score)));
}

function normaliseFixture(apiFixture, competition) {
  const fixture = apiFixture.fixture || {};
  const teams = apiFixture.teams || {};
  const venue = fixture.venue || {};
  const id = fixture.id ? `api_football_${fixture.id}` : "";
  const homeTeam = normaliseTeamName(teams.home && teams.home.name);
  const awayTeam = normaliseTeamName(teams.away && teams.away.name);
  const kickoff = fixture.date || "";
  if (!id || !homeTeam || !awayTeam || !kickoff) return null;

  return {
    id,
    apiFootballId: fixture.id,
    homeTeam,
    awayTeam,
    competition: competition.name,
    kickoff,
    venue: venue.name || "Venue TBC",
    importance: fixtureImportance(competition.name, homeTeam, awayTeam, competition.weight),
    status: fixture.status && fixture.status.long ? fixture.status.long : "Scheduled",
    sourceLeagueId: competition.id,
  };
}

async function fetchCompetitionFixtures({ competition, from, to, season, apiKey }) {
  const url = new URL(API_BASE_URL);
  url.searchParams.set("league", String(competition.id));
  url.searchParams.set("season", String(season));
  url.searchParams.set("from", from);
  url.searchParams.set("to", to);
  url.searchParams.set("timezone", "Europe/London");

  const response = await fetch(url, {
    headers: {
      "x-apisports-key": apiKey,
      "Accept": "application/json",
    },
  });

  if (!response.ok) {
    throw new Error(`${competition.name} API-Football HTTP ${response.status}`);
  }

  const json = await response.json();
  const raw = Array.isArray(json.response) ? json.response : [];
  return raw
    .map((item) => normaliseFixture(item, competition))
    .filter(Boolean);
}

async function readFreshCache() {
  const snap = await db.doc(CACHE_DOC).get();
  if (!snap.exists) return null;
  const data = snap.data();
  const generatedAtMs = data.generatedAtMs || 0;
  if (Date.now() - generatedAtMs > CACHE_TTL_MS) return null;
  return data.payload || null;
}

async function readAnyCache() {
  const snap = await db.doc(CACHE_DOC).get();
  if (!snap.exists) return null;
  const data = snap.data();
  return data.payload || null;
}

async function writeCache(payload) {
  await db.doc(CACHE_DOC).set({
    generatedAtMs: Date.now(),
    payload,
  }, { merge: true });
}

function isWithinRange(kickoff, from, to) {
  const time = new Date(kickoff).getTime();
  const start = new Date(`${from}T00:00:00Z`).getTime();
  const endExclusive = new Date(`${to}T23:59:59Z`).getTime();
  return Number.isFinite(time) && time >= start && time <= endExclusive;
}

function buildPayload({ fixtures, from, to, generatedAt, stale = false }) {
  const filtered = fixtures
    .filter((fixture) => isWithinRange(fixture.kickoff, from, to))
    .sort((a, b) => new Date(a.kickoff).getTime() - new Date(b.kickoff).getTime());
  const competitionCounts = {};
  for (const competition of COMPETITIONS) {
    competitionCounts[competition.name] = filtered.filter((fixture) => fixture.competition === competition.name).length;
  }
  return {
    source: stale ? "MatchPint Firebase backend cache" : "MatchPint Firebase backend + API-Football",
    rangeLabel: `${from} to ${to}`,
    from,
    to,
    generatedAt,
    stale,
    competitionCounts,
    fixtures: filtered,
  };
}

exports.getFixtures = onRequest(
  {
    region: REGION,
    secrets: [API_FOOTBALL_KEY],
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    try {
      const freshCache = await readFreshCache();
      if (freshCache) {
        res.set("Cache-Control", "public, max-age=300, s-maxage=300");
        res.status(200).json(freshCache);
        return;
      }

      const now = new Date();
      const from = londonDateString(now);
      const to = londonDateString(addDays(now, 3));
      const season = seasonStartYear(now);
      const apiKey = API_FOOTBALL_KEY.value();

      const batches = await Promise.all(
        COMPETITIONS.map((competition) => fetchCompetitionFixtures({ competition, from, to, season, apiKey }))
      );
      const fixtures = batches.flat();
      const payload = buildPayload({
        fixtures,
        from,
        to,
        generatedAt: new Date().toISOString(),
      });

      await writeCache(payload);
      res.set("Cache-Control", "public, max-age=300, s-maxage=300");
      res.status(200).json(payload);
    } catch (error) {
      const cached = await readAnyCache();
      if (cached) {
        res.status(200).json({
          ...cached,
          stale: true,
          source: "MatchPint Firebase backend cache",
          generatedAt: cached.generatedAt || new Date().toISOString(),
        });
        return;
      }
      res.status(503).json({
        source: "MatchPint Firebase backend",
        rangeLabel: "next 3 days",
        generatedAt: new Date().toISOString(),
        stale: true,
        competitionCounts: {},
        fixtures: [],
      });
    }
  }
);
