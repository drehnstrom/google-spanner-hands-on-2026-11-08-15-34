# Copy Edit Report Template

Write this file as `reviews/copy-edit-report.md`. If a report already exists, add a new dated `## Pass` section instead of overwriting.

The report records what this pass already changed. Every language and house-style error is already fixed in the course. A token left unchanged is one that might be an official product, command, or API name.

---

````markdown
# Copy Edit Report: Hands-On Terraform

## Pass: 2026-11-07

| Field | Value |
| :--- | :--- |
| Editor model | (model name) |
| Session | Fresh (yes / no) |
| Scope | Slides only / slides and labs (`labs/lab-01-…`) |

### Glossary

| Term | Form used | Notes |
| :--- | :--- | :--- |
| BigQuery | `BigQuery` | Standardized. Not “Big Query” |
| hands-on | `hands-on` | Hyphenated in titles and prose |
| gcloud | `gcloud` | Left as the command-style name |

### Fix counts

| Type | Count |
| :--- | :--- |
| Spelling | |
| Grammar | |
| Smart quotes | |
| Em-dashes / ampersands | |
| Consistency | |

### Representative fixes

- `01-….md` / Why Local State Fails: “corupt” → “corrupt”
- `02-….md` / Questions and Answers: `Q&A` → `Questions and Answers`

### Left unchanged

- `gcloud` and `kubectl` kept as command-style names
- Inline code and fenced samples untouched
- A name that might be an official product or API spelling, listed in the glossary
- `Lab link: TODO` on the slides
````
