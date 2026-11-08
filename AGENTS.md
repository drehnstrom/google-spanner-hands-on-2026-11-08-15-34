# Agent instructions — ROI course authoring

## Skills

- **Course architecture:** Always read and follow `.agents/skills/course-architect/SKILL.md` when planning a course or writing `plan/course-outline.md`.
- **Course spine:** After the outline is approved, read and follow `.agents/skills/course-spine-generator/SKILL.md` and `.agents/skills/shared/course-spine.md`. Write the frame only. Do not write teaching slides.
- **Slide courses:** When writing teaching slides, read and follow `.agents/skills/course-generator/SKILL.md`, `.agents/skills/course-generator/examples/layout-templates.md`, `.agents/skills/shared/slide-markdown-rules.md`, `.agents/skills/shared/course-spine.md`, and `.agents/skills/shared/svg-craft.md`. Leave the spine intact. A lab slide’s body is `Lab link: TODO`. Create an SVG only if it passes the svg-craft gate.
- **Instructor review:** After the teaching slides exist, read and follow `.agents/skills/instructor-review/SKILL.md`. Edit the course. Do not grade it against the outline.
- **Course graphics:** After Instructor Review, read and follow `.agents/skills/course-graphics-designer/SKILL.md`, `.agents/skills/course-graphics-designer/examples/visual-patterns.md`, and `.agents/skills/shared/svg-craft.md`. Improve layouts and graphics without breaking viewer rules. Redraw or delete SVGs that fail the quality bar.
- **Technical editing:** For accuracy and currency, read and follow `.agents/skills/technical-editor/SKILL.md` and `.agents/skills/shared/verify-current-facts.md`. Fresh session; do not trust model memory for APIs, CLIs, model names, or console labels. Teaching changes belong to Instructor Review.
- **Copy editing:** For spelling, grammar, house-style typography, and consistency, read and follow `.agents/skills/copy-editor/SKILL.md` and `.agents/skills/copy-editor/examples/editing-patterns.md`. Do not break code, directives, or product names.
- **Labs:** Always read and follow `.agents/skills/lab-generator/SKILL.md`, `.agents/skills/lab-generator/examples/lab-template.md`, and `.agents/skills/shared/lab-markdown-rules.md` when creating or editing files under `labs/`. Read the slides that lead up to the lab, then build the solution first and write steps that practice those slides.
- **Lab testing:** Read and follow `.agents/skills/lab-tester/SKILL.md`. Do not rewrite the lab; write `test-report.md` for a later Lab Generator pass.

Pipeline: see `PIPELINE.md`. One fresh session per step.

## Repository layout

- `course/` — slide Markdown and `images/`
- `labs/lab-NN-slug/` — each lab’s `lab.md`, `images/`, and `solution/`
- `plan/` — `course-outline.md` from Course Architect
- `reviews/` — technical-review.md and copy-edit-report.md
- Stock intro/outro slide images live in `course/images/`; copy/reuse those filenames; do not regenerate.

## Output expectations

- Prefer multi-file courses (`00-introduction.md`, `01-….md`, …) under `course/`; short single-deck courses may use one file.
- Same `<!-- course-title: … -->` in every chapter file.
- Same `<!-- course-theme: roi-alt-theme -->` in every chapter file (unless the user names another theme).
- No ampersand (`&`) in slide or lab titles/body text (use “and”).
- Content chapters: navigation and teaching, then a lab slide when the chapter has a lab, then What You Learned, quizzes, and Questions and Answers.
- Lab slide: the lab name and the body `Lab link: TODO`. A person adds the URL later. Do not put a time on the slide.
- Questions and Answers: the body is `Questions?` on every chapter.
- Labs: Title → Time Required → Overview (You learn how to) → optional Scenario → Lab Instructions (Task / Bonus Task) → Congratulations!; preferred file `lab.md`; no Qwiklabs `ql-*` tags.
- Preview labs at https://labv.roitraining.com/ (paste the lab folder URL).
