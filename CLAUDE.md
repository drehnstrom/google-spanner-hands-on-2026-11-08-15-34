# ROI course authoring

This repository is for authoring ROI Training slide courses and labs.

Follow **PIPELINE.md**: one fresh session per step (architect, spine, content,
instructor review, graphics, technical edit, labs, lab test, apply the test,
copy edit).

## Mandatory skills

Before **planning** a course, read and follow:

- `.agents/skills/course-architect/SKILL.md`
- `.agents/skills/course-architect/examples/outline-template.md`

Before creating the **spine**, read and follow:

- `.agents/skills/course-spine-generator/SKILL.md`
- `.agents/skills/shared/course-spine.md`
- `.agents/skills/shared/slide-markdown-rules.md`

Before creating or editing **teaching slides**, read and follow:

- `.agents/skills/course-generator/SKILL.md`
- `.agents/skills/course-generator/examples/layout-templates.md`
- `.agents/skills/shared/slide-markdown-rules.md`
- `.agents/skills/shared/course-spine.md`
- `.agents/skills/shared/svg-craft.md`

Before an **instructor review**, read and follow:

- `.agents/skills/instructor-review/SKILL.md`

Before polishing **course visuals** (layouts, diagrams, generated images, screenshots), read and follow:

- `.agents/skills/course-graphics-designer/SKILL.md`
- `.agents/skills/course-graphics-designer/examples/visual-patterns.md`
- `.agents/skills/shared/svg-craft.md`

Before **technical review** (accuracy and currency), read and follow:

- `.agents/skills/technical-editor/SKILL.md`
- `.agents/skills/shared/verify-current-facts.md`

Before **proofreading** courses for spelling, grammar, and house-style typography, read and follow:

- `.agents/skills/copy-editor/SKILL.md`
- `.agents/skills/copy-editor/examples/editing-patterns.md`

Before creating or editing **labs**, read and follow:

- `.agents/skills/lab-generator/SKILL.md`
- `.agents/skills/lab-generator/examples/lab-template.md`
- `.agents/skills/shared/lab-markdown-rules.md`

Before **testing** a lab, read and follow:

- `.agents/skills/lab-tester/SKILL.md`

## Layout

- Slides: `course/` (Markdown chapters + `course/images/`)
- Labs: `labs/lab-NN-slug/lab.md` + `images/` + `solution/`
- Plan: `plan/course-outline.md`
- Reviews: `reviews/`
- Reuse stock slide images in `course/images/` (`welcome.png`, `agenda.png`, `who-should-attend.png`, `prerequisites.png`, `qa.png`, ROI logo). Do not regenerate them.
- Default slide theme: `<!-- course-theme: roi-alt-theme -->` in every chapter file (immediately after `course-title`).
- Default chapter quizzes after What You Learned (see Course Generator skill).
- Lab slides: the lab name and the body `Lab link: TODO` (a person adds the URL later).

## Preview

Slides: https://slidesv.roitraining.com/
Labs: https://labv.roitraining.com/
