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
| `22.0.5` | `1.10.0` | `0.3.0` | `:22.0.5`, `:22.0.5-<git-tag>` |
| `23.0.7` | `1.12.0` | `0.3.0` | `:23.0.7`, `:23.0.7-<git-tag>` |
| `24.0.5` | `1.12.0` | `0.3.0` | `:24.0.5`, `:24.0.5-<git-tag>` |
| `25.0.6` | `1.13.0` | `0.3.0` | `:25.0.6`, `:25.0.6-<git-tag>` |
| `26.6.1` | `1.17.0` | `0.3.0` | `:26.6.1`, `:26.6.1-<git-tag>`, `:stable` |
| `latest` | `1.17.0` | `0.3.0` | `:latest`, `:latest-<git-tag>` |

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
  --build-arg FITP_VERSION=0.3.0 \
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

## Troubleshooting

### Il FITP Enricher non compare in "Identity providers"

È corretto: il FITP Enricher **non è un Identity Provider**, è un **Authenticator** (`com.hiwaymedia.keycloak.FitpEnricherAuthenticatorFactory`, provider id `fitp-enricher`). Si configura in **Authentication → Flows** come *step* dentro un flow (es. *Browser*, *First broker login*, *Post broker login*), non nella pagina *Identity providers*. A boot lo trovi nei log:

```
KC-SERVICES0047: fitp-enricher (com.hiwaymedia.keycloak.FitpEnricherAuthenticatorFactory)
is implementing the internal SPI authenticator
```

### Lo step FITP "sparisce" dal flow dopo un redeploy

Sintomo: lo step era configurato, dopo un riavvio/upgrade non si vede più nella console admin, ma le righe sembrano ancora nel DB.

Come funziona: ogni step di un flow è una riga in `authentication_execution`, la cui colonna `authenticator` contiene l'**ID del provider**. La console risolve quell'ID verso una factory registrata; se l'ID **non** corrisponde a una factory caricata, la riga resta nel DB ma lo step **non viene renderizzato**.

> Nota: l'ID `fitp-enricher` è **stabile** in 0.2.0 → 0.2.1 → 0.3.0, quindi un bump di versione **non** causa il mismatch.

Diagnosi (sostituire il nome realm):

```sql
SELECT ae.authenticator, af.alias AS flow, ae.requirement, ae.flow_id
FROM authentication_execution ae
LEFT JOIN authentication_flow af ON af.id = ae.flow_id
WHERE ae.realm_id = (SELECT id FROM realm WHERE name = 'supertennix')
  AND ae.authenticator ILIKE '%fitp%';
```

Cause e fix:

1. **`authenticator` ≠ `fitp-enricher`** (flow configurato con una vecchia 0.1.x dall'ID diverso) → step orfano: ri-aggiungerlo con l'ID attuale dalla UI.
2. **`flow` NULL / `flow_id` inesistente** → il flow padre è stato **ricreato da un realm-import al boot**, orfanando l'execution. Questa è la causa più frequente del "sparisce al redeploy".
3. **Tutto coerente** (`fitp-enricher` + flow valido) → cache Infinispan stale: riavvio pulito.

Prevenzione: **non** mischiare realm-import che sovrascrive a ogni boot con modifiche manuali in UI. Includere lo step FITP nel realm JSON versionato, oppure disabilitare l'import-on-every-boot così le modifiche persistono. Fare sempre un export di backup prima (`kc.sh export` o Admin REST `partial-export`).

## Documentazione (GitHub Pages)

Il sito di documentazione è pubblicato via GitHub Pages dalla cartella [docs/](docs/) tramite il workflow [.github/workflows/pages.yml](.github/workflows/pages.yml):

<https://hiway-media.github.io/keycloak-apple-identity-provider-fitp-enricher/>

> Setup una tantum: in **Settings → Pages → Build and deployment → Source** selezionare **GitHub Actions**.

## Licenza

[MIT](LICENSE)
