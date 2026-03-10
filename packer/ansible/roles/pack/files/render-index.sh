#!/bin/bash
set -e
CONFIG=/etc/default/nginx-app
OUT=/usr/share/nginx/html/index.html
if [ -f "$CONFIG" ]; then
  source "$CONFIG"
fi
APP_NAME="${APP_NAME:-unknown}"
ENVIRONMENT="${ENVIRONMENT:-unknown}"
MESSAGE="${MESSAGE:-}"
HOSTNAME=$(hostname -f 2>/dev/null || hostname)
TIMESTAMP=$(date -Iseconds 2>/dev/null || date)
cat > "$OUT" <<PAGE
<!DOCTYPE html>
<html>
<head><title>${APP_NAME}</title></head>
<body>
  <h1>${APP_NAME}</h1>
  <p><strong>Environment:</strong> ${ENVIRONMENT}</p>
  <p><strong>Message:</strong> ${MESSAGE}</p>
  <p><strong>Hostname:</strong> ${HOSTNAME}</p>
  <p><strong>Launch time:</strong> ${TIMESTAMP}</p>
</body>
</html>
PAGE
