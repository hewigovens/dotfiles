# jj cheatsheet (for git users)

## Mental model

- No staging area — all file changes are automatically part of the working copy commit
- No stash — just `jj new` to start a new change, the old one is kept
- Every revision is mutable until pushed
- Conflicts won't block you

## Commands

| git | jj |
|---|---|
| `git checkout -b feature` | `jj new -m "feature"` |
| `git checkout main` | `jj edit main` |
| `git checkout --track origin/branch` | `jj bookmark track branch@origin && jj edit branch` |
| `git reset --soft main` | `jj squash --into main` |
| `git reset --hard` | `jj restore` (discard working copy changes) |
| `git commit -a -m "msg"` | `jj describe -m "msg"` (auto-tracks all changes) |
| `git add -p` / partial commit | `jj split` (interactive hunk picker) |
| `git rebase --onto <dest>` | `jj rebase -d <dest>` (always merge-based) |
| `git rebase -i drop` | `jj abandon <rev>` |
| `git rebase -i edit` | `jj edit <rev>` (then `jj new` when done) |
| `git rebase -i fixup/squash` | `jj squash` or `jj squash --into <rev>` |
| `git rebase -i reorder` | `jj rebase -r <rev> --after <target>` |
| `git rebase -i reword` | `jj describe -r <rev> -m "new msg"` |
| `git status` | `jj st` |
| `git log` | `jj log` |
| `git diff` | `jj diff` |
| `git diff --staged` | (no concept — everything is always "staged") |
| `git stash` | `jj new` (old change is kept) |
| `git push` | `jj git push` |
| `git pull` | `jj git fetch && jj rebase -d main@origin` |
| `git cherry-pick <rev>` | `jj graft -r <rev>` |
| `git merge branch` | `jj new main branch` (multi-parent merge) |
| `git show <rev>` | `jj show <rev>` |
| `git branch -m old new` | `jj bookmark rename old new` |
| `git tag <name>` | `jj tag create <name>` |
| `git blame file` | `jj annotate file` |

## Submodules

Not supported by jj. In colocated repos, use git directly:

```bash
git submodule add <url>       # add submodule (then jj won't track pointer changes)
git submodule update --init   # init/update submodules
```

jj ignores submodule entries — pointer updates must be committed via `git commit`.

## Split (partial commits)

```bash
jj split              # split working copy by hunks
jj split -r <rev>     # split any revision
jj split <file>       # split only specific file(s)
```
