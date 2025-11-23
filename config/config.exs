import Config

# Shared umbrella configuration can live here.
# Pull in each app's own config to keep per-app settings intact.
for config <- Path.wildcard(Path.expand("../apps/*/config/config.exs", __DIR__)) do
  import_config config
end
