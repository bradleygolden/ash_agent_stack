#!/usr/bin/env elixir

defmodule StackSync do
  @apps_dir "apps"
  @templates_dir "priv/templates"

  @syncable_files %{
    "ci" => {".github/workflows/ci.yml", "ci.yml.eex"},
    "credo" => {".credo.exs", "credo.exs.eex"},
    "agents" => {"AGENTS.md", "AGENTS.md.eex"},
    "claude" => {"CLAUDE.md", "CLAUDE.md.eex"}
  }

  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        switches: [app: :string, file: :string, dry_run: :boolean, force: :boolean]
      )

    apps = if opts[:app], do: [opts[:app]], else: list_apps()

    files =
      if opts[:file] do
        case Map.fetch(@syncable_files, opts[:file]) do
          {:ok, _} ->
            [opts[:file]]

          :error ->
            IO.puts(
              "Unknown file type: #{opts[:file]}. Valid types: #{Map.keys(@syncable_files) |> Enum.join(", ")}"
            )

            System.halt(1)
        end
      else
        Map.keys(@syncable_files)
      end

    for app <- apps, file_type <- files do
      sync_file(app, file_type, opts)
    end

    IO.puts("\nSync complete!")
  end

  defp list_apps do
    @apps_dir
    |> File.ls!()
    |> Enum.filter(&File.dir?(Path.join(@apps_dir, &1)))
    |> Enum.sort()
  end

  defp sync_file(app, file_type, opts) do
    {dest_path, template_name} = @syncable_files[file_type]
    app_path = Path.join(@apps_dir, app)
    full_dest = Path.join(app_path, dest_path)
    template_path = Path.join(@templates_dir, template_name)

    if File.exists?(template_path) do
      assigns = build_assigns(app)
      new_content = render_template(template_path, assigns)

      cond do
        opts[:dry_run] ->
          show_diff(app, file_type, full_dest, new_content)

        !File.exists?(full_dest) ->
          create_file(full_dest, new_content)
          IO.puts("  Created #{full_dest}")

        opts[:force] ->
          update_file(full_dest, new_content)
          IO.puts("  Updated #{full_dest}")

        !content_matches?(full_dest, new_content) ->
          IO.puts("  #{full_dest} differs from template (use --force to overwrite)")

        true ->
          IO.puts("  #{full_dest} is up to date")
      end
    else
      IO.puts("Template not found: #{template_path}")
    end
  end

  defp build_assigns(app) do
    [
      app_name: app,
      app_module: Macro.camelize(app)
    ]
  end

  defp render_template(template_path, assigns) do
    template_path
    |> File.read!()
    |> EEx.eval_string(assigns: assigns)
  end

  defp show_diff(app, file_type, path, new_content) do
    IO.puts("\n[#{app}] #{file_type}:")

    if File.exists?(path) do
      old_content = File.read!(path)

      if old_content == new_content do
        IO.puts("  No changes needed")
      else
        IO.puts("  Would update #{path}")
        IO.puts("  - Current: #{String.length(old_content)} bytes")
        IO.puts("  + New: #{String.length(new_content)} bytes")
      end
    else
      IO.puts("  Would create #{path}")
    end
  end

  defp content_matches?(path, new_content) do
    File.read!(path) == new_content
  end

  defp create_file(path, content) do
    path |> Path.dirname() |> File.mkdir_p!()
    File.write!(path, content)
  end

  defp update_file(path, content) do
    File.write!(path, content)
  end
end

StackSync.run(System.argv())
