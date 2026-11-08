# Course Spine (Required Slide Order)

The spine is the frame of an ROI course. The Course Spine Generator writes it
from `plan/course-outline.md`. Later skills leave that frame intact and add
slides only in the places named below.

Syntax for each slide: [../course-generator/examples/layout-templates.md](../course-generator/examples/layout-templates.md).
Formatting gates: [slide-markdown-rules.md](slide-markdown-rules.md).

Every chapter file starts with the same two comments. The title is the course
name, without the length and without an invented course code. The theme is
ROI Alt Theme unless the user names another.

```markdown
<!-- course-title: Hands-On Terraform -->
<!-- course-theme: roi-alt-theme -->
```

---

## 1. Files

```text
course/
  00-introduction.md        # intro spine only
  01-short-chapter-slug.md  # one file per content chapter
  02-…
  images/
```

- Zero-padded index plus a short kebab-case slug.
- On the slides, Module N from the outline is Chapter N.
- `00-introduction.md` is the opening. It is not a chapter on the agenda.

---

## 2. Introduction (`00-introduction.md`)

The spine generator writes these six slides and no others.

| # | Slide | Layout | Notes |
| :--- | :--- | :--- | :--- |
| 1 | Title | `title` | ROI logo `images/roi-logo-with-name.png`. One `#` heading: the course name. No subtitle and no course code |
| 2 | Welcome! | `panel-right` | Instructor Name / Background / Contact info placeholders. Never invent a bio. `images/welcome.png` |
| 3 | Course Objectives | default | The outline’s Learning Objectives, in order. First bullet is the overall objective. Each following bullet is one chapter |
| 4 | Agenda | `panel-left` | One bullet per chapter: `Chapter N: Name`. `images/agenda.png`. Not a navigation slide |
| 5 | Who Should Attend | `panel-right` | The outline’s words. `images/who-should-attend.png` |
| 6 | Prerequisites | `panel-left` | The outline’s words. `images/prerequisites.png` |

No lab, no quiz, and no Questions and Answers in the introduction.

---

## 3. Each content chapter (`0N-….md`)

The spine generator writes these slides and nothing between them.

| # | Slide | Layout | Notes |
| :--- | :--- | :--- | :--- |
| 1 | Chapter title | `title` | ROI logo, the course name as plain text, then `# Chapter N: Name` |
| 2 | Chapter N: Objectives | default | One line each. First bullet is that chapter’s Learning Objectives line. Then one objective per section, including a lab section. Do not paste the section title as the whole bullet |
| 3 | Navigation, one per section | `navigation` | Heading `# Chapter N`. The same full section list on every slide, including a lab line. Exactly one item is bold, and it moves down the list |
| 4 | What You Learned | default | The Chapter Objectives in the past tense, same order, one line each |
| 5 | Questions and Answers | default | Body is `Questions?` and nothing else. Same pattern on every chapter |

A lab is a section for the objectives and the navigation. The spine does not
write a lab slide, a time, a URL, quizzes, or teaching slides.

---

## 4. What later skills add

Leave the spine slides as they are. Insert around them.

- **Course Generator.** After each navigation slide that is not a lab, insert the teaching slides for that section. After each lab navigation slide, insert one slide. The title is the lab name. The body is `Lab link: TODO`. After What You Learned and before Questions and Answers, insert three quizzes: two multiple choice with answer slides, then one discussion and its discussion points.
- **Instructor Review.** May add a demo, a Do Now, or a discussion inside the teaching. It does not rebuild the frame.
- **Course Graphics Designer.** May change a layout or add an image. It does not add a time or a URL to a lab slide, and it does not remove a Do Now or a discussion.

Do not score a missing lab time, a quiz count, or the spine order as an error
in a later pass. The lab slide stays `Lab link: TODO` until a person adds the URL.
A chapter with no lab has no lab slide. Quizzes are omitted only when the user says so.

---

## 5. Frame checklist

- [ ] Introduction order: Title, Welcome!, Course Objectives, Agenda, Who Should Attend, Prerequisites
- [ ] Welcome and Who Should Attend use `panel-right`; Agenda and Prerequisites use `panel-left`; stock images are wired and not regenerated
- [ ] Course Objectives match the outline’s Learning Objectives; the agenda lists every chapter
- [ ] Every content chapter from the spine: Title, Objectives, one navigation slide per section, What You Learned, Questions and Answers
- [ ] Every navigation slide lists every section of that chapter, with exactly one bold item
- [ ] What You Learned is the Chapter Objectives in the past tense
- [ ] Questions and Answers is `Questions?` on every chapter
- [ ] Teaching slides, quizzes, and `Lab link: TODO` were added by the content skill, not by the spine
