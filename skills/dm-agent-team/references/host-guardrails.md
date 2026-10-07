# Host guardrails

The Lead reads this at boot. The hard stops in SKILL.md (no push or publish, nothing outside the project, no network beyond the package manager, no mass deletion) are written as instructions, and instructions can be skipped. These host permission rules back them up deterministically, without hooks: the host refuses the command before it runs.

They are a backstop, not a sandbox. Rules match command text, so a command wrapped in another shell (`sh -c "git push"`) can slip past. The reviewer and the precheck still check the work itself.

## OpenCode

OpenCode reads `permission` from the project's `opencode.json` (or `opencode.jsonc`). Each rule is `allow`, `ask`, or `deny`; patterns use `*` and `?`, and **the last matching rule wins**, so the catch-all comes first. `external_directory` fires when a tool touches a path outside the project folder.

Merge these into the project's config (keep any rules the human already has, and keep the human's stricter rule when both match):

```jsonc
{
  "permission": {
    "external_directory": {
      "*": "deny",
      "~/.agents/skills/*": "allow"
    },
    "bash": {
      "*": "allow",
      "git push*": "deny",
      "git remote add*": "deny",
      "git remote set-url*": "deny",
      "npm publish*": "deny",
      "pnpm publish*": "deny",
      "yarn npm publish*": "deny",
      "cargo publish*": "deny",
      "twine upload*": "deny",
      "dotnet nuget push*": "deny",
      "docker push*": "deny",
      "kubectl *": "deny",
      "terraform apply*": "deny",
      "curl *": "deny",
      "wget *": "deny",
      "rm -rf *": "ask",
      "git reset --hard*": "ask",
      "git clean *": "ask"
    }
  }
}
```

- The skill folder is allowed outside the project because the Lead runs `scripts/precheck.sh` and agents read their `SKILL.md` and `PROTOCOL.md` from it. If the skills are linked elsewhere, use that path.
- `ask` needs a human. In unattended `scripts/run.sh` sessions nobody can answer, so treat an `ask` there as a stop. Change those to `deny` if you prefer a hard refusal.
- Add the stack's other publish or deploy commands if 03 names any.

## Claude Code

Claude Code reads `permissions` from `.claude/settings.json`. It already limits file access to the project folder and any added directories. Add:

```json
{
  "permissions": {
    "deny": [
      "Bash(git push:*)", "Bash(git remote add:*)", "Bash(git remote set-url:*)",
      "Bash(npm publish:*)", "Bash(pnpm publish:*)", "Bash(cargo publish:*)",
      "Bash(twine upload:*)", "Bash(dotnet nuget push:*)", "Bash(docker push:*)",
      "Bash(kubectl:*)", "Bash(terraform apply:*)", "Bash(curl:*)", "Bash(wget:*)"
    ],
    "ask": ["Bash(rm -rf:*)", "Bash(git reset --hard:*)", "Bash(git clean:*)"]
  }
}
```

Check the rule syntax against the current Claude Code permissions documentation before relying on it.

## Other hosts

If the host has no permission rules, say so at the brief gate: the hard stops then rest on the instructions, the precheck, and the reviewer alone.

## Not covered by rules

- **Unapproved dependencies** are caught by `scripts/precheck.sh` (check 5) and by the reviewer, not by the host: the install command is allowed because allowlisted packages need it.
- **Secrets** are covered by the §10.1 quality gate when it includes secret scanning, and by the reviewer.
