# Lab Test Report Template

Write this file as `labs/lab-NN-slug/test-report.md`. If a report already
exists, add a new dated `## Pass` section instead of overwriting.

---

````markdown
# Test Report: Lab 1: Deploy Your First Terraform Configuration

## Pass: 2026-11-07

| Field | Value |
| :--- | :--- |
| Tester model | (model name) |
| Session | Fresh (yes / no) |
| Environment | macOS, Terraform 1.x, gcloud, Cloud Shell (or local) |
| Credentials | Available / not available |
| Time Required in lab.md | 30 minutes |
| Time taken (required tasks) | (minutes, or not timed) |

### Overall

**Fail** (or Pass / Blocked)

One-sentence reason: Task 2 step 4 uses a flag that no longer exists.

### Tasks

| Task | Result | Notes |
| :--- | :--- | :--- |
| Task 1: Prepare your environment | Pass | |
| Task 2: Write and apply a bucket resource | Fail | Step 4, see I-1 |
| Task 3: Add variables and outputs | Blocked | Depends on Task 2 |
| Bonus Task 4: … | Not run | |

### Issues

| ID | Task / step | What happened | Suggested fix | Verified? |
| :--- | :--- | :--- | :--- | :--- |
| I-1 | Task 2 / step 4 | `terraform apply -auto-yes` fails: unknown flag | Use `-auto-approve` | Confirmed: `terraform apply -help`, YYYY-MM-DD |

### Images

| Path | Result |
| :--- | :--- |
| `images/create-bucket.png` | Present |
| `images/apply-output.png` | Missing; TODO IMAGE comment present |

### Verification log

| Claim | Result | Source | Date |
| :--- | :--- | :--- | :--- |
| `-auto-approve` is the current flag | Confirmed | `terraform apply -help` | YYYY-MM-DD |

### Could not test

- Console screenshots: no GUI session
- State locking with two applies: only one identity available

### Alignment with the slides

The slides before this lab teach a versioned remote backend and a state migration.

- Practiced: creating the bucket and migrating state.
- Missing: the slides show a lock failure. No required task makes the student cause one.
- Taught too early: none.

### Alignment with solution/

- Following the steps as far as Task 2 did not produce `solution/main.tf` as written because apply never succeeded.

A later Lab Generator pass applies the fixes in this report.
````
