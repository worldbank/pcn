# Troubleshooting

## Claim tags in markdown not rendering (0 claim nodes in DOM)

**Symptom:** Your backend or LLM returns markdown that contains raw `<claim id="..." policy="...">value</claim>` tags, and you pass `streamdownClaimComponents` (or `ClaimMarkStreamdown`) to Streamdown, but in the rendered page:

- No claim nodes appear (no checkmark, no tooltip).
- If you add diagnostic logging, the claim component is never invoked, and after render the DOM has 0 elements matching `[data-pcn-claim-id]` or `.pcn-claim`.

**Cause:** Streamdown uses **rehype-raw** (and other rehype plugins) by default to parse raw HTML in markdown into a hast tree. In some deployment or bundling setups (e.g. production builds, different bundler behavior), that default rehype pipeline may not be applied—for example due to tree-shaking or a different code path. When rehype-raw does not run, `<claim>...</claim>` stays as plain text and is never turned into nodes that react-markdown can pass to your `components.claim`.

**Fix:** Explicitly pass the rehype plugins to Streamdown so the pipeline (including rehype-raw) is always used, regardless of how the bundle is built:

```tsx
import { defaultRehypePlugins, Streamdown } from "streamdown";
import { streamdownClaimComponents } from "@pcn-js/ui";

// Build the plugin array from Streamdown’s defaults (harden, raw, katex).
const rehypePlugins = [
  ...(Array.isArray(defaultRehypePlugins)
    ? defaultRehypePlugins
    : [
        defaultRehypePlugins.harden,
        defaultRehypePlugins.raw,
        defaultRehypePlugins.katex,
      ].filter(Boolean)),
];

<Streamdown
  components={streamdownClaimComponents}
  rehypePlugins={rehypePlugins}
>
  {markdownContent}
</Streamdown>
```

This ensures raw HTML (including `<claim>`) is always parsed, so `components.claim` is invoked and claim nodes appear in the DOM.

**Optional diagnostics:** To confirm the issue, you can log before and after render when the content contains `<claim`: e.g. log the input snippet, whether `components.claim` is present, and after render query the wrapper for `[data-pcn-claim-id], .pcn-claim` and log the count. If the count is 0 and the claim component is never invoked, the fix above should resolve it.
