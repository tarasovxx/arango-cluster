#!/bin/bash
# Generate self-signed TLS certificate for Traefik

CERT_DIR="/vagrant/traefik/certs"
mkdir -p "$CERT_DIR"

# Generate certificate valid for localhost and private IPs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$CERT_DIR/traefik.key" \
    -out "$CERT_DIR/traefik.crt" \
    -subj "/C=RU/ST=Moscow/L=Moscow/O=ArangoDB/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,DNS:*.localhost,IP:127.0.0.1,IP:192.168.56.11,IP:192.168.56.12,IP:192.168.56.13,IP:10.0.0.1"

chmod 644 "$CERT_DIR/traefik.crt"
chmod 600 "$CERT_DIR/traefik.key"

echo "Certificate generated:"
echo "  Certificate: $CERT_DIR/traefik.crt"
echo "  Private Key: $CERT_DIR/traefik.key"
echo ""
echo "Valid for: localhost, 192.168.56.11-13"

