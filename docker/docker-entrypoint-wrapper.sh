#!/bin/sh
set -e

# Support for Docker Secrets
# Read secret files and export them as environment variables

# NOTE: In Cluster mode, ARANGO_ROOT_PASSWORD environment variable causes the 
# official entrypoint to attempt initialization which hangs or fails on COORDINATORS/DBSERVERS.
# HOWEVER, Agents need to pass the initial check or use ARANGO_NO_AUTH for the very first start.

# Since we handle authentication via JWT and post-init password setting:
# We export ARANGO_NO_AUTH=1 to bypass the "password option is not specified" error.
# This is safe because:
# 1. We enable --server.authentication=true explicitly in command args.
# 2. We use JWT secrets for cluster communication.
# 3. We set the root password via API immediately after startup.

export ARANGO_NO_AUTH=1

# Load JWT secret from Docker Secret
if [ -f /run/secrets/arango_jwt ]; then
  export ARANGO_JWT_SECRET=$(tr -d '\n\r' < /run/secrets/arango_jwt)
  echo "INFO: ARANGO_JWT_SECRET loaded from Docker Secret"
fi

exec /entrypoint.sh "$@"
