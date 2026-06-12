FROM python:3.14-slim

WORKDIR /app

COPY pyproject.toml README.md ./
COPY app ./app

RUN pip install --no-cache-dir .

ENV PORT=8000
ENV STEADYTAP_DB_PATH=/app/data/steadytap.sqlite
ENV STEADYTAP_RUNTIME_STORE_PATH=/app/data/runtime-events.jsonl

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen(f'http://127.0.0.1:{__import__(\"os\").environ.get(\"PORT\",\"8000\")}/v1/health', timeout=5).status == 200 else 1)"

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
