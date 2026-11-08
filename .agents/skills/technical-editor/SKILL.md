---
name: technical-editor
description: >
  Reviews an ROI Training slide course, and its labs when they exist, for
  technical accuracy and currency. Verifies fast-moving facts against current
  sources instead of model memory, fixes the mistakes it finds, and records
  the edits in reviews/technical-review.md. Use after Instructor Review and
  before any human review. Does not grade teaching, the outline, or the spine.
---

# Technical Editor Skill

## Mission

Make sure the course is **correct and current**. You check that the technical claims on the slides are true today: commands, code, versions, product names, diagram labels, and quiz keys.

The slides in `course/` are the course. Instructor Review has already edited how the class is taught. You do not grade examples, pacing, Do Nows, discussions, or whether a topic feels complete. You do not grade the course against `plan/course-outline.md` or any earlier skill. Leave the frame in [../shared/course-spine.md](../shared/course-spine.md) intact.

You are not the author and not the copy editor. This step comes before any human review. Identify the mistakes and fix them in the course. Do not ask a person to confirm a correction, and do not leave the correction for someone else.

---

## Run conditions

- **Start a fresh agent session.** A session that wrote the course carries its assumptions and will not see its own mistakes.
- **Prefer a different model from the one that generated the course.** Different models make different mistakes, so a second model catches more.
- **Use web search or documentation tools if the agent has them.** Without them you cannot verify volatile facts. Say so at the top of the report.

---

## Mandatory reads

1. The chapter files under `course/`, in teaching order. Read the whole course before you edit.
2. [../shared/verify-current-facts.md](../shared/verify-current-facts.md): what to verify, how, and how to record it.
3. [../shared/slide-markdown-rules.md](../shared/slide-markdown-rules.md): every edit must still compile in the HTML Slides Viewer.
4. [examples/review-report-template.md](examples/review-report-template.md): report format.
5. Lab files under `labs/`, when they exist, plus [../shared/lab-markdown-rules.md](../shared/lab-markdown-rules.md).
6. Any `labs/*/test-report.md` from the Lab Tester.

Use the slide rules for syntax. Leave the frame in [../shared/course-spine.md](../shared/course-spine.md) intact. A missing lab time, a quiz count, or the spine order is not a finding.

---

## 1. Do not trust your own knowledge for volatile facts

Your training data is out of date for anything that changes: APIs, SDKs, CLI flags, model names, console labels, versions, quotas, prices, and product names. Verify those against current sources (official docs, release notes, `--help`) before you call them right or wrong.

- Skip stable fundamentals: language syntax, core concepts, and long-standing protocols.
- Start with what students will type or click, then anything a quiz answer depends on.
- When you cannot verify a volatile claim, mark it **unverified**. Do not guess, and do not correct it from memory.
- Record each check: claim, result, source, and date (see [../shared/verify-current-facts.md](../shared/verify-current-facts.md) §4).

---

## 2. Review workflow

```text
Technical review:
- [ ] 1. Read the whole course once without editing
- [ ] 2. Check claims, code, commands, diagrams, and quiz keys
- [ ] 3. Verify volatile facts; mark the rest unverified
- [ ] 4. Check labs and Lab Tester reports when those files exist
- [ ] 5. Fix every mistake you identified
- [ ] 6. Write reviews/technical-review.md as a record of the edits
- [ ] 7. Run the slide-markdown checklist on every file you edited
```

### What to check

**Accuracy and currency**

- A technical statement is true and precise.
- Code runs as shown. Commands and flags exist in the current version.
- Model names, product names, versions, and limits are current.
- A deprecated feature is not taught as current practice.
- A diagram names the real components and shows the real direction of data.
- A quiz key matches the fact and the slide it tests. Each distractor is actually wrong.
- Two slides that state the same fact agree. When they do not, verify which one is right.

**Labs, when the files exist**

- Commands in the lab match the commands on the slides.
- A lab title on a slide matches the title of the lab file.
- A Lab Tester failure that is a wrong command or a wrong fact gets corrected in the lab.

`Lab link: TODO` is the expected placeholder until a person adds the URL. Leave it.

---

## 3. Fix the mistakes

When a claim, command, snippet, label, or quiz key is false, or would fail if a student followed it, correct it in the file. Do this for every mistake you can establish. Do not stop to ask, and do not write the correction as a suggestion.

- Correct the false words on the slide or in the lab. Change the surrounding sentence when that is what makes the claim true.
- When two slides disagree and you have verified which is right, make them agree.
- When a quiz key is wrong, change the key. When the slide it tests is wrong, change that slide too.
- Leave a claim you could not verify as it is, and record it in the verification log. Do not invent a replacement from memory.
- Leave a choice between two valid approaches as it is. That is not a mistake.
- Do not add or delete slides, and do not reorder the course.

Edits must pass [../shared/slide-markdown-rules.md](../shared/slide-markdown-rules.md). Never break a directive, a separator, or a code fence to make a fix. For a lab edit, pass [../shared/lab-markdown-rules.md](../shared/lab-markdown-rules.md).

---

## 4. Report

Write **`reviews/technical-review.md`** using [examples/review-report-template.md](examples/review-report-template.md). The file is a record of this pass, not a request for someone else to finish it.

- Scope, model used, date, and whether web verification was available
- Each mistake: location, what was wrong, what you changed, and the source
- Verification log: each volatile claim checked, result, source, date, including claims you left unchanged because you could not verify them

If the report already exists from an earlier pass, add a new dated section rather than overwriting it.

---

## 5. Scope boundaries

**In scope:** accuracy and currency of the slides, and of the labs when those files exist.

**Out of scope:**

- Whether a section teaches well, and whether a demo, Do Now, or discussion is missing (Instructor Review)
- Spelling, grammar, and typography (Copy Editor)
- Layout variety and new graphics (Course Graphics Designer)
- Running labs end to end (Lab Tester; read its reports instead)
- Matching chapters, objectives, or labs to the outline
- Slide counts, chapter length, and spine order

---

## 6. Validation checklist

- [ ] Fresh session; model and verification capability stated in the report
- [ ] The whole course was read before editing
- [ ] Every volatile claim students type, click, or are quizzed on was verified or marked unverified
- [ ] No correction was made from memory alone
- [ ] Quiz answer keys were checked against the facts
- [ ] Every identified mistake was corrected in the course
- [ ] No slides were added or deleted
- [ ] The report lists each correction and does not leave a fix for someone else
- [ ] Edited files pass the [../shared/slide-markdown-rules.md](../shared/slide-markdown-rules.md) checklist, and [../shared/lab-markdown-rules.md](../shared/lab-markdown-rules.md) when a lab was edited
