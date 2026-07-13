# Contributing workflow

## One feature, one branch, one squash commit

Every feature is developed on its own branch and merged into `main` as a
single squash commit. `main` stays a linear history of one commit per
feature.

1. Branch from the latest `main` using one of the recognized prefixes:
   `feature/<name>`, `feat/<name>`, or `claude/<name>`.
2. Develop and commit freely on the branch — intermediate commits are
   squashed away at merge time.
3. Open a pull request. Keep it as a **draft** while work is in progress.
4. Mark the pull request **ready for review** when the feature is complete.

## Automatic squash merge

The [`auto-squash-merge`](.github/workflows/auto-squash-merge.yml) workflow
squash-merges a pull request automatically when all of the following hold:

- the head branch starts with `feature/`, `feat/`, or `claude/`;
- the pull request is not a draft;
- the pull request does not carry the `no-automerge` label.

The squash commit title is taken from the pull request title, so write PR
titles as final commit messages. The head branch is deleted after merging.

If branch protection with required status checks is enabled on `main`, the
workflow enables GitHub auto-merge instead, and the merge happens once the
required checks pass. (Enable "Allow auto-merge" in the repository settings
for that path.)

## Opting out

To hold a specific pull request for manual review, keep it in draft state
or add the `no-automerge` label before marking it ready.
