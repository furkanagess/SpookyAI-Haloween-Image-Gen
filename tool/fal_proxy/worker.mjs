// Minimal fal.ai proxy for SpookyAI (Cloudflare Worker, also runs on Node 20+).
//
// Why: an API key compiled into a mobile app can always be extracted. The app
// talks to this proxy instead; the real key lives only here as a secret.
//
// What it does
//  * forwards ONLY the model endpoints the app uses (allowlist);
//  * adds `Authorization: Key <FAL_KEY>` server-side;
//  * enforces cost guards no matter what the client sends: one image, no web
//    search, resolution capped at 2K (4K doubles the price);
//  * rejects oversized bodies, unknown paths/methods and malformed request ids;
//  * optional shared app token (X-App-Token), kill switch (DISABLED=1) and
//    Cloudflare rate limiting (RATE_LIMITER binding);
//  * rewrites status_url/response_url in responses so polling goes through
//    the proxy as well.
//
// What it does NOT do: identify real users. For that, put an auth layer in
// front (App Attest / Play Integrity, or accounts) and move the token ledger
// server-side. Until then use fal's spend limit and the kill switch as a
// safety net.

const FAL_QUEUE = 'https://queue.fal.run';

export const ALLOWED_MODELS = [
  'openai/gpt-image-2',
  'openai/gpt-image-2/edit',
  'minimax/h3-max-turbo/image-to-video',
];

const MAX_BODY_BYTES = 12 * 1024 * 1024; // image-to-image sends a base64 photo
const REQUEST_ID = /^[0-9a-fA-F-]{8,64}$/;

const json = (status, body) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });

/** Returns {model, rest} when `path` targets an allowed model, else null. */
export function route(path) {
  for (const model of ALLOWED_MODELS) {
    const base = `/${model}`;
    if (path === base) return { model, kind: 'submit' };
    const m = path.match(
      new RegExp(`^${base}/requests/([^/]+)(/status|/cancel)?$`),
    );
    if (m) {
      if (!REQUEST_ID.test(m[1])) return null;
      return { model, kind: m[2] ? m[2].slice(1) : 'result', id: m[1] };
    }
  }
  return null;
}

const GPT_SIZES = new Set([
  'square_hd', 'square', 'portrait_4_3', 'portrait_16_9',
  'landscape_4_3', 'landscape_16_9', 'auto',
]);

/** Server-side cost guards. Never trust the client. */
export function sanitizeBody(model, body) {
  const out = { ...body };
  out.num_images = 1;

  if (model === 'openai/gpt-image-2' || model === 'openai/gpt-image-2/edit') {
    // Text-to-image sends no photo; edit sends exactly one.
    if (model === 'openai/gpt-image-2/edit') {
      out.image_urls = Array.isArray(out.image_urls) ? out.image_urls.slice(0, 1) : [];
    } else {
      delete out.image_urls;
    }
    // Custom {width,height} sizes can reach 14142px: presets only. The app
    // uses the 512x512 `square` preset.
    if (typeof out.image_size !== 'string' || !GPT_SIZES.has(out.image_size)) {
      out.image_size = 'square';
    }
    // Medium at most: "high" costs about 4x.
    if (!['low', 'medium'].includes(out.quality)) out.quality = 'medium';
    // Safety stays on; masks, BYOK keys and relaxed screening are not allowed.
    out.enable_safety_checker = true;
    delete out.mask_url;
    delete out.mask_image_url;
    delete out.openai_api_key;
  }

  if (model === 'minimax/h3-max-turbo/image-to-video') {
    // Billed per second: cap length and resolution server-side.
    const d = Number(out.duration);
    out.duration = Number.isFinite(d) ? Math.min(Math.max(d, 2), 5) : 5;
    if (!['480P', '768P'].includes(out.resolution)) out.resolution = '768P';
    if (!['disabled', 'balanced'].includes(out.prompt_expansion_mode)) {
      out.prompt_expansion_mode = 'balanced';
    }
    // First frame only: no end frame, custom audio or base64 responses.
    out.enable_safety_checker = true;
    delete out.end_image_url;
    delete out.target_audio_url;
    delete out.sync_mode;
    delete out.num_images;
  }
  return out;
}

const METHOD_FOR = { submit: 'POST', result: 'GET', status: 'GET', cancel: 'PUT' };

/**
 * One free-token trial per device. The app sends a device id that survives
 * reinstalls (Android ANDROID_ID, iOS Keychain UUID); only a salted SHA-256 of
 * it is stored in the TRIALS KV namespace. Answers { granted: true } the first
 * time a device asks and { granted: false } afterwards.
 */
export async function claimTrial(request, env) {
  if (request.method !== 'POST') return json(405, { error: 'method_not_allowed' });
  if (!env.TRIALS) return json(501, { error: 'trials_not_configured' });
  let body;
  try {
    body = JSON.parse(await request.text());
  } catch {
    return json(400, { error: 'invalid_json' });
  }
  const id = body?.deviceId;
  const platform = body?.platform;
  if (typeof id !== 'string' || id.length < 8 || id.length > 128) {
    return json(400, { error: 'invalid_device' });
  }
  if (platform !== 'android' && platform !== 'ios') {
    return json(400, { error: 'invalid_platform' });
  }
  const data = new TextEncoder().encode(`${env.TRIAL_SALT ?? ''}:${platform}:${id}`);
  const digest = await crypto.subtle.digest('SHA-256', data);
  const key = 'trial:' + [...new Uint8Array(digest)]
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
  if (await env.TRIALS.get(key)) return json(200, { granted: false });
  await env.TRIALS.put(key, new Date().toISOString());
  return json(200, { granted: true });
}

export async function handle(request, env, fetchImpl = fetch) {
  if (env.DISABLED === '1') return json(503, { error: 'service_disabled' });

  if (env.APP_TOKEN && request.headers.get('x-app-token') !== env.APP_TOKEN) {
    return json(401, { error: 'unauthorized' });
  }

  const url = new URL(request.url);
  if (url.pathname === '/trial/claim') {
    if (env.RATE_LIMITER) {
      const ip = request.headers.get('cf-connecting-ip') ?? 'unknown';
      const { success } = await env.RATE_LIMITER.limit({ key: ip });
      if (!success) return json(429, { error: 'rate_limited' });
    }
    return claimTrial(request, env);
  }
  if (!env.FAL_KEY) return json(500, { error: 'proxy_not_configured' });
  const r = route(url.pathname);
  if (!r) return json(404, { error: 'not_found' });
  if (request.method !== METHOD_FOR[r.kind]) {
    return json(405, { error: 'method_not_allowed' });
  }

  if (env.RATE_LIMITER) {
    const ip = request.headers.get('cf-connecting-ip') ?? 'unknown';
    const { success } = await env.RATE_LIMITER.limit({ key: ip });
    if (!success) return json(429, { error: 'rate_limited' });
  }

  let body;
  if (r.kind === 'submit') {
    const len = Number(request.headers.get('content-length') ?? '0');
    if (len > MAX_BODY_BYTES) return json(413, { error: 'too_large' });
    const raw = await request.text();
    if (raw.length > MAX_BODY_BYTES) return json(413, { error: 'too_large' });
    let parsed;
    try {
      parsed = JSON.parse(raw);
    } catch {
      return json(400, { error: 'invalid_json' });
    }
    if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) {
      return json(400, { error: 'invalid_json' });
    }
    body = JSON.stringify(sanitizeBody(r.model, parsed));
  }

  const upstream = await fetchImpl(`${FAL_QUEUE}${url.pathname}`, {
    method: request.method,
    headers: {
      authorization: `Key ${env.FAL_KEY}`,
      'content-type': 'application/json',
      accept: 'application/json',
    },
    body,
  });

  const text = await upstream.text();
  const proxyOrigin = url.origin;
  return new Response(text.split(FAL_QUEUE).join(proxyOrigin), {
    status: upstream.status,
    headers: { 'content-type': upstream.headers.get('content-type') ?? 'application/json' },
  });
}

export default {
  fetch: (request, env) => handle(request, env),
};
