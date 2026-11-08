# Labs

Hands-on lab Markdown for this course lives in this folder.

## Layout

```text
labs/
  lab-01-short-slug/
    lab.md         # lab manual (preferred name)
    images/        # screenshots and diagrams
    solution/      # finished result (build this first)
    starter/       # optional starting files
    test-report.md # Lab Tester output
  lab-02-…
```

## Authoring

Follow the **Lab Generator** skill (solution first, then steps):

- [.agents/skills/lab-generator/SKILL.md](../.agents/skills/lab-generator/SKILL.md)
- [.agents/skills/lab-generator/examples/lab-template.md](../.agents/skills/lab-generator/examples/lab-template.md)
- [.agents/skills/shared/lab-markdown-rules.md](../.agents/skills/shared/lab-markdown-rules.md)

Ask your coding agent, for example: *“Using the Lab Generator skill, write the lab for the lab slide in course/. Read the slides that lead up to it.”*

Test with the **Lab Tester** skill in a fresh session. It writes `test-report.md` and does not rewrite the lab. A later Lab Generator pass applies that report.

## Preview

Use the [HTML Lab Viewer](https://labv.roitraining.com/) and paste a GitHub URL to the **lab folder**.

## Sample

The authoring template repository includes `labs/lab-01-sample-lab-viewer-format/` as a format reference. New course repos created with `scripts/new-course.sh` do not copy it. Use `.agents/skills/lab-generator/examples/lab-template.md` when writing a lab.
