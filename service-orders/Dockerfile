FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

# A imagem leva TODOS os pacotes já instalados, e só os de PRD (requirements-prd.txt).
# Os módulos de teste (requirements-dev.txt / requirements-stg.txt) nunca entram aqui.
# É esta imagem, validada em STG, que é promovida para PRD: lá só se faz push/start.
COPY requirements-prd.txt .
RUN pip install --no-cache-dir -r requirements-prd.txt

COPY app/ ./app/

RUN groupadd --gid 1000 app && \
    useradd --uid 1000 --gid app --no-create-home --shell /usr/sbin/nologin app && \
    chown -R app:app /app
USER app

EXPOSE 8001

HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8001/health', timeout=2)"]

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001"]
