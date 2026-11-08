# Slide Markdown Rules (HTML Slides Viewer)

**Every skill that creates or edits slide Markdown must follow this file.** That
includes Course Spine Generator, Course Generator, Instructor Review, Course
Graphics Designer, Technical Editor, and Copy Editor.

The [HTML Slides Viewer](https://slidesv.roitraining.com/) parses these files
directly. A missing `---`, a bad layout comment, or a broken code fence breaks
the deck in front of a class. These rules are hard gates, not style preferences.

Copy-paste syntax for every layout lives in
[../course-generator/examples/layout-templates.md](../course-generator/examples/layout-templates.md).
Required slide order lives in [course-spine.md](course-spine.md).

---

## 1. File metadata

Put both comments at the top of **every** chapter file, identical across files:

```markdown
<!-- course-title: 815: Hands-On Terraform -->
<!-- course-theme: roi-alt-theme -->
```

- `course-title` drives the viewer footer.
- `course-theme` sets the default theme. **Default is `roi-alt-theme`.** Put the theme comment immediately after `course-title` in every chapter file. Do not use `roi-theme` unless the user asks for it.
- A single-file short course has them once at the top.

---

## 2. Slide structure

- Separate slides with a lone `---` line (nothing else on the line).
- Do not add, remove, or merge `---` separators unless you mean to change the slide count.
- Each slide has one `#` heading. It is the slide title and the drawer label, even on `image-only` and `full-bleed` slides where it is hidden.
- Put layout comments on their own line, directly above the `#` heading.
- Never nest HTML comments.

---

## 3. Valid layout directives

Use only these. Do not invent new ones.

| Layout | Directive (aliases) | Use when |
| :--- | :--- | :--- |
| Title | `<!-- layout: title -->` | Course cover and chapter dividers |
| Navigation | `<!-- layout: navigation -->` | Section orientation; bold exactly one active item |
| Content | *(omit)* | Default vertical bullets, short code, tables, alerts |
| Auto-split | *(omit)* | Same slide has a bullet list **and** an image: list left, image right |
| Two-column | `<!-- layout: 2-column -->` (`two-column`) | Compare two items. Columns start at `###` |
| Three-column | `<!-- layout: 3-column -->` (`three-column`) | Three parallel options. Columns start at `###` |
| Card layout | `<!-- layout: card-layout -->` (`cards`, `card`) | Each `###` is a card; dash items render as sentences. Three in a row, four in a 2-by-2 grid |
| Title-image | `<!-- layout: title-image -->` | One large diagram or screenshot with a title |
| Image-only | `<!-- layout: image-only -->` (`image`) | Full-stage image, no visible title; top bar and footer stay |
| Panel left | `<!-- layout: panel-left -->` (`left-panel`) | Colored left third with a centered image; text in the light area |
| Panel right | `<!-- layout: panel-right -->` (`right-panel`) | Same, colored third on the right |
| Full-bleed | `<!-- layout: full-bleed -->` (`bleed`) | Image covers the whole 16:9 slide, including top bar and footer |
| Stacked | `<!-- layout: stacked -->` (`stack`) | Content on top, wide image below; disables auto-split |

Column and card helpers:

- `<!-- below-columns -->` after the last column puts a following alert full width under the columns (2-column and 3-column).
- Do not put images inside `2-column`, `3-column`, or `card-layout` slides. Use auto-split, `stacked`, `title-image`, or `image-only`.

Variety rule: no more than **3 default content slides in a row**.

---

## 4. Callouts (alerts)

Only these five tags. Blockquote syntax, tag alone on the first line:

```markdown
> [!NOTE]
> Remote state is shared. Coordinate before force-unlocking.
```

| Alert | Use for |
| :--- | :--- |
| `> [!NOTE]` | Context, background, expected results |
| `> [!TIP]` | Shortcuts and pro tips |
| `> [!IMPORTANT]` | Must-not-miss rules |
| `> [!WARNING]` | Pitfalls |
| `> [!CAUTION]` | Strong caution before a risky action |

Use callouts for real emphasis, not on every slide.

---

## 5. Code

- Every fenced block has a language tag: ` ```python `, ` ```bash `, ` ```hcl `, ` ```text `.
- Keep code short enough to read from the back of the room (about 15 lines or fewer per slide).
- Code and inline code keep straight quotes (`'` `"`) and exact syntax.

---

## 6. Typography (visible slide text and titles)

| Rule | Do | Don’t |
| :--- | :--- | :--- |
| Smart quotes | `Let’s`, `don’t`, `the “apply” step` | `Let's`, `"apply"` in prose |
| Ampersand | `and`, **Questions and Answers** | `&`, `Q&A` |
| Em-dash | Colon to explain (`Quiz 1: Answer`); hyphen ` - ` for a break (`slides - not a textbook`) | `—` (U+2014) |
| Bullet depth | Two levels max | Three or more nested levels |

These rules do not apply inside code fences, inline code, URLs, file paths, or HTML comments.

---

## 7. Images

### Paths and names

- All course images live in the shared `images/` folder beside the chapter files.
- Reference with relative paths: `![Remote backend flow](images/ch02-remote-backend-flow.svg)`.
- Use descriptive filenames with a chapter prefix; never `image1.png`.
- Always write meaningful alt text.

### Stock images (reuse; never regenerate)

| File | Slide | Layout |
| :--- | :--- | :--- |
| `images/roi-logo-with-name.png` | Title and chapter dividers | `title` |
| `images/welcome.png` | Welcome! | `panel-right` |
| `images/agenda.png` | Agenda | `panel-left` |
| `images/who-should-attend.png` | Who Should Attend | `panel-right` |
| `images/prerequisites.png` | Prerequisites | `panel-left` |
| `images/qa.png` | Questions and Answers (optional) | `stacked` |

### Image shape by placement

| Placement | Layouts | Shape |
| :--- | :--- | :--- |
| Beside bullets | Auto-split | Square (`1:1`) |
| Panel fill | `panel-left`, `panel-right` | Tall (`3:4`) or square |
| Under content | `stacked` | Wide (`16:9` or `4:3`) |
| Dominant with title | `title-image` | Wide (`16:9`) |
| Alone on the stage | `image-only`, `full-bleed` | `16:9` |

### Missing or unverifiable images

When you cannot create an accurate asset (real product UI, branded captures), wire the image anyway and add a TODO for a human:

```markdown
<!-- TODO IMAGE: Screenshot of AWS S3 console showing bucket versioning enabled -->
![S3 versioning console](images/ch03-s3-versioning-screenshot.png)
```

- Never silently drop a needed visual.
- Never pass off a generated image as a real product screenshot.
- Never leave a broken image link without a TODO.

---

## 8. Conformance checklist

Run this after **any** edit to slide Markdown:

- [ ] Same `course-title` and `course-theme` comments at the top of every file (`roi-alt-theme` unless the user named another theme)
- [ ] Lone `---` between slides; slide count changed only on purpose
- [ ] One `#` title per slide, including image-only and full-bleed slides
- [ ] Only valid layout directives; comments on their own line, not nested
- [ ] No images inside 2-column, 3-column, or card-layout slides
- [ ] No more than 3 default content slides in a row
- [ ] Alerts use only `[!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, `[!CAUTION]`
- [ ] Every code fence has a language tag
- [ ] Smart quotes in prose; straight quotes in code
- [ ] No em-dashes and no `&` in visible text or titles
- [ ] Two bullet levels max
- [ ] Images under `images/` with relative paths and alt text; stock images reused; TODOs where an asset is missing
- [ ] The frame in [course-spine.md](course-spine.md) is intact. Teaching slides, quizzes, and `Lab link: TODO` sit where that file says they go
