# ROI Course Authoring Template

Template repository for ROI Training **slide courses** and **labs**.
It does **not** include the slide or lab viewer apps—only what instructors need
to author content with an AI coding agent.

## What’s in this repo

| Path | Purpose |
| :--- | :--- |
| `course/` | Slide Markdown + shared `images/` (stock graphics + sample) |
| `labs/` | One folder per lab (`lab.md`, `images/`, `solution/`) |
| `plan/` | Course Architect output (`course-outline.md`) |
| `reviews/` | Technical Editor and Copy Editor reports |
| `scripts/new-course.sh` | Create a new course repo from this template |
| `.agents/skills/course-architect/` | Plan the course before any slides |
| `.agents/skills/course-spine-generator/` | Opening file and chapter frame, after the outline is approved |
| `.agents/skills/course-generator/` | Teaching slides, quizzes, and `Lab link: TODO` |
| `.agents/skills/instructor-review/` | Teaching edits before any human review |
| `.agents/skills/course-graphics-designer/` | Visual polish after Instructor Review |
| `.agents/skills/technical-editor/` | Accuracy and currency |
| `.agents/skills/copy-editor/` | Spelling, grammar, typography, consistency |
| `.agents/skills/lab-generator/` | Labs that practice the slides; solution first |
| `.agents/skills/lab-tester/` | Run a lab as a student; report for Lab Generator |
| `.agents/skills/shared/` | Viewer formatting rules every editing skill must follow |
| `.cursorrules`, `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md` | Point every common coding agent at the skills |

## Quick start

1. **Create your course repo** with `scripts/new-course.sh` (ask an agent to run it), or GitHub → *Use this template*.
2. **Open the repo** in Cursor, VS Code (Copilot), Claude Code, Antigravity, or another agent-capable editor.
3. **Follow [PIPELINE.md](PIPELINE.md)** one step per fresh agent session:
   Architect → spine → content → instructor review → graphics → technical edit → labs → lab test → apply the test → copy edit.
4. **Preview slides** in the hosted HTML Slides Viewer (paste your GitHub course folder URL):
   - https://slidesv.roitraining.com/
5. **Preview labs** at https://labv.roitraining.com/ (paste the lab folder URL).

Authoring notes (folder layout, stock images, what not to do): **[AUTHORING.md](AUTHORING.md)**.

## Sample

Open `course/sample-course.md` in the slides viewer to see layouts and stock intro/outro images.

## Courses in this repo

- [Introducing the ROI Course Factory](https://slidesv.roitraining.com/?course=https://github.com/roitraining/roi-course-authoring-template/tree/main/introducing-the-roi-course-factory/course) — how authors, editors, and instructors use the template, the viewers, and the skills. Source: `introducing-the-roi-course-factory/`.

## Related products

- Slides viewer: https://slidesv.roitraining.com/ (source: https://github.com/roitraining/md-to-html-slides-viewer)
- Lab viewer: https://labv.roitraining.com/ (source: https://github.com/roitraining/md-to-html-lab-viewer)
