# Copy Editor: Editing Patterns

Safe copy-edit patterns for ROI Course Factory Markdown.

---

## 1. Protect these regions

```markdown
<!-- course-title: Hands-On Terraform -->
<!-- course-theme: roi-alt-theme -->
<!-- layout: 2-column -->
<!-- TODO IMAGE: Screenshot of the BigQuery console -->

![Architecture](images/ch02-bigquery-slots.svg)

```sql
SELECT user_id FROM `project.dataset.table`
WHERE status = "active";
```

Use `gcloud` and `terraform apply` as shown in the lab.
```

Do **not** “fix” comments, paths, SQL, or inline code for grammar or smart quotes.

---

## 2. Spelling and grammar (prose only)

**Before**

```markdown
# Why Local State Fails

- Concurrent applies can corupt state without locking
- Their is no shared source of truth on one laptop
```

**After**

```markdown
# Why Local State Fails

- Concurrent applies can corrupt state without locking
- There is no shared source of truth on one laptop
```

---

## 3. Smart quotes (prose yes, code no)

**Before**

```markdown
# The "apply" step

- Don't run apply until you've read the plan
- The command is `terraform apply`
```

**After**

```markdown
# The “apply” step

- Don’t run apply until you’ve read the plan
- The command is `terraform apply`
```

Note: inline code still uses straight characters.

---

## 4. Em-dashes and ampersands

**Before**

```markdown
# Plan — then apply

- Local state is fine for demos & prototypes
# Q&A
```

**After**

```markdown
# Plan: then apply

- Local state is fine for demos and prototypes
# Questions and Answers
```

Contrast form with a normal hyphen is also fine:

```markdown
# Slides - not a textbook
```

---

## 5. Product names that look “wrong” but are correct

Do **not** change these to dictionary spellings when used as product/tech names:

| Keep | Do not “correct” to |
| :--- | :--- |
| BigQuery | Big Query / Bigquery |
| PostgreSQL | Postgre Sql / PostgresSQL (unless course standardizes on Postgres as the informal name) |
| JavaScript | Javascript |
| TypeScript | Typescript |
| GitHub | Github |
| DevOps | Dev Ops (when used as the discipline name) |
| IAM | Iam |
| gcloud | Gcloud / G Cloud (in command contexts) |
| kubectl | Kubectl |
| Cloud Run | Cloud run (mid-sentence title case for the product is OK) |
| Pub/Sub | Pub-Sub (keep official form; if `&` appears elsewhere, still avoid `&` in surrounding prose) |
| LinkedIn | Linkedin |
| npm | NPM (unless referring to the org stylization in a logo context) |

If the course mixes two accepted forms (`Postgres` vs `PostgreSQL`), prefer consistency with the dominant form already in that chapter rather than inventing a new standard mid-pass. Record the choice in the glossary.

---

## 6. Ambiguous tokens

| Token | Action |
| :--- | :--- |
| `BigQuery` in a GCP chapter | Keep |
| `big querry` | Fix to `BigQuery` |
| `terriform` | Fix to `Terraform` |
| `its` vs `it’s` | Fix from sentence meaning |
| `JSON` / `YAML` / `HTML` | Keep all caps |
| Unusual API name matching nearby code | Keep; record it in the glossary |

---

## 7. Consistency

**Before**

```markdown
# Hands On Terraform
…
- Use Big Query for analytics
- Export to BigQuery when the job finishes
```

**After**

```markdown
# Hands-On Terraform
…
- Use BigQuery for analytics
- Export to BigQuery when the job finishes
```

Pick one form per term and apply it across every chapter in scope. Do not
invent a spelling that contradicts the vendor.

---

## 8. Minimal edit principle

**Before (over-editing: do not do this)**

Turning four short bullets into a paragraph essay, or changing “Configure a remote backend with locking” to a new objective.

**After (editor scope)**

Only fix the typo/grammar/typography. Leave slide altitude and structure alone.
