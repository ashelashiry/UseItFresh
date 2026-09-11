// recognise-food — calling Gemini, and choosing a model that still exists.
//
// One of five files. The Supabase dashboard editor stops a paste at about
// 20,000 characters, so the function is split into files that each stay well
// under that. index.ts is the entry point; the rest are imported by it.

import { reply } from "./shared.ts";

export const API = "https://generativelanguage.googleapis.com/v1beta";

// Google retires model names on its own schedule (gemini-2.0-flash went in
// June 2026) and a retired name answers 404. So nothing here is pinned to a
// version: the alias is tried first, and if that is gone too, the key is asked
// which Flash models it can use and the newest stable one is taken.
export const PREFERRED = ["gemini-flash-latest"];
let discovered = ""; // kept while this instance stays warm
export function version(name: string): number[] {
  const m = name.match(/^gemini-([\d.]+)-/);
  return m ? m[1].split(".").map(Number) : [0];
}

export function newerFirst(a: string, b: string): number {
  const va = version(a), vb = version(b);
  for (let i = 0; i < Math.max(va.length, vb.length); i++) {
    const d = (vb[i] ?? 0) - (va[i] ?? 0);
    if (d !== 0) return d;
  }
  // Same version: full Flash before Flash-Lite.
  return Number(a.endsWith("-lite")) - Number(b.endsWith("-lite"));
}

// The newest stable Flash model this key can call. Stable means a plain
// "gemini-<version>-flash" or "-flash-lite" name: no preview, experimental,
// dated, image, audio or live variants.
export async function discoverModel(key: string): Promise<string> {
  const res = await fetch(`${API}/models?pageSize=1000`, {
    headers: { "x-goog-api-key": key },
  });
  if (!res.ok) return "";
  const { models = [] } = await res.json();
  const usable = (models as { name?: string; supportedGenerationMethods?: string[] }[])
    .filter((m) => (m.supportedGenerationMethods ?? []).includes("generateContent"))
    .map((m) => String(m.name ?? "").replace(/^models\//, ""))
    .filter((n) => /^gemini-[\d.]+-flash(-lite)?$/.test(n))
    .sort(newerFirst);
  return usable[0] ?? "";
}

export async function generate(model: string, key: string, body: string) {
  return await fetch(`${API}/models/${model}:generateContent`, {
    method: "POST",
    // Header, not query string, so the key never lands in a URL log.
    headers: { "Content-Type": "application/json", "x-goog-api-key": key },
    body,
  });
}

export async function callGemini(key: string, body: string) {
  const tried: string[] = [];
  let res: Response | null = null;
  for (const model of [discovered, ...PREFERRED]) {
    if (!model || tried.includes(model)) continue;
    tried.push(model);
    res = await generate(model, key, body);
    if (res.status !== 404) return { res, model };
  }
  const found = await discoverModel(key);
  if (found && !tried.includes(found)) {
    res = await generate(found, key, body);
    if (res.ok) discovered = found;
    return { res, model: found };
  }
  return { res, model: tried.join(",") };
}

// A Gemini call that did not work, said in words the app can show.
export async function failed(
  res: Response | null,
  model: string,
  said: { sorry: string; unavailable: string; busy: string },
): Promise<Response> {
  const status = res?.status ?? 0;
  // Google's own message, never the key: it is sent in a header and error
  // bodies do not echo it. `detail` is for diagnosis; the app shows `error`.
  let why = "";
  try {
    why = String((await res?.json())?.error?.message ?? "").slice(0, 200);
  } catch { /* not JSON */ }
  console.error("gemini", model, status, why);
  // A 429 is two different things. Too many calls at once passes in a
  // minute; an account with no credit left does not, and telling someone to
  // "try again in a minute" then is a promise the app cannot keep.
  const unfunded = status === 429 && /credit|billing|prepay/i.test(why);
  return reply({
    error: unfunded ? said.unavailable : status === 429 ? said.busy : said.sorry,
    detail: `gemini ${status} ${model}: ${why}`,
  }, 502);
}

// The answer's text. Thinking models may return thought parts first.
export function answer(data: unknown): string {
  const parts = ((data as { candidates?: { content?: { parts?: unknown[] } }[] })
    ?.candidates?.[0]?.content?.parts ?? []) as { text?: string; thought?: boolean }[];
  return parts.filter((p) => !p.thought).map((p) => p.text ?? "").join("");
}
