# dm-outcome-team vs. dm-agent-team

As of 6 Nov 2026: dm-agent-team (lean-2, on `main`) compared with the dm-outcome-team draft, revised after the Blockfall test run.

## In one paragraph

Both skills aim at the same result. They take an idea from one interview to software the human accepts, with requirements traced to tests, independent review, hard safety limits, resumable state, and a living description of the system. **dm-agent-team** says *how* to get there: six steps, three sizes, three run modes, two named agents, fixed spec templates, retry counts, and an exceptions handbook. The runtime it loads is about 11,200 words across 12 files. **dm-outcome-team** says only *what* must be true at the end, the limits, and the quality bars. It is about 1,440 words in one file, and it keeps the two scripts through a short contracts section. The trade is predictability and auditability for flexibility and far less to maintain.

## Side by side

| | dm-agent-team | dm-outcome-team |
|---|---|---|
| **Size** | ~11,200 words across SKILL, PROTOCOL, ROUTING, 2 agents, and 7 references; a word budget keeps it from growing | ~1,440 words in one file |
| **Shape of the instructions** | Steps 1–6, stage names, gate names, and a table for each policy | Seven "Done means" properties, the human's part, hard limits, surviving interruption, spending well, and honest reporting |
| **Scaling to the job** | A small/standard/large table fixes specs, phase counts, review points, and REVISE rounds | "Scale the process to the job" and tell the human the scale at the first stop |
| **Human stops** | Brief and accept always stop; spec, milestone, and others follow the stepwise/checkpoint/yolo table | Direction and result always stop; design stops unless the human chose more autonomy; the human can ask for more |
| **Interview** | One batch of at most 12 questions, a fixed topic list, and a recommended answer for each | The same idea, stated as an outcome; now also asks where the work lives |
| **Who does the work** | A Lead plus a persistent `dm-at-builder` and a fresh `dm-at-reviewer`, with a fixed dispatch prompt, Return block, and tier/effort routing | Unspecified. "Nothing is accepted on its author's word", and helpers only when independence or parallelism earns them |
| **Specs** | 01 requirements, 02 UX, and 03 architecture with fixed sections, an ID scheme, and a §13 build plan | "Written down precisely enough to test", including timing, limits, and how rules interact; format free except where the scripts read it |
| **Traceability** | Global IDs, `REQ_004_2` test names, and precheck check 3 | Every requirement has a test that would fail if any part broke; the ID convention survives only through the contracts section |
| **Mechanical checks** | `precheck.sh` after every phase, required | The same script, required through the contracts section; plus "make checks mechanical where you can" |
| **Test strength** | The reviewer checks that tests "would really fail" at milestones and acceptance | Stated as a bar in Done means §2: partial tests don't count, and "a test with that name exists" isn't proof |
| **Failure handling** | REVISE caps per size, escalation, a circuit breaker after 3, stalled-build stops, and override rules | One rule: when work stops converging, change something real or take it to the human, and never loop |
| **State and resume** | A full `state.md` skeleton, a §Log, `next-action`, drift checks against gate commits, and a recovery procedure | A fresh session can tell purpose, status, decisions, waits, and the next step, and checks for tampering; `run.sh` fields kept through the contracts section |
| **Brownfield** | BROWNFIELD.md (~1,150 words): baseline gate, change tags, characterisation phases, delete rules | Five lines in hard limits: a branch from a clean tree, no regressions without approval, pin behaviour before changing it |
| **Parallel work** | PARALLEL.md: worktree lanes, `touches:` overlap rules, merge order | Left to the model ("real parallelism") |
| **Cost control** | Cache-aware design built into the procedure; `run.sh` records cost per session | One line on cache economics, plus a ceiling in the hard limits |
| **Evidence** | One end-to-end eval, of an older version (~$34, 60+ dispatches); lean-2 itself unmeasured | One test run (Blockfall): ~50 min, 2 human stops, 2 fresh reviewers, 3 phases with precheck PASS, accepted; cost not measured |

## What dm-agent-team does better

- **Predictable runs.** Two runs of the same kickoff produce the same artifacts in the same places. That makes audits, diffs, and the bakeoff comparison straightforward.
- **Rare paths are written down.** Drift, a crash mid-phase, a stalled build, and three escalations in a row each have a tested answer. dm-outcome-team relies on the model to work these out under pressure.
- **Brownfield is much more thorough.** The baseline gate, change tags, and the precheck's baseline-test rule are real protection, and dm-outcome-team states only the outcome.
- **Parallel lanes have rules.** dm-outcome-team gives a model nothing to stop two lanes editing the same file.
- **Weaker or cheaper models can run it.** The procedure is a scaffold. dm-outcome-team assumes strong judgment.

## What dm-outcome-team does better

- **It reads as intent.** Every rule is something a reviewer would reject the result for breaking. The model knows *why* each constraint exists, which is the guidance lean-2-design.md itself cites for 5.x models.
- **It's about 8× smaller and in one file.** Much less to keep consistent. dm-agent-team needs a word budget and a lint to stop growth, and its 12 files cross-reference each other.
- **Process fits the job.** In the test run, a small game got 3 phases, 2 reviews, and no milestone machinery, without a size table saying so.
- **Test strength is a stated bar.** dm-agent-team checks that tests exist mechanically and their strength only by review. The revised draft says partial tests don't count, which is the gap the test run exposed.
- **It's open to better methods.** It doesn't lock in a persistent builder versus a fresh builder per phase, or a dispatch pattern. The bakeoff question in the research ("persistent or fresh builder?") goes away, because the skill doesn't decide it.

## Where they're the same in practice

The contracts section pulls a lot of dm-agent-team back in. To keep `precheck.sh` and `run.sh`, a run still writes `state.md` fields, an `03-architecture.md` with §9–§13, `PHASE-###` entries, `touches:`, and `REQ_n_n` test names. The Blockfall run ended up looking much like a dm-agent-team run: brief, specs, spec review, phases with precheck, acceptance review, retro. The difference is that the model chose that structure instead of being told to.

**One confound to keep in mind.** The model that ran Blockfall had just read all of dm-agent-team in the same session. A fresh model with only dm-outcome-team might structure the run quite differently. A clean test needs a session that has never seen dm-agent-team.

## When to use which

- **dm-agent-team** fits brownfield changes to code that matters, large runs with parallel lanes, unattended overnight runs where you want every failure path pinned down, and runs you need to compare side by side.
- **dm-outcome-team** fits greenfield and small-to-standard work on a strong model, where you want less ceremony and are willing to judge by outcome rather than process.

## What would settle it

Run both in the bakeoff the research already proposes, each in a fresh session that has never seen the other skill, on the same kickoff. Score both on the seven "Done means" items, which work as a neutral rubric. Compare cost through `run.sh`'s `costs.tsv`, human stops, defects found at acceptance, and run-to-run variance from two or three runs each. Add a brownfield kickoff, because that is where the drafts differ most.
