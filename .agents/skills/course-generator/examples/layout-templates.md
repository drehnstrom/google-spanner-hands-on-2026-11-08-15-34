# Course Generator Slide Layout Templates

Copy and paste these templates when building decks for the HTML Slides Viewer.
See [SKILL.md](../SKILL.md) for phases and teaching craft,
[../../shared/course-spine.md](../../shared/course-spine.md) for required slide order, and
[../../shared/slide-markdown-rules.md](../../shared/slide-markdown-rules.md) for the formatting gates.

---

## 0. Course file layout

**Default (multi-chapter / full courses):**

```text
course-root/
  00-introduction.md
  01-getting-started.md
  02-basic-language-syntax.md
  images/
    roi-logo-with-name.png      # stock: copy from template
    welcome.png                 # stock
    agenda.png                  # stock
    who-should-attend.png       # stock
    prerequisites.png           # stock
    qa.png                      # stock (optional Q and A visual)
    ch01-architecture-overview.png
    ch02-console-screenshot.png   # may be a TODO placeholder target
```

Copy the **stock** files from `course/images/` in this template (do not regenerate). Wire them on Welcome, Agenda, Who Should Attend, Prerequisites, and optionally Questions and Answers.

**Short-course exception:** one Markdown file (e.g. `course.md`) is fine for a thin single-sitting deck. Split when the outline becomes multi-chapter.

Every Markdown file starts with the **same** course-title and course-theme metadata (or once at the top of a single-file short course):

```markdown
<!-- course-title: Hands-On Terraform -->
<!-- course-theme: roi-alt-theme -->
```

---

## 1. Title / Chapter Divider

```markdown
<!-- layout: title -->
![ROI Logo](images/roi-logo-with-name.png)

# Hands-On Terraform
```

Chapter divider variant:

```markdown
<!-- layout: title -->
![ROI Logo](images/roi-logo-with-name.png)

Hands-On Terraform

# Chapter 2: State and Remote Backends
```

---

## 2. Welcome (Introduction chapter)

`<!-- layout: panel-right -->`. Bullets stay in the light area. `welcome.png` is centered in the colored third. **Required** for the introduction when using this template’s stock set.

```markdown
<!-- layout: panel-right -->
# Welcome!

- ROI leads the industry in designing and delivering customized technology and management training solutions
- Meet your instructor
  - Name
  - Background
  - Contact info
- Let’s get started!

![Welcome](images/welcome.png)
```

Do **not** invent a fictional instructor: leave Name / Background / Contact info as placeholders unless the user provides details.

---

## 3. Course Objectives (1 overall + one per chapter)

```markdown
# Course Objectives

- Build and operate production Terraform workflows with remote state, modules, and safe apply practices
- Get productive with Terraform core workflow and providers
- Manage remote state, locking, and collaboration
- Design reusable modules and workspaces
- Apply policy, testing, and delivery patterns
```

(First bullet = overall course objective; following bullets = one per content chapter.)

---

## 4. Course Agenda (chapter list)

Course-level orientation (distinct from per-section Navigation):

`<!-- layout: panel-left -->`. Chapter list stays in the light area. `agenda.png` is centered in the colored third.

```markdown
<!-- layout: panel-left -->
# Agenda

- Chapter 1: Getting Started with Terraform
- Chapter 2: State and Remote Backends
- Chapter 3: Modules and Workspaces
- Chapter 4: Delivery and Guardrails

![Agenda](images/agenda.png)
```

This is the course-level agenda, not section Navigation. Do not use `<!-- layout: navigation -->` here.

---

## 5. Who Should Attend / Prerequisites

Who Should Attend uses `<!-- layout: panel-right -->`. Prerequisites uses `<!-- layout: panel-left -->`. Bullets stay in the light area. The stock image is centered in the colored third.

```markdown
<!-- layout: panel-right -->
# Who Should Attend

- Cloud engineers and DevOps practitioners
- Developers who own infrastructure as code
- Technical leads standardizing IaC practices

![Who Should Attend](images/who-should-attend.png)
```

```markdown
<!-- layout: panel-left -->
# Prerequisites

- Comfortable with the Linux command line
- Familiar with at least one major cloud console (AWS, Azure, or GCP)
- Basic Git workflows (clone, commit, push)

![Prerequisites](images/prerequisites.png)
```

---

## 6. Chapter Objectives

```markdown
# Chapter 2: Objectives

- Explain why local state fails for teams
- Configure a remote backend with locking
- Recover from common state drift scenarios
```

---

## 7. Section Navigation (full list, one bold)

Repeat before **each** section. Same list every time; move the bold.

```markdown
<!-- layout: navigation -->
# Chapter 2

- **Why State Matters**
- Remote Backends
- State Locking and Conflicts
- Drift and Recovery
```

Later in the chapter:

```markdown
<!-- layout: navigation -->
# Chapter 2

- Why State Matters
- **Remote Backends**
- State Locking and Conflicts
- Drift and Recovery
```

---

## 8. Default Content (+ alerts)

```markdown
# Why Local State Fails

- **Single laptop**: state lives on one machine
- **No locking**: concurrent applies can corrupt state
- **Secrets risk**: state may contain sensitive values
- **No history**: hard to audit who changed what

> [!WARNING]
> Never commit `terraform.tfstate` to git.
```

Alert examples:

```markdown
> [!NOTE]
> Background context the instructor can expand on.

> [!TIP]
> A shortcut experienced practitioners use.

> [!IMPORTANT]
> A rule students must not miss.

> [!CAUTION]
> Strong caution before a destructive action.
```

---

## 9. Auto-Split (list + image, no layout directive)

```markdown
# Remote Backend Shape

- **Bucket / container** stores state objects
- **Lock table** prevents concurrent writes
- **IAM / identity** scopes least privilege
- **Encryption** at rest is mandatory

![Backend Diagram](images/ch02-remote-backend-diagram.png)
```

---

## 10. Two-Column / Three-Column

```markdown
<!-- layout: 2-column -->
# Local vs Remote State

### Local
- Fast for solo prototypes
- No team sharing
- Easy to lose or overwrite

### Remote
- Shared source of truth
- State locking
- Audit-friendly workflows
```

```markdown
<!-- layout: 3-column -->
# Backend Options

### Amazon S3
- DynamoDB locks
- Common in AWS shops

### Azure Blob
- Native lease locking
- Entra ID auth patterns

### GCS
- Object generation preconditions
- Strong GCP IAM fit
```

Prefer the house style when it helps teaching (thesis-first, ~3–4 main bullets, optional sub-bullets, **two levels max**). If you need deeper structure, use a **table** or columns, or split the slide. **Teaching quality wins** over blind bullet-count compliance; viewer syntax remains a hard constraint.

### Full-width callout below columns

By default, alerts placed after a column header stay **inside that column**. To put a NOTE/WARNING under the whole column row (full slide width), end the column region with:

```markdown
<!-- layout: 2-column -->
# Local vs Remote State

### Local
- Fast for solo prototypes
- No team sharing

### Remote
- Shared source of truth
- State locking

<!-- below-columns -->

> [!WARNING]
> This warning spans the full slide width under both columns.
```

The same `<!-- below-columns -->` marker works with `<!-- layout: 3-column -->`.

---

## 10c. Card layout

Each `###` heading becomes a card title. Dash list items under that heading become **sentences** in the card body (the viewer strips the bullets). Prefer complete sentences. Three cards sit in a row; four cards use a 2-by-2 grid.

```markdown
<!-- layout: card-layout -->
# Choose a Backend Shape

### Locking
- Concurrent writes must be blocked before they corrupt state.
- Pick a lock that the team already knows how to operate.

### Durability
- State belongs in a service with versioning and encryption at rest.
- Local files are fine for a prototype and risky the moment two people apply.

### Access
- Grant the pipeline identity only what it needs to read and write state.
- Do not share a personal credential across laptops.
```

Aliases: `<!-- layout: cards -->` or `<!-- layout: card -->`.

---

## 11. Title-Image

```markdown
<!-- layout: title-image -->
# Reference Architecture

![System Diagram](images/ch02-reference-architecture.png)
```

---

## 11a. Image-only (tray title, no on-slide heading)

Use when the diagram should fill the stage with **no visible title**. Keep an `#` heading in Markdown so the slide drawer still has a useful label.

```markdown
<!-- layout: image-only -->
# Reference Architecture

![System Diagram](images/ch02-reference-architecture.png)
```

Alias: `<!-- layout: image -->` also works.

---

## 11a1. Panel left and panel right

The colored third comes from the active theme (solid ROI blue, or the Holcim gradient). Title and bullets stay in the light two-thirds. An image is centered in the colored third. The top bar and footer stay visible.

**Introduction standard** (copy sections 2, 4, and 5, do not invent a different shape):

| Slide | Layout | Image |
| :--- | :--- | :--- |
| Welcome! | `panel-right` | `images/welcome.png` |
| Agenda | `panel-left` | `images/agenda.png` |
| Who Should Attend | `panel-right` | `images/who-should-attend.png` |
| Prerequisites | `panel-left` | `images/prerequisites.png` |

Aliases: `<!-- layout: left-panel -->` and `<!-- layout: right-panel -->`.

The image is optional on other slides. Without one, the colored third is empty and the title still sits in the light area.

---

## 11a2. Full-bleed (covers top bar and footer)

Use when the image should fill the **entire 16:9 slide**, overlapping the accent bar and footer. Keep an `#` heading so the drawer still has a label. The image uses `cover` (fills the canvas; may crop).

```markdown
<!-- layout: full-bleed -->
# Opening Visual

![Keynote photo](images/ch01-opening-visual.png)
```

Aliases: `<!-- layout: bleed -->` or `<!-- layout: full-bleed-image -->`.

Do **not** use this when you still want the ROI footer and top bar. That is `image-only`.

---

## 11b. Stacked (content top, image below)

Use when bullets and a wide diagram belong on the same slide, but auto-split (side-by-side) is the wrong shape.

```markdown
<!-- layout: stacked -->
# From Chatbots to Agents

- A chatbot answers one prompt at a time - you drive every step
- An agent pursues a goal: it plans, acts, checks results, and keeps going
- The shift is giving the model a loop, tools, and permission to act

![From chatbots to agents](images/chatbots-to-agents.png)
```

Alias: `<!-- layout: stack -->` also works.

---

## 12. Code teaching slide

~~~~markdown
# Declaring a Remote Backend

- Backends are configured in Terraform, not variables
- Changing backend settings requires a migration workflow

```hcl
terraform {
  backend "s3" {
    bucket         = "tf-state-prod"
    key            = "network/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-locks"
    encrypt        = true
  }
}
```
~~~~

Always include a language tag on fences.

---

## 13. Image placeholder (human must supply)

When you cannot create an accurate asset (e.g. real product UI):

```markdown
# Enable Bucket Versioning

- Turn on versioning before migrating state
- Confirm the setting in the cloud console

<!-- TODO IMAGE: Screenshot of AWS S3 console showing bucket versioning enabled -->
![S3 versioning console](images/ch02-s3-versioning-screenshot.png)
```

Generate custom diagrams/infographics/photos into `images/` when you can; use TODO placeholders when you cannot.

---

## 14. Lab slide

The Course Generator inserts this after the lab’s navigation slide. The title is the lab name. The body is one line. Do not write a time, a URL, or lab steps. A person adds the link later. The Lab Generator writes the manual.

```markdown
# Configure Remote State

Lab link: TODO
```

---

## 15. What You Learned (past tense of Chapter Objectives)

```markdown
# What You Learned

- Explained why local state fails for teams
- Configured a remote backend with locking
- Recovered from common state drift scenarios
```

---

## 16. Chapter quizzes (default: content chapters only)

Place after What You Learned and **before** Questions and Answers. Skip for Introduction and course-summary/office-hours closers; omit if the chapter is very short or the user declines quizzes.

### Quiz 1–2 (multiple choice + answer)

```markdown
# Quiz 1 of 3

**Why does local Terraform state fail for teams?**

- A. It is always encrypted at rest
- B. Concurrent applies can corrupt state without locking or a shared backend
- C. Providers cannot authenticate when state is local
- D. Remote backends disable versioning

---

# Quiz 1: Answer

**Why does local Terraform state fail for teams?**

**Correct: B.** Concurrent applies can corrupt state without locking or a shared backend

- Local state lives on one machine: no shared source of truth
- Without locking, two applies can overwrite each other
- Secrets in state increase risk if the file is copied or committed
- Remote backends + locking are the usual team fix
```

(Repeat as `Quiz 2 of 3` / `Quiz 2: Answer`.)

### Quiz 3 (open discussion + discussion points)

```markdown
<!-- layout: 2-column -->
# Quiz 3 of 3: Discussion

### Prompt
Your team still keeps `terraform.tfstate` on laptops for a shared network stack.

### Discuss
- What failure mode worries you most?
- What minimum remote-backend controls would you require?
- Who approves the first migration?

---

<!-- layout: 2-column -->
# Quiz 3: Discussion Points

**Your team still keeps `terraform.tfstate` on laptops for a shared network stack.**

### Strong Answers Mention
- Concurrent apply / lost updates
- Secret leakage via copied state files
- Backend with locking, encryption, least-privilege IAM
- Named owner for migration and rollback

### Watch For
- “We are careful, so local is fine”
- Migrating without a rollback plan
- Broad write credentials on the state bucket
```

---

## 17. Questions and Answers

**Default:** title + `Questions?` body.

**Template alternative:** stacked layout with stock `qa.png` (title only, no `Q&A` / ampersand).

```markdown
# Questions and Answers

Questions?
```

```markdown
<!-- layout: stacked -->
# Questions and Answers

![Questions and Answers](images/qa.png)
```

---

## 18. Assemble files

**Spine, `00-introduction.md`:** Title → Welcome (`panel-right` + `welcome.png`) → Course Objectives → Agenda (`panel-left` + `agenda.png`) → Who Should Attend (`panel-right` + `who-should-attend.png`) → Prerequisites (`panel-left` + `prerequisites.png`)

**Spine, each content `0N-….md` chapter:** Title → Chapter Objectives → one navigation slide per section (a lab is a section) → What You Learned → Questions and Answers (`Questions?`)

**Course Generator then inserts:** teaching slides after each navigation slide that is not a lab; one lab slide after each lab navigation item; three quizzes (2 multiple choice with answers, then a discussion and discussion points) after What You Learned and before Questions and Answers.

No quizzes in the introduction. Omit the chapter quizzes only when the user says so.

Ensure `images/` includes the stock set: `roi-logo-with-name.png`, `welcome.png`, `agenda.png`, `who-should-attend.png`, `prerequisites.png`, `qa.png`. Do not regenerate them.

---

## 19. Spine skeleton

This is a content chapter after the **spine** skill. There are no teaching slides, no quizzes, and no lab slide yet.

```markdown
<!-- course-title: Hands-On Terraform -->
<!-- course-theme: roi-alt-theme -->

<!-- layout: title -->
![ROI Logo](images/roi-logo-with-name.png)

Hands-On Terraform

# Chapter 2: State and Remote Backends

---

# Chapter 2: Objectives

- Explain why local state fails for a team and how a remote backend fixes it
- Explain why two people applying from laptops lose updates
- Configure a remote backend and migrate the existing state

---

<!-- layout: navigation -->
# Chapter 2

- **Why State Matters**
- Lab: Configure Remote State

---

<!-- layout: navigation -->
# Chapter 2

- Why State Matters
- **Lab: Configure Remote State**

---

# What You Learned

- Explained why local state fails for a team and how a remote backend fixes it
- Explained why two people applying from laptops lose updates
- Configured a remote backend and migrated the existing state

---

# Questions and Answers

Questions?
```

The content skill inserts teaching slides after the first navigation slide. After the lab navigation slide it inserts one slide, and nothing else about the lab:

```markdown
# Configure Remote State

Lab link: TODO
```

It then inserts the three quizzes between What You Learned and Questions and Answers.
