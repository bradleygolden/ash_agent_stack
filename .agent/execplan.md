# Split tool-calling into ash_agent_tools

This ExecPlan is a living document. Maintain all sections per `.agent/PLANS.md`.

## Purpose / Big Picture

Make `ash_agent` a provider-agnostic core that only renders prompts, calls LLMs, and maintains iteration context on resources, with zero knowledge of tools. All tool DSL, execution loops, and provider adapters should live in `ash_agent_tools`, which plugs into the context attribute supplied by the core. After this change, configuring tools without the extension yields a clear error; with the extension present, agents can loop through tool calls while storing tool-related context alongside the base conversation.

## Progress

- [x] (2025-11-23 17:35Z) Reviewed ash_agent tool pipeline (DSL, ToolConverter, ToolExecutor, Runtime loop) and provider registry to understand current coupling.
- [x] (2025-11-23 17:40Z) Noted AGENTS.md constraints (no new code comments in ash_agent/ash_baml; avoid @spec there) and submodule state for ash_agent_tools.
- [x] (2025-11-23 17:45Z) Created feature branch `tool-split-runtime` for ash_agent changes to comply with branch rule.
- [x] (2025-11-23 17:48Z) Scaffolded ash_agent_tools Mix app with supervisor using `mix new . --sup` inside submodule.
- [x] (2025-11-23 18:10Z) Ported initial tool infrastructure into ash_agent_tools (Tool, ToolConverter, Tools.Function/AshAction, DSL.Tools, ToolRegistry, ResultProcessors, ProgressiveDisclosure, ToolExecutor); context integration is still missing.
- [x] (2025-11-23 18:47Z) Re-scanned both apps: ash_agent still owns full tool DSL/runtime and provider hooks; ash_agent_tools contains duplicated modules plus references to a missing Context module and lacks runtime wiring to the core.
- [x] (2025-11-23 19:01Z) Added ash_agent_tools resource/info/runtime scaffolding (tools extension, Info helpers, runtime copy) and delegated ash_agent Runtime call/stream to ash_agent_tools when tools are present; removed tool sections from ash_agent resource and tool validation check from ValidateAgent.
- [x] (2025-11-23 19:08Z) Gated ash_baml dependency via env in ash_agent and ash_agent_tools, adjusted dynamic references to AshAgentTools to avoid compile warnings, and aligned tool DSL injection to load only when ash_agent_tools is present.
- [x] (2025-11-23 23:45Z) Re-reviewed code: ash_agent_tools runtime references undefined modules and lacks context implementation; ash_agent test suite still asserts tool behaviors that no longer exist in core; need to relocate tool tests/contexts into ash_agent_tools and clean delegation errors.
- [x] (2025-11-23 23:58Z) Added tool-aware Context wrapper and integration test in ash_agent_tools, moved tool DSL/result processor/registry/executor tests out of ash_agent, and made ash_agent Runtime error when tools are configured without a registered tool runtime.
- [x] (2025-11-24 01:45Z) Re-audited runtime delegation and found ash_agent still introspecting the :tools DSL directly; decided to move detection to a persisted flag and tool-runtime `handles?/1` predicate owned by ash_agent_tools.
- [x] (2025-11-24 01:46Z) Wired the persisted marker and runtime predicate, added regression tests for missing tool runtime and marker presence, and reran `mise run precommit`.
- [ ] Finalize design for a tool-agnostic ash_agent core and a tool-only ash_agent_tools extension in this plan.
- [ ] Implement ash_agent_tools provider adapters and runtime (context behaviour-driven loop).
- [ ] Refactor ash_agent core: add context behaviour/config, delegate tool paths, update docs/tests.
- [ ] Validate with test runs (`mix test` / `mix check`) in ash_agent_tools and ash_agent.

## Surprises & Discoveries

- ash_agent_tools ProgressiveDisclosure currently aliases a non-existent `AshAgentTools.Context`, so context compaction helpers would fail if invoked. Evidence: `lib/ash_agent_tools/progressive_disclosure.ex` imports Context, but no such module exists in the submodule.
- Running `mix test` in `apps/ash_agent_tools` compiled ash_agent (as a dependency) and then failed to start `ash_baml` because its .app file is missing when the env flag disables that dependency; need a strategy to prevent ash_baml from starting/compiling during tool tests or to stub it in test env.
- ash_agent core tests still expect tool helpers (`Context.add_tool_results/2`, tool converters, tool registries) that were removed from the core; they must move to ash_agent_tools to avoid reintroducing coupling. Evidence: `apps/ash_agent/test/ash_agent/context_test.exs` exercises add_tool_results/2 but the function no longer exists.
- Telemetry spans return `{result, metadata}`, so runtimes must unwrap to keep call-with-hooks pattern matching on `{:ok, result}` working.
- ash_agent runtime still checked `Extension.get_entities(module, [:tools])`, keeping core coupled to the tool DSL. Plan: replace detection with a persisted flag set by ash_agent_tools and a runtime predicate. Evidence: `AshAgent.Runtime.has_tools?/1`.

## Decision Log

- Decision: Perform any ash_agent edits from a feature branch to comply with instruction that non-root, non-ash_agent_tools apps must change off main. Root and ash_agent_tools changes can live on main if needed. Date/Author: 2025-11-23, Codex.
- Decision: Honor AGENTS.md in ash_agent and ash_baml by not adding new code comments or @specs unless required for a workaround; call this out in summaries. Date/Author: 2025-11-23, Codex.
- Decision: No backward-compatibility shims required because there are no production users; migrations can be breaking. Date/Author: 2025-11-23, Codex.
- Decision: Skip adding a dev/test dependency on ash_agent inside ash_agent_tools to avoid a dependency cycle once ash_agent depends on ash_agent_tools; rely on local stubs for integration-style tests. Date/Author: 2025-11-23, Codex.
- Decision: Context stays in ash_agent core but is tool-agnostic: define a minimal context behaviour (iterations/messages/token tracking only, no tool-specific helpers like add_tool_results/2). ash_agent_tools implements/extends that behaviour with tool-aware functions. This keeps tools out of ash_agent core while preserving a pluggable context surface. Date/Author: 2025-11-23, Codex.
- Decision: Treat existing tool modules in ash_agent as source material to relocate into ash_agent_tools, trimming ash_agent to only provider calls, hooks, and context lifecycle. Date/Author: 2025-11-23, Codex.
- Decision: Introduce `AshAgentTools.Context` implementing the core context behaviour plus tool-result helpers, and migrate tool-focused tests/docs into ash_agent_tools; ash_agent tests will cover only core behaviors and should error when tools are configured without the extension. Date/Author: 2025-11-23, Codex.
- Decision: Remove ash_agent’s direct knowledge of the :tools DSL by relying on a persisted marker and a tool-runtime `handles?/1` predicate registered by ash_agent_tools, keeping delegation logic extensible without DSL coupling. Date/Author: 2025-11-24, Codex.

## Outcomes & Retrospective

- To be completed after implementation.

## Context and Orientation

Repository is an Elixir umbrella with submodules for each app (`apps/ash_agent`, `apps/ash_agent_tools`, `apps/ash_agent_ui`, `apps/ash_baml`). Branch `tool-split-runtime` is active. ash_agent now exposes a tool-agnostic core: agent DSL/resource extension, context behaviour, runtime registry, telemetry helpers, providers (req_llm/mock/baml), and runtime delegation that errors when tools are configured without a registered tool runtime. ash_agent_tools owns the tool DSL/extension, tool-aware context wrapper, converters/registries/result processors, tool executor, and the multi-turn runtime plus a stub-provider integration test. AGENTS.md in ash_agent and ash_baml forbids adding new code comments or @specs unless strictly necessary; acknowledge this when proposing edits. Goal remains to keep tools out of ash_agent while letting ash_agent_tools plug in cleanly.

## Plan of Work

Explainable sequence to deliver the split:
1. Clarify desired architecture in this plan: ash_agent owns context lifecycle (iterations/messages/token usage) and provider calls; ash_agent_tools owns tool DSL, registry, execution loop, provider adapters, and tool-specific context augmentation. Document how tool context is stored in the core context attribute (e.g., additional fields per iteration) without adding comments to ash_agent code.
2. Stabilize ash_agent_tools foundations: reconcile duplicated modules, add the missing Context implementation that wraps/extends the ash_agent context behaviour, and ensure mix config reflects optional req_llm/ash_baml deps plus docs/testing settings. Remove or rewrite placeholder modules (e.g., AshAgentTools.hello/0) to match the intended API surface.
3. Implement provider adapters inside ash_agent_tools (ReqLLM, BAML) that format tools, invoke providers, and extract tool calls/content from responses or streams, handling absent optional deps with clear errors. Provide a provider capability contract (behaviour or module) for adapters.
4. Move the multi-turn tool loop out of ash_agent into ash_agent_tools (new `AshAgentTools.Runtime`), reusing AshAgentHooks/Prompt rendering where appropriate via well-defined interfaces. The loop should read/write the shared context attribute, append tool call metadata, and return the same result shape ash_agent currently emits.
5. Strip tool knowledge from ash_agent: remove tool DSL inclusion from `AshAgent.Resource` unless ash_agent_tools exposes it, update transformers (`AddContextAttribute`, `ValidateAgent`, etc.) and `AshAgent.Info` to become tool-agnostic, and have `AshAgent.Runtime` delegate tool-enabled calls to ash_agent_tools (or raise a helpful missing-dep error). Ensure provider registry and docs mention only core capabilities.
6. Align DSL and configuration: ensure tool sections live in ash_agent_tools and are imported into resources/domains only when the extension is present. Validate compile-time error surfaces when a user declares tools without the extension added to deps.
7. Update documentation and tests: ash_agent README should emphasize core-only scope and point to ash_agent_tools for tool support; ash_agent_tools README should describe setup and usage. Add tests in both packages covering: core single-call flow; error path when tools configured without extension; tool execution loop with mock provider; provider adapters handling missing deps gracefully.
8. Validation pass: run `mix test` (or `mix check` if feasible) in both apps, and include a small end-to-end scenario in ash_agent_tools that shows tool calls updating context and producing a final result.

## Concrete Steps

- Keep work on branch `tool-split-runtime` for ash_agent edits. Use repo root for commands unless noted.
- Audit ash_agent_tools contents and remove placeholder exports (`AshAgentTools.hello/0`), fill the missing Context implementation, and ensure mix.exs optional deps/aliases/docs are accurate. Guard optional deps (req_llm, ash_baml) so compilation succeeds without them.
- Implement provider adapter behaviour and concrete adapters under `apps/ash_agent_tools/lib/ash_agent_tools/adapters/*.ex`, using provider APIs directly without modifying ash_agent.
- Move the tool loop from `apps/ash_agent/lib/ash_agent/runtime.ex` into a new runtime module in ash_agent_tools; adjust hooks/context usage to consume the core context behaviour. Re-home tool DSL/entities and helpers into ash_agent_tools namespaces and rewire references internally.
- Update ash_agent: make Resource/Domain extensions import tool DSL only when ash_agent_tools is available, strip tool-only code paths, and delegate tool-enabled execution to ash_agent_tools with a clear missing-dependency error message. Keep code comment constraints in mind.
- Rewrite docs: core README describes core-only scope; ash_agent_tools README explains adding the dependency and defining tools. Add/adjust tests for both packages to cover delegation, error handling, and successful tool execution with mocks.
- Run `mix test` (or `mix check` if feasible) inside `apps/ash_agent_tools` and `apps/ash_agent`, capturing results in Progress.

## Validation and Acceptance

Success criteria:
- `mix test` (and `mix check` if practical) pass in `apps/ash_agent_tools` with optional deps guarded.
- `mix test` (and ideally `mix check`) pass in `apps/ash_agent` after delegating tool logic out.
- Declaring tools without adding `:ash_agent_tools` raises a clear compile-time or runtime error with remediation.
- With ash_agent_tools present, a tool-enabled agent runs through at least one tool call, updates context iterations with tool metadata, and returns the final result via the new runtime.

## Idempotence and Recovery

- Guard optional deps so repeated compiles succeed even when req_llm/ash_baml are absent; adapter functions should return actionable errors rather than crashing.
- Delegation from ash_agent to ash_agent_tools should be feature-flagged so agents without tools continue to work unaffected; retries only require re-running tests after code changes.
- Work remains on branch `tool-split-runtime`, keeping main clean; if a step fails, revert that commit locally without touching unrelated submodule changes.

## Artifacts and Notes

- Keep notable command outputs (test summaries, error messages for missing ash_agent_tools) appended here during implementation for future contributors.

## Interfaces and Dependencies

- `AshAgent` exposes a tool-agnostic context behaviour and default context resource that tracks iterations/messages/usage but not tool calls. Tool DSL is removed or only injected via ash_agent_tools.
- `AshAgentTools.Runtime` accepts the same config/context inputs currently used in ash_agent’s tool loop and returns `{:ok, result}` or `{:error, reason}` plus updated context. It owns tool iteration handling, tool result injection, and telemetry hooks.
- `AshAgentTools.ProviderAdapter` (behaviour) plus concrete adapters (ReqLLM, BAML) format tool definitions, call providers, and extract tool calls/content. Adapters return tool calls as maps with `id`, `name`, and `arguments` fields and tolerate missing optional deps gracefully.
- Tool modules now live under `AshAgentTools.*` (Tool, ToolConverter, Tools.Function/AshAction, ToolRegistry, ProgressiveDisclosure, ResultProcessors.*, Runtime.ToolExecutor). ash_agent references them only through the extension boundary.

Revision Note (2025-11-23): Updated plan after re-reviewing ash_agent and ash_agent_tools to emphasize making ash_agent tool-agnostic, documenting the missing Context in ash_agent_tools, and reshaping the work plan around relocating tool logic into the extension.
Revision Note (2025-11-24): Recorded the plan to decouple ash_agent runtime delegation from the tool DSL by using a persisted marker and a tool-runtime predicate supplied by ash_agent_tools.
