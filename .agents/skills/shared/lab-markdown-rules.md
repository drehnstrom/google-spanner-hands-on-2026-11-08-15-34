# Lab Markdown Rules (HTML Lab Viewer)

**Every skill that creates or edits a lab manual must follow this file.** That
includes Lab Generator, Technical Editor, and Copy Editor. Lab Tester reads it
to report structural problems but does not edit the lab.

The [HTML Lab Viewer](https://labv.roitraining.com/) renders one `lab.md` as a
single scrolling page with a table of contents built from the headings. Broken
headings or fences break the page and the TOC.

Copy-paste skeleton: [../lab-generator/examples/lab-template.md](../lab-generator/examples/lab-template.md).
Reference sample: `labs/lab-01-sample-lab-viewer-format/lab.md`.

---

## 1. Folder layout

```text
labs/
  lab-01-short-slug/
    lab.md          # the manual (preferred filename)
    images/         # screenshots and diagrams
    solution/       # finished solution files (when the lab produces code or config)
    test-report.md  # written by Lab Tester
```

- Folder: `lab-NN-short-kebab-slug`, numbered to match the course.
- Preview by pasting the GitHub URL of the **lab folder** into the Lab Viewer.

---

## 2. Required structure (in order)

| Section | Heading | Required |
| :--- | :--- | :--- |
| Title | `# …` | Yes. Title Case, outcome-oriented, names the key technology |
| Time Required | `## Time Required` | Yes. Full phrase, such as `30 minutes` |
| Overview | `## Overview` | Yes. “In this lab, you…” narrative |
| You learn how to | `### You learn how to:` | Yes. Imperative, complete sentences with ending punctuation |
| Scenario | `## Scenario` | Optional (preferred) |
| Lab Instructions | `## Lab Instructions` | Yes |
| Tasks | `### Task N: …` | Yes. Setup goes in Task 1; no separate Setup or Prerequisites section |
| Bonus | `### Bonus Task N: …` | Preferred |
| Closing | `## Congratulations!` | Yes. “In this lab, you have:” + past tense of You learn how to |

Heading case: Title Case for `#` and `##`. Task headings use a colon and
sentence case after it: `### Task 2: Configure the backend and migrate state`.

---

## 3. Task body

- Open with one or two sentences on what the task achieves.
- Numbered steps restart at **1.** in each task, with a blank line between steps.
- Each step starts with an imperative verb and does one main action.
- Introduce commands with their purpose: “To list regions, run:”.
- UI labels in sentence case, even if the product shows all caps.
- When a step ends with text the learner types, omit ending punctuation.
- Use a table for three or more field and value pairs on one screen.

---

## 4. Syntax

- Every fenced code block has a language tag.
- Alerts: only `> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`, `> [!WARNING]`, `> [!CAUTION]`. Use them for real guidance, not on every step.
- Do not use Qwiklabs syntax: no `ql-*` tags, no `![[/fragments/…]]`, no templated `ql-variable`.
- Use placeholders such as `YOUR_PROJECT_ID` for credentials, project IDs, and secrets. Never invent real values.

---

## 5. Typography

Same as slides: smart quotes in prose, straight quotes in code, no em-dashes,
no `&` in titles or body text. Second person (*you*), simple present tense.

---

## 6. Images

- Relative paths from `lab.md`: `![Create bucket dialog](images/create-bucket.png)`.
- Descriptive filenames and meaningful alt text.
- Do not screenshot text that belongs in a code block.
- When a real capture is not available yet: keep the image reference, add `<!-- TODO IMAGE: … -->` describing what to capture, and put a labeled placeholder file at that path so the link is not broken.
- Never present a generated image as a real product screenshot.

---

## 7. Conformance checklist

Run this after **any** edit to a lab manual:

- [ ] `labs/lab-NN-slug/lab.md` with `images/` as needed
- [ ] Title, Time Required, Overview with You learn how to, optional Scenario, Lab Instructions, Congratulations! in that order
- [ ] Heading case correct; tasks are `### Task N: …` with sentence case after the colon
- [ ] Setup is in Task 1; no standalone Setup section
- [ ] Numbering restarts at 1 in each task; blank line between steps
- [ ] Every code fence has a language tag
- [ ] Alerts use valid tags only; no `ql-*` or fragment syntax
- [ ] Congratulations mirrors You learn how to in past tense
- [ ] No `&`, no em-dashes; smart quotes outside code
- [ ] Every image reference has alt text and a file on disk (real or placeholder with a TODO)
