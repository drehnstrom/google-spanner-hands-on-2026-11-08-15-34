---
name: lab-tester
description: >
  Tests an ROI Training lab as a student would, without rewriting it. Runs the
  steps, checks that the lab practices the slides that lead into it, and writes
  labs/lab-NN-slug/test-report.md for a later Lab Generator pass. Use when
  testing a lab, verifying lab steps, or acting as the Lab Tester after Lab
  Generator.
---

# Lab Tester Skill

## Mission

Prove that a named lab works for a student, and that the work practices the slides that lead into it. Follow `lab.md` as written. Do not rewrite it.

When a command, a label, the order, or the fit with the slides fails, write the failure and a concrete fix in `test-report.md`. A later Lab Generator pass applies that report. Do not ask a person to repair the lab, and do not patch it yourself.

**Run in a fresh agent session.** A session that wrote the lab will skip steps it remembers and miss a broken order.

---

## Mandatory reads

1. The lab’s `lab.md`, `solution/README.md`, and any `starter/` files. A missing `solution/` is a finding. Still test `lab.md`.
2. The teaching slides that lead up to this lab’s slide. Start after the previous lab slide, or at the first teaching slide when this is the first lab. Stop at the lab slide. Its body is `Lab link: TODO`.
3. [../shared/lab-markdown-rules.md](../shared/lab-markdown-rules.md): structure and syntax to report against. Do not edit the lab to satisfy them.
4. [../shared/verify-current-facts.md](../shared/verify-current-facts.md): when a step fails or looks out of date.
5. [examples/test-report-template.md](examples/test-report-template.md): report format.

The outline is not the lab plan. The slides define what the student should be able to do. **Time Required** in `lab.md` is the time you compare against.

---

## 1. Workflow

```text
Lab test:
- [ ] 1. Read the preceding slides, lab.md, and solution/ without editing
- [ ] 2. Confirm the starting state (accounts, tools, starter files)
- [ ] 3. Execute every required task as a student, in order
- [ ] 4. Attempt the Bonus Task if time and access allow
- [ ] 5. Compare the result to solution/README.md
- [ ] 6. Compare the tasks to the preceding slides
- [ ] 7. Check images, timing, and structure
- [ ] 8. Write labs/lab-NN-slug/test-report.md
```

### How to run

- Follow the steps literally. If a step says “click Create,” look for that label. Do not substitute a different command.
- Restart numbering per task, the way the student sees it.
- Use the tools the lab names.
- Do not skip setup in Task 1 because your environment is already configured, unless the report says you started from a warmer state.

### When a step fails or looks out of date

Do not guess a fix into `lab.md`. Follow [../shared/verify-current-facts.md](../shared/verify-current-facts.md):

1. Check current docs, release notes, or `--help`.
2. Record the claim, the result, the source, and the date.
3. Write a concrete fix: the replacement command, the new label, or the extra step.
4. Leave the lab file unchanged.

Stable fundamentals, such as language syntax and Git basics, do not need a lookup.

---

## 2. What to check

| Check | Pass when |
| :--- | :--- |
| Commands | They run as written. Flags exist. Expected output appears. |
| UI labels | Menus, buttons, and fields match the current product. |
| Ordering | No step depends on something a later step creates. |
| Starting state | A new student can begin where Task 1 says. |
| Solution match | Following the steps produces what `solution/` describes. |
| Course fit | Each required task practices a skill from the slides that lead into this lab. No task needs a tool or an idea those slides never taught. A skill those slides assigned to this lab is actually practiced. |
| Images | Every `images/…` path exists. Alt text is present. A placeholder is marked with TODO. |
| Timing | A student at the course’s level can finish the required tasks in the **Time Required** stated in `lab.md`. |
| Structure | Headings and alerts match [../shared/lab-markdown-rules.md](../shared/lab-markdown-rules.md). |
| Secrets | No real project IDs, keys, or credentials are committed. |

Mark each task pass, fail, or blocked.

---

## 3. Do not rewrite the lab

- Do not edit `lab.md`, `solution/`, or images to make the lab pass.
- Do not skip a broken step and continue as if it worked. Stop that path, record it, and resume only when a later task is independent.
- A one-character typo that causes the failure still goes in the report. Do not patch it.

The Lab Generator applies the report in a later session.

---

## 4. Report

Write **`labs/lab-NN-slug/test-report.md`** using [examples/test-report-template.md](examples/test-report-template.md). The file is the input to the next Lab Generator pass.

Include:

- Environment: OS, tools, versions, date, and whether credentials were available
- Per-task result: pass, fail, or blocked
- Each issue with the step number, what happened, and a concrete fix
- Timing against **Time Required** in `lab.md`
- Alignment with the preceding slides, and with `solution/`
- What could not be tested, and why
- A verification log for any volatile claim you checked

If a report already exists, add a new dated pass section.

---

## 5. Scope

**In scope:** one named lab, or each lab in the list you were given. Execute it and evaluate it.

**Out of scope:** writing or editing the lab, writing slides, copy editing, and calling the lab tested because you read it.

---

## 6. Validation checklist

- [ ] Fresh session
- [ ] Preceding slides were read before the tasks were judged
- [ ] The lab was executed as a student, or the blocked reason is recorded
- [ ] Each required task is pass, fail, or blocked
- [ ] Course fit is recorded: skills practiced, skills missing, and anything the slides never taught
- [ ] Each failure has a step number, evidence, and a concrete fix
- [ ] A volatile failure was checked against a current source, or marked unverified
- [ ] Image paths were checked
- [ ] Timing was compared with **Time Required** in `lab.md`
- [ ] `lab.md` was not rewritten
- [ ] `labs/lab-NN-slug/test-report.md` was written
