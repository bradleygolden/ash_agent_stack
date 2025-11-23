defmodule AshAgentTools.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/bradleygolden/ash_agent_tools"

  def project do
    [
      app: :ash_agent_tools,
      version: @version,
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: dialyzer(),
      preferred_cli_env: [
        check: :test,
        precommit: :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {AshAgentTools.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Core dependencies
      {:ash, "~> 3.0"},
      {:spark, "~> 2.2"},
      {:req_llm, "~> 1.0"},

      # Local ash_agent dependency (will be published version later)
      {:ash_agent, path: "../ash_agent", in_umbrella: true},

      # Dev and test dependencies
      {:ex_doc, "~> 0.34", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
    Tool calling functionality for AshAgent - enables LLM agents to execute functions and Ash actions.
    """
  end

  defp package do
    [
      name: :ash_agent_tools,
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      },
      maintainers: ["Bradley Golden"],
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md"]
    ]
  end

  defp aliases do
    [
      precommit: ["check"],
      check: [
        "deps.get",
        "deps.compile",
        "deps.unlock --check-unused",
        "compile --warnings-as-errors",
        "test --warnings-as-errors",
        "format --check-formatted",
        "credo --strict",
        "dialyzer --format github",
        "docs --warnings-as-errors"
      ]
    ]
  end

  defp dialyzer do
    [
      plt_core_path: "priv/plts",
      plt_local_path: "priv/plts",
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      plt_add_apps: [:mix, :ex_unit]
    ]
  end
end
