# Technical Review Report Template

Write this file as `reviews/technical-review.md`. If a report already exists, add a new dated `## Pass` section instead of overwriting.

The report records what this pass already changed. Every row in Corrections is a mistake that is already fixed in the course. A claim you could not verify stays in the verification log and stays unchanged in the course. A thin explanation is not a correction.

---

````markdown
# Technical Review: Hands-On Terraform

## Pass: 2026-11-07

| Field | Value |
| :--- | :--- |
| Reviewer model | (model name) |
| Session | Fresh (yes / no) |
| Web / CLI verification | Available / not available |
| Labs in scope | Yes (`labs/lab-01-…`) / no lab files yet |
| Lab tester reports | `labs/lab-01-…/test-report.md`, or none |
| Scope | Slides, labs, or both |

### Corrections

| ID | Location | What was wrong | Change made | Source |
| :--- | :--- | :--- | :--- | :--- |
| T-1 | `01-….md` / Why Local State Fails | `terraform force-unlock` flag was wrong | Corrected the flag | Official docs, YYYY-MM-DD |
| T-2 | `02-….md` / Remote Backends | One slide said the default prefix was `terraform` and the next used `infra` | Both slides now use the documented default, `terraform` | Official docs, YYYY-MM-DD |

### Verification log

| Location | Claim | Result | Source | Date |
| :--- | :--- | :--- | :--- | :--- |
| `02-….md` / Remote Backends | `gcs` backend takes `bucket` and `prefix` | Confirmed | https://developer.hashicorp.com/terraform/language/backend/gcs | YYYY-MM-DD |
| `03-….md` / Locking | Lock timeout matches the current product default | Unverified | No web access this session | YYYY-MM-DD |

### Left unchanged

- Teaching gaps, demos, Do Nows, and discussions stay with Instructor Review
- Spelling and typography stay with the Copy Editor
- Layout and new graphics stay with the Course Graphics Designer
- A choice between two valid approaches stays as written
- A volatile claim marked unverified stays as written
````
