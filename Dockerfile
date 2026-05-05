# hevy-mcp image wrapped with supergateway.
#
# Contract:
#   - MCP streamable-HTTP on 0.0.0.0:$PORT at /mcp
#   - Health endpoint at /healthz
#   - stdio-speaking MCP process spawned by supergateway as a child
#
# Override the supergateway version at build time with:
#   docker build --build-arg SUPERGATEWAY_VERSION=3.5.0 .

ARG SUPERGATEWAY_VERSION=3.4.3

# -----------------------------------------------------------------------------
# Stage 1: builder. Installs devDependencies, compiles the dist bundle.
# -----------------------------------------------------------------------------
FROM node:24-alpine AS builder

WORKDIR /build

COPY package.json package-lock.json tsconfig.json tsdown.config.ts ./
COPY src ./src
COPY README.md ./

# `npm ci` needs devDependencies (tsdown + sentry rollup plugin) to build
# the dist bundle.
RUN npm ci --include=dev \
    && npm run build

# -----------------------------------------------------------------------------
# Stage 2: runtime. Only production deps + dist + globally-installed bin.
# -----------------------------------------------------------------------------
FROM node:24-alpine

# MCP Registry ownership attestation. The registry refuses to publish an
# OCI package entry unless the image carries this label with a value that
# matches the server.json `name` field, proving that whoever pushed the
# image also controls the registry namespace.
LABEL io.modelcontextprotocol.server.name="io.github.rwestergren/hevy-mcp-remote"

ARG SUPERGATEWAY_VERSION

ENV NODE_ENV=production \
    PORT=8080

RUN npm install -g supergateway@${SUPERGATEWAY_VERSION}

WORKDIR /app

# Copy only what's needed to run: package manifests (so `npm install -g .`
# resolves), the built dist/, and README (referenced by package.json).
COPY package.json package-lock.json ./
COPY README.md ./
COPY --from=builder /build/dist ./dist

# Install prod deps only, then install this package globally so the
# `hevy-mcp` bin lands on PATH for supergateway to spawn.
RUN npm ci --omit=dev \
    && npm install -g .

# --stateful enables Mcp-Session-Id semantics per the MCP streamable-HTTP spec.
ENTRYPOINT ["/bin/sh", "-c", "exec supergateway \
  --stdio 'hevy-mcp' \
  --outputTransport streamableHttp \
  --stateful \
  --streamableHttpPath /mcp \
  --healthEndpoint /healthz \
  --port \"${PORT}\" \
  --sessionTimeout 3600000 \
  --logLevel info"]
