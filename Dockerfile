ARG KC_VERSION=latest

FROM quay.io/keycloak/keycloak:${KC_VERSION} AS builder
ARG APPLE_IDP_VERSION
ARG FITP_VERSION
ENV KC_FEATURES=token-exchange
ENV KC_METRICS_ENABLED=true

ADD --chown=keycloak:keycloak https://github.com/klausbetz/apple-identity-provider-keycloak/releases/download/${APPLE_IDP_VERSION}/apple-identity-provider-${APPLE_IDP_VERSION}.jar /opt/keycloak/providers/apple-identity-provider-${APPLE_IDP_VERSION}.jar
ADD --chown=keycloak:keycloak https://github.com/HiWay-Media/keycloak-fitp-enricher/releases/download/v${FITP_VERSION}/fitp-enricher-${FITP_VERSION}.jar /opt/keycloak/providers/fitp-enricher-${FITP_VERSION}.jar

RUN ls -l /opt/keycloak/providers/ && /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:${KC_VERSION}
WORKDIR /opt/keycloak
COPY --from=builder /opt/keycloak/ /opt/keycloak/
RUN /opt/keycloak/bin/kc.sh build

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
