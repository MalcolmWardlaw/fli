# Stage 1: dependency resolver
FROM python:3.12-slim AS builder

COPY --from=ghcr.io/astral-sh/uv:0.6.0 /uv /bin/uv

WORKDIR /app

COPY pyproject.toml uv.lock README.md ./
COPY fli/ ./fli/

RUN uv sync --frozen --no-dev --no-cache --extra mcp


# Stage 2: minimal runtime
FROM python:3.12-slim AS runtime

WORKDIR /app

# Copy only the installed venv and source from the builder
COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /app/fli /app/fli

ENV PATH="/app/.venv/bin:$PATH"
ENV VIRTUAL_ENV="/app/.venv"
ENV PYTHONUNBUFFERED=1
ENV HOST="0.0.0.0"
ENV PORT="8000"

EXPOSE 8000

# Run as non-root, with a home directory. FastMCP's OAuth client storage is
# written under $HOME, so appuser needs a writable home (mount a volume there
# to persist registered OAuth clients across container recreations).
RUN useradd --create-home --shell /bin/false appuser
ENV HOME="/home/appuser"
USER appuser

CMD ["fli-mcp-http"]
