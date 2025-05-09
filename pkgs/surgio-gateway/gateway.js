'use strict';

const gateway = require('@surgio/gateway');
const addr = process.argv[process.argv.length - 2];
const port = process.argv[process.argv.length - 1];

(async () => {
  const app = await gateway.bootstrapServer();

  await app.listen(port, addr);
  console.log(`> Your app is ready at http://${addr}:${port}`);
})();

