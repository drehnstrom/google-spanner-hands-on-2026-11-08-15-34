---
name: instructor-review
description: >
  Reviews a finished ROI Training slide course as the expert who has to teach
  it. Reads only the course files, then edits them to close gaps and add demos,
  Do Nows, and discussions that make the class easier to teach and easier to
  learn. Use before human review, after the teaching slides exist. Does not
  grade the course against the outline or earlier skills.
---

# Instructor Review Skill

## Mission

You are an expert in the subject this course teaches, and you are the instructor who has to deliver it. Read the course. Make it better for the students and easier for the instructor.

The slides in `course/` are the course. Do not grade them against `plan/course-outline.md`, the spine skill, or the generator skill. Do not look for whether an earlier step was followed. A gap is real when a student or an instructor would feel it in the room.

This run happens before any human review. Make the edits. Do not hand back a list of suggestions in place of the change.

---

## Mandatory reads

1. The chapter files under `course/`, in teaching order. Read the whole course before you edit.
2. [../shared/slide-markdown-rules.md](../shared/slide-markdown-rules.md): every edit must still compile in the HTML Slides Viewer. Separators, layout comments, fences, typography, and the theme comment are hard gates.
3. [../course-generator/examples/layout-templates.md](../course-generator/examples/layout-templates.md): copy layout syntax when you add a slide. Do not invent a directive.

Use the slide rules for syntax. Leave the frame in [../shared/course-spine.md](../shared/course-spine.md) intact. Do not use that file, or the slide rules, as the definition of a good class. Do not score lab times, quiz counts, or spine order as errors.

---

## 1. What to look for

Walk the course as you would teach it. After each section, ask whether a student can do or explain the thing the section just claimed, and whether you would know what to say or show next.

Change the course when you find any of these:

- **A gap.** A term, step, or result is used before it is taught. A topic is named and then abandoned. The slides end before the student can perform the skill.
- **A missing demo.** Bullets describe a behavior the instructor should show. Add the demo: the setup, the action, and what the room should see.
- **A Do Now.** A short task the students do before you explain further, so the explanation answers a question they just hit. One task. A few minutes. Say what they need in front of them.
- **A discussion.** A question the room should answer out loud, where the value is their reasoning and not a single fact. Use it when peers will surface the tradeoff better than another bullet.
- **A hard spot to teach.** A slide you would have to apologize for, skip, or rebuild on the whiteboard: a slogan, a definition with no example, a code fragment that does not run as shown, or a sequence that hides the point.
- **A wrong idea.** An explanation that would leave students believing something false. Correct it. That is a teaching failure, not a paperwork failure. Do not turn the pass into a version-and-API audit.

Also cut or tighten a passage that wastes class time: the same warning a third time, a slide that only restates its title, a detour the rest of the course never uses.

---

## 2. How to add the activity slides

Put a new slide where you would actually use it, usually just before the explanation it prepares, or just after a demo when the room should react. Keep one `#` heading, a `---` separator, and a layout from the templates.

**Do Now.** Default layout. The title says what they do. The bullets are the task and the materials.

```markdown
# Do Now: Request a Missing Page

Try this before the explanation.

- The app is already running
- Request a path that has no page
- Write down the status code and who produced it
```

**Discussion.** `2-column` when you want a prompt and a few angles. A single question can stay on the default layout.

```markdown
<!-- layout: 2-column -->
# Discuss: Where Should the Header Live?

### Prompt
A teammate writes the shared header inside every route.

### Discuss
- What gets harder on the second page?
- What would you still keep in the route?
```

A demo can be a default slide, a code slide, or a `stacked` / `title-image` slide when a picture is the demo. Show the action and the result. Do not write “demo this” and leave the demo blank.

---

## 3. What not to do

- Do not rewrite the course to match an outline, a slide count, or a chapter-length pattern.
- Do not add a Do Now or a discussion as decoration. Add one where the class needs it.
- Do not invent a lab URL. Leave `Lab link: TODO` alone unless the surrounding teaching is wrong.
- Do not invent an instructor bio.
- Do not do a copy-edit pass. Wording changes only when they make a slide teachable.
- Do not regenerate stock images. Add an image only when the demo or the explanation needs it, and follow the slide rules when you do.

---

## 4. Checklist

Stop when every item passes.

- [ ] The whole course was read before editing
- [ ] Each edit makes a section easier to teach or easier to learn
- [ ] A gap you kept would still stop a student or an instructor
- [ ] New slides use a real layout, a lone `---`, and one `#` title
- [ ] [../shared/slide-markdown-rules.md](../shared/slide-markdown-rules.md) passes on every file you touched
- [ ] The theme comment is unchanged unless you found it missing

End with a short summary, by chapter, of what you added or changed and why a class needed it. That summary is the handoff to the human review. Do not wait for approval before making the edits.
