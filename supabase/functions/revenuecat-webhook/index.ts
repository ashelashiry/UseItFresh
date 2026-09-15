// revenuecat-webhook — keeps each account's Plus plan in step with App Store
// purchases (owner, 15 Sep: free and Plus; see docs/free_vs_plus.html).
//
// RevenueCat calls this for every purchase event. The app logs in to
// RevenueCat with the Supabase user id, so `app_user_id` is the profile id.
// The function writes profiles.plan / plan_source / plan_expires_at with the
// service role — the only way those columns can change (migration 10).
//
//   INITIAL_PURCHASE, RENEWAL, UNCANCELLATION, PRODUCT_CHANGE,
//   NON_RENEWING_PURCHASE, SUBSCRIPTION_EXTENDED,
//   TEMPORARY_ENTITLEMENT_GRANT            -> plus until expiration_at
//   CANCELLATION, BILLING_ISSUE,
//   SUBSCRIPTION_PAUSED                    -> still plus until expiration_at
//   EXPIRATION                             -> free (never for plan_source 'test')
//   TRANSFER                               -> moves Plus between accounts
//
// Only events that carry the "plus" entitlement change anything. Plus is
// shared by the household in the app, so nothing here touches households.
//
// Not deployed yet. When selling starts:
//   1. Supabase → Edge Functions → new function "revenuecat-webhook", paste this
//      file, and turn "Verify JWT" OFF (RevenueCat sends no Supabase session).
//   2. Supabase → Edge Functions → Secrets: REVENUECAT_WEBHOOK_AUTH = a long
//      random value (the owner makes it; never in this repository).
//   3. RevenueCat → Project → Integrations → Webhooks: URL
//      https://<project-ref>.supabase.co/functions/v1/revenuecat-webhook and
//      Authorization header = that same value.
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by Supabase.

import { createClient } from "jsr:@supabase/supabase-js@2";

const ENTITLEMENT = "plus";
const GRANTS = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "UNCANCELLATION",
  "PRODUCT_CHANGE",
  "NON_RENEWING_PURCHASE",
  "SUBSCRIPTION_EXTENDED",
  "TEMPORARY_ENTITLEMENT_GRANT",
]);
const KEEPS = new Set(["CANCELLATION", "BILLING_ISSUE", "SUBSCRIPTION_PAUSED"]);

type RcEvent = {
  type?: string;
  app_user_id?: string;
  original_app_user_id?: string;
  aliases?: string[];
  entitlement_ids?: string[] | null;
  entitlement_id?: string | null;
  expiration_at_ms?: number | null;
  store?: string;
  environment?: string;
  transferred_from?: string[];
  transferred_to?: string[];
};

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/** The Supabase profile ids an event is about (RevenueCat anonymous ids skipped). */
function profileIds(e: RcEvent): string[] {
  const all = [e.app_user_id, e.original_app_user_id, ...(e.aliases ?? [])];
  return [...new Set(all.filter((v): v is string => !!v && UUID.test(v)))];
}

function hasPlus(e: RcEvent): boolean {
  const ids = e.entitlement_ids ?? (e.entitlement_id ? [e.entitlement_id] : []);
  return ids.includes(ENTITLEMENT);
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json(405, { error: "POST only" });

  const secret = Deno.env.get("REVENUECAT_WEBHOOK_AUTH") ?? "";
  const given = req.headers.get("Authorization") ?? "";
  if (!secret || given !== secret && given !== `Bearer ${secret}`) {
    return json(401, { error: "unauthorised" });
  }

  let event: RcEvent;
  try {
    const body = await req.json();
    event = (body?.event ?? {}) as RcEvent;
  } catch {
    return json(400, { error: "not JSON" });
  }

  const type = event.type ?? "";
  if (type === "TEST") return json(200, { ok: true, note: "test event received" });

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );
  const source = (event.store ?? "app_store").toLowerCase() +
    (event.environment === "SANDBOX" ? "_sandbox" : "");
  const expires = event.expiration_at_ms
    ? new Date(event.expiration_at_ms).toISOString()
    : null;

  async function grant(ids: string[]) {
    if (ids.length === 0) return;
    const { error } = await admin
      .from("profiles")
      .update({ plan: "plus", plan_source: source, plan_expires_at: expires })
      .in("id", ids);
    if (error) throw error;
  }

  async function end(ids: string[]) {
    if (ids.length === 0) return;
    const { error } = await admin
      .from("profiles")
      .update({ plan: "free", plan_source: null, plan_expires_at: null })
      .in("id", ids)
      .or("plan_source.is.null,plan_source.neq.test");
    if (error) throw error;
  }

  try {
    if (type === "TRANSFER") {
      const from = (event.transferred_from ?? []).filter((v) => UUID.test(v));
      const to = (event.transferred_to ?? []).filter((v) => UUID.test(v));
      await end(from);
      await grant(to);
      return json(200, { ok: true, type, from: from.length, to: to.length });
    }

    if (!hasPlus(event)) return json(200, { ok: true, ignored: type });
    const ids = profileIds(event);
    if (ids.length === 0) return json(200, { ok: true, ignored: "no profile id" });

    if (GRANTS.has(type) || KEEPS.has(type)) {
      await grant(ids);
    } else if (type === "EXPIRATION") {
      await end(ids);
    } else {
      return json(200, { ok: true, ignored: type });
    }
    return json(200, { ok: true, type, accounts: ids.length });
  } catch (error) {
    console.error("revenuecat-webhook", type, error);
    // 500 makes RevenueCat retry later.
    return json(500, { error: "could not update the plan" });
  }
});
