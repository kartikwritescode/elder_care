import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

// ============================================================================
// IN-MEMORY GOOGLE OAUTH CACHE (persists across warm Deno isolate invocations)
// ============================================================================
interface CachedOAuthToken {
  token: string;
  expiresAt: number; // epoch ms
}

let cachedOAuthToken: CachedOAuthToken | null = null;

function base64UrlEncode(input: string | Uint8Array): string {
  let bytes: Uint8Array;
  if (typeof input === "string") {
    bytes = new TextEncoder().encode(input);
  } else {
    bytes = input;
  }
  let binary = "";
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----[^\n]+-----/g, "")
    .replace(/\s+/g, "");
  const raw = atob(b64);
  const buf = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) {
    buf[i] = raw.charCodeAt(i);
  }
  return buf.buffer;
}

async function getGoogleOAuthToken(): Promise<{ accessToken: string; projectId: string }> {
  // Check warm cache with 60-second safety window
  if (cachedOAuthToken && Date.now() < cachedOAuthToken.expiresAt - 60000) {
    const projectId = Deno.env.get("FIREBASE_PROJECT_ID") || "eldercare-3db06";
    return { accessToken: cachedOAuthToken.token, projectId };
  }

  const serviceAccountRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  let serviceAccount: any = null;
  if (serviceAccountRaw) {
    try {
      serviceAccount = JSON.parse(serviceAccountRaw);
    } catch {
      // ignore parse error if formatted differently
    }
  }

  const clientEmail =
    serviceAccount?.client_email || Deno.env.get("FIREBASE_CLIENT_EMAIL");
  let privateKey =
    serviceAccount?.private_key || Deno.env.get("FIREBASE_PRIVATE_KEY");
  const projectId =
    serviceAccount?.project_id ||
    Deno.env.get("FIREBASE_PROJECT_ID") ||
    "eldercare-3db06";

  if (!clientEmail || !privateKey) {
    throw new Error(
      "Missing Firebase service account credentials (FIREBASE_SERVICE_ACCOUNT or FIREBASE_CLIENT_EMAIL/FIREBASE_PRIVATE_KEY)"
    );
  }

  privateKey = privateKey.replace(/\\n/g, "\n");

  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claimSet = {
    iss: clientEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedClaimSet = base64UrlEncode(JSON.stringify(claimSet));
  const signatureInput = `${encodedHeader}.${encodedClaimSet}`;

  const binaryKey = pemToArrayBuffer(privateKey);
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signatureBuffer = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(signatureInput)
  );

  const signature = base64UrlEncode(new Uint8Array(signatureBuffer));
  const jwt = `${signatureInput}.${signature}`;

  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!tokenResponse.ok) {
    const errText = await tokenResponse.text();
    throw new Error(`Google OAuth token request failed (${tokenResponse.status}): ${errText}`);
  }

  const tokenData = await tokenResponse.json();
  const expiresIn = tokenData.expires_in || 3600;

  cachedOAuthToken = {
    token: tokenData.access_token,
    expiresAt: Date.now() + expiresIn * 1000,
  };

  return { accessToken: cachedOAuthToken.token, projectId };
}

async function sendFcmMessage(
  accessToken: string,
  projectId: string,
  fcmToken: string,
  notification: { title: string; body: string },
  data: Record<string, string>
): Promise<Response> {
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  return await fetch(url, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: {
        token: fcmToken,
        notification,
        data,
        android: {
          priority: "high",
          notification: {
            channel_id: "alarm_channel",
            sound: "default",
          },
        },
      },
    }),
  });
}

function extractFcmToken(usersRelation: any): string | null {
  if (!usersRelation) return null;
  if (Array.isArray(usersRelation)) {
    return usersRelation[0]?.fcm_token || null;
  }
  return usersRelation.fcm_token || null;
}

// ============================================================================
// MAIN EDGE FUNCTION HANDLER
// ============================================================================
Deno.serve(async (req: Request) => {
  const startTime = performance.now();

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(
        JSON.stringify({ error: "Missing Supabase environment variables" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const now = new Date();
    const nowIso = now.toISOString();

    // 1. Query only necessary columns using composite partial index
    // SELECT id, title, users!receiver_id(fcm_token) FROM alarm_instances WHERE status = 'scheduled' AND scheduled_time <= now()
    const { data: scheduledAlarms, error: schedError } = await supabase
      .from("alarm_instances")
      .select("id, title, users!receiver_id(fcm_token)")
      .eq("status", "scheduled")
      .lte("scheduled_time", nowIso)
      .limit(100);

    if (schedError) {
      console.error("Error querying scheduled alarms:", schedError);
      throw schedError;
    }

    // 2. Query only necessary columns for missed alarms needing escalation (> 3 minutes without acknowledgment)
    // SELECT id, title, users!caregiver_id(fcm_token) FROM alarm_instances WHERE status = 'triggered' AND acknowledged_at IS NULL AND triggered_at <= threshold
    const escalationThreshold = new Date(now.getTime() - 3 * 60 * 1000).toISOString();
    const { data: missedAlarms, error: missError } = await supabase
      .from("alarm_instances")
      .select("id, title, users!caregiver_id(fcm_token)")
      .eq("status", "triggered")
      .is("acknowledged_at", null)
      .lte("triggered_at", escalationThreshold)
      .limit(100);

    if (missError) {
      console.error("Error querying missed alarms:", missError);
      throw missError;
    }

    const scheduledCount = scheduledAlarms?.length ?? 0;
    const missedCount = missedAlarms?.length ?? 0;

    // 3. Early Exit Optimization: If no alarms to process, exit in < 20ms WITHOUT requesting Google OAuth
    if (scheduledCount === 0 && missedCount === 0) {
      const elapsed = (performance.now() - startTime).toFixed(2);
      return new Response(
        JSON.stringify({
          success: true,
          idle: true,
          message: "No due or missed alarms to process",
          processedScheduled: 0,
          processedMissed: 0,
          durationMs: Number(elapsed),
        }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    console.log(`⏰ Found ${scheduledCount} due alarm(s) and ${missedCount} missed alarm(s).`);

    // 4. Batch Database Updates via .in('id', ids) to eliminate N+1 row-by-row updates
    const scheduledIds = scheduledAlarms?.map((a: any) => a.id) ?? [];
    if (scheduledIds.length > 0) {
      const { error: updateSchedError } = await supabase
        .from("alarm_instances")
        .update({
          status: "triggered",
          triggered_at: nowIso,
          updated_at: nowIso,
        })
        .in("id", scheduledIds);

      if (updateSchedError) {
        console.error("Error batch updating scheduled alarms:", updateSchedError);
      }
    }

    const missedIds = missedAlarms?.map((a: any) => a.id) ?? [];
    if (missedIds.length > 0) {
      const { error: updateMissError } = await supabase
        .from("alarm_instances")
        .update({
          status: "missed",
          escalated_at: nowIso,
          updated_at: nowIso,
        })
        .in("id", missedIds);

      if (updateMissError) {
        console.error("Error batch updating missed alarms:", updateMissError);
      }
    }

    // 5. Get Google OAuth token (warm cache or exchange once)
    const { accessToken, projectId } = await getGoogleOAuthToken();

    // 6. Dispatch FCM notifications concurrently using Promise.allSettled
    const fcmPromises: Promise<any>[] = [];

    if (scheduledAlarms) {
      for (const alarm of scheduledAlarms) {
        const token = extractFcmToken((alarm as any).users);
        if (token) {
          fcmPromises.push(
            sendFcmMessage(
              accessToken,
              projectId,
              token,
              {
                title: "Alarm Triggered",
                body: (alarm as any).title || "Your scheduled alarm is ringing!",
              },
              {
                type: "alarm_trigger",
                alarm_id: String(alarm.id),
                title: (alarm as any).title || "Alarm",
              }
            )
          );
        }
      }
    }

    if (missedAlarms) {
      for (const alarm of missedAlarms) {
        const token = extractFcmToken((alarm as any).users);
        if (token) {
          fcmPromises.push(
            sendFcmMessage(
              accessToken,
              projectId,
              token,
              {
                title: "Missed Alarm Alert!",
                body: `The care receiver did not acknowledge alarm: ${(alarm as any).title || "Scheduled Alarm"}`,
              },
              {
                type: "alarm_missed",
                alarm_id: String(alarm.id),
                title: (alarm as any).title || "Alarm",
              }
            )
          );
        }
      }
    }

    const results = await Promise.allSettled(fcmPromises);
    const sentCount = results.filter((r) => r.status === "fulfilled").length;
    const failedCount = results.filter((r) => r.status === "rejected").length;

    const elapsed = (performance.now() - startTime).toFixed(2);
    console.log(`✅ Processed in ${elapsed}ms: ${sentCount} sent, ${failedCount} failed.`);

    return new Response(
      JSON.stringify({
        success: true,
        idle: false,
        processedScheduled: scheduledCount,
        processedMissed: missedCount,
        notificationsSent: sentCount,
        notificationsFailed: failedCount,
        durationMs: Number(elapsed),
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    const elapsed = (performance.now() - startTime).toFixed(2);
    console.error("❌ Exception in trigger-alarms Edge Function:", err);

    return new Response(
      JSON.stringify({
        success: false,
        error: err.message || String(err),
        durationMs: Number(elapsed),
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
