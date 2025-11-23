# AshAgentTools

Tool calling functionality for [AshAgent](https://github.com/bradleygolden/ash_agent).

This library provides the tool execution system for AshAgent, enabling LLM agents to interact with external systems by executing Elixir functions and Ash resource actions.

## Installation

Add `ash_agent_tools` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ash_agent, "~> 0.1"},
    {:ash_agent_tools, "~> 0.1"}
  ]
end
```

## Usage

Define tools in your agent resource using the `tools` DSL:

```elixir
defmodule MyApp.CustomerAgent do
  use Ash.Resource,
    domain: MyApp.Domain,
    extensions: [AshAgent.Resource]

  defmodule Reply do
    use Ash.TypedStruct

    typed_struct do
      field :content, :string, enforce: true
    end
  end

  agent do
    client "anthropic:claude-3-5-sonnet"
    output Reply
    prompt "You are a helpful customer service agent."
  end

  tools do
    max_iterations 5
    timeout 60_000
    on_error :continue

    tool :get_customer do
      description "Retrieve customer information by ID"
      action {MyApp.Customers.Customer, :read}
      parameters [
        customer_id: [type: :uuid, required: true, description: "The customer's ID"]
      ]
    end

    tool :send_email do
      description "Send an email to a customer"
      function {MyApp.Email, :send, []}
      parameters [
        to: [type: :string, required: true],
        subject: [type: :string, required: true],
        body: [type: :string, required: true]
      ]
    end
  end

  code_interface do
    define :call, args: [:message]
  end
end
```

Then call your agent:

```elixir
{:ok, reply} = MyApp.CustomerAgent.call("What is the email for customer 123?")
```

The agent will automatically:
1. Recognize it needs the customer's information
2. Call the `get_customer` tool with the customer ID
3. Use the result to draft an email
4. Return the final response

## Tool Types

### Ash Action Tools

Execute Ash resource actions:

```elixir
tool :get_customer do
  description "Retrieve customer information"
  action {MyApp.Customers.Customer, :read}
  parameters [
    customer_id: [type: :uuid, required: true]
  ]
end
```

### Function Tools

Execute Elixir functions:

```elixir
tool :send_email do
  description "Send an email"
  function {MyApp.Email, :send, []}
  parameters [
    to: [type: :string, required: true],
    subject: [type: :string, required: true],
    body: [type: :string, required: true]
  ]
end
```

Anonymous functions are also supported:

```elixir
tool :calculate do
  description "Perform a calculation"
  function fn args, _context ->
    {:ok, %{result: args.x + args.y}}
  end
  parameters [
    x: [type: :integer, required: true],
    y: [type: :integer, required: true]
  ]
end
```

## Configuration

Configure tool behavior in the `tools` block:

```elixir
tools do
  max_iterations 10  # Maximum tool-calling iterations (default: 10)
  timeout 30_000     # Tool execution timeout in ms (default: 30_000)
  on_error :continue # :continue or :halt on tool errors (default: :continue)

  tool :my_tool do
    # ...
  end
end
```

## Result Processors

AshAgent.Tools includes result processors for handling large tool outputs:

```elixir
alias AshAgent.Tools.ResultProcessors.{Truncate, Sample, Summarize}

# Truncate large results
Truncate.process(results, max_size: 1000)

# Sample items from lists
Sample.process(results, sample_size: 5, strategy: :first)

# Summarize complex data structures
Summarize.process(results, sample_size: 3)
```

## Architecture

AshAgent.Tools is split from the core AshAgent library to:
- Keep the core lightweight for simple agents
- Allow optional tool functionality
- Enable separate versioning and evolution
- Reduce dependencies when tools aren't needed

## License

MIT License. See LICENSE for details.
