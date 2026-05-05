# keycloak-apple-identity-provider-fitp-enricher

Immagine Docker custom di [Keycloak](https://www.keycloak.org/) preconfezionata con due provider aggiuntivi:

- **Apple Social Identity Provider** ([klausbetz/apple-identity-provider-keycloak](https://github.com/klausbetz/apple-identity-provider-keycloak)) — login "Sign in with Apple".
- **FITP Enricher** ([HiWay-Media/keycloak-fitp-enricher](https://github.com/HiWay-Media/keycloak-fitp-enricher)) — arricchimento token HiWay/FITP.

Le immagini vengono pubblicate su GitHub Container Registry: `ghcr.io/hiway-media/keycloak-apple-identity-provider-fitp-enricher`.

## Contenuto della repo

| File | Scopo |
| --- | --- |
| [Dockerfile.latest](Dockerfile.latest) | Build sopra `quay.io/keycloak/keycloak:latest` (segue l'upstream Keycloak). |
| [Dockerfile.22.0.1](Dockerfile.22.0.1) | Build sopra `quay.io/keycloak/keycloak:22.0.1` (immagine pinnata). |
| [.github/workflows/docker-publish.yml](.github/workflows/docker-publish.yml) | Pipeline che builda `Dockerfile.latest` e fa push su `ghcr.io` ad ogni tag. |
| [.github/workflows/docker-publish.22.0.1.yml](.github/workflows/docker-publish.22.0.1.yml) | Pipeline gemella per `Dockerfile.22.0.1`. |

## Versioni dei provider incluse

- `apple-identity-provider` **1.10.0**
- `fitp-enricher` **1.0.0** (release tag `v0.1.0`)

Per aggiornare un provider, modificare l'URL nei `Dockerfile.*` e taggare una nuova release.

## Build/push automatici

Il workflow [docker-publish.yml](.github/workflows/docker-publish.yml) si attiva su `push` di un tag git e calcola i tag Docker così:

- Tag semver `vX.Y.Z` → vengono pubblicati `:vX.Y.Z`, `:vX.Y`, `:vX`, `:latest`.
- Qualunque altro tag → solo `:<tag>`.

Per pubblicare una nuova versione:

```bash
git tag v0.1.0
git push origin v0.1.0
```

L'immagine viene pushata come `linux/amd64` su `ghcr.io/hiway-media/keycloak-apple-identity-provider-fitp-enricher`.

## Build locale

```bash
docker build -f Dockerfile.latest -t keycloak-apple-fitp:dev .
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
