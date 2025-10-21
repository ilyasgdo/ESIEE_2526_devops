#!/usr/bin/env bash

set -xe

yum update -y

curl -fsSL https://rpm.nodesource.com/setup_21.x | bash -
yum install -y nodejs

cat > /home/ec2-user/app.js << 'EOF'
const http = require('http');

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Hello, World!\n');
});

const port = process.env.PORT || 80;
server.listen(port,() => {
  console.log(`Listening on port ${port}`);
});
EOF

nohup node /home/ec2-user/app.js &