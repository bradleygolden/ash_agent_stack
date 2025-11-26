# AshAgent Stack

The AshAgent ecosystem for building production AI agents in Elixir.

## Packages

| Package | Description | Status |
|---------|-------------|--------|
| [ash_agent](https://github.com/bradleygolden/ash_agent) | Core agent framework with declarative DSL, provider abstraction, and Ash integration | Pre-release |
| [ash_baml](https://github.com/bradleygolden/ash_baml) | BAML integration for structured LLM outputs | Pre-release |
| [ash_agent_tools](https://github.com/bradleygolden/ash_agent_tools) | Tool calling support for agents | In Development |
| [ash_agent_marketplace](https://github.com/bradleygolden/ash_agent_marketplace) | Marketplace for sharing and discovering agents | In Development |
| [ash_agent_studio](https://github.com/bradleygolden/ash_agent_studio) | Visual studio for building and testing agents | In Development |

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
            |
            +-- ash_agent_marketplace (agent sharing)
            |
            +-- ash_agent_studio (visual builder)
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
