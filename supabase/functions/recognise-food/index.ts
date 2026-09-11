// recognise-food — read food from a photograph, and suggest what to make.
//
// Four jobs, chosen by `mode` in the request body:
//   "item"    (default) one food → { name, category, note }
//   "receipt" a till receipt     → { items: [{ name, category, quantity }], note }
//   "shelf"   a fridge shelf or cupboard → { items: [...], note }
//   "ideas"   meal ideas from the household's own food, no photo
//             → { ideas: [{ title, uses, extras, steps, minutes, servings, soon }], note }
//             optional choices: meal, minutes, servings, leaveOut
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
// What it may say is deliberately narrow: names, categories and counts, as
// suggestions. Never freshness, safety, spoilage, a price or a date, even when
// one is visible. Nothing is saved from here — the person confirms first.
//
// Five files, because the Supabase editor stops a paste at about 20,000
// characters: index.ts (this file), shared.ts, prompts.ts, gemini.ts,
// ideas.ts. Paste each into its own file in the editor.

import { createClient } from "jsr:@supabase/supabase-js@2";
import {
  CATEGORIES,
  CORS,
  KINDS,
  outline,
  PHOTO_WORDS,
  readChoices,
  reply,
  SORRY,
  toBase64,
} from "./shared.ts";
import {
  ITEM_PROMPT,
  ITEM_SCHEMA,
  RECEIPT_PROMPT,
  RECEIPT_SCHEMA,
  SHELF_PROMPT,
  SHELF_SCHEMA,
} from "./prompts.ts";
import { answer, callGemini, failed } from "./gemini.ts";
import { ideas } from "./ideas.ts";


Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  const base = Deno.env.get("SUPABASE_URL") ?? "";
  const publicKey = Deno.env.get("SUPABASE_ANON_KEY") ??
    Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ?? "";

  // A signed-in person, checked with the auth server — not merely a token that
  // parses. The anon key is a valid JWT but belongs to no user, so it stops here.
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return reply({ error: "Sign in first." }, 401);
  }
  const supabase = createClient(base, publicKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData } = await supabase.auth.getUser();
  if (!userData?.user) {
    return reply({ error: "Sign in first." }, 401);
  }

  const key = Deno.env.get("GEMINI_API_KEY");
  if (!key) return reply({ error: "This is not set up yet." }, 503);

  let input: Record<string, unknown> = {};
  try {
    const raw = await req.json();
    if (raw && typeof raw === "object") input = raw as Record<string, unknown>;
  } catch {
    return reply({ error: "Nothing was sent." }, 400);
  }
  const imageUrl = String(input.imageUrl ?? "");
  const householdId = String(input.householdId ?? "");
  const mode = ["receipt", "shelf", "ideas"].includes(String(input.mode))
    ? String(input.mode) : "item";

  if (mode === "ideas") {
    return await ideas(supabase, key, householdId, readChoices(input));
  }

  const sorry = SORRY[mode as keyof typeof SORRY];

  // Signed links into the private food-images bucket only. Anything else —
  // another site, or the public avatars bucket — would turn this into a way
  // to spend the key on pictures that are not someone's food.
  if (!imageUrl.startsWith(`${base}/storage/v1/object/sign/food-images/`)) {
    return reply({ error: "That photo is not from this app." }, 400);
  }

  const img = await fetch(imageUrl);
  if (!img.ok) return reply({ error: "Could not read the photo." }, 400);
  const bytes = new Uint8Array(await img.arrayBuffer());
  if (bytes.length > 8_000_000) {
    return reply({ error: "That photo is too large." }, 413);
  }
  const mime = img.headers.get("content-type") ?? "image/jpeg";

  const prompt = mode === "receipt" ? RECEIPT_PROMPT
    : mode === "shelf" ? SHELF_PROMPT : ITEM_PROMPT;
  const schema = mode === "receipt" ? RECEIPT_SCHEMA
    : mode === "shelf" ? SHELF_SCHEMA : ITEM_SCHEMA;

  const body = JSON.stringify({
    contents: [{
      parts: [
        { text: prompt },
        { inline_data: { mime_type: mime, data: toBase64(bytes) } },
      ],
    }],
    generationConfig: {
      temperature: 0.1,
      responseMimeType: "application/json",
      responseSchema: schema,
    },
  });

  const { res, model } = await callGemini(key, body);

  if (!res || !res.ok) return await failed(res, model, { sorry, ...PHOTO_WORDS });

  const text = answer(await res.json());
  let out: {
    name?: string;
    category?: string;
    isFood?: boolean;
    isReceipt?: boolean;
    items?: {
      name?: string;
      category?: string;
      quantity?: number;
      kind?: string;
      box_2d?: number[];
    }[];
  };
  try {
    out = JSON.parse(text);
  } catch {
    console.error("unparsed", model, text.slice(0, 200));
    return reply({ error: sorry, detail: `unparsed ${model}` }, 502);
  }

  const clean = (c: unknown) =>
    CATEGORIES.includes(String(c)) ? String(c) : "";

  if (mode === "item") {
    if (out.isFood === false) {
      return reply({ name: "", category: "", note: "That does not look like food." });
    }
    const name = String(out.name ?? "").trim().slice(0, 60);
    return reply({ name, category: clean(out.category), note: "", model });
  }

  if (mode === "receipt" && out.isReceipt === false) {
    return reply({ items: [], note: "That does not look like a receipt." });
  }
  const items = (out.items ?? [])
    .map((i) => ({
      name: String(i.name ?? "").trim().slice(0, 60),
      category: clean(i.category),
      quantity: Math.min(Math.max(Math.round(Number(i.quantity) || 1), 1), 24),
      // Shelf photos only: what it comes in, and where it is on the photo.
      ...(mode === "shelf" ? { kind: KINDS.includes(String(i.kind)) ? String(i.kind) : "",
        box: outline(i.box_2d) } : {}),
    }))
    .filter((i) => i.name)
    .slice(0, 40);
  const none = mode === "receipt"
    ? "No food found on that receipt."
    : "No food I could name in that photo.";
  return reply({ items, note: items.length ? "" : none, model });
});
