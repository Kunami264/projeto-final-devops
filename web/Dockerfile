FROM nginxinc/nginx-unprivileged:1.27-alpine

USER root
RUN apk upgrade --no-cache
USER 101

# Destinos do proxy (valores do Docker Compose; no Kubernetes vêm do chart Helm).
# NGINX_ENTRYPOINT_LOCAL_RESOLVERS: a imagem lê o DNS do contentor (/etc/resolv.conf)
# e disponibiliza-o ao template como ${NGINX_LOCAL_RESOLVERS}.
ENV NGINX_ENTRYPOINT_LOCAL_RESOLVERS=1 \
    USERS_URL=http://service-users:8002 \
    ORDERS_URL=http://service-orders:8001 \
    KEYCLOAK_URL=http://keycloak:8080

COPY nginx.conf.template /etc/nginx/templates/default.conf.template
COPY static/ /usr/share/nginx/html/

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
    CMD ["wget", "-q", "-O", "/dev/null", "http://127.0.0.1:8080/healthz"]
