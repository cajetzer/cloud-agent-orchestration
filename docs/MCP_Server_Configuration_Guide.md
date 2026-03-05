# MCP Server Configuration Guide

A comprehensive guide to configuring MCP servers for use by GitHub Copilot across different surfaces: VS Code, Copilot CLI, and GitHub.com Coding Agent.

> **Last Updated:** March 2026  
> **Status:** MCP support in VS Code is Generally Available (GA as of July 2025). GitHub.com Coding Agent MCP is in Technical Preview.

> **IDE Scope:** This guide focuses on **VS Code** for IDE configuration examples. At the time of this writing, GitHub Copilot MCP support is also Generally Available in **JetBrains IDEs** (IntelliJ, PyCharm, WebStorm, etc.), **Eclipse**, and **Xcode**, with Visual Studio offering partial MCP support in preview. While core MCP concepts are consistent across IDEs, configuration file locations, schema details, and specific features may differ. Refer to the [Copilot feature matrix](https://docs.github.com/en/copilot/reference/copilot-feature-matrix) and the IDE-specific tabs in the [MCP documentation](https://docs.github.com/en/copilot/how-tos/provide-context/use-mcp/extend-copilot-chat-with-mcp) for guidance on other editors.

## 1. Local vs. Remote MCP Servers

MCP servers can run in two fundamentally different modes:

**Local MCP Servers (stdio transport):**
- Process spawned locally on your machine using `command` + `args`
- Communicates via standard input/output (stdio)
- Examples: Custom scripts, locally-installed npm packages
- **Use when:** Building custom tools, need local file access, integrating local dev tools

**Remote MCP Servers (HTTP/SSE transport):**
- Hosted elsewhere, accessed via HTTP(S) endpoint
- Communicates via Server-Sent Events (SSE) or HTTP
- Examples: Figma MCP, third-party APIs, self-hosted services
- **Use when:** Accessing existing services, sharing across team, avoiding local setup
- **Note:** GitHub.com Coding Agent does not currently support remote MCP servers that use OAuth for authentication

This guide covers both patterns. For discovering available MCP servers, visit the [MCP Registry](https://registry.modelcontextprotocol.io/).

### Remote vs. Local: When to Use Each

| Consideration | Local (stdio) | Remote (HTTP/SSE) |
|--------------|---------------|-------------------|
| **Setup Complexity** | Higher (install deps) | Lower (just URL + token) |
| **GitHub.com Support** | Full (`npx` commands) | Limited (no OAuth) |
| **Team Consistency** | Varies per machine | Same for everyone |
| **Performance** | Fast (no network) | Network latency |
| **Security** | Credentials local | Credentials in transit |
| **Offline Work** | Yes | Requires internet |
| **Custom Tools** | Easy to develop | Need hosting |

### Best Practices for Remote Servers

1. **Use HTTPS Always** - Never connect to `http://` endpoints
2. **Rotate Tokens Regularly** - Especially for high-privilege services
3. **Set Timeouts** - Prevent hanging on slow/unavailable servers
4. **Verify Endpoints** - Confirm URLs from official docs before configuring

## 2. **Configuration Schema by Surface**

Each Copilot surface has a different configuration file and schema. While the underlying server definitions (`command`, `args`, `env`) are similar and portable, the top-level schema keys, required fields, and secret syntax differ — so configuration files cannot simply be copied between surfaces without adaptation.

### VS Code Configuration (`.vscode/mcp.json`)

VS Code uses a dedicated `mcp.json` file with a **`servers`** top-level key:

**Local Server (stdio) Example — Azure MCP Server using local credentials:**
```json
{
  "servers": {
    "azureMcp": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@azure/mcp@latest", "server", "start"]
    }
  }
}
```

> This example utilizes local authentication via `az login`, the VS Code Azure extension, or another [DefaultAzureCredential](https://learn.microsoft.com/azure/developer/azure-mcp-server/overview) source.

**Remote Server (http) Example — GitHub MCP Server hosted by GitHub:**
```json
{
  "servers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    }
  }
}
```

> With VS Code 1.101+, OAuth authentication is handled automatically. For PAT-based auth or older versions, add `"headers": { "Authorization": "Bearer ${input:github_mcp_pat}" }` and a corresponding `inputs` entry. See the [GitHub MCP Server](https://github.com/github/github-mcp-server) repo for full configuration options.

**Key VS Code Features:**
- **Location:** `.vscode/mcp.json` (workspace) or user settings
- **Schema:** Uses `"servers"` (not `"mcpServers"`)
- **Secrets:** Use `"inputs"` array with `${input:id}` for secure prompting
- **Policy:** Controlled by "MCP servers in Copilot" policy (disabled by default for enterprises)
- **Trust:** VS Code shows trust prompts before starting MCP servers
- **Discovery:** Search `@mcp` in Extensions to find installable servers, or enable `chat.mcp.discovery.enabled` to auto-discover from Claude Desktop config

**Reference:** [VS Code MCP Configuration](https://code.visualstudio.com/docs/copilot/reference/mcp-configuration)

### Copilot CLI Configuration (`~/.copilot/mcp-config.json`)

Copilot CLI uses a separate config file with a `"mcpServers"` top-level key. It supports `type` values of `"local"` / `"stdio"` for local servers and `"http"` / `"sse"` for remote servers. Using `"stdio"` is recommended if you want your configuration to be compatible for cross-client compatibility (VS Code, Coding Agent, etc.).

```json
{
  "mcpServers": {
    "azureMcp": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@azure/mcp@latest", "server", "start"],
      "tools": ["*"]
    }
  }
}
```

> This example is for a locally run Azure MCP Server, utilizing local authentication via `az login` or another [DefaultAzureCredential](https://learn.microsoft.com/azure/developer/azure-mcp-server/overview) source available in your shell environment.

**Key CLI Features:**
- **Location:** `~/.copilot/mcp-config.json` (Linux/Mac) or `%USERPROFILE%\.copilot\mcp-config.json` (Windows)
- **Management:** Use `/mcp add`, `/mcp show`, `/mcp remove`, `/mcp edit`, `/mcp delete`, `/mcp enable`, `/mcp disable` commands
- **Schema:** Uses `"mcpServers"` (same key as GitHub.com, different from VS Code's `"servers"`)
- **Secrets:** Uses shell environment variable expansion (`${VAR_NAME}`)
- **Tools:** Supports an optional `"tools"` field to control which tools are available. Use `["*"]` for all (default behavior if not included), or a list of allowed tool names.

**Reference:** [Adding MCP servers for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-mcp-servers)

### GitHub.com Coding Agent (Cloud)

**How It Works:**

GitHub.com Coding Agent runs inside GitHub Actions runners — ephemeral cloud VMs that spin up for each session. When the agent needs to use an MCP server, it spawns the server process within that runner environment. This means:

- The runner starts fresh each time (no persistent state)
- MCP servers must be installable via the configured command (e.g., `npx`)
- Any authentication or setup must happen before the agent runs
- The `.github/copilot-setup-steps.yml` file lets you run preparation steps (install dependencies, authenticate, configure tools) in the runner before the Coding Agent session begins

**Setup Steps:**

1. **Add Copilot environment secrets** — In Repository Settings → Secrets and variables → Copilot, add any secrets your MCP server needs. Use the `COPILOT_MCP_` prefix (e.g., `COPILOT_MCP_API_KEY`). Reference them in your config as `$COPILOT_MCP_API_KEY`.

2. **Configure `copilot-setup-steps.yml`** (if needed) — For servers requiring pre-installation, authentication setup, or other dependencies, add steps to `.github/copilot-setup-steps.yml` that run before the agent starts.

3. **Add MCP configuration** — In Repository Settings → Copilot → MCP Servers, paste your JSON configuration.

**⚠️ Security Note:** Tools execute autonomously without approval prompts. This is different from VS Code, where you can configure approval prompts. Design configurations with least-privilege principles.

**Reference:** [Extending Coding Agent with MCP](https://docs.github.com/en/copilot/how-tos/agents/copilot-coding-agent/extending-copilot-coding-agent-with-mcp)

### Example: Azure MCP Server for GitHub.com Coding Agent

This example demonstrates all the setup steps using the Azure MCP Server:

**Step 1 — Add Copilot environment secrets:**
```
COPILOT_MCP_AZURE_TENANT_ID     = <your-tenant-id>
COPILOT_MCP_AZURE_CLIENT_ID     = <your-client-id>
COPILOT_MCP_AZURE_CLIENT_SECRET = <your-client-secret>
```

**Step 2 — (Optional) Configure `.github/copilot-setup-steps.yml`:**
```yaml
# For managed identity setup, you may need:
- name: Configure Azure MCP
  run: azd coding-agent config
```

**Step 3 — Add MCP configuration (Settings UI):**
```json
{
  "mcpServers": {
    "azure": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@azure/mcp@latest", "server", "start"],
      "env": {
        "AZURE_TENANT_ID": "$COPILOT_MCP_AZURE_TENANT_ID",
        "AZURE_CLIENT_ID": "$COPILOT_MCP_AZURE_CLIENT_ID",
        "AZURE_CLIENT_SECRET": "$COPILOT_MCP_AZURE_CLIENT_SECRET"
      },
      "tools": ["list_subscriptions", "list_resource_groups", "get_resource"]
    }
  }
}
```
**Schema Requirements:**
- **`type`:** REQUIRED — must be `"local"`, `"stdio"`, `"http"`, or `"sse"`
- **`tools`:** REQUIRED — explicit allowlist of tools (use `["*"]` for all, but prefer a minimal list for least privilege)
- **`command`/`args`:** For stdio servers, the command to spawn the MCP server process
- **`env`:** Environment variables passed to the server (use `$COPILOT_MCP_*` for secrets)

**What WON'T work:**
- `${{ secrets.X }}` syntax (that's for Actions, not Copilot)
- OAuth-based remote MCP servers (not currently supported)
- Private network endpoints (must be publicly accessible)
- `localhost` or on-premises resources (runs in GitHub's cloud)

**Reference:** [Azure MCP with Coding Agent](https://learn.microsoft.com/azure/developer/azure-mcp-server/how-to/github-copilot-coding-agent)

## 3. **Authentication Methods**

MCP servers require authentication to access protected resources. The method depends on whether you're using a local or remote server, and which Copilot surface you're configuring.

### Authentication Patterns Overview

| Pattern | Use Case | Supported Surfaces |
|---------|----------|-------------------|
| **Ambient/Local Credentials** | Development with logged-in user identity | VS Code, CLI |
| **Environment Variables** | API keys, tokens passed to server process | All surfaces |
| **Secure Input Prompts** | Interactive credential entry (not stored in config) | VS Code |
| **OAuth 2.1 with PKCE** | Remote servers with delegated auth | VS Code (1.101+) |
| **Federated Identity (OIDC)** | Cloud workloads without stored secrets | GitHub.com (via setup steps) |

### Pattern 1: Ambient/Local Credentials

For local development, many MCP servers can use credentials already available in your environment — no explicit configuration needed.

**How it works:** The MCP server's SDK (e.g., Azure Identity, GitHub CLI) checks for logged-in sessions automatically.

**VS Code Example (Azure MCP using local `az login`):**
```json
{
  "servers": {
    "azure": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@azure/mcp@latest", "server", "start"]
    }
  }
}
```

**Credential chain (Azure example):** Environment variables → Managed Identity → VS Code Azure extension → Azure CLI → Azure PowerShell

**Best for:** Local development where you're already authenticated to the service.

### Pattern 2: Environment Variables

Pass credentials as environment variables to the MCP server process. This works across all surfaces but requires different syntax for each.

**VS Code — using `inputs` for secure prompting:**
```json
{
  "servers": {
    "my-server": {
      "type": "stdio",
      "command": "my-mcp-server",
      "env": {
        "API_KEY": "${input:apiKey}"
      }
    }
  },
  "inputs": [
    {
      "id": "apiKey",
      "type": "promptString",
      "description": "Enter API Key",
      "password": true
    }
  ]
}
```

**VS Code — using system environment variables:**
```json
{
  "env": {
    "API_KEY": "${env:MY_API_KEY}"
  }
}
```

**Copilot CLI — shell-level environment expansion:**
```json
{
  "mcpServers": {
    "my-server": {
      "type": "stdio",
      "command": "my-mcp-server",
      "env": {
        "API_KEY": "${MY_API_KEY}"
      }
    }
  }
}
```

**GitHub.com Coding Agent — Copilot environment secrets:**
```json
{
  "mcpServers": {
    "my-server": {
      "type": "stdio",
      "command": "my-mcp-server",
      "env": {
        "API_KEY": "$COPILOT_MCP_API_KEY"
      }
    }
  }
}
```
> Secrets must be added in Repository Settings → Secrets and variables → Copilot with the `COPILOT_MCP_` prefix.

### Pattern 3: OAuth 2.1 (Remote Servers)

For remote MCP servers, VS Code 1.101+ supports OAuth 2.1 with PKCE for secure delegated authentication. The client handles the OAuth flow automatically.

**VS Code Example (GitHub MCP Server with auto-OAuth):**
```json
{
  "servers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    }
  }
}
```

When you first use this server, VS Code initiates an OAuth flow and stores the token securely.

**Fallback to PAT (Personal Access Token):**
```json
{
  "servers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer ${input:github_pat}"
      }
    }
  },
  "inputs": [
    {
      "id": "github_pat",
      "type": "promptString",
      "description": "GitHub Personal Access Token",
      "password": true
    }
  ]
}
```

> **Note:** GitHub.com Coding Agent does not currently support OAuth-based remote MCP servers.

### Pattern 4: Federated Identity (OIDC)

For GitHub.com Coding Agent connecting to cloud resources, use federated identity (OIDC) instead of storing long-lived secrets. This is the recommended approach for Azure integration.

**How it works:**
1. Create a managed identity or service principal in your cloud provider
2. Configure OIDC federation to trust GitHub Actions
3. Use `copilot-setup-steps.yml` to authenticate before the agent runs

**Azure Example (using `azd coding-agent config`):**
```yaml
# .github/copilot-setup-steps.yml
- name: Azure Login (OIDC)
  uses: azure/login@v2
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

The Azure MCP Server then uses the authenticated session — no client secret needed.

**Reference:** [Connect Coding Agent to Azure MCP Server](https://learn.microsoft.com/azure/developer/azure-mcp-server/how-to/github-copilot-coding-agent)

### Secret Syntax Quick Reference

| Surface | Syntax | Storage Location |
|---------|--------|------------------|
| **VS Code** | `${input:id}` | Prompted at runtime (secure) |
| **VS Code** | `${env:VAR}` | System environment variables |
| **Copilot CLI** | `${VAR}` | Shell environment |
| **GitHub.com** | `$COPILOT_MCP_*` | Copilot environment secrets |

### Security Best Practices

1. **Never hardcode secrets** in configuration files
2. **Use `password: true`** for VS Code input prompts to mask entry
3. **Prefer OAuth/OIDC** over long-lived tokens when available
4. **Use least-privilege** — only grant permissions the MCP server actually needs
5. **Rotate credentials** regularly, especially for service principals
6. **Audit access** — review which MCP servers have access to which secrets

**References:**
- [VS Code MCP Configuration Reference](https://code.visualstudio.com/docs/copilot/reference/mcp-configuration)
- [Extending Coding Agent with MCP](https://docs.github.com/en/copilot/how-tos/agents/copilot-coding-agent/extending-copilot-coding-agent-with-mcp)
- [Secure MCP Servers with Microsoft Entra](https://learn.microsoft.com/azure/app-service/configure-authentication-mcp-server-vscode) - example of using Microsoft Entra for secure authentication to an MCP server hosted on Azure App Service

## 4. **Multiple Configurations**

You can configure the same MCP server multiple times with different credentials for different environments or purposes:

### VS Code: Multiple Azure Environments
```json
{
  "servers": {
    "azure-prod": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@azure/mcp@latest", "server", "start"],
      "env": {
        "AZURE_TENANT_ID": "${input:prodTenantId}",
        "AZURE_CLIENT_ID": "${input:prodClientId}",
        "AZURE_CLIENT_SECRET": "${input:prodSecret}",
        "AZURE_SUBSCRIPTION_ID": "${input:prodSubId}"
      }
    },
    "azure-dev": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@azure/mcp@latest", "server", "start"],
      "env": {
        "AZURE_SUBSCRIPTION_ID": "${input:devSubId}"
      }
    }
  }
}
```

### GitHub.com: Per-Agent MCP Configuration

GitHub.com supports configuring MCP servers per custom agent using the `mcp-servers` field in agent YAML:

```yaml
# .github/agents/my-agent.agent.md front matter
---
mcp-servers:
  azure:
    type: stdio
    command: npx
    args: ["-y", "@azure/mcp@latest", "server", "start"]
    env:
      AZURE_TENANT_ID: $COPILOT_MCP_AZURE_TENANT_ID
    tools: ["list_subscriptions"]
---
```

**Reference:** [Custom Agents Configuration](https://docs.github.com/en/copilot/reference/custom-agents-configuration)

## 5. **Networking Considerations**

### Local Development (VS Code/CLI)

- MCP servers run as local processes on your machine
- Can access `localhost`, private networks, VPNs
- Uses your local Azure CLI credentials for Azure resources
- Azure Private Endpoints work if your machine is on the connected VNet

### GitHub.com Coding Agent

**Cloud Execution - Critical Limitations:**

| ✅ CAN Access | ❌ CANNOT Access |
|--------------|-----------------|
| Public internet endpoints | `localhost` or `127.0.0.1` |
| Azure resources with public endpoints | Private networks or VPNs |
| GitHub-hosted services | On-premises resources |
| Public APIs | Resources behind firewalls |

**For Azure resources:** Enable public endpoints and configure firewall rules to allow GitHub's IP ranges, OR use Azure API Management as a gateway.

## 6. **Enterprise Governance**

### VS Code Policy Control

MCP servers in VS Code are controlled by the **"MCP servers in Copilot"** policy:
- **Disabled by default** for enterprise organizations
- Admins must explicitly enable via organization policies
- Individual users see trust prompts before MCP servers start

### GitHub.com Access Control

- Configure allowed MCP servers at organization level
- Use MCP Registries to curate approved servers
- All MCP tool calls are logged for audit

### Security Best Practices

1. **Least Privilege:** Use minimal `tools` arrays—never `["*"]` in production
2. **Audit Regularly:** Review MCP configurations and tool usage logs
3. **Rotate Credentials:** Use short-lived tokens where possible
4. **Trust Verification:** Only use MCP servers from verified sources (MCP Registry)
5. **Supply Chain:** Pin MCP server versions to avoid unexpected changes

## 7. **Quick Reference**

### Configuration Syntax by Surface

| Surface | Config Location | Schema Key | Secret Syntax |
|---------|----------------|------------|---------------|
| **VS Code** | `.vscode/mcp.json` | `"servers"` | `${input:id}` or `${env:VAR}` |
| **Copilot CLI** | `~/.copilot/mcp-config.json` | `"mcpServers"` | `${VAR_NAME}` (shell env) |
| **GitHub.com** | Settings UI (not file) | `"mcpServers"` | `$COPILOT_MCP_*` |

### Required Fields by Surface

| Field | VS Code | CLI | GitHub.com |
|-------|---------|-----|------------|
| `type` | Required | Optional (recommended) | **Required** |
| `tools` | Optional | Optional (default `*`) | **Required** |
| `command`/`url` | Required | Required | Required |

### Key Differences

| Feature | VS Code | GitHub.com |
|---------|---------|------------|
| Tool Approval | Configurable (can prompt) | **No prompts (autonomous)** |
| OAuth Remote Servers | Supported | **Not supported** |
| Private Network Access | Yes | **No** |
| Configuration Method | File-based | **Settings UI only** |

## 8. **Debugging & Troubleshooting**

### VS Code
- **Output Panel:** View → Output → select "GitHub Copilot Chat MCP"
- **Developer Tools:** Help → Toggle Developer Tools (check Console)
- **Trust Issues:** Check if MCP server trust prompt was dismissed

### GitHub.com
- Errors shown inline in chat as tool failures
- Check Repository Settings → Copilot → MCP Servers for config validation
- Verify Copilot environment secrets are set correctly

### Common Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| "Server not found" | Wrong config location | Use correct file/UI for surface |
| "Tool not allowed" | Missing `tools` array | Add explicit tool allowlist |
| "Connection refused" | Private endpoint | Use public endpoint for GitHub.com |
| "Authentication failed" | Wrong secret syntax | Check syntax table above |

---

## Resources

- [VS Code MCP Configuration Reference](https://code.visualstudio.com/docs/copilot/reference/mcp-configuration)
- [VS Code MCP Servers Guide](https://code.visualstudio.com/docs/copilot/chat/mcp-servers)
- [Adding MCP Servers for Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-mcp-servers)
- [GitHub Coding Agent MCP](https://docs.github.com/en/copilot/how-tos/agents/copilot-coding-agent/extending-copilot-coding-agent-with-mcp)
- [Azure MCP Server](https://learn.microsoft.com/azure/developer/azure-mcp-server/overview)
- [MCP Registry](https://registry.modelcontextprotocol.io/)
- [Custom Agents Configuration](https://docs.github.com/en/copilot/reference/custom-agents-configuration)
- [Copilot Customization Cheat Sheet](https://docs.github.com/en/copilot/reference/customization-cheat-sheet)

---

## Summary

This guide covers configuring MCP servers across all GitHub Copilot surfaces. Key takeaways:

1. **Schemas differ by surface** — VS Code uses `"servers"`, Copilot CLI and GitHub.com use `"mcpServers"`. The underlying server definitions are portable but top-level keys, required fields, and secret syntax vary
2. **GitHub.com executes autonomously** — No approval prompts; design for least privilege
3. **Verify endpoints** — Many example URLs are placeholders; check official docs
4. **Use the MCP Registry** — Discover verified servers at [registry.modelcontextprotocol.io](https://registry.modelcontextprotocol.io/)
5. **Secret syntax varies** — VS Code: `${input:id}`, CLI: `${VAR}`, GitHub.com: `$COPILOT_MCP_*`
6. **GitHub.com limitations** — No OAuth remote servers, no private networks, Settings UI only (not file-based)

**Recommended for getting started:** Start by configuring an MCP server locally in VS Code or Copilot CLI to learn the patterns interactively, then adapt the configuration for GitHub.com Coding Agent using the Settings UI and `COPILOT_MCP_` prefixed secrets. Browse the [MCP Registry](https://github.com/mcp) to find a server that fits your workflow.
