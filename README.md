# AshAgent Stack

The AshAgent ecosystem for building production AI agents in Elixir.

## Packages

| Package | Description | CI |
|---------|-------------|-----|
| [ash_agent](https://github.com/bradleygolden/ash_agent) | Core agent framework with declarative DSL, provider abstraction, and Ash integration | [![CI](https://github.com/bradleygolden/ash_agent/actions/workflows/ci.yml/badge.svg)](https://github.com/bradleygolden/ash_agent/actions/workflows/ci.yml) |
| [ash_baml](https://github.com/bradleygolden/ash_baml) | BAML integration for structured LLM outputs | [![CI](https://github.com/bradleygolden/ash_baml/actions/workflows/ci.yml/badge.svg)](https://github.com/bradleygolden/ash_baml/actions/workflows/ci.yml) |
| [ash_agent_tools](https://github.com/bradleygolden/ash_agent_tools) | Tool calling support for agents | [![CI](https://github.com/bradleygolden/ash_agent_tools/actions/workflows/ci.yml/badge.svg)](https://github.com/bradleygolden/ash_agent_tools/actions/workflows/ci.yml) |
| [ash_agent_mcp](https://github.com/bradleygolden/ash_agent_mcp) | MCP (Model Context Protocol) client for external tool servers | [![CI](https://github.com/bradleygolden/ash_agent_mcp/actions/workflows/ci.yml/badge.svg)](https://github.com/bradleygolden/ash_agent_mcp/actions/workflows/ci.yml) |
| [ash_agent_session](https://github.com/bradleygolden/ash_agent_session) | Session persistence and state management for agents | [![CI](https://github.com/bradleygolden/ash_agent_session/actions/workflows/ci.yml/badge.svg)](https://github.com/bradleygolden/ash_agent_session/actions/workflows/ci.yml) |
| [ash_agent_marketplace](https://github.com/bradleygolden/ash_agent_marketplace) | Marketplace for sharing and discovering agents | [![CI](https://github.com/bradleygolden/ash_agent_marketplace/actions/workflows/ci.yml/badge.svg)](https://github.com/bradleygolden/ash_agent_marketplace/actions/workflows/ci.yml) |
| [ash_agent_studio](https://github.com/bradleygolden/ash_agent_studio) | Visual studio for building and testing agents | [![CI](https://github.com/bradleygolden/ash_agent_studio/actions/workflows/ci.yml/badge.svg)](https://github.com/bradleygolden/ash_agent_studio/actions/workflows/ci.yml) |

## Capabilities

### Core

| Capability | ReqLLM | BAML |
|------------|--------|------|
| LLM Calling | Yes | Yes |
| Structured Outputs | Yes | Yes |

### Streaming

| Capability | ReqLLM | BAML |
|------------|--------|------|
| Text | Yes | Yes |
| Structured | No | Yes |
| With Thinking | Yes | No |
| With Thinking + Structured | No | No |

### Extended Thinking (experimental)

| Capability | ReqLLM | BAML |
|------------|--------|------|
| Text Output | Yes | Yes |
| Structured Output | No | Yes |

### In Development

| Capability | ReqLLM | BAML |
|------------|--------|------|
| Tool Calling | Yes | Yes |
| Multi-turn Conversations | Yes | Yes |
| Token Management | Yes | Yes |

## Getting Started

Start with [ash_agent](https://github.com/bradleygolden/ash_agent) - the core package that provides the declarative DSL for defining AI agents as Ash resources.

```elixir
def deps do
  [
    {:ash_agent, "~> 0.1.0"}
  ]
end
```

## Architecture

```
ash_agent (core)
    |
    +-- ash_baml (optional BAML provider)
    |
    +-- ash_agent_tools (tool calling)
    |       |
    |       +-- ash_agent_mcp (MCP client)
    |       |
    |       +-- ash_agent_marketplace (agent sharing)
    |       |
    |       +-- ash_agent_studio (visual builder)
    |
    +-- ash_agent_session (session persistence)
```

## Development

This repository uses git submodules to manage each package. Each package is also published independently to Hex.

```bash
# Clone with submodules
git clone --recurse-submodules git@github.com:bradleygolden/ash_agent_stack.git

# Or if already cloned
git submodule update --init --recursive
```

## License

MIT License - see individual packages for details.
