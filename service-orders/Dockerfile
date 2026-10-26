# Alpine: base mínima, sem as vulnerabilidades por corrigir da imagem Debian (python:3.12-slim)
FROM python:3.12-alpine3.24

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# OpenTelemetry só em DEV: o docker-compose.yml constrói com INSTALL_TRACING=true.
# A imagem de STG/PRD (por omissão) não leva as bibliotecas de rastreio.
ARG INSTALL_TRACING=false

WORKDIR /app

RUN apk upgrade --no-cache

# O pip só é preciso para instalar as dependências: é removido no fim, porque traz
# bibliotecas próprias (urllib3, msgpack, ...) que não fazem falta em execução.
COPY requirements-prd.txt requirements-tracing.txt ./
RUN pip install --no-cache-dir -r requirements-prd.txt \
    && if [ "$INSTALL_TRACING" = "true" ]; then pip install --no-cache-dir -r requirements-tracing.txt; fi \
    && pip uninstall -y pip \
    && rm -rf /usr/local/lib/python3.12/ensurepip

COPY app/ ./app/

RUN addgroup -g 1000 app && \
    adduser -u 1000 -G app -H -D -s /sbin/nologin app && \
    chown -R app:app /app
USER app

EXPOSE 8001

HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8001/health', timeout=2)"]

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001"]
