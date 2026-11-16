# CKA / CKAD Study Guide

Linux, then Kubernetes basics, then CKAD, then CKA, on Kubernetes v1.37. 76 lessons in four parts. Every lesson has concepts, a diagram, commands to produce fast, a worked example, common mistakes, three labs (easy, medium, break-fix), exam tips and a quick review.

Use the sidebar to pick a lesson. Start with the [conventions](00-conventions.md): they define the shell aliases, lab clusters and image pins every lesson uses. [Progress](PROGRESS.md) shows the review state of each lesson.

All 76 lessons are written. Lessons marked FIXED in the progress table were reviewed once and fixed once; outputs labelled "EXPECTED OUTPUT (not captured)" have not been run on a live cluster yet — [VERIFY-LIST](VERIFY-LIST.md) collects every one of those items by environment.

## Extras

- [Exam intel and strategy (CKAD)](extras/exam-intel.md) — what recent pass/fail reports say actually shows up, the resources that correlate with passing, speed tactics and the exam-day checklist. Community-sourced, not official.
- [15-day CKAD study plan](extras/study-plan.md) — a day-by-day plan that maps each topic to the lessons here.
- [CKAD practice questions](extras/practice-questions.md) — a timed question bank with hints and collapsed solutions, plus scenario projects and a quick reference.
- [Exam intel and strategy (CKA)](extras/cka-exam-intel.md) — community-sourced pass/fail intel for the administrator exam: which cluster tasks show up, the resources that correlate with passing and exam-day tactics. Directional, not official.
- [7-week CKA study plan](extras/cka-study-plan.md) — a week-by-week plan weighted by the official CKA domain weights, with the CKA-only reading order and timed practice each week.
- [CKA task bank](extras/cka-task-bank.md) — timed cluster-admin tasks per exam domain, with verification steps for every task.
- [CKA mock exams](extras/cka-mock-exams.md) — full 2-hour mock sets for the final-week cadence, with scoring guidance.

## Studying for the CKA only?

Follow the [7-week CKA study plan](extras/cka-study-plan.md) — it maps every week to lessons, drills and mocks. Reading order:

- **All of Part 4** (T4.01–T4.27) — every lesson maps to a CKA competency.
- **All of Part 2** — the API model, kubectl fluency and object basics the admin lessons build on.
- **Part 1 subset** — T1.01 (shell), T1.03 (vim), T1.06 (systemd/journalctl), T1.07 + T1.08 (Linux networking), T1.12 (TLS/PKI/openssl), T1.14 (SSH), T1.15 (packages/kernel/sysctl/swap).
- **Part 3 only where Part 4 links to it** — 18 lessons, listed in the plan; skip the rest of Part 3 and the CKAD extras.

## Lab environments

Each lesson's labs run on one of three setups (details in [conventions §2](00-conventions.md)):

- **linux-vm** — one Ubuntu LTS VM for the Part 1 Linux topics.
- **kind** — a 3-node kind cluster (`env/kind-up.sh`) for most Kubernetes topics.
- **vms** — three kubeadm VMs (`env/vm-prereqs.sh`) for cluster-admin topics.

## How to move around

- The sidebar lists only the lessons that exist, with a count per part. Click one to read it.
- [Roadmap](ROADMAP.md) shows all 76 topics and their status.
- Press `m` (or use the button at the top left) to hide the sidebar and read full width.
- Inside a lesson, the right-hand outline jumps between its sections.
