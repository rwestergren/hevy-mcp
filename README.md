# hevy-mcp-remote: Hosted / gateway-ready MCP for Hevy Fitness

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Build Docker image](https://github.com/rwestergren/hevy-mcp/actions/workflows/docker.yml/badge.svg)](https://github.com/rwestergren/hevy-mcp/actions/workflows/docker.yml)
[![ghcr.io](https://img.shields.io/badge/ghcr.io-rwestergren%2Fhevy--mcp-blue)](https://github.com/rwestergren/hevy-mcp/pkgs/container/hevy-mcp)

> **Fork notice.** This is an independently-maintained fork of [`chrisdoc/hevy-mcp`](https://github.com/chrisdoc/hevy-mcp), repackaged for multi-tenant MCP gateways. It ships the same Hevy tools wrapped in [supergateway](https://github.com/supercorp-ai/supergateway) as an OCI image that speaks MCP streamable-HTTP over HTTP, instead of stdio. Use the upstream `hevy-mcp` npm package for local/stdio use in Claude Desktop, Cursor, etc.

A Model Context Protocol (MCP) server for the [Hevy fitness tracking app](https://www.hevyapp.com/), packaged as a supergateway-wrapped OCI image for hosting behind an MCP gateway. Exposes MCP streamable-HTTP on `/mcp` and health on `/healthz`; reads `HEVY_API_KEY` from the container environment.

---

## 📋 Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Claude Desktop Configuration](#claude-desktop-configuration)
  - [Cursor Configuration](#cursor-configuration)
- [Why hevy-mcp?](#why-hevy-mcp)
- [Configuration](#configuration)
- [Available MCP Tools](#available-mcp-tools)
- [Development & Contributing](#development--contributing)

---

## 🚀 Features

- **Workout Management**: Fetch, create, and update workouts.
- **Routine Management**: Access and manage workout routines.
- **Exercise Templates**: Browse available exercise templates with in-memory caching.
- **Folder Organization**: Manage routine folders.
- **Webhook Subscriptions**: Create, view, and delete webhook subscriptions for workout events.

---

## 🏁 Quick Start

Pick the workflow that fits your setup:

| Scenario              | Command                                     | Requirements               |
| :-------------------- | :------------------------------------------ | :------------------------- |
| **One-off stdio run** | `HEVY_API_KEY=sk_live... npx -y hevy-mcp`   | Node.js ≥ 24, Hevy API key |
| **Local development** | `npm install && npm run build && npm start` | `.env` with `HEVY_API_KEY` |

---

## 🛠️ Prerequisites

- **Node.js**: v24 or higher (strongly recommended to use the exact version pinned in `.nvmrc`).
- **npm**: v10 or higher.
- **Hevy API key**: Required for all operations (available with Hevy PRO).

---

## 📦 Installation

### Run via npx (Recommended)

You can launch the server directly without cloning:

```bash
HEVY_API_KEY=your_hevy_api_key_here npx -y hevy-mcp
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/chrisdoc/hevy-mcp.git
cd hevy-mcp

# Install dependencies
npm install

# Create .env and add your keys
cp .env.sample .env
# Edit .env and add your HEVY_API_KEY
```

---

## 🔗 Integration

### Claude Desktop Configuration

To use this server with Claude Desktop, add the following to your `claude_desktop_config.json`:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`  
**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
	"mcpServers": {
		"hevy-mcp": {
			"command": "npx",
			"args": ["-y", "hevy-mcp"],
			"env": {
				"HEVY_API_KEY": "sk_live_your_key_here"
			}
		}
	}
}
```

### Cursor Configuration

Add this server under `"mcpServers"` in `~/.cursor/mcp.json`:

```json
{
	"mcpServers": {
		"hevy-mcp": {
			"command": "npx",
			"args": ["-y", "hevy-mcp"],
			"env": {
				"HEVY_API_KEY": "your-api-key-here"
			}
		}
	}
}
```

---

## ✨ Why hevy-mcp?

- 🚀 **High Performance**: Built with the **Oxc** toolchain (`oxlint`/`oxfmt`) for near-instant linting and formatting.
- 🛡️ **Type Safety**: Fully type-safe implementation using **Zod** and **Kubb**-generated API clients.
- 📉 **Observability**: Built-in **Sentry** monitoring for error tracking and performance profiling.
- ⚡ **Optimized**: Includes in-memory caching for exercise templates to reduce API latency.

---

## ⚙️ Configuration

Supply your Hevy API key via:

1. **Environment Variable**: `HEVY_API_KEY` (in `.env` or system environment).
2. **CLI Argument**: `--hevy-api-key=your_key` (after `--` in npm scripts).

```env
# Example .env
HEVY_API_KEY=your_hevy_api_key_here
```

### 📡 Sentry Monitoring

`hevy-mcp` includes Sentry monitoring to observe errors and usage in production. It initializes `@sentry/node` with tracing enabled and PII collection disabled by default.

---

## 🐳 Running behind an MCP gateway (supergateway contract)

The MCP server itself speaks **stdio only**. For multi-tenant gateway
deployments (e.g. [mcp-gateway-poc](https://github.com/rwestergren/mcp-gateway-poc)),
this repo ships a `Dockerfile` that wraps the stdio binary with
[supergateway](https://github.com/supercorp-ai/supergateway) so a single
container exposes MCP streamable-HTTP.

The image follows the same contract every gateway-hosted MCP uses:

- MCP streamable-HTTP on `0.0.0.0:$PORT` at `/mcp`
- Health endpoint at `/healthz`
- Stateful sessions (`Mcp-Session-Id` honored)
- `HEVY_API_KEY` is read from the container environment and passed to the
  spawned stdio child

Images are published to `ghcr.io/rwestergren/hevy-mcp` from `main` and from
any manually cut GitHub release. Build locally with:

```bash
docker build -t hevy-mcp:local .
docker run --rm -e HEVY_API_KEY=sk_live_... -p 8080:8080 hevy-mcp:local
curl http://localhost:8080/healthz
```

End users running `hevy-mcp` directly should use the stdio/`npx` flow above;
the Docker image is aimed at gateway operators, not individual clients.

---

## 🛠️ Available MCP Tools

| Category      | Tools                                                                                                        |
| :------------ | :----------------------------------------------------------------------------------------------------------- |
| **Workouts**  | `get-workouts`, `get-workout`, `create-workout`, `update-workout`, `get-workout-count`, `get-workout-events` |
| **Routines**  | `get-routines`, `get-routine-by-id`, `create-routine`, `update-routine`                                      |
| **Templates** | `get-exercise-templates`, `get-exercise-template`, `search-exercise-templates`                               |
| **Folders**   | `get-routine-folders`, `get-routine-folder`, `create-routine-folder`                                         |
| **Webhooks**  | `get-webhook-subscription`, `create-webhook-subscription`, `delete-webhook-subscription`                     |

---

## 👨‍💻 Development & Contributing

### Quick Commands

- **Build**: `npm run build`
- **Lint/Format**: `npm run check` (uses oxlint/oxfmt)
- **Unit Tests**: `npx vitest run --exclude tests/integration/**`
- **Full Test Suite**: `npm test` (requires `HEVY_API_KEY`)

For a detailed senior engineer guide, please refer to [AGENTS.md](./AGENTS.md).

### API Client Generation

The API client is automatically generated from the OpenAPI spec using [Kubb](https://kubb.dev/):

```bash
npm run build:client
```

---

## 📄 License & Acknowledgements

- **License**: [MIT](./LICENSE)
- **Credits**: [Model Context Protocol](https://github.com/modelcontextprotocol), [Hevy Fitness](https://www.hevyapp.com/).

---

**Contributions are welcome!** Please open an issue or PR for any major changes.
