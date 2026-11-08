# Authoring guide (instructors)

How to create an ROI Training course with this template and an AI coding agent.

**Run the steps in [PIPELINE.md](PIPELINE.md).** That runbook is the workflow:
one fresh agent session per step, copy-paste prompts, model tiers, and human
checkpoints. This page is the layout and house-rule reference.

## 1. Create your repository

Prefer the setup script (ask an agent to run it):

```bash
scripts/new-course.sh ../my-course-folder
scripts/new-course.sh ../my-course-folder --github owner/repo --private
```

You can instead use GitHub → *Use this template*, or copy this folder and `git init`.

You do **not** need the slides viewer or lab viewer source code in your repo.

## 2. Open in your editor

Use any editor with a coding agent:

- Cursor
- Visual Studio Code + GitHub Copilot
- Claude Code
- Antigravity / Gemini

Pointer files in this repo (`.cursorrules`, `CLAUDE.md`, `AGENTS.md`,
`.github/copilot-instructions.md`) tell the agent to follow the skills. You
should not need global machine setup.

If the agent seems unaware of the rules, say explicitly:

> Read `PIPELINE.md` and the skill for the current step, then follow it. One fresh session per step.

## 3. Course layout (slides)

```text
course/
  00-introduction.md
  01-your-first-chapter.md
  02-…
  images/
    roi-logo-with-name.png   # stock — do not regenerate
    welcome.png
    agenda.png
    who-should-attend.png
    prerequisites.png
    qa.png
    …                        # your diagrams / screenshots
plan/
  course-outline.md          # Course Architect; required before the spine
reviews/
  technical-review.md
  copy-edit-report.md
```

- **Multi-chapter courses:** one Markdown file per chapter (required by the skill).
- **Stock images** are already in `course/images/`. Copy them into place for every new course folder if you split courses later; do not reinvent them.
- Replace `course/sample-course.md` with your real chapters when you start (or keep it as a layout reference). The setup script does not copy the sample course.

## 4. Labs layout

```text
labs/
  lab-01-getting-started/
    lab.md
    images/
    solution/          # finished result, built first
    starter/           # optional
    test-report.md     # Lab Tester; do not confuse with the manual
  lab-02-…
```

Follow:

- [.agents/skills/lab-generator/SKILL.md](.agents/skills/lab-generator/SKILL.md)
- [.agents/skills/lab-generator/examples/lab-template.md](.agents/skills/lab-generator/examples/lab-template.md)

See also [labs/README.md](labs/README.md) and the sample at `labs/lab-01-sample-lab-viewer-format/lab.md`.

### Lab slides

After a lab’s navigation slide, the Course Generator adds one slide. The title is the lab name. The body is `Lab link: TODO`. Do not add a time or a URL. A person adds the link later. Do not write lab steps on the slide.

## 5. Preview

### Slides

1. Push your repo to GitHub (public, or ensure the viewer can read it).
2. Open the [HTML Slides Viewer](https://slidesv.roitraining.com/).
3. **Open → GitHub**, paste the URL to your `course/` folder (or a single `.md` file).

Local alternative: run any static server in a checkout of the slides viewer and pass `?course=` at your Markdown URL.

### Labs

Use the [HTML Lab Viewer](https://labv.roitraining.com/) and paste a GitHub URL to the lab folder.

## 6. What not to do

- Do not skip the outline when you have no plan, or only a thin bullet list.
- Do not ask one session to write the whole course. Follow PIPELINE.md: spine, then content, then the later steps.
- Do not paste an entire multi-chapter course into one mega-file (unless you intentionally author a short single-file workshop).
- Do not invent instructor bios on the Welcome slide.
- Do not use `&` in slide titles/body (write “and”; use **Questions and Answers**, not “Q&A”).
- Do not regenerate the stock intro/outro images—reuse the files in `course/images/`.
- Do not put full lab procedures in slide Markdown—use `labs/` and the Lab Generator skill.
- Do not put a time or a lab URL on the lab slide. The body stays `Lab link: TODO` until a person adds the link.
- Do not use Qwiklabs `ql-*` tags or fragments in Lab Viewer manuals.
- Do not reuse the authoring session for technical review, copy edit, or lab testing.

## 7. Skill reference

- Pipeline: [PIPELINE.md](PIPELINE.md)
- Shared slide rules: [.agents/skills/shared/slide-markdown-rules.md](.agents/skills/shared/slide-markdown-rules.md)
- Shared lab rules: [.agents/skills/shared/lab-markdown-rules.md](.agents/skills/shared/lab-markdown-rules.md)
- Course spine: [.agents/skills/shared/course-spine.md](.agents/skills/shared/course-spine.md)
- SVG craft: [.agents/skills/shared/svg-craft.md](.agents/skills/shared/svg-craft.md)
- Verify current facts: [.agents/skills/shared/verify-current-facts.md](.agents/skills/shared/verify-current-facts.md)
- Architect: [.agents/skills/course-architect/SKILL.md](.agents/skills/course-architect/SKILL.md)
- Spine: [.agents/skills/course-spine-generator/SKILL.md](.agents/skills/course-spine-generator/SKILL.md)
- Course: [.agents/skills/course-generator/SKILL.md](.agents/skills/course-generator/SKILL.md)
- Instructor review: [.agents/skills/instructor-review/SKILL.md](.agents/skills/instructor-review/SKILL.md)
- Course templates: [.agents/skills/course-generator/examples/layout-templates.md](.agents/skills/course-generator/examples/layout-templates.md)
- Course graphics: [.agents/skills/course-graphics-designer/SKILL.md](.agents/skills/course-graphics-designer/SKILL.md)
- Graphics patterns: [.agents/skills/course-graphics-designer/examples/visual-patterns.md](.agents/skills/course-graphics-designer/examples/visual-patterns.md)
- Technical editor: [.agents/skills/technical-editor/SKILL.md](.agents/skills/technical-editor/SKILL.md)
- Copy editor: [.agents/skills/copy-editor/SKILL.md](.agents/skills/copy-editor/SKILL.md)
- Editing patterns: [.agents/skills/copy-editor/examples/editing-patterns.md](.agents/skills/copy-editor/examples/editing-patterns.md)
- Labs: [.agents/skills/lab-generator/SKILL.md](.agents/skills/lab-generator/SKILL.md)
- Lab template: [.agents/skills/lab-generator/examples/lab-template.md](.agents/skills/lab-generator/examples/lab-template.md)
- Lab tester: [.agents/skills/lab-tester/SKILL.md](.agents/skills/lab-tester/SKILL.md)
