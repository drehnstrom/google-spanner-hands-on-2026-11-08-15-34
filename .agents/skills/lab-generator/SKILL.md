---
name: lab-generator
description: >
  Designs and writes ROI Training hands-on lab manuals as Markdown for the HTML
  Lab Viewer. Studies the slides that lead up to a lab and writes tasks that
  make students practice that material. Builds the finished solution first,
  then the steps. Use when creating or fixing labs, including a pass that
  applies a Lab Tester report.
---

# Lab Generator Skill

Write the lab that makes students do what the course just taught. The manual compiles in the [HTML Lab Viewer](https://labv.roitraining.com/) as one Markdown document.

The slides already explained the idea. The lab is the practice: the same skills, in the same order, with the tools and examples those slides used.

---

## Mandatory reads

1. The chapter files under `course/`, in teaching order, through the lab slide you are writing. Read the whole stretch. The slides since the previous lab, or from the first teaching slide when this is the first lab, are the skills this lab enforces. Stop before the lab slide itself. Its body is `Lab link: TODO`.
2. [../shared/lab-markdown-rules.md](../shared/lab-markdown-rules.md): structure, syntax, typography, images, conformance checklist.
3. [examples/lab-template.md](examples/lab-template.md): copy this skeleton.
4. `labs/lab-01-sample-lab-viewer-format/lab.md`: reference sample, when that file is in the repo.
5. [../shared/verify-current-facts.md](../shared/verify-current-facts.md): verify commands, flags, and UI labels while you build.
6. `labs/lab-NN-slug/test-report.md` when it exists. Apply the failures it established.

If the chapter files are missing, stop. Say that the teaching slides have to exist first. Do not ask for an outcome, a time, or an environment, and do not invent a lab from the outline. The outline lists titles. The slides are the course.

---

## 1. What this lab practices

Find the lab slide. The title is the lab name.

Then list the skills in the teaching slides that lead up to it. A required task practices one of those skills. The tasks follow the order of the slides. Use the tools, data, and examples the slides used.

- A step that needs a command, a concept, or a tool those slides have not taught does not belong in this lab.
- A skill those slides taught, which this lab is the place to practice, has a task. Leaving it out means the lab did not enforce the course.
- Do not reteach the section. One or two sentences can say what a task achieves. The steps are the work.
- Take the audience from the course. Do not assume a default level.
- The starting state is what those slides, and any earlier lab, say the student already has. Put files they need in `starter/`. Setup they still have to do goes in Task 1.

When a `test-report.md` exists, fix every failure it proved: the broken command, the wrong label, the step out of order, and a task that does not match the slides. Do not leave a suggested fix unused.

---

## 2. Workflow: solution first, then steps

Build the finished result first, then write the path to it. Steps written before the solution exists produce a lab that does not work.

### Build the finished solution

- Build the end state that shows the student can do what the preceding slides taught. Do it for real when you have the tools and access.
- Save solution files under `labs/lab-NN-slug/solution/`.
- Write `solution/README.md` with the finished state, how to verify it, and the versions and tools used, with the date.
- For a lab that produces no files, `solution/README.md` describes the end state and how to check it.
- If you cannot build it, write the most accurate solution you can and mark every unverified part. Record that for the Lab Tester.

### Write the steps

- Take the shortest path from the starting state to that solution that still practices each required skill.
- Group the work into tasks that each produce a visible result. Do not pad or cut the tasks to hit a count.
- Add a Bonus Task only when it stretches the same skill without teaching a new topic. Omit it when that stretch does not exist.
- Every command and code block in `lab.md` matches the solution files.
- When a step copies a starter file, give the exact relative path from the lab folder, such as `starter/README.md`, and the destination.

### Time and the slide

- Set **Time Required** to how long the required tasks take for this audience.
- Do not drop a skill the slides require in order to hit a shorter number.
- Leave the lab slide as it is. The title stays the lab name. The body stays `Lab link: TODO`. Do not add a time or a URL.

### Images

- Capture a real screenshot for a non-obvious UI step when you can.
- Otherwise use an image reference, `<!-- TODO IMAGE: … -->`, and a labeled placeholder file. See [../shared/lab-markdown-rules.md](../shared/lab-markdown-rules.md).

### Then stop

- Run the lab conformance checklist and the checklist at the end of this skill.
- Do not grade your own lab as tested. The Lab Tester does that in a fresh session.
- Record what you could run and what you could not. That record is for the tester.

---

## 3. Folder layout

```text
labs/
  lab-01-getting-started/
    lab.md             # the manual (preferred filename)
    images/
    solution/          # finished result + README.md (how to verify)
    starter/           # optional: files students start from
```

- Folder: `lab-NN-short-kebab-slug`, aligned with the lab’s place in the course.
- Preview by pasting the GitHub URL of the lab folder into the [Lab Viewer](https://labv.roitraining.com/).

---

## 4. How to write the manual

Structure, headings, syntax, and typography come from [../shared/lab-markdown-rules.md](../shared/lab-markdown-rules.md).

Voice is second person (*you*), simple present. Steps begin with an imperative: Click, Run, Create, Configure.

### Overview

```markdown
## Overview

In this lab, you will configure a remote backend and migrate Terraform state for team use.

### You learn how to:
- Create a remote state bucket with versioning enabled.
- Configure a Terraform backend and migrate state.
- Verify that state locking prevents concurrent applies.
```

One learning bullet per primary task. The bullets are the skills from the slides, not a new list of topics. Congratulations mirrors them in past tense.

A short Scenario is useful when the slides set up a problem the lab continues. Omit it when the Overview is enough.

### Task body

1. One or two sentences on what this task achieves.
2. Numbered steps, one primary action each, with a blank line between steps.
3. Commands introduced by their purpose (“To list regions, run:”), in fenced blocks with a language tag.
4. Screenshots for non-obvious UI. Do not screenshot text that belongs in a code block.
5. A callout after the step it applies to, not on every step.
6. A short success check when the student needs to know the step worked.

| Alert | Use when |
| :--- | :--- |
| `> [!NOTE]` | Helpful context, expected results, “you should see…” |
| `> [!IMPORTANT]` | A constraint the student must follow |
| `> [!WARNING]` | A mistake, a destructive action, or an easy miss |
| `> [!TIP]` | An optional shortcut |
| `> [!CAUTION]` | A high-risk action |

---

## 5. What this skill does not do

- It does not write or restyle the slide deck.
- It does not put a URL or a time on the lab slide.
- It does not invent credentials, project IDs, or secrets. Use placeholders such as `YOUR_PROJECT_ID`.
- It does not invent a product screenshot and present it as real.
- It does not add a separate Setup or Prerequisites section. Setup goes in Task 1.
- It does not author Qwiklabs YAML or `ql-*` markup.
- It does not mark the lab as tested.

---

## 6. Validation checklist

- [ ] The slides leading up to this lab were read before any step was written
- [ ] Each required task practices a skill from those slides, in that order
- [ ] No task depends on a tool or an idea those slides never taught
- [ ] No skill those slides assigned to this lab is missing
- [ ] [../shared/lab-markdown-rules.md](../shared/lab-markdown-rules.md) conformance checklist passes
- [ ] `solution/` exists, with `README.md` describing the end state and how to verify it
- [ ] Every command and code block in `lab.md` matches the solution
- [ ] Starting state is clear, and `starter/` exists when students need files
- [ ] Every “copy this file” step names the source path and the destination
- [ ] **Time Required** matches the required work, and no required practice was cut to shrink it
- [ ] The lab slide still has the lab title and the body `Lab link: TODO`
- [ ] Volatile commands, flags, UI labels, and versions are verified or marked unverified
- [ ] A `test-report.md`, when one existed, has had its proved failures fixed
- [ ] The record for the Lab Tester lists what was run and what was not
