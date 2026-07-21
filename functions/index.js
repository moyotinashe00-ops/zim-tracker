/**
 * Volt AI backend proxy.
 *
 * All Gemini calls that used to run on-device in AIService now run here.
 * The API key lives only in Secret Manager (GEMINI_API_KEY) and is never
 * shipped to the Flutter client. Every function requires a signed-in
 * Firebase user (request.auth), matching the app's existing auth gate.
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const logger = require("firebase-functions/logger");

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

// Same tiered fallback order as the original client-side service.
const MODEL_TIERS = ["gemini-3.5-flash", "gemini-3.1-pro", "gemini-3.1-flash-lite"];

function requireAuth(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required to use Volt AI.");
  }
}

/**
 * Runs `prompt` against the model tiers in order, stepping down on any
 * failure (503/quota/not-found/empty-response) until one succeeds or the
 * tiers are exhausted.
 */
async function executeWithResilience(genAI, { prompt, jsonMode = false, parse }, depth = 0) {
  if (depth >= MODEL_TIERS.length) {
    throw new HttpsError("unavailable", "All Volt AI model tiers exhausted.");
  }

  const modelName = MODEL_TIERS[depth];

  try {
    const model = genAI.getGenerativeModel({
      model: modelName,
      ...(jsonMode ? { generationConfig: { responseMimeType: "application/json" } } : {}),
    });

    const result = await model.generateContent(prompt);
    const text = result.response.text();
    const parsed = parse(text);

    if (parsed === null || parsed === undefined) {
      throw new Error("Empty or unparseable response");
    }
    return parsed;
  } catch (e) {
    logger.warn(`Volt AI: model "${modelName}" failed (${e.message}). Falling back.`);
    return executeWithResilience(genAI, { prompt, jsonMode, parse }, depth + 1);
  }
}

function extractJson(text) {
  if (!text) return null;
  let sanitized = text.replace(/```json/g, "").replace(/```/g, "").trim();

  const start = sanitized.indexOf("{");
  if (start === -1) return null;

  let depth = 0;
  let end = -1;
  for (let i = start; i < sanitized.length; i++) {
    if (sanitized[i] === "{") depth++;
    if (sanitized[i] === "}") {
      depth--;
      if (depth === 0) {
        end = i;
        break;
      }
    }
  }
  if (end === -1) end = sanitized.lastIndexOf("}");
  if (end === -1 || end <= start) return null;

  try {
    return JSON.parse(sanitized.substring(start, end + 1));
  } catch (e) {
    logger.warn(`Volt AI: JSON parse failed: ${e.message}`);
    return null;
  }
}

const CALLABLE_OPTS = { secrets: [GEMINI_API_KEY], region: "us-central1" };

// ---------------------------------------------------------------------------
// 1. Parse a raw ZETDC load-shedding notice into structured zone/schedule JSON
// ---------------------------------------------------------------------------
exports.parseZetdcNotice = onCall(CALLABLE_OPTS, async (request) => {
  requireAuth(request);
  const text = request.data?.text;
  if (!text || typeof text !== "string") {
    throw new HttpsError("invalid-argument", "Notice text is required.");
  }

  const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
  const prompt = `Return ONLY a JSON object representing the ZETDC load shedding notice.
DO NOT include conversational text or markdown.

Schema:
{
  "zones": [
    {
      "name": "Suburb Name",
      "suburbCode": "Code",
      "schedule": [
        {"day": "MONDAY", "slots": [{"startTime": "06:00", "endTime": "10:00", "type": "OFF"}]}
      ]
    }
  ]
}

Notice Text:
${text}`;

  const data = await executeWithResilience(genAI, { prompt, jsonMode: true, parse: extractJson });
  return { data };
});

// ---------------------------------------------------------------------------
// 2. Predictive 1-sentence grid stability forecast
// ---------------------------------------------------------------------------
exports.getGridForecast = onCall(CALLABLE_OPTS, async (request) => {
  requireAuth(request);
  const { generation, demand, stage } = request.data || {};
  if (typeof generation !== "number" || typeof demand !== "number" || !stage) {
    throw new HttpsError("invalid-argument", "generation, demand (numbers) and stage are required.");
  }

  const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
  const prompt = `Given current generation of ${generation}MW against a demand of ${demand}MW at Stage ${stage}, provide a 1-sentence grid stability forecast for a Zimbabwean user.`;

  const forecast = await executeWithResilience(genAI, {
    prompt,
    jsonMode: false,
    parse: (t) => t || "Stability expected to remain consistent with current schedule.",
  }).catch(() => "Forecast telemetry currently unavailable.");

  return { forecast };
});

// ---------------------------------------------------------------------------
// 3. National grid strategic summary (Atlas screen)
// ---------------------------------------------------------------------------
exports.getMapIntelligenceSummary = onCall(CALLABLE_OPTS, async (request) => {
  requireAuth(request);
  const zones = request.data?.zones;
  if (!Array.isArray(zones)) {
    throw new HttpsError("invalid-argument", "A zones array is required.");
  }

  const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
  const offZones = zones
    .filter((z) => z.status === "OFF")
    .map((z) => z.name)
    .join(", ");
  const prompt = `Analyze these Zimbabwean suburbs currently without power: ${offZones}. Provide a 1-sentence strategic summary of the national grid health and where the primary deficits are concentrated.`;

  const summary = await executeWithResilience(genAI, {
    prompt,
    jsonMode: false,
    parse: (t) => t || "Grid stability holding across most nodes.",
  }).catch(() => "National grid intelligence currently normalizing.");

  return { summary };
});

// ---------------------------------------------------------------------------
// 4. National sweep: infer ON/OFF for every registered zone at once
// ---------------------------------------------------------------------------
exports.performNationalIntelligenceSweep = onCall(CALLABLE_OPTS, async (request) => {
  requireAuth(request);
  const zones = request.data?.zones;
  if (!Array.isArray(zones) || zones.length === 0) {
    throw new HttpsError("invalid-argument", "A non-empty zones array is required.");
  }

  const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
  const nodeInfo = zones.map((z) => `ID: ${z.id}, Name: ${z.name}`).join("\n");
  const prompt = `Current Zimbabwe Time: ${new Date().toISOString()}.
Given the current generation deficit, analyze these specific grid nodes:
${nodeInfo}

Identify which are MOST LIKELY to be experiencing load shedding (OFF) vs active supply (ON).
Return ONLY a JSON list mapping the provided IDs to their status.

Format: {"nodes": [{"id": "node_id_from_list", "status": "ON"}]}`;

  const validIds = new Set(zones.map((z) => z.id));

  const data = await executeWithResilience(genAI, {
    prompt,
    jsonMode: true,
    parse: extractJson,
  }).catch(() => null);

  const nodes = data?.nodes || [];
  const results = {};
  for (const n of nodes) {
    if (n?.id && validIds.has(n.id)) {
      results[n.id] = n.status === "ON" ? "ON" : "OFF";
    }
  }

  return { results };
});

// ---------------------------------------------------------------------------
// 5. Infer ON/OFF for a single lat/lng (used when registering a new zone)
// ---------------------------------------------------------------------------
exports.inferStatusForCoordinate = onCall(CALLABLE_OPTS, async (request) => {
  requireAuth(request);
  const { lat, lng } = request.data || {};
  if (typeof lat !== "number" || typeof lng !== "number") {
    throw new HttpsError("invalid-argument", "lat and lng (numbers) are required.");
  }

  const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
  const prompt = `Given a specific location in Zimbabwe at coordinates (${lat}, ${lng}), infer if it is currently LIKELY to have power given typical load shedding patterns. Return ONLY "ON" or "OFF".`;

  const status = await executeWithResilience(genAI, {
    prompt,
    jsonMode: false,
    parse: (t) => {
      const trimmed = t?.trim();
      return trimmed === "ON" || trimmed === "OFF" ? trimmed : "ON";
    },
  }).catch(() => "ON");

  return { status };
});
