import { spawn } from 'node:child_process';
import { createHmac, timingSafeEqual } from 'node:crypto';
import { createServer } from 'node:http';

const LOG_PREFIX = '[git-webhook-deploy]';
const WEBHOOK_PORT = Number.parseInt(process.env.WEBHOOK_PORT ?? '5000', 10);
const WEBHOOK_PATH = normalizePath(process.env.WEBHOOK_PATH ?? '/webhook');
const REPO_BRANCH = process.env.REPO_BRANCH ?? 'main';
const WEBHOOK_SECRET = process.env.WEBHOOK_SECRET ?? '';
const DEPLOY_SCRIPT = '/scripts/deploy.sh';
const MAX_BODY_BYTES = 1024 * 1024;

function log(message) {
  console.log(`${LOG_PREFIX} ${message}`);
}

function normalizePath(pathValue) {
  const normalized = (pathValue || '/').trim();
  if (!normalized.startsWith('/')) {
    return `/${normalized}`;
  }
  if (normalized.length > 1 && normalized.endsWith('/')) {
    return normalized.slice(0, -1);
  }
  return normalized;
}

function verifyGithubSignature(rawBody, signatureHeader) {
  if (!WEBHOOK_SECRET) return false;
  if (!signatureHeader || !signatureHeader.startsWith('sha256=')) return false;

  const expected = `sha256=${createHmac('sha256', WEBHOOK_SECRET).update(rawBody).digest('hex')}`;
  const expectedBuffer = Buffer.from(expected, 'utf8');
  const signatureBuffer = Buffer.from(signatureHeader, 'utf8');

  if (expectedBuffer.length !== signatureBuffer.length) return false;

  return timingSafeEqual(expectedBuffer, signatureBuffer);
}

function triggerDeploy(commitSha = '') {
  log(`Triggering deploy${commitSha ? ` for commit ${commitSha}` : ''}...`);

  const child = spawn('/bin/sh', [DEPLOY_SCRIPT], {
    stdio: 'inherit',
    env: {
      ...process.env,
      DEPLOY_TRIGGER_SHA: commitSha,
    },
  });

  child.on('exit', (code) => {
    log(`Deploy process exited with code ${code ?? 'unknown'}.`);
  });

  child.on('error', (error) => {
    log(`Deploy process failed to start: ${error.message}`);
  });
}

const server = createServer((req, res) => {
  const requestPath = normalizePath(new URL(req.url ?? '/', 'http://localhost').pathname);

  if (req.method === 'GET' && requestPath === '/health') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('ok');
    return;
  }

  if (requestPath !== WEBHOOK_PATH) {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
    return;
  }

  if (req.method !== 'POST') {
    res.writeHead(405, { 'Content-Type': 'text/plain' });
    res.end('Method Not Allowed');
    return;
  }

  const chunks = [];
  let totalBytes = 0;

  req.on('data', (chunk) => {
    totalBytes += chunk.length;
    if (totalBytes > MAX_BODY_BYTES) {
      res.writeHead(413, { 'Content-Type': 'text/plain' });
      res.end('Payload Too Large');
      req.destroy();
      return;
    }
    chunks.push(chunk);
  });

  req.on('end', () => {
    const body = Buffer.concat(chunks);
    const signature = req.headers['x-hub-signature-256'];

    if (!verifyGithubSignature(body, typeof signature === 'string' ? signature : '')) {
      res.writeHead(401, { 'Content-Type': 'text/plain' });
      res.end('Unauthorized');
      return;
    }

    const event = req.headers['x-github-event'];

    if (event === 'ping') {
      log('Received GitHub ping event.');
      res.writeHead(200, { 'Content-Type': 'text/plain' });
      res.end('pong');
      return;
    }

    if (event !== 'push') {
      log(`Ignoring unsupported event type: ${String(event)}`);
      res.writeHead(202, { 'Content-Type': 'text/plain' });
      res.end('Ignored');
      return;
    }

    let payload;
    try {
      payload = JSON.parse(body.toString('utf8'));
    } catch {
      res.writeHead(400, { 'Content-Type': 'text/plain' });
      res.end('Invalid JSON');
      return;
    }

    const expectedRef = `refs/heads/${REPO_BRANCH}`;
    if (payload.ref !== expectedRef) {
      log(`Ignoring push for ${payload.ref}; waiting for ${expectedRef}.`);
      res.writeHead(202, { 'Content-Type': 'text/plain' });
      res.end('Ignored branch');
      return;
    }

    triggerDeploy(payload.after ?? '');

    res.writeHead(202, { 'Content-Type': 'text/plain' });
    res.end('Deploy triggered');
  });

  req.on('error', (error) => {
    log(`Webhook request error: ${error.message}`);
    if (!res.headersSent) {
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      res.end('Internal Server Error');
    }
  });
});

server.listen(WEBHOOK_PORT, '0.0.0.0', () => {
  log(`Webhook server listening on port ${WEBHOOK_PORT}, path ${WEBHOOK_PATH}`);
  log(`Watching GitHub push events for branch ${REPO_BRANCH}`);
});
