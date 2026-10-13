FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

COPY requirements-prd.txt .
RUN pip install --no-cache-dir -r requirements-prd.txt

COPY app/ ./app/

RUN groupadd --gid 1000 app && \
    useradd --uid 1000 --gid app --no-create-home --shell /usr/sbin/nologin app && \
    chown -R app:app /app
USER app

EXPOSE 8002

HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8002/health', timeout=2)"]

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8002"]
