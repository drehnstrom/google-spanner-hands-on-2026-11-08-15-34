# Verify Current Facts (Do Not Trust Model Memory)

Model training data goes stale. APIs change, models are renamed and retired,
CLI flags move, consoles get redesigned, and prices change. A course that
teaches last year’s API breaks in class.

Technical Editor and Lab Tester **must** follow this file. Course Architect,
Course Generator, and Lab Generator should follow it when they have web or
tool access.

---

## 1. What needs verification

Verify claims that are **likely to change**:

| Category | Examples |
| :--- | :--- |
| API surface | Endpoint names, method signatures, request fields, SDK package names, import paths |
| Versions | Current release, minimum supported version, deprecations, end-of-life dates |
| CLI | Commands, subcommands, flags, default values, output format |
| AI models | Model names and IDs, context sizes, capabilities, availability by region |
| Console UI | Menu paths, button and field labels, wizard steps |
| Products | Product names after rebrands, feature availability (GA, preview), regions |
| Limits and pricing | Quotas, free tiers, prices, rate limits |

## 2. What does not need verification

Stable fundamentals: language syntax and semantics, core computer science
concepts, established design patterns, long-standing protocols (HTTP, SQL,
Git basics), and general practice advice. Do not spend lookups on these.

---

## 3. How to verify

Prefer sources in this order:

1. **The tool itself**: run `--help`, `--version`, or a harmless read-only command when you have the CLI.
2. **Official documentation and release notes** from the vendor.
3. **Official SDK source or changelog** (for example, the vendor’s GitHub repository).

Avoid blogs, forums, and other AI output as the only source.

Verify the claims that matter, not every word. Start with what students will
type or click, then anything a quiz answer depends on.

---

## 4. Recording what you checked

For each volatile claim you check, record:

- The file and slide title (or lab task and step)
- The claim
- Result: **confirmed**, **corrected**, or **unverified**
- Source URL (or the command you ran) and the date you checked

When you cannot verify a volatile claim (no web access, no credentials,
ambiguous docs), mark it **unverified** in the review log and leave it unchanged.
Do not guess, and do not invent a replacement.

When writing new content without verification, prefer wording that ages well
(“the current Gemini Pro model”) only if exact names do not matter for the
exercise. Exact commands and identifiers must be verified or flagged.
