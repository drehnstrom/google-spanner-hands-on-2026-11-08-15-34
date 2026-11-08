---
name: course-spine-generator
description: >
  Builds the opening file and the boilerplate for every chapter from
  plan/course-outline.md: title, welcome, objectives, agenda, audience,
  prerequisites, chapter objectives, section navigation, What You Learned,
  and Questions and Answers. Uses the ROI Alt Theme by default. Use when
  starting the slide spine after an approved outline. Does not write teaching
  slides, quizzes, or lab steps.
---

# Course Spine Generator

## Mission

Read `plan/course-outline.md` and write the frame of the course. An instructor can see every chapter, its objective, and its sections. You do not teach yet.

Do not write teaching slides, quizzes, lab slides, or lab steps. Do not add slides to fill time.

**Default theme:** ROI Alt Theme. Every file starts with `<!-- course-title: … -->` and then `<!-- course-theme: roi-alt-theme -->`. Do not emit `roi-theme` unless the user asks for that theme.

---

## Mandatory reads

1. [../shared/slide-markdown-rules.md](../shared/slide-markdown-rules.md): separators, layouts, theme, typography, images. These are hard gates.
2. [../course-generator/examples/layout-templates.md](../course-generator/examples/layout-templates.md): copy the syntax for the title, Welcome, agenda, Who Should Attend, Prerequisites, navigation, and Questions and Answers slides. Do not invent directives.
3. `plan/course-outline.md`: the chapters, sections, labs, objectives, audience, and prerequisites.

[../shared/course-spine.md](../shared/course-spine.md) is the frame this skill writes. Follow it.

---

## 1. Files

Write under `course/`. The viewer treats a numbered course as files whose names start with two digits.

```text
course/
  00-introduction.md
  01-short-slug.md
  02-another-slug.md
  images/                  # stock images already live here; do not regenerate them
```

- `00-introduction.md` is the opening. It is not a chapter on the agenda.
- One file per module, in outline order. Zero-pad the index. The slug is a short kebab-case name from the module title.
- On the slides, **Module N** is **Chapter N**.

Every file starts with the same two comments. The title is the course name from the outline, without the length in parentheses, and without an invented course code.

```markdown
<!-- course-title: Python Web Development for Beginners -->
<!-- course-theme: roi-alt-theme -->
```

---

## 2. Introduction

`00-introduction.md` has these slides, in this order, and no others.

1. **Title.** `<!-- layout: title -->`, the ROI logo `images/roi-logo-with-name.png`, and one `#` heading: the course name without the length. Do not invent a subtitle.
2. **Welcome!** `<!-- layout: panel-right -->` and `images/welcome.png`. Use the Welcome bullets from the layout templates, including the instructor Name / Background / Contact info placeholders. Do not invent a bio.
3. **Course Objectives.** Copy the Learning Objectives bullets from the outline, in the same order. The first is the overall objective. Each following bullet is one chapter. Do not rewrite them.
4. **Agenda.** `<!-- layout: panel-left -->` and `images/agenda.png`. One bullet per chapter: `Chapter N: Name`. This is not a navigation slide.
5. **Who Should Attend.** `<!-- layout: panel-right -->` and `images/who-should-attend.png`. Use the outline’s words. A single sentence becomes one bullet. Do not add an audience the outline does not name.
6. **Prerequisites.** `<!-- layout: panel-left -->` and `images/prerequisites.png`. Use the outline’s words. Keep bullets if the outline already has them.

No lab, no quiz, and no Questions and Answers in this file.

---

## 3. Each chapter

Each `0N-….md` file has these slides, in this order.

1. **Chapter title.** `<!-- layout: title -->`, the ROI logo, the course name as plain text above the heading, and `# Chapter N: Name`.
2. **Chapter Objectives.** Heading `# Chapter N: Objectives`. Every bullet fits on one line.
   - The first bullet is that chapter’s overall objective, copied from the matching Learning Objectives line.
   - Then one bullet per section in that module, in outline order. A `Lab:` line is a section. Write an objective for it. Do not copy the section title as the whole bullet.
3. **Navigation, one slide per section.** Place these immediately after the objectives. Nothing else sits between them.
   - `<!-- layout: navigation -->`
   - The `#` heading is `Chapter N`
   - The same full list of section names on every slide, taken from the outline, including a lab line when the module has one
   - Exactly one item is `**bold**`. The bold item is the current section, and it moves down the list in order.
4. **What You Learned.** The Chapter Objectives bullets in the past tense, same ideas, same order, still one line each.
5. **Questions and Answers.** The body is `Questions?` and nothing else. Use this pattern on every chapter. Do not use an ampersand in the title.

A lab in the module is a section for the objectives and the navigation. Do not add a lab-stub slide. Do not write a time, a URL, or lab steps.

---

## 4. Explicit non-goals

- Do not write a teaching slide between the navigation slides.
- Do not write quizzes.
- Do not write lab manuals or lab slides.
- Do not regenerate `welcome.png`, `agenda.png`, `who-should-attend.png`, `prerequisites.png`, `qa.png`, or the ROI logo.
- Do not change `plan/course-outline.md`.
- Do not add or remove a chapter the outline does not have.

---

## 5. Checklist

Stop when every item passes.

- [ ] `00-introduction.md` is Title, Welcome, Course Objectives, Agenda, Who Should Attend, Prerequisites
- [ ] Course Objectives match the outline’s Learning Objectives, in order
- [ ] Agenda lists every chapter and no extra chapter
- [ ] Welcome and Who Should Attend use `panel-right`. Agenda and Prerequisites use `panel-left`. Stock images are wired
- [ ] Instructor lines are placeholders
- [ ] Every module has a `0N-….md` file in outline order
- [ ] Every chapter is Title, Objectives, one navigation slide per section, What You Learned, Questions and Answers
- [ ] The first objectives bullet is the chapter’s Learning Objectives line
- [ ] Each later objectives bullet is one line and states the section’s objective, including a lab section when the outline lists one
- [ ] Every navigation slide lists every section of that chapter, with exactly one bold item, in outline order
- [ ] What You Learned is the Chapter Objectives in the past tense
- [ ] Questions and Answers is `Questions?` on every chapter
- [ ] No teaching slide, quiz, or lab slide
- [ ] Both metadata comments are on every file, and the theme is ROI Alt Theme: `roi-alt-theme`
- [ ] [../shared/slide-markdown-rules.md](../shared/slide-markdown-rules.md) passes, including smart quotes and no ampersand in slide text
