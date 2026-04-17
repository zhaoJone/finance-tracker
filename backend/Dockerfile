FROM python:3.12-alpine AS builder

WORKDIR /app

# Install dependencies
COPY pyproject.toml .
RUN pip install --user --no-cache-dir .

# Production stage
FROM python:3.12-alpine AS runtime

WORKDIR /app

# Install ca-certificates for HTTPS requests
RUN apk add --no-cache ca-certificates

# Create non-root user
RUN addgroup -g 1000 appgroup && \
    adduser -u 1000 -G appgroup -s /bin/sh -D appuser

# Copy installed packages from builder
COPY --from=builder /root/.local /home/appuser/.local

# Copy application code
COPY --chown=appuser:appgroup src/ ./src/

# Switch to non-root user
USER appuser

# Set Python path
ENV PATH=/home/appuser/.local/bin:$PATH
ENV PYTHONPATH=/app

# No volume needed - data is in PostgreSQL

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["python", "-m", "uvicorn", "src.api.main:app", "--host", "0.0.0.0", "--port", "8000"]
