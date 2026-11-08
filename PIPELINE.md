# Course Factory pipeline

How to create an ROI Training course with this template and an AI coding agent.
Each step is a **new agent session** that reads and writes **files on disk**,
not chat history. That keeps the work portable across Cursor, VS Code + Copilot,
Claude Code, and Antigravity.

The skills make the course as clean as they can before a person reads it.
A person approves the outline, and later reads the finished course and adds the lab URLs.

If a skill seems unaware of the rules, tell it to read the skill file listed
in that step before doing any work.

---

## Model tiers

| Tier | Use for |
| :--- | :--- |
| **Best available** | Architecture, spine, content, instructor review, graphics, labs |
| **Different model** from the one that wrote the course | Technical review, and lab testing when you can |
| **Cheaper** | Copy editing |

“Best available” means the strongest model you can give a long, careful task.
Architecture should run in a **planning mode** if the tool has one (for example Cursor Plan mode).

---

## Step 0: New course repo

**Purpose:** copy this template into a new git repo, disconnected from the template’s history.

**Model:** any. **Fresh session:** not required.

**Who runs it:** ask an agent to run the script, or run it yourself.

```bash
# From a clone of this template (Git Bash or WSL on Windows):
scripts/new-course.sh ../my-course-folder
scripts/new-course.sh ../my-course-folder --github owner/repo --private
```

The script copies the template **without** `.git`, `course/sample-course.md`,
`introducing-the-roi-course-factory/`, sample course images, the sample lab,
and any `plan/course-outline.md` left in the template. It runs `git init`,
makes the first commit, and optionally creates a GitHub repo.

**Human checkpoint:** open the new folder in your editor. Confirm you are not
still inside the template repo.

**Copy-paste prompt**

```text
Run scripts/new-course.sh to create a new course repo at ../COURSE-FOLDER-NAME.
Use --github owner/repo if I should create a GitHub repo, and --private if it
should be private. If git or gh is missing or I am not signed in, tell me
exactly what to install or run. Do not create the GitHub repo unless I named it.
```

---

## Step 1: Course architecture

**Purpose:** a catalog outline. Title and length, two short description paragraphs, one-line objectives, who should attend, prerequisites, lab titles, and a two-level outline.

**Skill:** `.agents/skills/course-architect/SKILL.md`

**Model:** best available, in planning mode. **Fresh session:** yes.

**Input:** your request, or an existing outline.
**Output:** `plan/course-outline.md`

**Human checkpoint (required):** read the outline. Fix the audience, the length, and the lab titles. Do not start the spine until you approve this file.

**Copy-paste prompt**

```text
Read .agents/skills/course-architect/SKILL.md and follow it.
Write plan/course-outline.md. Ask only what you cannot infer.
Do not write slides or labs. Stop for my approval.
```

---

## Step 2: Course spine

**Purpose:** the opening file and the frame of every chapter. No teaching slides yet.

**Skill:** `.agents/skills/course-spine-generator/SKILL.md`

**Model:** best available. **Fresh session:** yes.

**Input:** the approved `plan/course-outline.md`
**Output:** `course/00-introduction.md`, `course/01-….md`, …, using the stock images in `course/images/`

**Copy-paste prompt**

```text
Read .agents/skills/course-spine-generator/SKILL.md and follow it.
Use the approved outline in plan/course-outline.md. Write the chapter files
under course/. Do not write teaching slides, quizzes, or lab steps.
Stop when the spine checklist passes.
```

---

## Step 3: Course content

**Purpose:** teach each section. Add quizzes, and one lab slide whose body is `Lab link: TODO`.

**Skill:** `.agents/skills/course-generator/SKILL.md`

**Model:** best available. **Fresh session:** yes (one chapter per session on a long course).

**Input:** the spine files and the outline
**Output:** teaching slides in the chapter files

**Copy-paste prompt**

```text
Read .agents/skills/course-generator/SKILL.md and follow it.
Fill chapter N (file course/0N-….md). Teach each section from the outline
and the spine. Leave the spine slides as they are. After each lab navigation
item, add one slide whose body is exactly "Lab link: TODO". Add the three
quizzes after What You Learned. Do not write a lab manual. Do not start
another chapter.
```

---

## Step 4: Instructor review

**Purpose:** an expert instructor reads the slides and edits gaps, demos, Do Nows, and discussions.

**Skill:** `.agents/skills/instructor-review/SKILL.md`

**Model:** best available. **Fresh session:** yes.

**Input:** the chapter files under `course/`
**Output:** edited slides, plus a short summary of what changed

**Copy-paste prompt**

```text
Read .agents/skills/instructor-review/SKILL.md and follow it.
Read the course under course/ and make the edits. Do not grade it against
the outline. Do not wait for approval.
```

---

## Step 5: Graphics

**Purpose:** improve layouts and diagrams across the whole deck, including slides the instructor review added.

**Skill:** `.agents/skills/course-graphics-designer/SKILL.md`

**Model:** best available. **Fresh session:** yes.

**Input:** the course after instructor review
**Output:** updated layouts and `course/images/` assets

Do not run this step on a spine-only course.

**Copy-paste prompt**

```text
Read .agents/skills/course-graphics-designer/SKILL.md and
.agents/skills/shared/svg-craft.md and follow them.
Polish the course under course/. Do not rewrite objectives or quiz answers.
Do not regenerate stock intro images. Leave every lab slide as
"Lab link: TODO". Redraw or delete SVGs that fail the svg-craft gate.
```

---

## Step 6: Technical review

**Purpose:** accuracy and currency. Fix a mistake you can verify. Record the rest.

**Skill:** `.agents/skills/technical-editor/SKILL.md`

**Model:** a **different** model from the one that wrote the course. **Fresh session:** required.

**Input:** `course/`
**Output:** corrected slides and `reviews/technical-review.md`

**Copy-paste prompt**

```text
Read .agents/skills/technical-editor/SKILL.md and follow it in this fresh session.
Read the course under course/. Verify volatile facts from current docs or
--help. Fix every mistake you can establish. Do not grade teaching, the
outline, or the spine. Write reviews/technical-review.md as a record of the
edits. Do not copy-edit.
```

---

## Step 7: Lab creation

**Purpose:** for each lab, read the slides that lead up to it, build the solution, then write the steps.

**Skill:** `.agents/skills/lab-generator/SKILL.md`

**Model:** best available. **Fresh session:** yes. One lab per session on a long course.

**Input:** the teaching slides before that lab’s slide
**Output:** `labs/lab-NN-slug/lab.md`, `images/`, `solution/` (and `starter/` if needed)

Do not start labs from the outline alone. The slides have to exist, and the technical review should already have corrected them.

**Copy-paste prompt**

```text
Read .agents/skills/lab-generator/SKILL.md and follow it.
Write the lab for the lab slide titled "LAB NAME" in course/.
Read the slides that lead up to it. Build the solution first, then lab.md.
Leave the slide body as "Lab link: TODO". Do not mark the lab as tested.
```

---

## Step 8: Lab testing

**Purpose:** run the lab as a student and record what fails.

**Skill:** `.agents/skills/lab-tester/SKILL.md`

**Model:** a different model from the one that wrote the lab, when you can. **Fresh session:** required.

**Input:** one lab folder, and the slides that lead into it
**Output:** `labs/lab-NN-slug/test-report.md`. The lab files stay unchanged.

**Copy-paste prompt**

```text
Read .agents/skills/lab-tester/SKILL.md and follow it in this fresh session.
Test labs/lab-NN-slug/ as a student. Read the slides that lead up to this lab.
Do not edit lab.md. Write labs/lab-NN-slug/test-report.md with a concrete fix
for each failure.
```

---

## Step 9: Apply the lab test

**Purpose:** fix what the test report proved.

**Skill:** `.agents/skills/lab-generator/SKILL.md`

**Model:** best available. **Fresh session:** yes.

**Input:** `labs/lab-NN-slug/test-report.md` and the lab files
**Output:** the corrected lab

**Copy-paste prompt**

```text
Read .agents/skills/lab-generator/SKILL.md and follow it.
Apply every proved failure in labs/lab-NN-slug/test-report.md.
Do not leave a suggested fix unused. Do not mark the lab as tested.
```

---

## Step 10: Copy editing

**Purpose:** spelling, grammar, house style, and consistency, in the slides and in any labs that exist.

**Skill:** `.agents/skills/copy-editor/SKILL.md`

**Model:** cheaper. **Fresh session:** required.

**Input:** the course and the labs
**Output:** in-place language fixes and `reviews/copy-edit-report.md`

Run this once, after the lab fix pass, so the labs are included.

**Copy-paste prompt**

```text
Read .agents/skills/copy-editor/SKILL.md and follow it in this fresh session.
Copy-edit the course under course/ and every labs/**/lab.md.
Fix spelling, grammar, smart quotes, em-dashes, ampersands, and consistency.
Do not change meaning, code, or layout directives. Leave "Lab link: TODO"
as written. Write reviews/copy-edit-report.md as a record of the edits.
```

---

## Step 11: Human read

Read the finished course and the labs. Add each lab URL on its slide in place of `Lab link: TODO`. That is the remaining human work.

---

## Order

```text
0 New repo
1 Course Architect, then you approve the outline
2 Course Spine Generator
3 Course Generator
4 Instructor Review
5 Course Graphics Designer
6 Technical Editor
7 Lab Generator
8 Lab Tester
9 Lab Generator applies the test report
10 Copy Editor
11 You read the course and add the lab URLs
```

One fresh session per step. Do not start the labs until the slides exist.

---

## Shared rules

Every skill that edits slides or labs follows:

- `.agents/skills/shared/slide-markdown-rules.md`
- `.agents/skills/shared/lab-markdown-rules.md`
- `.agents/skills/shared/course-spine.md`
- `.agents/skills/shared/verify-current-facts.md`

---

## Preview

- Slides: https://slidesv.roitraining.com/ (paste the GitHub URL of `course/`)
- Labs: https://labv.roitraining.com/ (paste the GitHub URL of the lab folder)
