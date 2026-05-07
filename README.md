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

Le immagini sono buildate con:

- `KC_FEATURES=token-exchange` — abilita il token exchange (necessario per scenari di federation).
- `KC_METRICS_ENABLED=true` — espone le metriche Prometheus su `/metrics`.

Per la configurazione runtime (DB, hostname, TLS, ecc.) fare riferimento alla [documentazione Keycloak](https://www.keycloak.org/server/all-config).

## Licenza

[MIT](LICENSE)
