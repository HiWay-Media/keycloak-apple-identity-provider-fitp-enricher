# keycloak-apple-identity-provider-fitp-enricher

Immagine Docker custom di [Keycloak](https://www.keycloak.org/) preconfezionata con due provider aggiuntivi:

- **Apple Social Identity Provider** ([klausbetz/apple-identity-provider-keycloak](https://github.com/klausbetz/apple-identity-provider-keycloak)) — login "Sign in with Apple".
- **FITP Enricher** ([HiWay-Media/keycloak-fitp-enricher](https://github.com/HiWay-Media/keycloak-fitp-enricher)) — arricchimento token HiWay/FITP.

Le immagini vengono pubblicate su GitHub Container Registry: `ghcr.io/hiway-media/keycloak-apple-identity-provider-fitp-enricher`.

## Contenuto della repo

| File | Scopo |
| --- | --- |
| [Dockerfile](Dockerfile) | Build parametrizzato (`ARG KC_VERSION`, `ARG APPLE_IDP_VERSION`, `ARG FITP_VERSION`) usato dal workflow matrix. |
| [Dockerfile.latest](Dockerfile.latest) | Legacy: build sopra `quay.io/keycloak/keycloak:latest`. |
| [Dockerfile.22.0.1](Dockerfile.22.0.1) | Legacy: build sopra `quay.io/keycloak/keycloak:22.0.1`. |
| [.github/workflows/docker-publish-matrix.yml](.github/workflows/docker-publish-matrix.yml) | Pipeline che builda il `Dockerfile` parametrizzato per tutte le major Keycloak (22→26 + `latest`). |
| [.github/workflows/docker-publish.yml](.github/workflows/docker-publish.yml) | Legacy: builda `Dockerfile.latest`. |
| [.github/workflows/docker-publish.22.0.1.yml](.github/workflows/docker-publish.22.0.1.yml) | Legacy: builda `Dockerfile.22.0.1`. |

## Matrice versioni (Dockerfile parametrizzato)

Il workflow [docker-publish-matrix.yml](.github/workflows/docker-publish-matrix.yml) builda in parallelo:

| Keycloak | apple-identity-provider | fitp-enricher | Tag immagine |
| --- | --- | --- | --- |
| `22.0.5` | `1.10.0` | `0.2.0` | `:22.0.5`, `:22.0.5-<git-tag>` |
| `23.0.7` | `1.12.0` | `0.2.0` | `:23.0.7`, `:23.0.7-<git-tag>` |
| `24.0.5` | `1.12.0` | `0.2.0` | `:24.0.5`, `:24.0.5-<git-tag>` |
| `25.0.6` | `1.13.0` | `0.2.0` | `:25.0.6`, `:25.0.6-<git-tag>` |
| `26.6.1` | `1.17.0` | `0.2.0` | `:26.6.1`, `:26.6.1-<git-tag>`, `:stable` |
| `latest` | `1.17.0` | `0.2.0` | `:latest`, `:latest-<git-tag>` |

Per aggiungere una nuova versione di Keycloak alla matrice, aggiungere un blocco `include` in [docker-publish-matrix.yml](.github/workflows/docker-publish-matrix.yml).

## Build/push automatici

Tutti i workflow si attivano su `push` di un tag git. Il flusso consigliato per le nuove release è:

```bash
git tag v0.3.0
git push origin v0.3.0
```

Le immagini vengono pubblicate come `linux/amd64` su `ghcr.io/hiway-media/keycloak-apple-identity-provider-fitp-enricher`.

> Nota: i workflow legacy [docker-publish.yml](.github/workflows/docker-publish.yml) e [docker-publish.22.0.1.yml](.github/workflows/docker-publish.22.0.1.yml) restano attivi e pubblicano i loro tag (`:vX.Y.Z`, `:vX.Y`, `:vX`, `:latest`) in parallelo alla matrice.

## Build locale

```bash
# parametrizzato
docker build \
  --build-arg KC_VERSION=26.6.1 \
  --build-arg APPLE_IDP_VERSION=1.17.0 \
  --build-arg FITP_VERSION=0.2.0 \
  -t keycloak-apple-fitp:dev .

# legacy
docker build -f Dockerfile.latest -t keycloak-apple-fitp:legacy-latest .
```

## Run

L'`ENTRYPOINT` è `/opt/keycloak/bin/kc.sh`, quindi i comandi Keycloak (`start`, `start-dev`, ecc.) vanno passati come argomenti del container. Esempio dev:

```bash
docker run --rm -p 8080:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  ghcr.io/hiway-media/keycloak-apple-identity-provider-fitp-enricher:latest \
  start-dev
```

## Test locale con docker-compose

Per provare i provider su una singola versione della matrice è incluso un [docker-compose.yml](docker-compose.yml) che avvia Keycloak (con Postgres) e configura `KC_HEALTH_ENABLED`, `KC_METRICS_ENABLED`, `token-exchange`.

```bash
cp .env.example .env                # personalizza KC_IMAGE_TAG, password, ecc.
docker compose up -d
docker compose logs -f keycloak     # attendi "Keycloak ... started"
```

Endpoint utili:

- Admin console: <http://localhost:8080> (login con `KC_ADMIN_USER`/`KC_ADMIN_PASSWORD` da `.env`)
- Health: <http://localhost:8080/health/ready> (quando `KC_HEALTH_ENABLED=true`)
- Metrics: <http://localhost:8080/metrics>

Per testare un'altra versione della matrice basta cambiare `KC_IMAGE_TAG` in `.env` (es. `22.0.5`, `23.0.7`, `24.0.5`, `25.0.6`, `26.6.1`, `stable`) e ricreare il container:

```bash
docker compose up -d --force-recreate keycloak
```

### Verifica automatica dei provider

Il compose include un servizio one-shot `verify` (profilo `verify`) che chiede un token admin, interroga `/admin/serverinfo` e fallisce se `apple` o `fitp-enricher` non sono registrati come SPI:

```bash
docker compose --profile verify run --rm verify
```

In alternativa è disponibile uno script bash equivalente che gira dall'host (richiede `curl` + `docker compose`):

```bash
./scripts/verify-providers.sh
```

Output atteso (estratto):

```
[OK] identity provider 'apple'
[OK] authenticator 'fitp-enricher'
==> all providers verified
```

### Test manuale dei provider

1. Admin console → realm `master` (o creane uno) → **Identity Providers** → "Add provider" → deve comparire **Apple**. Configurare `Services ID`, `Team ID`, `Key ID`, `Private key` Apple per provarlo.
2. **Authentication** → **Flows** → si dovrebbe poter aggiungere lo step **FITP Enricher** (richiede credenziali Microsoft Graph configurate come parametri dell'authenticator).

Per fermare e pulire tutto (incluso il volume Postgres):

```bash
docker compose down -v
```

Le immagini sono buildate con:

- `KC_FEATURES=token-exchange` — abilita il token exchange (necessario per scenari di federation).
- `KC_METRICS_ENABLED=true` — espone le metriche Prometheus su `/metrics`.

Per la configurazione runtime (DB, hostname, TLS, ecc.) fare riferimento alla [documentazione Keycloak](https://www.keycloak.org/server/all-config).

## Licenza

[MIT](LICENSE)
