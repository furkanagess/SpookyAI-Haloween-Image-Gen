import { test } from 'node:test';
import assert from 'node:assert/strict';
import { handle, route, sanitizeBody } from './worker.mjs';

const ENV = { FAL_KEY: 'real-fal-key', APP_TOKEN: 'tok' };
const ORIGIN = 'https://proxy.example.com';
const req = (path, init = {}) =>
  new Request(`${ORIGIN}${path}`, {
    ...init,
    headers: { 'x-app-token': 'tok', 'content-type': 'application/json', ...(init.headers ?? {}) },
  });

function recorder(reply = { status: 200, body: '{}' }) {
  const calls = [];
  const fn = async (url, init) => {
    calls.push({ url, init });
    return new Response(reply.body, { status: reply.status, headers: { 'content-type': 'application/json' } });
  };
  return { fn, calls };
}

test('route allowlist', () => {
  const id = 'a1b2c3d4-0000-1111-2222-333344445555';
  assert.equal(route('/openai/gpt-image-2').kind, 'submit');
  assert.equal(route(`/openai/gpt-image-2/requests/${id}/status`).kind, 'status');
  assert.equal(route(`/openai/gpt-image-2/requests/${id}`).kind, 'result');
  assert.equal(route(`/openai/gpt-image-2/requests/${id}/cancel`).kind, 'cancel');
  assert.equal(route('/openai/gpt-image-2/edit').kind, 'submit');
  assert.equal(route(`/openai/gpt-image-2/edit/requests/${id}/status`).kind, 'status');
  assert.equal(route('/fal-ai/nano-banana-pro'), null); // replaced
  assert.equal(route('/fal-ai/flux-pro/v1.1'), null); // not allowlisted
  assert.equal(route('/openai/gpt-image-2/requests/../../secret'), null);
  assert.equal(route('/openai/gpt-image-2/requests/a b/status'), null);
});

test('sanitizeBody enforces cost guards for both gpt-image-2 endpoints', () => {
  const dirty = {
    prompt: 'x', num_images: 5, quality: 'high',
    image_urls: ['data:a', 'data:b', 'data:c'],
    image_size: { width: 14000, height: 14000 },
    enable_safety_checker: false, mask_url: 'm', mask_image_url: 'm', openai_api_key: 'sk-x',
  };
  const edit = sanitizeBody('openai/gpt-image-2/edit', dirty);
  assert.equal(edit.num_images, 1);
  assert.deepEqual(edit.image_urls, ['data:a']);
  assert.equal(edit.image_size, 'square');
  assert.equal(edit.quality, 'medium'); // never "high"
  assert.equal(edit.enable_safety_checker, true);
  for (const k of ['mask_url', 'mask_image_url', 'openai_api_key']) assert.ok(!(k in edit), k);

  const t2i = sanitizeBody('openai/gpt-image-2', dirty);
  assert.equal(t2i.num_images, 1);
  assert.ok(!('image_urls' in t2i));
  assert.equal(t2i.image_size, 'square');
  assert.equal(t2i.quality, 'medium');
  assert.equal(t2i.enable_safety_checker, true);

  assert.equal(sanitizeBody('openai/gpt-image-2', { quality: 'low' }).quality, 'low');
  assert.equal(sanitizeBody('openai/gpt-image-2/edit', { image_size: 'square_hd' }).image_size, 'square_hd');
});

test('image-to-video is routed and its cost knobs are capped', () => {
  const m = 'minimax/h3-max-turbo/image-to-video';
  assert.equal(route(`/${m}`).kind, 'submit');
  const b = sanitizeBody(m, {
    prompt: 'x',
    duration: 15,
    resolution: '1080P',
    enable_safety_checker: false,
    end_image_url: 'https://e',
    target_audio_url: 'https://a',
    sync_mode: true,
  });
  assert.equal(b.duration, 5);
  assert.equal(b.resolution, '768P');
  assert.equal(b.enable_safety_checker, true);
  assert.equal(b.end_image_url, undefined);
  assert.equal(b.target_audio_url, undefined);
  assert.equal(b.sync_mode, undefined);
});

function memoryKv() {
  const m = new Map();
  return { get: async (k) => m.get(k) ?? null, put: async (k, v) => void m.set(k, v), m };
}
const claim = (body, headers) =>
  req('/trial/claim', { method: 'POST', body: JSON.stringify(body), headers });

test('trial is granted once per device and platform', async () => {
  const env = { ...ENV, TRIALS: memoryKv(), TRIAL_SALT: 's' };
  const dev = { deviceId: 'abcdef123456', platform: 'android' };
  assert.deepEqual(await (await handle(claim(dev), env)).json(), { granted: true });
  assert.deepEqual(await (await handle(claim(dev), env)).json(), { granted: false });
  const other = { deviceId: 'zzzzzz999999', platform: 'android' };
  assert.deepEqual(await (await handle(claim(other), env)).json(), { granted: true });
  // Only hashes are stored, never the raw id.
  for (const k of env.TRIALS.m.keys()) assert.ok(!k.includes('abcdef123456'));
});

test('trial claim validates input, auth and configuration', async () => {
  const env = { ...ENV, TRIALS: memoryKv() };
  assert.equal((await handle(claim({ deviceId: 'x', platform: 'ios' }), env)).status, 400);
  assert.equal((await handle(claim({ deviceId: 'abcdef123456', platform: 'web' }), env)).status, 400);
  assert.equal(
    (await handle(claim({ deviceId: 'abcdef123456', platform: 'ios' }, { 'x-app-token': 'bad' }), env)).status,
    401,
  );
  assert.equal(
    (await handle(claim({ deviceId: 'abcdef123456', platform: 'ios' }), { ...ENV })).status,
    501,
  );
  assert.equal((await handle(req('/trial/claim'), env)).status, 405);
});
