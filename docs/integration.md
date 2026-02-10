# Integrating PCN in Your App

This guide explains how to integrate the PCN packages into your application: integration paths (Data360 preset vs custom data), dependencies, and what your app must provide.

## Summary

- **Framework**: React 18+ (for UI). The core (`@pcn-js/core`) can be used without React for HTML processing.
- **Data source**: Use the Data360 preset for Data360 get_data, or wire your own tool/output shape with `@pcn-js/core` + `@pcn-js/ui`.
- **Rendering**: Use `ClaimMark` where you display claim values; optionally use Streamdown/react-markdown and `streamdownClaimComponents` for `<claim>` tags in markdown.
- **Styling**: Optional; import `@pcn-js/ui/styles.css` for default claim/tooltip styles.

## Two Integration Paths

### Path A: Data360 preset (minimal setup)

If your app uses the **Data360** get_data API (tool results with `claim_id`, `OBS_VALUE`, `REF_AREA`, `TIME_PERIOD`):

1. Install: `@pcn-js/core`, `@pcn-js/ui`, `@pcn-js/data360`, `react` (and `react-dom` for the UI).
2. Wrap your app in `Data360ClaimsProvider`.
3. Ingest session data: use `IngestSessionData360` with `messages` and optional `initialMessages`.
4. When rendering a data360 get_data tool result, wrap it in `IngestToolOutput` with `toolName={DATA360_GET_DATA_TOOL}`.
5. Render claims with `ClaimMark` (and optionally `streamdownClaimComponents` for markdown).
6. Optional: `import "@pcn-js/ui/styles.css"` for default styles.

See [@pcn-js/data360](../packages/data360/README.md) for full usage.

### Path B: Custom data source (any tool/output shape)

If your tool results have a **different shape** (different keys, multiple tools, or non–Data360 APIs):

1. Install: `@pcn-js/core`, `@pcn-js/ui`, `react`, `react-dom`.
2. Create a `ClaimsManager` and register one or more **extractors** (e.g. `createDataPointExtractor` for array-of-points, or a custom `(result) => ClaimEntry[]`).
3. Wrap your app in `ClaimsProvider` with that manager.
4. When tool results arrive, call `manager.ingest(toolName, result)` (or use `IngestToolOutput` with your tool name).
5. Render claims with `ClaimMark` (same as Path A).
6. Optional: `import "@pcn-js/ui/styles.css"`.

See [@pcn-js/core](../packages/core/README.md) (Claims manager, Data point extractor) and [@pcn-js/ui](../packages/ui/README.md).

## Dependencies

| Package           | Peer / runtime           | Notes                                      |
|-------------------|--------------------------|--------------------------------------------|
| `@pcn-js/core`    | None (Node/browser)      | Can be used without React for HTML/claims. |
| `@pcn-js/ui`      | `react` ≥18, `react-dom` ≥18 | React components and context.          |
| `@pcn-js/data360` | `@pcn-js/core`, `@pcn-js/ui`, `react` ≥18 | Preset only; add if using Data360.   |

- **Build**: Packages publish ESM + CJS and types; works with Vite, Next.js, Webpack, etc.
- **No framework lock-in for core**: Use `ClaimsManager`, `createDataPointExtractor`, `compareByPolicy`, `extractClaimsFromHtml`, `processPCNClaims` in any JS/TS app (including non-React).

## What Your App Must Provide

1. **A React tree** (for UI): So that `ClaimsProvider` (or `Data360ClaimsProvider`) and `ClaimMark` can run.
2. **Tool/output ingestion**: When your backend or LLM returns tool results that contain claim data, you must either:
   - Use `IngestToolOutput` and render the tool result under it, or
   - Call `manager.ingest(toolName, result)` yourself (e.g. from `useEffect` or when messages update).
3. **Rendering of claim values**: Where you display a number (or other claimable value), use `<ClaimMark id={claimId} policy={policy}>…</ClaimMark>`. The `id` must match the `claim_id` (or equivalent) produced by your extractor.
4. **Message shape (if using session ingestion)**: `IngestSessionData360` expects messages with `parts` (e.g. AI SDK / data-thinking). For other shapes, use `extractData360Outputs` or implement your own ingestion from messages.

## Custom Extractors

Your tool might return something other than `{ data: [{ claim_id, OBS_VALUE, ... }] }`. You can:

- Use **`createDataPointExtractor(options)`** and map your keys: `dataKey`, `claimIdKey`, `valueKey`, `countryKey`, `dateKey`. Any key can be omitted.
- Or implement a **custom extractor**: `(result: unknown) => ClaimEntry[]`, where `ClaimEntry` is `{ id: string, claim: Claim }`. Register it with `manager.registerExtractor(toolName, yourExtractor)`.

Claims are keyed by `id`; the UI looks up by that id in `ClaimMark`.

## Optional Pieces

- **Styles**: `import "@pcn-js/ui/styles.css"` for default claim and tooltip styles. You can omit it and style `.pcn-claim`, `.verified-mark`, `.verify-pending`, `.pcn-claim-detail` yourself.
- **Streamdown / react-markdown**: Only if you render markdown that contains `<claim id="..." policy="rounded" decimals="2">…</claim>`. Use `streamdownClaimComponents` or `ClaimMarkStreamdown` from `@pcn-js/ui`. If claim tags do not render in production (0 claim nodes in DOM), see [Troubleshooting](troubleshooting.md#claim-tags-in-markdown-not-rendering-0-claim-nodes-in-dom).
- **Data360 package**: Only if you use the Data360 get_data API; otherwise use core + ui and your own extractor.

## Local Development (workspace / file: links)

If you depend on PCN via `file:../../pcn/packages/...` (e.g. in a monorepo):

1. Build the PCN packages after changing them: from the PCN repo run `pnpm build` in `packages/core`, `packages/ui`, and (if used) `packages/data360`.
2. In the consuming app, clear any bundler/cache (e.g. Next.js `.next`) and reinstall if your package manager copies instead of symlinking `file:` deps.
3. Resolve peer warnings if needed (e.g. pnpm `peerDependencyRules.allowedVersions` for `@pcn-js/core` / `@pcn-js/ui` when using file links).

## Summary Table

| Concern              | Supported? | Notes                                                |
|----------------------|-----------|------------------------------------------------------|
| Any React 18+ app    | Yes       | Use provider + ClaimMark + ingestion.                |
| Non-React app       | Core only | Use `ClaimsManager`, extractors, HTML helpers.       |
| Data360 API         | Yes       | Use `@pcn-js/data360` preset.                        |
| Other APIs/tools     | Yes       | Use core + ui + custom or data-point extractor.      |
| Styling              | Optional  | Default CSS or your own.                             |
| Markdown `<claim>`   | Optional  | Use streamdown/react-markdown + streamdown components. |
| Tooltip / delay      | Configurable | `ClaimMark` supports `tooltipHideDelayMs`.       |
