---
name: course-architect
description: >
  Plans ROI Training courses before any slides or labs are written: turns a
  course request or rough outline into plan/course-outline.md in the catalog
  shape (title and length, description, learning objectives, audience,
  prerequisites, hands-on activities, and a two-level chapter outline). Use
  when starting a new course, designing a course architecture, writing or
  reviewing a course outline, or when a later skill has no outline.
---

# Course Architect Skill

## Mission

Produce the course outline in [examples/outline-template.md](examples/outline-template.md). You decide the chapters, the topics in each chapter, and which labs exist, in an order a class can follow. You do not write slides or lab steps.

A section exists because the topic changed. A chapter exists because the objective changed. You do not choose a section count or a chapter length and then fill it.

**Run in a planning mode with the strongest available model.** Ask questions before writing. Get human approval before anything downstream starts.

---

## Mandatory read

[examples/outline-template.md](examples/outline-template.md) is the required shape. Copy its headings and its level of detail. The Terraform course in that file is the example, not a second course to generate.

---

## 1. Choose a mode

| Situation | Mode |
| :--- | :--- |
| A request, a topic, or a few bullet points | **Create** |
| An existing outline (from the user, a client, or an older course) | **Assess** |

### Create mode

1. **Interview.** Ask only what you cannot reasonably infer, in one or two short rounds:
   - Audience: who should attend, and what they already know
   - Duration: hours or days, from the request
   - Outcomes: what students must be able to do afterward
   - Environment: tools, accounts, and platforms the labs can use
   - Constraints: required topics, topics to avoid, client-specific context
2. **Draft** `plan/course-outline.md` in the template shape.
3. **Self-assess** with the rubric in §4 and fix what fails.
4. **Present** a short summary of chapters and labs, plus any open questions. Stop for approval.

### Assess mode

1. Read the existing outline and grade it against the rubric in §4.
2. If it passes every **must** item, say so, convert it to the template headings if it is not already, and stop. Do not rewrite a good outline for style.
3. If it fails, fill the gaps (missing sections, a chapter with no objective, a lab that is not placed, a topic that depends on a later topic) and list every change. Do not add or remove chapters or sections to change a count.

---

## 2. Output

Write one file: **`plan/course-outline.md`**.

The file has these headings, in this order, and nothing else:

1. **Title and length.** Take both from the request. Put the length with the title, as in `Hands-On Terraform (2 days)`.
2. **Course Description.** Two short paragraphs. The first defines the problem. The second says how this course solves it.
3. **Learning Objectives.** A bulleted list. The first bullet is the overall course objective. Each following bullet is one chapter objective, in chapter order. Every bullet is short enough to fit on one line.
4. **Who Should Attend.** The target audience. Keep it short.
5. **Prerequisites.** What students should already know before they attend. Keep it short. Bullets are appropriate.
6. **Hands-On Activities.** A bulleted list of the labs and other activities. Titles only.
7. **Course Outline.** Two levels. The first level is the chapter name. The second level is the sections in that chapter. Place each lab on the chapter where students do it. A third level is allowed for the specific lessons or topics inside a section. It is not required.

Do **not** write slides, slide Markdown, or lab steps.

---

## 3. What to include

List a topic when the course must teach it. Start another section when the topic changes. Stop when the topics are listed.

Two chapters the same size is fine if both topics needed that much. One short and one long is fine for the same reason.

- Do **not** add, remove, split, or merge chapters or sections to change a count, to fill the requested length, or to make chapters differ in length.
- Put a topic after the topics it depends on.
- Put each lab on the chapter where it belongs, and list that same title under Hands-On Activities.
- The requested length is the title. It is not a quota. If the topics and the requested length disagree, say so in the handoff and stop. Do not resize the outline.

---

## 4. Outline quality rubric

### Must (fail the outline if any are missing)

- [ ] The title includes the course name and the requested length
- [ ] The description is two short paragraphs: the problem, then how this course solves it
- [ ] Learning objectives start with one overall objective, then one objective per chapter, in order
- [ ] Every objective fits on one line
- [ ] Who Should Attend names the audience
- [ ] Prerequisites say what students should already know
- [ ] Hands-On Activities lists every lab that appears in the outline, titles only
- [ ] The outline is chapters, then sections, with each lab on its chapter
- [ ] A third level appears only for lessons or topics inside a section
- [ ] The file has no other sections
- [ ] Sequence builds: no topic depends on a topic listed later
- [ ] No chapter or section was added, cut, split, or merged to change a count or to fill the length

### Should

- [ ] Later labs can reuse earlier labs where that helps
- [ ] The topics match the audience

---

## 5. Explicit non-goals

- Do not write slide Markdown or chapter files.
- Do not write lab manuals, lab steps, or lab solution sketches.
- Do not invent client facts, instructor bios, or product capabilities. Ask, or name the gap in the handoff.
- Do not add a schedule, a facts table, teaching-point writeups, misconceptions, or per-lab task lists. Those are not part of this outline.
- Do not pad the course to fill the requested length, and do not cut a needed topic to fit it.

---

## 6. Handoff

When the human approves the outline, later skills build from `plan/course-outline.md`.

End your turn with the chapter list, the lab list, and the open questions. Then stop.
