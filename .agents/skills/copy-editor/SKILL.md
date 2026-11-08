---
name: copy-editor
description: >
  Proofreads an ROI Training course for spelling, grammar, house-style
  typography, and consistency, and fixes those errors in the files. Includes
  labs when lab files exist. Preserves viewer syntax, code, and teaching.
  Use before any human review, after the Technical Editor or after labs exist.
---

# Copy Editor Skill

## Mission

Make the course clean to read. Fix spelling, grammar, house-style typography, and inconsistent wording in the visible prose.

This step comes before any human review. The course should be as clean as possible before a person sees it. Fix every language and house-style error you find. Do not ask a person to confirm a spelling, and do not leave the correction for someone else.

You are not the author, the technical reviewer, or the graphics designer. Leave teaching, structure, code, and facts alone. A wording change is allowed only when it corrects a language or house-style error.

**Run in a fresh agent session.** Do not reuse the session that wrote or technically reviewed the course.

---

## Mandatory reads

1. The chapter files under `course/`, in teaching order.
2. Every `labs/**/lab.md`, when those files exist. Also proofread visible prose in the same lab folder. A missing `labs/` tree is not an error.
3. [../shared/slide-markdown-rules.md](../shared/slide-markdown-rules.md): syntax you must not break, and the typography rules.
4. [../shared/lab-markdown-rules.md](../shared/lab-markdown-rules.md): typography for labs, when a lab file exists.
5. [examples/editing-patterns.md](examples/editing-patterns.md): safe edits and product-name examples.
6. [examples/copy-edit-report-template.md](examples/copy-edit-report-template.md): report format.

Leave the frame in [../shared/course-spine.md](../shared/course-spine.md) intact. Do not treat lab times, quiz counts, spine order, or `Lab link: TODO` as language errors.

---

## 1. Editing workflow

```text
Copy-edit pass:
- [ ] 1. Read every chapter, and every lab.md when labs exist
- [ ] 2. Note the product names and key terms the course already uses
- [ ] 3. Fix spelling, grammar, typography, and consistency in visible prose
- [ ] 4. Leave code, directives, filenames, and real product names untouched
- [ ] 5. Write reviews/copy-edit-report.md as a record of the edits
- [ ] 6. Confirm the edits did not break viewer syntax
```

### What to fix

- Misspellings in titles, bullets, alerts, quiz stems, explanations, and lab prose
- Clear grammar problems: agreement, articles, and tense that breaks a sentence
- Straight quotes in visible prose, changed to smart quotes
- Em-dashes (`—`) changed to a colon or a normal hyphen (`-`)
- Ampersands (`&`) in visible text changed to `and`, including a title of `Q&A` changed to `Questions and Answers`
- Double spaces, obvious punctuation glitches, and a sentence that starts with a lowercase letter
- Inconsistent heading case, a term spelled two ways, and mixed product-name forms

### What to leave

- Code fences and inline code, including straight quotes and exact syntax
- Layout comments, `course-title`, `course-theme`, and `TODO IMAGE` comments
- Image paths, filenames, and URLs
- Quiz answer letters and technical identifiers that are meant to be literal
- Short slide bullets that are phrases rather than full sentences
- Product, service, API, CLI, and brand names, including unconventional spelling or casing
- Technical claims, command flags, and quiz correctness
- `Lab link: TODO`

---

## 2. Do-not-break rules

An edit that breaks the viewer is not a cleanup. Follow the syntax sections of [../shared/slide-markdown-rules.md](../shared/slide-markdown-rules.md). For a lab, follow the syntax sections of [../shared/lab-markdown-rules.md](../shared/lab-markdown-rules.md).

- Do not remove, reorder, or rewrite `---` slide separators.
- Do not alter or invent `<!-- layout: … -->` or `<!-- below-columns -->` comments.
- Keep `<!-- course-title: … -->` and `<!-- course-theme: … -->` intact.
- Do not change a code fence language tag or the code inside it.
- Do not nest HTML comments or break image Markdown.
- Do not rewrite learning objectives, lab steps, or a quiz except to correct spelling, grammar, or house style in the words that are already there.
- Do not expand short bullets into paragraphs.
- Do not add or delete slides, and do not add or delete lab sections.

If a change would break a directive or a code sample, leave that spot as written and record it in the report. That is a viewer constraint, not a language error left for later.

Do not apply the structural checklist items: spine order, how many default slides sit in a row, bullet depth, missing images, or a lab that is missing a required section. Those are not copy.

---

## 3. House typography

Required in visible slide text, lab text, and titles. These rules do not apply inside code fences, inline code, URLs, file paths, or HTML comments.

| Rule | Do | Don’t |
| :--- | :--- | :--- |
| Smart quotes | `Let’s`, `don’t`, `the “apply” step` | `Let's`, `"apply"` in prose |
| Quotes in code | Keep `'` and `"` inside fences and inline code | Curly quotes inside code |
| Ampersand | `and`, `Questions and Answers` | `&`, `Q&A` |
| Em-dash | Colon for an explanation; hyphen `-` for a break or a contrast | `—` (U+2014) |

Em-dash replacements:

- Introducing or explaining becomes a colon: `Quiz 1: Answer`
- A break or a contrast becomes a hyphen: `slides - not a textbook`

---

## 4. Consistency

After the spelling pass, use one form for each term everywhere in the visible prose you edited.

| Check | Rule |
| :--- | :--- |
| Heading case | Slide titles match the titles around them. Lab `#` and `##` headings use Title Case. Task headings keep the colon and the sentence case after it. Quiz titles stay in the form the course already uses. |
| Product names | One official form per product (`BigQuery`, not a mix of `Big Query` and `BigQuery`) |
| Key terms | One spelling for a course-specific term |
| Hyphenation | The same compound is treated the same way (`hands-on` or `hands on`, not both) |
| Lists | A bullet list on one slide uses parallel grammar |

When the course already mixes two official forms, use the form that appears most often and apply it. Record the choice in the glossary. Do not invent a spelling that contradicts the vendor.

A clear misspelling of a known product is a spelling error. Fix `terriform` to `Terraform` and `big querry` to `BigQuery`.

---

## 5. Product names and technical terms

A token that looks odd may be the real name.

- If it matches a real product, SDK, command, or official casing, keep it.
- Do not turn camelCase, PascalCase, or a glued product word into dictionary English.
- Do not change `gcloud`, `npm`, or `terraform` to title case when the course uses the command-style name.
- When you cannot tell a misspelling from an official name, leave it and record it in the glossary.

More examples: [examples/editing-patterns.md](examples/editing-patterns.md).

---

## 6. Code-aware editing

Leave these regions unchanged:

- Fenced code blocks
- Inline code
- Indented code samples

You may fix spelling in the sentence around a code span, never inside it.

---

## 7. Scope

**In scope**

- Every chapter file under `course/`
- Every `labs/**/lab.md`, and the visible prose beside it, when those files exist
- House-style typography and the consistency checks above

**Out of scope**

- Technical accuracy and currency (Technical Editor)
- Layout variety and new graphics (Course Graphics Designer)
- New teaching, demos, Do Nows, and discussions (Instructor Review)
- Rebuilding the spine or matching an outline
- Rewriting a lab’s steps, commands, or section order
- A style polish that changes meaning or how dense a slide is

---

## 8. Report

Write **`reviews/copy-edit-report.md`** using [examples/copy-edit-report-template.md](examples/copy-edit-report-template.md). The file is a record of this pass. It lists what you already changed.

Include the counts, a few representative fixes, the glossary of forms you standardized, and any token you left because it might be an official name. Do not dump a full diff.

If a report already exists, add a new dated pass section.

---

## 9. Validation checklist

- [ ] Spelling and grammar errors in visible prose are fixed, including labs when lab files exist
- [ ] Smart quotes are used in prose, and straight quotes remain in code
- [ ] No em-dashes in slide or lab text or titles
- [ ] No ampersands in visible text or titles
- [ ] Heading case, terminology, and product-name spelling are consistent, and the glossary records the forms used
- [ ] Product, brand, and CLI names were not rewritten into dictionary English
- [ ] Code fences, inline code, image paths, and layout comments are unchanged
- [ ] `---` separators and course metadata are intact
- [ ] No slides or lab sections were added or deleted
- [ ] Teaching meaning is unchanged
- [ ] `reviews/copy-edit-report.md` records the edits
