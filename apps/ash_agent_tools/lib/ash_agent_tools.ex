defmodule AshAgent.Tools do
  @moduledoc """
  Tool calling functionality for AshAgent.

  This library provides the tool execution system for AshAgent, enabling LLM agents to:
  - Execute Elixir functions
  - Call Ash resource actions
  - Use custom tool implementations

  ## Installation

  Add `ash_agent_tools` to your dependencies:

      def deps do
        [
          {:ash_agent, "~> 0.1"},
          {:ash_agent_tools, "~> 0.1"}
        ]
      end

  ## Usage

  Define tools in your agent resource:

      defmodule MyApp.CustomerAgent do
        use Ash.Resource,
          domain: MyApp.Domain,
          extensions: [AshAgent.Resource]

        agent do
          client "anthropic:claude-3-5-sonnet"
          output Reply
          prompt "You are a helpful customer service agent."
        end

        tools do
          max_iterations 5

          tool :get_customer do
            description "Retrieve customer information by ID"
            action {MyApp.Customers.Customer, :read}
            parameters [
              customer_id: [type: :uuid, required: true]
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
      end

  ## Architecture

  AshAgent.Tools is split from the core AshAgent library to:
  - Keep the core lightweight
  - Allow optional tool functionality
  - Enable separate versioning and evolution
  - Reduce dependencies for simple agents
  """
end
