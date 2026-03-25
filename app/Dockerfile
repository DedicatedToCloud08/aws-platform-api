FROM python:3.12-slim AS builder

WORKDIR /app

COPY requirements.txt .

RUN pip install --upgrade pip && \
    pip install --prefix=/install -r requirements.txt

FROM python:3.12-slim AS final

WORKDIR /app

COPY --from=builder /install /usr/local

COPY main.py .

RUN useradd --no-create-home --shell /bin/false appuser
USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD  python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]