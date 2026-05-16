const http = require('http');
const https = require('https');

const targetOrigin = 'https://minifoot.76.13.53.119.nip.io';
const port = Number(process.env.PORT || 3001);

const server = http.createServer((clientReq, clientRes) => {
  const targetUrl = new URL(clientReq.url, targetOrigin);

  const headers = { ...clientReq.headers };
  headers.host = targetUrl.host;

  const proxyReq = https.request(
    targetUrl,
    {
      method: clientReq.method,
      headers,
    },
    (proxyRes) => {
      clientRes.writeHead(proxyRes.statusCode || 502, proxyRes.headers);
      proxyRes.pipe(clientRes);
    },
  );

  proxyReq.on('error', (error) => {
    console.error(`[proxy] ${clientReq.method} ${clientReq.url}: ${error.message}`);
    if (!clientRes.headersSent) {
      clientRes.writeHead(502, { 'content-type': 'application/json' });
    }
    clientRes.end(JSON.stringify({ message: 'Backend proxy unavailable' }));
  });

  clientReq.pipe(proxyReq);
});

server.listen(port, '127.0.0.1', () => {
  console.log(`[proxy] http://127.0.0.1:${port} -> ${targetOrigin}`);
});
