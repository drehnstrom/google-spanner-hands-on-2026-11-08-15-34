---
name: course-generator
description: >
  Writes the teaching slides for an ROI Training course after the spine exists.
  Reads plan/course-outline.md and the chapter files, then teaches each section
  thoroughly with layouts that make the point clear. Use when filling chapter
  content, refining slides, or choosing layout directives. Does not build the
  spine.
---

# Course Generator Skill

## Mission

Your job is to **teach the course**. A student at the level named in the outline should be able to learn each topic from the slides: the idea, a concrete example, and a contrast or failure when the topic has one. An instructor should be able to teach from the deck without inventing the missing explanation.

That is the goal. House style, slide counts, and matching one chapter’s length to another are not. When a rule and the teaching disagree, **teaching wins**.

**Non-negotiable constraint:** the deck must compile in the **HTML Slides Viewer**. An invalid layout comment, a missing `---`, or a broken code fence is a broken class, not a style choice.

**Default theme:** ROI Alt Theme. Leave `<!-- course-title: … -->` and `<!-- course-theme: roi-alt-theme -->` as the spine wrote them. Do not emit `roi-theme` unless the user asks for that theme.

---

## Mandatory reads

1. [../shared/slide-markdown-rules.md](../shared/slide-markdown-rules.md): viewer syntax, typography, images, conformance checklist
2. [examples/layout-templates.md](examples/layout-templates.md): copy the layout syntax. Do not invent directives
3. [../shared/svg-craft.md](../shared/svg-craft.md): read this before creating any SVG
4. `plan/course-outline.md`: topics, order, audience, and labs
5. The chapter files under `course/`: the spine you fill

Leave the frame in [../shared/course-spine.md](../shared/course-spine.md) intact. The spine skill already wrote it. Insert teaching, quizzes, and the lab slide where that file says. Do not score lab times, quiz counts, or spine order as errors.

### When the inputs are missing

- If `plan/course-outline.md` is missing, stop. Say to run the Course Architect.
- If `course/00-introduction.md` or the chapter files are missing, stop. Say to run the Course Spine Generator.

---

## 1. What you write

Read the outline and the chapter spine before you add a slide. Default to **one chapter per run** on a long course. A short course can be filled in one run. Do that work, then stop.

Leave these slides as the spine wrote them:

- Introduction: title, Welcome, course objectives, agenda, who should attend, prerequisites
- Each chapter: chapter title, chapter objectives, navigation, What You Learned, Questions and Answers

If the teaching shows an objective is wrong, tell the user. Do not silently rewrite it.

### Teaching slides

For each navigation item that is not a lab, insert the teaching slides after that navigation slide and before the next one. A section is done when a student at the outline’s level can learn the topic. A programming section includes code the student can read.

One slide is not the goal. Matching another section’s length is not the goal. Do not add a slide to hit a count or to fill the day. Do not stop because a slogan fits on one slide.

### Layouts

Choose the layout that teaches the point. Copy the syntax from [examples/layout-templates.md](examples/layout-templates.md).

- A comparison is `2-column`
- Three parallel items are `3-column` or `card-layout`
- A diagram that carries the idea is `stacked`, `title-image`, or auto-split (a bullet list and an image on the same slide, with no layout comment)
- A short worked example can stay on the default layout

Vary the layouts through the chapter so the student is not reading the same bullet stack for every idea. Do not pick a layout only to be different. Do not leave more than three default bullet slides in a row when another layout would teach the next point more clearly.

### Lab placeholder

For each navigation item that is a lab, insert one slide after that navigation slide. The title is the lab name from the outline. The body is one line:

```markdown
Lab link: TODO
```

Do not invent a URL, a time, or lab steps. A person adds the link later.

### Quizzes

After What You Learned and before Questions and Answers, add three quizzes. Copy the templates from [examples/layout-templates.md](examples/layout-templates.md).

- **Quiz 1 and 2:** multiple choice A–D, each followed by an answer slide that restates the question, gives `**Correct: X.**`, and lists short rationale bullets
- **Quiz 3:** a `2-column` discussion (`### Prompt`, `### Discuss`), then a `2-column` Discussion Points slide (`### Strong Answers Mention`, `### Watch For`)

Quizzes practice this chapter: application, decisions, and misconceptions, not trivia. Distractors are plausible. The discussion works in class for 2–4 minutes. Quizzes are not a way to add slides. Do not put them in the introduction. Omit them when the user declines.

### When you finish the chapter

Remove nothing the spine owns. In the summary, one ballpark sentence: “At 2–3 minutes a teaching slide, plus the spine slides in this chapter, this chapter is about N minutes.” Do not add, cut, or rewrite slides to move that number.

---

## 2. Audience

Teach the people named in the outline’s Who Should Attend and Prerequisites. Do not assume intermediate professionals when the outline says beginners, and do not talk down to experienced people.

Write the slides the topic needs. Report how that compares with the requested duration. Do not resize the deck to match it.

---

## 3. Teaching craft

Write for an instructor at the front of the room: one clear point per slide, enough detail to teach, no filler.

### What good looks like

- A student can do the thing the chapter objective names
- The altitude matches the outline’s audience
- Concrete examples, contrasts, failure modes, and decision rules, not only definitions
- Slides an instructor can talk from without reading paragraphs aloud
- A direct, concrete tone

### Usual pattern

- About 3–4 main bullets. The first bullet is the thesis of the slide
- Supporting bullets develop that thesis. They do not start a new topic
- Optional sub-bullets (0–3) for how, an example, or what to watch for
- Two bullet levels maximum. Deeper structure becomes a table, columns, cards, or a new slide
- Prefer one-line bullets

### Use judgment

Prefer that pattern because it keeps a deck teachable. Leave it when another shape teaches better: a worked example, a comparison, a code sample, or a diagram. Do not sacrifice clarity to satisfy a bullet count. Do not write walls of prose.

Layout choice is part of teaching. Use the layout that makes the point clear, and vary layouts across the chapter. Include code in a programming course.

### Accuracy

Fast-moving facts (API signatures, CLI flags, model names, console labels, versions, prices) go stale in model memory. When you have web or tool access, check them per [../shared/verify-current-facts.md](../shared/verify-current-facts.md). When you cannot, write the most accurate version you can and list the unverified claims in the summary so the Technical Editor can check them.

---

## 4. Images

Create the visual while you write the slide. The Course Graphics Designer polishes later.

Read [../shared/svg-craft.md](../shared/svg-craft.md) first. Ship an SVG only if a spatial, mechanical, or contrast picture teaches better than type, the canvas is transparent, the colors are ROI Alt only, there is no heading that restates the slide title, and the graphic would still teach if the bullets were muted. If the file is boxes containing the slide’s words, do not emit it. Use columns or cards, or skip the image. A strong text layout beats a weak diagram.

- Diagrams that pass the gate: SVG. Labels you control are never misspelled
- Photos, metaphors, rich scenes: generated images with little or no text in the image
- Real product UI: a real screenshot when you can capture it. Otherwise a `TODO IMAGE` placeholder. Never fake a product screenshot
- Prefer `title-image`, `image-only`, `full-bleed`, `stacked`, or auto-split when a visual should dominate, stand alone, fill the slide, sit below the content, or sit beside the bullets
- Do not omit a needed visual silently. Prefer a placeholder over a weak text-only slide. Prefer no SVG over a row of rounded rectangles

Paths, names, stock images, and TODO syntax: [../shared/slide-markdown-rules.md](../shared/slide-markdown-rules.md) §7.

---

## 5. Refine

When asked to refine, read the whole course as an author reviewing a draft.

- Cut a slide that repeats a point already taught, or that only restates the title
- Do not cut a slide that still carries an example, contrast, or failure the others do not
- Add the example a topic is missing
- Change a layout when a run of default slides hides the point
- Do not restyle a slide that already teaches
- Do not add a slide to look busy, to differ from another chapter, or to fill time
- Split a slide only when it teaches two ideas. Merge two slides only when they teach the same idea
- Close a gap: a concept used before it is taught, or an objective with no supporting slides
- Rewrite a vague thesis, a definition with no example, and hype

Report what you changed and why, by chapter. End with the same ballpark sentence as a content run. Do not edit again to move that number.

---

## 6. Explicit non-goals

- Do not build or rebuild the spine. The Course Spine Generator does that.
- Do not write lab manuals or lab steps. The lab slide is `Lab link: TODO`.
- Do not invent an instructor bio.
- Do not change the outline’s topics or objectives silently. Propose the change.
- Do not regenerate or replace stock images.

---

## 7. Checklist

### Before you start

- [ ] `plan/course-outline.md` is present
- [ ] The introduction and chapter files are present

### After content

- [ ] [../shared/slide-markdown-rules.md](../shared/slide-markdown-rules.md) passes
- [ ] Spine slides are still in place and were not rewritten
- [ ] Every non-lab section has the idea, a concrete example, and a contrast or failure when the topic has one
- [ ] A programming section includes code
- [ ] Layouts teach the point and vary through the chapter. No more than three default bullet slides in a row when another layout would teach more clearly
- [ ] Each lab navigation item is followed by one slide whose body is `Lab link: TODO`
- [ ] Three quizzes sit after What You Learned and before Questions and Answers, and they practice this chapter
- [ ] The introduction has no quizzes and no new teaching slides
- [ ] Theme remains `roi-alt-theme` unless the user named another
- [ ] Images are created or marked `TODO IMAGE`
- [ ] Every SVG passes [../shared/svg-craft.md](../shared/svg-craft.md). No SVG is boxes containing the slide’s words
- [ ] Unverified volatile facts are listed in the summary
- [ ] One ballpark sentence is in the summary, and no edit was made to chase it

### After refine

- [ ] A repeated or title-only slide was cut
- [ ] A missing example was added
- [ ] A run of default slides that hid a point was given a layout that teaches it
- [ ] No concept is used before it is taught
- [ ] The change summary names what changed, by chapter, and includes the ballpark sentence
