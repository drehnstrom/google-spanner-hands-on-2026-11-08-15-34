# Course Graphics Designer — Visual Patterns

Copy these patterns when polishing decks for the HTML Slides Viewer.
Viewer syntax must match [../../course-generator/examples/layout-templates.md](../../course-generator/examples/layout-templates.md)
and pass [../../shared/slide-markdown-rules.md](../../shared/slide-markdown-rules.md).

**SVG quality bar:** before creating or replacing a diagram, read
[../../shared/svg-craft.md](../../shared/svg-craft.md). Layout recipes below
(auto-split, stacked, title-image) are fine. The old three-box SVG starter is
gone on purpose; do not recreate it.

---

## 1. Media choice cheat sheet

| Need | Choose | Example filename |
| :--- | :--- | :--- |
| Spatial / mechanical picture that still teaches muted | SVG (must pass svg-craft.md) | `images/ch01-grid-to-classes.svg` |
| Parallel options (no picture needed) | `2-column` / `card-layout`, skip the SVG | — |
| Team collaboration metaphor | Generated photo (`1:1` or `16:9`) | `images/ch01-pair-programming.jpg` |
| Complex infographic scene | Generated (`16:9`), minimal text | `images/ch04-pipeline-overview.png` |
| Cloud console step | Screenshot or TODO | `images/ch02-s3-versioning-screenshot.png` |

---

## 2. Auto-split (square side image)

**When:** thesis bullets plus a supporting diagram or photo on the right.  
**Shape:** square (`1:1`).

```markdown
# Remote Backend Shape

- **Bucket / container** stores state objects
- **Lock table** prevents concurrent writes
- **IAM / identity** scopes least privilege
- **Encryption** at rest is mandatory

![Remote backend shape](images/ch02-remote-backend-shape.svg)
```

No `<!-- layout: … -->` comment. List + image triggers auto-split.

---

## 3. Stacked (wide image under bullets)

**When:** short bullets need a wide flow or timeline underneath.  
**Shape:** wide (`16:9` or `4:3`).

```markdown
<!-- layout: stacked -->
# Plan, Apply, Repeat

- Plan shows the blast radius before you change anything
- Apply makes the real change once the plan looks right
- The loop is how teams stay safe at speed

![Plan apply loop](images/ch01-plan-apply-loop.svg)
```

---

## 4. Title-image / image-only (16:9 hero diagram)

**When:** the diagram is the teaching point.

```markdown
<!-- layout: title-image -->
# Reference Architecture

![Reference architecture](images/ch02-reference-architecture.svg)
```

```markdown
<!-- layout: image-only -->
# Reference Architecture

![Reference architecture](images/ch02-reference-architecture.svg)
```

`image-only` hides the on-stage title but keeps the `#` heading for the slide tray. Use **16:9** assets.

---

## 5. Full-bleed mood slide (16:9, use sparingly)

```markdown
<!-- layout: full-bleed -->
# Why State Discipline Matters

![Operations center](images/ch02-state-discipline-bleed.jpg)
```

Keep the subject centered; edges may crop. Prefer generated photos with **no embedded text**.

---

## 6. Panel side art (tall or square)

Intro slides already use stock panel images. For a rare content-chapter panel:

```markdown
<!-- layout: panel-right -->
# When Local State Is Enough

- Solo prototypes on one laptop
- Throwaway sandboxes you will never share
- Learning labs before the team backend exists

![Local state](images/ch02-local-state-panel.svg)
```

**Shape:** tall (`3:4`) or square (`1:1`). Do **not** replace `welcome.png` / `agenda.png` / `who-should-attend.png` / `prerequisites.png`.

---

## 7. Columns and cards (usually no images)

Use for parallel text options. Do not force a diagram into these layouts.

```markdown
<!-- layout: 2-column -->
# Local vs Remote State

### Local
- Fast for solo prototypes
- No team sharing
- Easy to lose or overwrite

### Remote
- Shared source of truth
- State locking
- Audit-friendly workflows
```

```markdown
<!-- layout: card-layout -->
# Choose a Backend Shape

### Locking
- Concurrent writes must be blocked before they corrupt state.

### Durability
- State belongs in a service with versioning and encryption at rest.

### Access
- Grant the pipeline identity only what it needs to read and write state.
```

If students also need a picture, add a **follow-on** auto-split, stacked, or title-image slide.

---

## 8. Screenshot placeholder

```markdown
# Enable Bucket Versioning

- Turn on versioning before migrating state
- Confirm the setting in the cloud console

<!-- TODO IMAGE: Screenshot of AWS S3 console showing bucket versioning enabled -->
![S3 versioning console](images/ch02-s3-versioning-screenshot.png)
```

Acceptable outcome: wired path + clear TODO for the human. Do not fake the console with image generation when accuracy matters.

---

## 9. SVG: weak vs strong (same slide)

Do **not** copy a three-box flow. Source of truth and accept/reject snippets:
[../../shared/svg-craft.md](../../shared/svg-craft.md).

**Before (weak):** slide title “Features In, Label Out.” Graphic is three rounded
navy cards labeled `X`, `f(X)`, `y`, gray canvas, orange arrows, a banner that
repeats the heading. A human deletes this.

```markdown
<!-- layout: stacked -->
# Features In, Label Out

- Features are a vector `X`
- The model is a function `f`
- The label is `y`

![Features in, label out](images/ch01-x-to-y.svg)
```

**After (strong):** the picture **is** the mapping. Transparent canvas. ROI Alt
colors. Labels are `8 x 8`, `64`, `10`. No title in the SVG.

```markdown
<!-- layout: stacked -->
# Features In, Label Out

- An 8-by-8 digit is 64 numbers, not a picture the model “sees”
- `Linear(64, 10)` maps that vector onto ten class scores
- The largest score is the predicted digit

![Eight by eight pixels flatten to 64 values, then a weight band lights one of ten classes](images/ch01-grid-to-classes.svg)
```

If the idea is just two named options (train vs test as bullet lists), skip the
SVG and use `2-column`. Only draw when the object itself (pile vs sealed stack)
carries the contrast.

---

## 10. Before / after thinking (layout pacing)

**Before (weak):** four default bullet slides in a row, no visuals.

**After (stronger):**

1. Default thesis slide (text)
2. Auto-split with a square SVG that passes svg-craft.md
3. `2-column` comparison (text, no diagram of labeled cards)
4. `stacked` wide diagram that encodes the concept
5. `title-image` closer when the picture is the teaching point

Same teaching points; better pacing and retention. Never fill a pacing gap with
rounded rectangles.
