// recognise-food — suggest a name and category for a food photograph.
//
// Deploy with "Verify JWT with legacy secret" OFF. This project signs user
// sessions with the new ES256 keys, which that legacy check rejects, while it
// ACCEPTS the anon key — and the anon key ships inside the app. So the gateway
// check would block every real user and let in anyone who unpacks the app.
// Instead the caller is checked here, against the auth server, which accepts
// real sessions of either kind and gives the anon key no user at all.
//
// The Gemini key lives in Supabase as the GEMINI_API_KEY secret and never
// leaves the server.
//
// What it may say is deliberately narrow: a name and a category, as a
// suggestion. Never freshness, safety, spoilage or a date, even when one is
// visible. Not food gets "That does not look like food", not an invented item.

import { createClient } from "jsr:@supabase/supabase-js@2";

// Models are tried in order; a retired model name answers 404 and the next
// one is used, so a deprecation does not take the feature down.
const MODELS = ["gemini-2.5-flash", "gemini-2.0-flash"];

const CATEGORIES = [
  "dairy", "meat_poultry", "seafood", "eggs", "cooked_leftovers", "fruit",
  "vegetables", "bread_bakery", "pantry_dry", "frozen", "condiments_sauces",
  "infant_food",
];

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const PROMPT = `You are helping someone log the food in their kitchen.
Look at the photo and name the single main food item in plain everyday words,
for example "Cheddar cheese", "Semi-skimmed milk", "Spinach", "Chicken thighs".
Include a brand only if it is clearly legible and is what people call it.
Choose the closest category from the list, or "unknown" if none fits.
Do NOT judge freshness, safety, spoilage or ripeness, and do NOT read or
estimate any date, even if one is visible.
If the photo is not of food, set isFood to false.`;

function reply(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

function toBase64(bytes: Uint8Array): string {
  let bin = "";
  for (let i = 0; i < bytes.length; i += 0x8000) {
    bin += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  }
  return btoa(bin);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  const base = Deno.env.get("SUPABASE_URL") ?? "";
  const publicKey = Deno.env.get("SUPABASE_ANON_KEY") ??
    Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ?? "";

  // A signed-in person, checked with the auth server — not merely a token that
  // parses. The anon key is a valid JWT but belongs to no user, so it stops here.
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return reply({ error: "Sign in to name photos." }, 401);
  }
  const supabase = createClient(base, publicKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData } = await supabase.auth.getUser();
  if (!userData?.user) {
    return reply({ error: "Sign in to name photos." }, 401);
  }

  const key = Deno.env.get("GEMINI_API_KEY");
  if (!key) return reply({ error: "Photo naming is not set up yet." }, 503);

  let imageUrl = "";
  try {
    ({ imageUrl } = await req.json());
  } catch {
    return reply({ error: "No photo was sent." }, 400);
  }

  // Signed links into the private food-images bucket only. Anything else —
  // another site, or the public avatars bucket — would turn this into a way
  // to spend the key on pictures that are not someone's food.
  if (!imageUrl ||
      !String(imageUrl).startsWith(`${base}/storage/v1/object/sign/food-images/`)) {
    return reply({ error: "That photo is not from this app." }, 400);
  }

  const img = await fetch(imageUrl);
  if (!img.ok) return reply({ error: "Could not read the photo." }, 400);
  const bytes = new Uint8Array(await img.arrayBuffer());
  if (bytes.length > 6_000_000) {
    return reply({ error: "That photo is too large." }, 413);
  }
  const mime = img.headers.get("content-type") ?? "image/jpeg";

  const body = JSON.stringify({
    contents: [{
      parts: [
        { text: PROMPT },
        { inline_data: { mime_type: mime, data: toBase64(bytes) } },
      ],
    }],
    generationConfig: {
      temperature: 0.1,
      responseMimeType: "application/json",
      responseSchema: {
        type: "OBJECT",
        properties: {
          name: { type: "STRING" },
          category: { type: "STRING", enum: [...CATEGORIES, "unknown"] },
          isFood: { type: "BOOLEAN" },
        },
        required: ["name", "category", "isFood"],
      },
    },
  });

  let res: Response | null = null;
  for (const model of MODELS) {
    res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
      {
        method: "POST",
        // Header, not query string, so the key never lands in a URL log.
        headers: { "Content-Type": "application/json", "x-goog-api-key": key },
        body,
      },
    );
    if (res.status !== 404) break;
  }

  if (!res || !res.ok) {
    const status = res?.status ?? 0;
    console.error("gemini", status, (await res?.text())?.slice(0, 300));
    return reply({
      error: status === 429
        ? "Too many photos just now. Try again in a minute."
        : "Could not name that photo. You can type it instead.",
    }, 502);
  }

  const data = await res.json();
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
  let out: { name?: string; category?: string; isFood?: boolean };
  try {
    out = JSON.parse(text);
  } catch {
    return reply({ error: "Could not name that photo. You can type it instead." }, 502);
  }

  if (out.isFood === false) {
    return reply({ name: "", category: "", note: "That does not look like food." });
  }
  const name = String(out.name ?? "").trim().slice(0, 60);
  const category = CATEGORIES.includes(String(out.category))
    ? String(out.category)
    : "";
  return reply({ name, category, note: "" });
});
