#!/usr/bin/env bash
# Verifica che apple-identity-provider e fitp-enricher siano caricati come SPI
# nel container Keycloak avviato da docker-compose.
#
# Uso:
#   ./scripts/verify-providers.sh
#
# Variabili (con default):
#   KC_URL           http://localhost:8080
#   KC_ADMIN_USER    admin
#   KC_ADMIN_PASSWORD admin
#   COMPOSE_SVC      keycloak           (nome del servizio compose)

set -euo pipefail

KC_URL=${KC_URL:-http://localhost:8080}
KC_USER=${KC_ADMIN_USER:-admin}
KC_PASS=${KC_ADMIN_PASSWORD:-admin}
COMPOSE_SVC=${COMPOSE_SVC:-keycloak}

log()  { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }
ok()   { printf '  [OK]   %s\n' "$*"; }
fail() { printf '  [FAIL] %s\n' "$*"; exit 1; }

log "Attendo Keycloak su ${KC_URL}/health/ready ..."
for i in $(seq 1 60); do
  if curl -sf "${KC_URL}/health/ready" >/dev/null 2>&1; then
    ok "Keycloak ready"
    break
  fi
  sleep 2
  [ "$i" -eq 60 ] && fail "Timeout: Keycloak non risponde"
done

log "Listing provider JARs nel container..."
if ! docker compose exec -T "$COMPOSE_SVC" ls -la /opt/keycloak/providers/; then
  fail "Impossibile listare /opt/keycloak/providers/"
fi

JAR_LIST=$(docker compose exec -T "$COMPOSE_SVC" ls /opt/keycloak/providers/ 2>/dev/null || true)
echo "$JAR_LIST" | grep -qi 'apple-identity-provider' || fail "JAR apple-identity-provider non trovato"
ok "JAR apple-identity-provider presente"
echo "$JAR_LIST" | grep -qi 'fitp-enricher'           || fail "JAR fitp-enricher non trovato"
ok "JAR fitp-enricher presente"

log "Richiedo token admin..."
TOKEN=$(curl -sf -X POST "${KC_URL}/realms/master/protocol/openid-connect/token" \
  -d "client_id=admin-cli" \
  -d "username=${KC_USER}" \
  -d "password=${KC_PASS}" \
  -d "grant_type=password" \
  | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
[ -n "${TOKEN:-}" ] || fail "Token admin non ottenuto (credenziali errate o realm master non raggiungibile)"
ok "Token admin ottenuto"

log "Interrogo /admin/serverinfo ..."
INFO=$(curl -sf -H "Authorization: Bearer $TOKEN" "${KC_URL}/admin/serverinfo")
[ -n "$INFO" ] || fail "serverinfo vuoto"

# apple-identity-provider espone il provider id "apple" sotto org.keycloak.broker.provider.IdentityProviderFactory
echo "$INFO" | grep -q '"apple"'         || fail "Provider 'apple' non trovato in serverinfo"
ok "Identity provider 'apple' registrato"

# fitp-enricher espone l'authenticator id "fitp-enricher" sotto org.keycloak.authentication.AuthenticatorFactory
echo "$INFO" | grep -q '"fitp-enricher"' || fail "Provider 'fitp-enricher' non trovato in serverinfo"
ok "Authenticator 'fitp-enricher' registrato"

log "Tutti i provider sono caricati correttamente."
