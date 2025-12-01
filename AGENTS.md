# Ash Agent Stack

An Elixir umbrella project that bundles the Ash agent ecosystem. Each app in `apps/` is a git submodule with its own GitHub repository.

## Key Concepts

- **Reusable CI**: `.github/workflows/elixir-ci.yml` is a reusable workflow. Each submodule's CI calls it, so fixing the workflow here fixes all projects.
- **Shared Config**: `templates/` contains shared config files. `scripts/sync_config.sh` propagates them to all apps.
- **Submodule Workflow**: Changes inside a submodule must be committed/pushed in that submodule first, then the umbrella updated to reference the new commit.

# ExecPlans

When writing complex features or significant refactors, use an ExecPlan (as described in .agent/PLANS.md) from design to implementation.
