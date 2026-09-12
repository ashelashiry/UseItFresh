// recognise-food — meal ideas from the food a household has.
//
// One of five files. The Supabase dashboard editor stops a paste at about
// 20,000 characters, so the function is split into files that each stay well
// under that. index.ts is the entry point; the rest are imported by it.

import { createClient } from "jsr:@supabase/supabase-js@2";

import {
  type Choices,
  IDEAS_WORDS,
  LEAVE_OUT,
  mentionsAny,
  reply,
  SOON,
  words,
} from "./shared.ts";
import { IDEAS_PROMPT, IDEAS_SCHEMA } from "./prompts.ts";
import { answer, callGemini, failed } from "./gemini.ts";

// Meal ideas from the food a household actually has, soonest-to-go first,
// shaped by the person's choices.
//
// The kitchen is read with the caller's own session, so row-level security
// decides what is visible: someone outside the household gets no rows and so
// the "add some food first" answer, never another household's food.
// Only names, a "use first" mark and the choices are sent to Gemini
// (spec §13.5). The choices are checked again on the answer, not trusted: an
// idea that uses a left-out food, or runs over the time, is dropped.
export async function ideas(
  supabase: ReturnType<typeof createClient>,
  key: string,
  householdId: string,
  choices: Choices,
): Promise<Response> {
  if (!/^[0-9a-f-]{36}$/i.test(householdId)) {
    return reply({ error: "No household yet. Create or join one first." }, 400);
  }
  const { data: rows, error } = await supabase
    .from("food_items_status")
    .select("name, computed_status, urgency_rank, days_left")
    .eq("household_id", householdId)
    .order("urgency_rank", { ascending: true })
    .order("days_left", { ascending: true, nullsFirst: false })
    .limit(200);
  if (error) {
    console.error("ideas read", error.message);
    return reply({ error: "Could not read your kitchen. Try again.", detail: error.message }, 502);
  }

  const foods: { name: string; soon: boolean }[] = [];
  const seen = new Set<string>();
  let usable = 0;
  for (const r of (rows ?? []) as { name?: string; computed_status?: string }[]) {
    if (LEAVE_OUT.includes(String(r.computed_status))) continue;
    const name = String(r.name ?? "").replace(/\s+/g, " ").trim().slice(0, 60);
    if (!name || seen.has(name.toLowerCase())) continue;
    seen.add(name.toLowerCase());
    usable++;
    if (mentionsAny(name, choices.leaveOut)) continue;
    foods.push({ name, soon: SOON.includes(String(r.computed_status)) });
    if (foods.length >= 60) break;
  }
  if (!foods.length) {
    return reply({
      ideas: [],
      note: usable
        ? "Everything in your kitchen is on your leave-out list."
        : "Add some food to your kitchen first, then ask again.",
    });
  }

  const people = `${choices.servings} ${choices.servings === 1 ? "person" : "people"}`;
  const wants = [
    choices.meal ? `Every idea must be a ${choices.meal} dish.` : "",
    choices.minutes ? `Every idea must take ${choices.minutes} minutes or less, start to finish.` : "",
    `Every idea serves ${people}: give amounts in the steps for that many.`,
    choices.kitchenOnly
      ? "Every idea must use only the food listed, plus salt, pepper, cooking oil and water: extras must be empty."
      : "",
  ].filter(Boolean).join("\n");
  const list = foods.map((f) => `- ${f.name}${f.soon ? " (use first)" : ""}`).join("\n");
  const avoid = choices.leaveOut.length
    ? `\n\nNever use any of these, not even as an extra:\n${choices.leaveOut.map((w) => `- ${w}`).join("\n")}`
    : "";
  const body = JSON.stringify({
    contents: [{ parts: [{ text: `${IDEAS_PROMPT}\n${wants}\n\nThe food:\n${list}${avoid}` }] }],
    generationConfig: {
      temperature: 0.8,
      responseMimeType: "application/json",
      responseSchema: IDEAS_SCHEMA,
    },
  });
  const { res, model } = await callGemini(key, body);
  if (!res || !res.ok) return await failed(res, model, IDEAS_WORDS);

  const text = answer(await res.json());
  let out: { ideas?: Record<string, unknown>[] };
  try {
    out = JSON.parse(text);
  } catch {
    console.error("unparsed", model, text.slice(0, 200));
    return reply({ error: IDEAS_WORDS.sorry, detail: `unparsed ${model}` }, 502);
  }

  // "From your kitchen" is checked, not trusted: a food the model says is
  // there but is not on the list is moved to what else it needs.
  const byName = new Map(foods.map((f) => [f.name.toLowerCase(), f]));
  const shaped = (out.ideas ?? []).map((i) => {
    const uses: string[] = [];
    const extras: string[] = [];
    for (const u of words(i.uses, 12)) {
      const f = byName.get(u.replace(/\s*\(use first\)\s*$/i, "").toLowerCase());
      if (f) {
        if (!uses.includes(f.name)) uses.push(f.name);
      } else if (!extras.some((e) => e.toLowerCase() === u.toLowerCase())) {
        extras.push(u);
      }
    }
    for (const e of words(i.extras, 12)) {
      if (byName.has(e.toLowerCase())) continue;
      if (!extras.some((x) => x.toLowerCase() === e.toLowerCase())) extras.push(e);
    }
    return {
      title: String(i.title ?? "").trim().slice(0, 80),
      uses,
      extras: extras.slice(0, 8),
      steps: words(i.steps, 6, 240),
      minutes: Math.min(Math.max(Math.round(Number(i.minutes) || 0), 0), 240),
      servings: choices.servings,
      soon: uses.some((n) => byName.get(n.toLowerCase())?.soon === true),
    };
  }).filter((i) => i.title && i.uses.length);

  const made = shaped
    .filter((i) =>
      !choices.leaveOut.length ||
      !mentionsAny([i.title, ...i.uses, ...i.extras, ...i.steps].join("\n"), choices.leaveOut)
    )
    .filter((i) => !choices.minutes || (i.minutes > 0 && i.minutes <= choices.minutes))
    // "Use my food" is checked, not trusted, like everything the model says.
    .filter((i) => !choices.kitchenOnly || i.extras.length === 0)
    .slice(0, 4);
  // Ideas that use up what goes off soonest come first; otherwise as given.
  made.sort((a, b) => Number(b.soon) - Number(a.soon));
  const note = made.length ? ""
    : shaped.length && choices.kitchenOnly
    ? "Nothing fits with only your food. Turn off Use my food to see ideas that need a few things."
    : shaped.length ? "No ideas fit those choices. Try a longer time, or leave out fewer foods."
    : IDEAS_WORDS.sorry;
  return reply({ ideas: made, note, model });
}
