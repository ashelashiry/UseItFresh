library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';
// setPageRoute is the documented way to change a page's route, but it is not
// re-exported from the barrel (only findPage/findComponent are). Reaching into
// src/ is the workaround; the alternative -- poking routePath on
// ensurePageRouteSettings() -- skips route normalisation and is explicitly
// warned against.
// ignore: implementation_imports
import 'package:flutterflow_ai/src/helpers/routing_helpers.dart';
// ignore: implementation_imports
import 'package:flutterflow_ai/src/helpers/project_helpers.dart' show setInitialPage;

import 'package:ff_agent_useitfresh_fridge_wise_gvpy0s/flutterflow_project.dart'
    as ff;


Future<void> main(List<String> args) async {
  final options = _parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildStarterEditFlow,
      apiKey: options.apiKey,
      baseUrl: options.baseUrl,
      projectName: options.projectName,
      projectId: options.projectId,
      findOrCreate: options.findOrCreate,
      allowNewProject: options.allowNewProject,
      dryRun: options.dryRun,
      commitMessage: options.commitMessage,
    );
  } catch (error) {
    stderr.writeln('Error: ${formatFlutterFlowAIError(error)}');
    exit(1);
  }
}

final class _CliOptions {
  const _CliOptions({
    this.apiKey,
    this.baseUrl,
    this.projectName,
    this.projectId,
    this.findOrCreate = false,
    this.allowNewProject = false,
    this.dryRun = false,
    this.commitMessage,
  });

  final String? apiKey;
  final String? baseUrl;
  final String? projectName;
  final String? projectId;
  final bool findOrCreate;
  final bool allowNewProject;
  final bool dryRun;
  final String? commitMessage;
}

_CliOptions _parseCliOptions(List<String> args) {
  String? apiKey;
  String? baseUrl;
  String? projectName;
  String? projectId;
  String? commitMessage;
  var findOrCreate = false;
  var allowNewProject = false;
  var dryRun = false;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    switch (arg) {
      case '--help':
      case '-h':
        _printUsage();
        exit(0);
      case '--api-key':
        apiKey = _requireValue(args, ++i, '--api-key');
      case '--base-url':
        baseUrl = _requireValue(args, ++i, '--base-url');
      case '--project-name':
        projectName = _requireValue(args, ++i, '--project-name');
      case '--project-id':
        projectId = _requireValue(args, ++i, '--project-id');
      case '--commit-message':
        commitMessage = _requireValue(args, ++i, '--commit-message');
      case '--find-or-create':
        findOrCreate = true;
      case '--allow-new-project':
        allowNewProject = true;
      case '--dry-run':
        dryRun = true;
      default:
        stderr.writeln('Unknown option: $arg');
        _printUsage();
        exit(64);
    }
  }

  return _CliOptions(
    apiKey: apiKey,
    baseUrl: baseUrl,
    projectName: projectName,
    projectId: projectId,
    findOrCreate: findOrCreate,
    allowNewProject: allowNewProject,
    dryRun: dryRun,
    commitMessage: commitMessage,
  );
}

String _requireValue(List<String> args, int index, String flag) {
  if (index >= args.length) {
    stderr.writeln('Missing value for $flag.');
    _printUsage();
    exit(64);
  }
  return args[index];
}

void _printUsage() {
  stdout.writeln('''
Run the starter FlutterFlow AI edit flow.

Usage:
  dart run dsl/edit.dart [options]

Options:
  --api-key <key>           FlutterFlow API key. Defaults to FF_API_KEY.
  --base-url <url>          Override the FlutterFlow API base URL.
  --project-name <name>     Create a new project with this name.
  --project-id <id>         Push into an existing project by ID.
  --find-or-create          Retry by reusing a same-name project before creating.
  --allow-new-project       Bypass the workspace binding guard and create a different project.
  --commit-message <text>   Commit message for the push.
  --dry-run                 Compile and validate without pushing.
  --help, -h                Show this help.
''');
}

// ---------------------------------------------------------------------------
// Home: the feature panel from the design pack.
//
// The panel component was built days ago and never placed. The pack puts it
// directly under the greeting, above "Use first" — a graphite block that gives
// the screen a centre of gravity instead of a list starting at the top.
//
// Its supporting line counts the real items rather than repeating the pack's
// example copy. A hero that says "3 items to check first today" when there are
// none is worse than no hero: it is the first thing anyone reads, and being
// wrong there costs more trust than the panel buys in polish.
// ---------------------------------------------------------------------------

/// Point the Receipt and Fridge photo tiles at the review screen.
///
/// Until now both said "arrives in Phase 3". Each takes one photo, has it
/// read, and opens the review list. Closing the camera says nothing, because
/// changing your mind is not an error; anything else that stops it says why.
void buildStarterEditFlow(App app) {
  final scan = ff.Pages.scanAddPage;

  List<DslAction> readThenReview(String mode, String tag) => [
        CallCustomAction.named(
          'ReadPhotoFoods',
          args: {'mode': string},
          returnType: string,
          arguments: {'mode': mode},
          outputAs: 'read$tag',
        ),
        If(
          Equals(ActionOutput('read$tag'), 'ok'),
          then: [Navigate(ff.Pages.scanReviewPage)],
          orElse: [
            If(
              Not(Equals(ActionOutput('read$tag'), '')),
              then: [Snackbar(ActionOutput('read$tag'))],
            ),
          ],
        ),
      ];

  app.editPage(scan, (page) {
    page.ensureActions(
      scan.widgets.byKey('Container_g7jwjr0v').single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: readThenReview('receipt', 'Receipt'),
    );
    page.ensureActions(
      scan.widgets.byKey('Container_u78daphn').single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: readThenReview('shelf', 'Shelf'),
    );
  });

  // FlutterFlow's copy of the function, kept the same as the deployed one.
  // FlutterFlow declares edge functions but does not deploy them: the live
  // code is whatever was last deployed from the Supabase editor. This copy
  // only stops a later deploy from FlutterFlow putting the old code back.
  app.supabaseEdgeFunction(
    name: 'recognise-food',
    description:
        'Reads food from a photo in this project storage: one item, a '
        'receipt, or a fridge shelf. Never judges freshness, safety or dates.',
    verifyJwt: false,
    enableCors: true,
    code: r'''
// recognise-food — read food from a photograph.
//
// Three kinds of photo, chosen by `mode` in the request body:
//   "item"    (default) one food → { name, category, note }
//   "receipt" a till receipt     → { items: [{ name, category, quantity }], note }
//   "shelf"   a fridge shelf or cupboard → { items: [...], note }
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

import { createClient } from "jsr:@supabase/supabase-js@2";

const API = "https://generativelanguage.googleapis.com/v1beta";

// Google retires model names on its own schedule (gemini-2.0-flash went in
// June 2026) and a retired name answers 404. So nothing here is pinned to a
// version: the alias is tried first, and if that is gone too, the key is asked
// which Flash models it can use and the newest stable one is taken.
const PREFERRED = ["gemini-flash-latest"];
let discovered = ""; // kept while this instance stays warm

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

const NEVER = `Do NOT judge freshness, safety, spoilage or ripeness. Do NOT read
or estimate any date, even if one is visible. Do NOT include prices.`;

const ITEM_PROMPT = `You are helping someone log the food in their kitchen.
Look at the photo and name the single main food item in plain everyday words,
for example "Cheddar cheese", "Semi-skimmed milk", "Spinach", "Chicken thighs".
Include a brand only if it is clearly legible and is what people call it.
Choose the closest category from the list, or "unknown" if none fits.
${NEVER}
If the photo is not of food, set isFood to false.`;

const RECEIPT_PROMPT = `This is a photo of a shopping receipt. List every FOOD
or DRINK item that was bought, so it can be added to a kitchen inventory.
Skip bags, cleaning products, toiletries, medicine, household goods, offers,
discounts, subtotals, totals and payment lines.
Shops abbreviate: write each item as a plain everyday name, for example
"SEMI SKMD MLK 4PT" becomes "Semi-skimmed milk" and "TSC BRST FLLT" becomes
"Chicken breast fillets". Keep a brand only when it is what people call it.
If one product appears on several lines, list it once and add the quantities.
quantity is the number of units bought; use 1 when it is not shown.
Choose the closest category from the list, or "unknown" if none fits.
If you cannot read a line well enough to name it, leave it out rather than guess.
${NEVER}
If the photo is not a receipt, set isReceipt to false and return no items.`;

const SHELF_PROMPT = `This is a photo of a fridge shelf, a cupboard or a
worktop. List each distinct food item you can clearly see, so it can be added
to a kitchen inventory. Name each in plain everyday words; include a brand only
when it is clearly legible. quantity is how many of that item you can see.
List only what is actually visible. Do not guess what is inside an opaque or
unlabelled container — leave it out.
Choose the closest category from the list, or "unknown" if none fits.
${NEVER}
If there is no food in the photo, return no items.`;

const CATEGORY = { type: "STRING", enum: [...CATEGORIES, "unknown"] };

const ITEM_SCHEMA = {
  type: "OBJECT",
  properties: {
    name: { type: "STRING" },
    category: CATEGORY,
    isFood: { type: "BOOLEAN" },
  },
  required: ["name", "category", "isFood"],
};

const LIST_ITEMS = {
  type: "ARRAY",
  items: {
    type: "OBJECT",
    properties: {
      name: { type: "STRING" },
      category: CATEGORY,
      quantity: { type: "INTEGER" },
    },
    required: ["name", "category", "quantity"],
  },
};

const RECEIPT_SCHEMA = {
  type: "OBJECT",
  properties: { isReceipt: { type: "BOOLEAN" }, items: LIST_ITEMS },
  required: ["isReceipt", "items"],
};

const SHELF_SCHEMA = {
  type: "OBJECT",
  properties: { items: LIST_ITEMS },
  required: ["items"],
};

const SORRY = {
  item: "Could not name that photo. You can type it instead.",
  receipt: "Could not read that receipt. Try a flatter, brighter photo.",
  shelf: "Could not read that photo. Try again closer up.",
};

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

function version(name: string): number[] {
  const m = name.match(/^gemini-([\d.]+)-/);
  return m ? m[1].split(".").map(Number) : [0];
}

function newerFirst(a: string, b: string): number {
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
async function discoverModel(key: string): Promise<string> {
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

async function generate(model: string, key: string, body: string) {
  return await fetch(`${API}/models/${model}:generateContent`, {
    method: "POST",
    // Header, not query string, so the key never lands in a URL log.
    headers: { "Content-Type": "application/json", "x-goog-api-key": key },
    body,
  });
}

async function callGemini(key: string, body: string) {
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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  const base = Deno.env.get("SUPABASE_URL") ?? "";
  const publicKey = Deno.env.get("SUPABASE_ANON_KEY") ??
    Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ?? "";

  // A signed-in person, checked with the auth server — not merely a token that
  // parses. The anon key is a valid JWT but belongs to no user, so it stops here.
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return reply({ error: "Sign in to read photos." }, 401);
  }
  const supabase = createClient(base, publicKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData } = await supabase.auth.getUser();
  if (!userData?.user) {
    return reply({ error: "Sign in to read photos." }, 401);
  }

  const key = Deno.env.get("GEMINI_API_KEY");
  if (!key) return reply({ error: "Photo reading is not set up yet." }, 503);

  let imageUrl = "";
  let mode = "item";
  try {
    const input = await req.json();
    imageUrl = String(input?.imageUrl ?? "");
    if (input?.mode === "receipt" || input?.mode === "shelf") mode = input.mode;
  } catch {
    return reply({ error: "No photo was sent." }, 400);
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

  if (!res || !res.ok) {
    const status = res?.status ?? 0;
    // Google's own message, never the key: it is sent in a header and error
    // bodies do not echo it. `detail` is for diagnosis; the app shows `error`.
    let why = "";
    try {
      why = String((await res?.json())?.error?.message ?? "").slice(0, 200);
    } catch { /* not JSON */ }
    console.error("gemini", model, status, why);
    return reply({
      error: status === 429 ? "Too many photos just now. Try again in a minute." : sorry,
      detail: `gemini ${status} ${model}: ${why}`,
    }, 502);
  }

  const data = await res.json();
  // Thinking models may return thought parts first; the answer is the rest.
  const parts = (data?.candidates?.[0]?.content?.parts ?? []) as {
    text?: string;
    thought?: boolean;
  }[];
  const text = parts.filter((p) => !p.thought).map((p) => p.text ?? "").join("");
  let out: {
    name?: string;
    category?: string;
    isFood?: boolean;
    isReceipt?: boolean;
    items?: { name?: string; category?: string; quantity?: number }[];
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
    }))
    .filter((i) => i.name)
    .slice(0, 40);
  const none = mode === "receipt"
    ? "No food found on that receipt."
    : "No food I could name in that photo.";
  return reply({ items, note: items.length ? "" : none, model });
});
''',
  );
}
