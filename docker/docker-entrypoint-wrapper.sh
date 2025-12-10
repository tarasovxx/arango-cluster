#!/bin/sh
set -e

# Support for Docker Secrets
# Read secret files and export them as environment variables

# NOTE: In Cluster mode, ArangoDB requires one of the following for initialization:
# ARANGO_ROOT_PASSWORD, ARANGO_ROOT_PASSWORD_FILE, ARANGO_NO_AUTH, or ARANGO_RANDOM_ROOT_PASSWORD
# 
# For cluster mode (COORDINATOR/DBSERVER roles), we use ARANGO_RANDOM_ROOT_PASSWORD
# to allow initialization while keeping JWT authentication enabled.
# This is safe because:
# 1. We enable --server.authentication=true explicitly in command args.
# 2. We use JWT secrets for cluster communication.
# 3. The random root password is only used for initialization; JWT is used for actual authentication.
# 4. In cluster mode, coordinators/dbservers don't need persistent root password.

# Check if we're running in cluster mode by checking command arguments
IS_CLUSTER_MODE=false
for arg in "$@"; do
  case "$arg" in
    *--cluster.my-role*|*--agency*)
      IS_CLUSTER_MODE=true
      break
      ;;
  esac
done

# Load root password from Docker Secret (if available)
if [ -f /run/secrets/arango_root_password ]; then
  # In cluster mode, use random password to avoid initialization issues with tmpfs
  # The root password is not critical for cluster nodes as they use JWT
  if [ "$IS_CLUSTER_MODE" = "true" ]; then
    export ARANGO_RANDOM_ROOT_PASSWORD=1
    echo "INFO: Cluster mode detected - using ARANGO_RANDOM_ROOT_PASSWORD (JWT authentication enabled)"
  else
    export ARANGO_ROOT_PASSWORD_FILE=/run/secrets/arango_root_password
    echo "INFO: ARANGO_ROOT_PASSWORD_FILE set from Docker Secret"
  fi
# If no root password secret is provided, use random password for initialization
# This allows the database to initialize while keeping JWT authentication enabled
elif [ -z "$ARANGO_ROOT_PASSWORD" ] && [ -z "$ARANGO_ROOT_PASSWORD_FILE" ] && [ -z "$ARANGO_NO_AUTH" ] && [ -z "$ARANGO_RANDOM_ROOT_PASSWORD" ]; then
  export ARANGO_RANDOM_ROOT_PASSWORD=1
  echo "INFO: Using ARANGO_RANDOM_ROOT_PASSWORD for initialization (JWT authentication will be enabled)"
fi

# Load JWT secret from Docker Secret
if [ -f /run/secrets/arango_jwt ]; then
  export ARANGO_JWT_SECRET=$(tr -d '\n\r' < /run/secrets/arango_jwt)
  echo "INFO: ARANGO_JWT_SECRET loaded from Docker Secret"
fi

exec /entrypoint.sh "$@"
