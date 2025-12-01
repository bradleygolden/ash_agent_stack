#!/usr/bin/env elixir

defmodule StackValidator do
  @apps_dir "apps"
  @required_files ["CLAUDE.md", "AGENTS.md", ".formatter.exs", "README.md"]
  @required_deps [:credo, :dialyxir, :ex_doc, :sobelow]

  def run do
    IO.puts("\n=== Ash Agent Stack Validation ===\n")

    apps = list_apps()

    results =
      for app <- apps do
        {app, validate_app(app)}
      end

    for {app, checks} <- results do
      print_app_result(app, checks)
    end

    IO.puts("\n=== Summary ===\n")

    total_apps = length(results)
    passing_apps = Enum.count(results, fn {_, checks} -> all_passing?(checks) end)

    IO.puts("Apps: #{passing_apps}/#{total_apps} passing")

    if any_failures?(results) do
      System.halt(1)
    end
  end

  defp list_apps do
    @apps_dir
    |> File.ls!()
    |> Enum.filter(&File.dir?(Path.join(@apps_dir, &1)))
    |> Enum.sort()
  end

  defp validate_app(app) do
    app_path = Path.join(@apps_dir, app)

    %{
      required_files: check_required_files(app_path),
      precommit_alias: check_precommit_alias(app_path),
      ci_workflow: check_ci_workflow(app_path),
      required_deps: check_required_deps(app_path),
      claude_md_content: check_claude_md_content(app_path)
    }
  end

  defp check_required_files(app_path) do
    missing =
      @required_files
      |> Enum.reject(fn file -> File.exists?(Path.join(app_path, file)) end)

    {missing == [], missing}
  end

  defp check_precommit_alias(app_path) do
    mix_exs = Path.join(app_path, "mix.exs")

    if File.exists?(mix_exs) do
      content = File.read!(mix_exs)
      {String.contains?(content, "precommit:"), nil}
    else
      {false, "mix.exs not found"}
    end
  end

  defp check_ci_workflow(app_path) do
    ci_path = Path.join([app_path, ".github", "workflows", "ci.yml"])
    {File.exists?(ci_path), nil}
  end

  defp check_required_deps(app_path) do
    mix_exs = Path.join(app_path, "mix.exs")

    if File.exists?(mix_exs) do
      content = File.read!(mix_exs)

      missing =
        @required_deps
        |> Enum.reject(fn dep -> String.contains?(content, ":#{dep}") end)

      {missing == [], missing}
    else
      {false, "mix.exs not found"}
    end
  end

  defp check_claude_md_content(app_path) do
    claude_md = Path.join(app_path, "CLAUDE.md")

    if File.exists?(claude_md) do
      content = File.read!(claude_md)
      {String.contains?(content, "@AGENTS.md"), nil}
    else
      {false, "CLAUDE.md not found"}
    end
  end

  defp print_app_result(app, checks) do
    status =
      if all_passing?(checks),
        do: IO.ANSI.green() <> "PASS" <> IO.ANSI.reset(),
        else: IO.ANSI.red() <> "FAIL" <> IO.ANSI.reset()

    IO.puts("#{app}: #{status}")

    for {check_name, {passed, details}} <- checks do
      indicator =
        if passed,
          do: IO.ANSI.green() <> "  [OK]" <> IO.ANSI.reset(),
          else: IO.ANSI.red() <> "  [!!]" <> IO.ANSI.reset()

      check_label = check_name |> Atom.to_string() |> String.replace("_", " ")

      case details do
        nil ->
          IO.puts("#{indicator} #{check_label}")

        list when is_list(list) and list != [] ->
          IO.puts("#{indicator} #{check_label}: missing #{inspect(list)}")

        msg when is_binary(msg) ->
          IO.puts("#{indicator} #{check_label}: #{msg}")

        _ ->
          IO.puts("#{indicator} #{check_label}")
      end
    end

    IO.puts("")
  end

  defp all_passing?(checks) do
    Enum.all?(checks, fn {_, {passed, _}} -> passed end)
  end

  defp any_failures?(results) do
    Enum.any?(results, fn {_, checks} -> !all_passing?(checks) end)
  end
end

StackValidator.run()
