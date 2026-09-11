// recognise-food — the pieces every part uses.
//
// One of five files. The Supabase dashboard editor stops a paste at about
// 20,000 characters, so the function is split into files that each stay well
// under that. index.ts is the entry point; the rest are imported by it.

export const CATEGORIES = [
  "dairy", "meat_poultry", "seafood", "eggs", "cooked_leftovers", "fruit",
  "vegetables", "bread_bakery", "pantry_dry", "frozen", "condiments_sauces",
  "infant_food",
];

export const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
export const KINDS = ["carton", "jar", "bottle", "can", "tub", "box", "bag",
  "packet", "tray", "bowl", "loose"];

export const SORRY = {
  item: "Could not name that photo. You can type it instead.",
  receipt: "Could not read that receipt. Try a flatter, brighter photo.",
  shelf: "Could not read that photo. Try again closer up.",
};

export const PHOTO_WORDS = {
  unavailable: "Photo reading is not available right now. You can type it instead.",
  busy: "Too many photos just now. Try again in a minute.",
};

export const IDEAS_WORDS = {
  sorry: "Could not come up with ideas just now. Try again in a minute.",
  unavailable: "Ideas are not available right now.",
  busy: "Too many requests just now. Try again in a minute.",
};

// What the ideas are built from. Anything past its date, or already used or
// thrown out, is left out: an idea is never built around food the app has
// told someone to check or throw away.
export const LEAVE_OUT = ["past_use_by", "past_best_before", "consumed", "discarded"];
export const SOON = ["use_today", "use_soon"];

// The choices the Recipes screen offers. Anything else is treated as "any".
export const MEALS = ["breakfast", "lunch", "dinner", "snack"];
export const TIMES = [15, 30, 60];

export type Choices = {
  meal: string; // "" for any
  minutes: number; // 0 for any
  servings: number;
  leaveOut: string[]; // stems, lower case
};

// Which copy of this file is deployed. Every reply carries it, the signed-out
// one included, so a single unauthenticated call says whether a paste landed:
//   curl -s -X POST <project>/functions/v1/recognise-food
// Raise it with every change: date, then a count for that day.
export const VERSION = "2026-09-12.2";

export function reply(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify({ ...body, version: VERSION }), {
    status,
    headers: {
      ...CORS,
      "Content-Type": "application/json",
      "x-function-version": VERSION,
    },
  });
}

export function toBase64(bytes: Uint8Array): string {
  let bin = "";
  for (let i = 0; i < bytes.length; i += 0x8000) {
    bin += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  }
  return btoa(bin);
}

// [ymin, xmin, ymax, xmax] on 0-1000, or "" when the model's outline is not
// four numbers in order. Sent as one string so the app can store it simply.
export function outline(b: unknown): string {
  if (!Array.isArray(b) || b.length !== 4) return "";
  const [y0, x0, y1, x1] = b.map((v) => Math.min(Math.max(Math.round(Number(v)), 0), 1000));
  if ([y0, x0, y1, x1].some((v) => Number.isNaN(v)) || y1 <= y0 || x1 <= x0) return "";
  return `${y0},${x0},${y1},${x1}`;
}

// Trimmed, non-empty strings from a model's list, each kept short.
export function words(v: unknown, max: number, len = 60): string[] {
  if (!Array.isArray(v)) return [];
  return v.map((w) => String(w ?? "").trim().slice(0, len)).filter(Boolean)
    .slice(0, max);
}

// "eggs" also catches "egg", and "tomatoes" also "tomato". Matching is by
// containment, so it errs towards leaving more out, never less.
export function stem(w: string): string {
  if (w.length > 4 && w.endsWith("es")) return w.slice(0, -2);
  if (w.length > 3 && w.endsWith("s")) return w.slice(0, -1);
  return w;
}

export function mentionsAny(text: string, stems: string[]): boolean {
  const t = text.toLowerCase();
  return stems.some((s) => t.includes(s));
}

export function readChoices(input: Record<string, unknown>): Choices {
  const meal = MEALS.includes(String(input.meal)) ? String(input.meal) : "";
  const minutes = TIMES.includes(Number(input.minutes)) ? Number(input.minutes) : 0;
  const s = Math.round(Number(input.servings));
  const servings = Number.isFinite(s) && s >= 1 && s <= 8 ? s : 2;
  const leaveOut = String(input.leaveOut ?? "").split(/[,;\n]/)
    .map((w) => w.replace(/\s+/g, " ").trim().toLowerCase().slice(0, 40))
    .filter((w) => w.length >= 2)
    .slice(0, 10)
    .map(stem);
  return { meal, minutes, servings, leaveOut };
}
