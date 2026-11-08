# Lab Generator — copy-paste template

Copy this skeleton when creating a new lab. See [SKILL.md](../SKILL.md) for the
solution-first workflow and [../../shared/lab-markdown-rules.md](../../shared/lab-markdown-rules.md)
for the formatting gates. Emulate the sample at `labs/lab-01-sample-lab-viewer-format/lab.md`.

Place files at:

```text
labs/lab-NN-short-slug/lab.md
labs/lab-NN-short-slug/images/     # screenshots and diagrams
labs/lab-NN-short-slug/solution/   # finished result + README.md (built first)
labs/lab-NN-short-slug/starter/    # optional starting files
```

## Solution README skeleton

Write this **before** `lab.md`:

````markdown
# Solution: Configure Remote State for Terraform

## End State

- A versioned GCS bucket named `YOUR_PROJECT_ID-tf-state`
- Terraform configuration in `main.tf` using the `gcs` backend with prefix `demo`
- State object stored at `gs://YOUR_PROJECT_ID-tf-state/demo/default.tfstate`

## How to Verify

```bash
gcloud storage ls "gs://${PROJECT_ID}-tf-state/demo/"
terraform state list
```

Expected: the state object is listed, and `terraform state list` shows the bucket resource.

## Built With

- Terraform 1.x, Google provider 6.x, Cloud Shell (checked YYYY-MM-DD)
- Unverified: (list anything you could not run)
````

## Lab manual skeleton

**Heading case:** Title Case for `#` and `##`. Task headings: `### Task N: …` with sentence case after the colon.

**Preview:** [https://labv.roitraining.com/](https://labv.roitraining.com/) — paste the GitHub URL to the **lab folder**.

---

````markdown
# Configure Remote State for Terraform

## Time Required

30 minutes

## Overview

In this lab, you will configure a remote backend so Terraform state is stored safely for team use. You create the storage resources, update the backend block, migrate existing state, and verify locking behavior.

### You learn how to:
- Create a remote state bucket with versioning enabled.
- Configure a Terraform backend and migrate state.
- Verify that state locking prevents concurrent applies.

## Scenario

Your team is moving from laptop-local Terraform state to a shared backend. Without remote state and locking, two engineers can overwrite each other’s changes and leave infrastructure inconsistent.

## Lab Instructions

### Task 1: Prepare your environment and create the state bucket

In this task, you sign in, select your project, and create the storage bucket that holds Terraform state objects.

1. Sign in to your cloud console and select your lab project.

2. Open Cloud Shell (or your local terminal with cloud SDK authenticated).

3. Set your project ID:

```bash
export PROJECT_ID="$(gcloud config get-value project)"
```

4. Create a uniquely named bucket (replace the suffix if needed):

```bash
gcloud storage buckets create "gs://${PROJECT_ID}-tf-state" \
  --project="${PROJECT_ID}" \
  --location="us-central1"
```

5. Enable object versioning on the bucket.

> [!IMPORTANT]
> Use a bucket name that is globally unique. Do not commit real project IDs to shared repos.

<!-- TODO IMAGE: Console screenshot of the new bucket with versioning enabled -->
![Bucket with versioning enabled](images/bucket-versioning.png)

### Task 2: Configure the backend and migrate state

In this task, you point Terraform at the remote backend and migrate local state.

1. Add a backend block to your Terraform configuration.

2. Run an init with migrate flags appropriate to your Terraform version.

3. Confirm that a state object appears in the bucket.

```hcl
terraform {
  backend "gcs" {
    bucket = "YOUR_PROJECT_ID-tf-state"
    prefix = "demo"
  }
}
```

> [!NOTE]
> If init asks to migrate existing state, accept the migration so local state is not left behind.

### Task 3: Verify locking

In this task, you observe that a lock prevents a second apply while one is in progress.

1. Start a long-running apply in one terminal (or simulate a lock per your instructor’s guidance).

2. In a second terminal, attempt another apply and note the lock error.

3. Release the lock only after the first operation finishes.

> [!WARNING]
> Do not force-unlock shared state unless you are sure no other apply is running.

### Bonus Task 4: Document the backend for your team

With fewer step-by-step hints, capture how a teammate would adopt this backend.

1. Write a short README section that lists the bucket name pattern, required IAM roles, and the init/migrate commands.

2. Optional: add a second prefix (for example `demo-dev`) and initialize a second working directory against the same bucket.

## Congratulations!

In this lab, you have:
- Created a remote state bucket with versioning enabled.
- Configured a Terraform backend and migrated state.
- Verified that state locking prevents concurrent applies.
````

---

## Image TODO reminder

When you cannot capture a real UI screenshot yet:

```markdown
<!-- TODO IMAGE: Describe exactly what the screenshot should show -->
![Short alt text](images/descriptive-name.png)
```
