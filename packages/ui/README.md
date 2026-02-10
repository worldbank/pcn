# @pcn-js/ui

React components and claims context for rendering PCN verified/pending claims in the UI.

## Install

```bash
pnpm add @pcn-js/core @pcn-js/ui react
```

## Usage

For **Data360** get_data (claim_id, OBS_VALUE, REF_AREA, TIME_PERIOD), use the preset: [@pcn/data360](../data360/README.md). It provides `Data360ClaimsProvider` and `DATA360_GET_DATA_TOOL`.

### 1. Claims manager + provider

Create a `ClaimsManager`, register extractors for tools that return `claim_id`, and wrap your app (or chat) in `ClaimsProvider` so components can look up claims.

```tsx
import { ClaimsManager, createDataPointExtractor } from "@pcn-js/core";
import { ClaimsProvider, ClaimMark, useClaimsManager } from "@pcn-js/ui";

const manager = new ClaimsManager();

// When get_data returns { data: [{ claim_id, OBS_VALUE, REF_AREA, TIME_PERIOD, ... }] }
manager.registerExtractor(
  "get_data",
  createDataPointExtractor({
    dataKey: "data",
    claimIdKey: "claim_id",
    valueKey: "OBS_VALUE",
    countryKey: "REF_AREA",
    dateKey: "TIME_PERIOD",
  })
);

function App() {
  return (
    <ClaimsProvider manager={manager}>
      <Chat />
    </ClaimsProvider>
  );
}
```

### 2. Ingest tool results

When a tool result arrives, either use the **IngestToolOutput** component (works with any provider, including Data360’s `Data360ClaimsProvider`):

```tsx
<IngestToolOutput toolName="get_data" output={toolResult}>
  <YourToolOutputUI output={toolResult} />
</IngestToolOutput>
```

Or call `manager.ingest(toolName, result)` yourself:

```tsx
function Chat() {
  const manager = useClaimsManager();

  useEffect(() => {
    if (toolName === "get_data") manager?.ingest("get_data", toolResult);
  }, [toolName, toolResult, manager]);

  return (/* ... */);
}
```

### 3. Render claims with ClaimMark

Use `ClaimMark` where you render claim content (e.g. as a custom component for `<claim>` in your markdown renderer). It looks up the claim by id, runs the policy comparison, and renders the content plus ✓ or ⚠. Hovering (or focusing) the mark shows a tooltip with claim details (country, date, source value, display rule).

```tsx
import { ClaimMark } from "@pcn-js/ui";

// In your markdown components or stream renderer:
<ClaimMark id={claimId} policy={{ type: "rounded", decimals: 0 }}>
  42
</ClaimMark>
```

**Tooltip behavior:** By default the tooltip stays open briefly (150 ms) after the pointer leaves the mark, so you can move the cursor onto the tooltip to read or copy. Set `tooltipHideDelayMs={0}` for immediate hide (original behavior), or a custom value (e.g. `300`) for a longer delay.

### 4. Streamdown / react-markdown (tables and markdown)

If you use **Streamdown** or **react-markdown** with **rehype-raw**, pass the built-in claim component so raw HTML `<claim>` tags are rendered as `ClaimMark` and tables/layout stay intact:

```tsx
import { Streamdown } from "streamdown";
import { streamdownClaimComponents } from "@pcn-js/ui";

<Streamdown components={streamdownClaimComponents}>
  {markdownContent}
</Streamdown>
```

Or use the component directly: `components={{ claim: ClaimMarkStreamdown }}`. The model can emit markdown with `<claim id="..." policy="rounded" decimals="2">3439.1</claim>` inside table cells or paragraphs.

**If claim tags don’t render in production** (e.g. 0 claim nodes in the DOM), the rehype pipeline may not be applied by the bundler. Explicitly pass `rehypePlugins` using Streamdown’s `defaultRehypePlugins`; see [Troubleshooting — Claim tags in markdown not rendering](../../docs/troubleshooting.md#claim-tags-in-markdown-not-rendering-0-claim-nodes-in-dom) in the docs.

### Static claims (no manager)

If you have a fixed map of claims (e.g. from server props), pass `initialClaims` and omit `manager`:

```tsx
<ClaimsProvider initialClaims={claimsMap}>
  <Content />
</ClaimsProvider>
```

## API

- **IngestToolOutput** – ingests a tool result into the manager when mounted; `toolName`, `output`, `children`
- **ClaimsProvider** – `manager?: ClaimsManager`, `initialClaims?: Record<string, Claim>`, `children`
- **useClaims()** – returns `Record<string, Claim>`
- **useClaimsManager()** – returns `ClaimsManager | null`
- **useClaim(id)** – returns `Claim | undefined`
- **ClaimMark** – `id`, `policy`, `children` (the displayed text to verify), optional `tooltipHideDelayMs?: number` (ms before hiding tooltip on leave; default 150; use 0 for immediate hide)
- **ClaimMarkStreamdown** – component for react-markdown/Streamdown `components.claim` (props: id, policy, decimals, tolerance, children from raw HTML)
- **streamdownClaimComponents** – `{ claim: ClaimMarkStreamdown }` for `<Streamdown components={streamdownClaimComponents}>`

Optional styles: `import "@pcn-js/ui/styles.css"` for `.pcn-claim`, `.verified-mark`, `.verify-pending`.
