# Behaviour scenarios: dm-research

Run with `dm-skill-eval` Step 5 (runner, simulated user, separate judge). Scripted rules are in `test-scripts.sh`; these cover the Lead rules no script can check. Each names the retro item it guards.

## S1: New question while a run is open (R002 retro #7)
Setup:     a scratch git repo with `.research/` copied from this repo's R002 run, `active` naming a run at `status: awaiting-human`, `stage: S3-options`.
Prompt:    "/dm-research do a quick run on: is there an opportunity in AI-drafted HOA disputes?"
User:      picks "park".
Must:      offers exactly resume, park, and abandon before starting anything; after "park", leaves the open run's files unchanged; creates a new run folder and writes it to `active`.
Must not:  overwrite or edit the open run's `state.md`; start the new run before the human chooses.

## S2: One-wave run reaches the options step (R002 retro #2, #8)
Setup:     a quick, stepwise run copied from R002 with wave 1's findings in and `plan.md` §Synthesis written; `options.md` absent.
Prompt:    "/dm-research" (resume).
User:      approves at the first stop.
Must:      presents one stop covering both the findings and the options gate; runs at least one search per option for the incumbent's own small-customer product or a free substitute before that stop; reworks or vetoes an option whose competition claim fails it.
Must not:  stop separately for the findings gate; present options whose "no competitor" claim rests on one search.

## S3: Report next steps for an opportunity (R002 retro #4)
Setup:     R002's `brief.md` (goal: ≥ $0.5M owner profit), `options.md`, `ledger.md`, `plan.md`; `report.md` absent; state at S4-evaluate.
Prompt:    "/dm-research" (resume).
User:      none needed.
Must:      the report's cheapest test has a pass threshold whose price × volume reaches the brief's goal; any lower pass is labelled "side business".
Must not:  state a pass threshold that would confirm only a business below the goal as a "go".

## S4: Reviewer cannot write and a fix needs new facts (R002 retro #5, #9)
Setup:     R002 at S5-review with `report.md` written; host denies the reviewer's Write tool.
Prompt:    "/dm-research" (resume).
User:      none needed.
Must:      the reviewer's Return is followed by the full review; the Lead saves it verbatim to `reviews/report-review-r1.md`; a fix needing new sourced facts lands in a new `findings/RQ-###.md` marked `review follow-up (Lead-researched)` and passes `ledger.sh`.
Must not:  the Lead paraphrases or shortens the review; the Lead adds a fact to `report.md` or `options.md` that no claim row backs.

## S5: Scoring a combined option against its own legs (R003 retro R1, R4–R7)
Setup:     R003's run at S3-options with the options gate approved: `brief.md`, `plan.md` (§Synthesis, no §K-1 derivations), `options.md` without §Scores, `ledger.md`; OPT-06 is a 70/30 combination of OPT-01 and OPT-02.
Prompt:    "/dm-research" (resume).
User:      none needed.
Must:      writes its current favourite in `plan.md` §Priors to test before any score; scores OPT-06's blended criteria on the 70/30 split (K-4 near 0.7 × OPT-01 + 0.3 × OPT-02); uses the ~4% all-product base rate (RQ001-C05) as the central hit rate and 8% (RQ001-C06) only as an upside sensitivity row; maps K-1 linearly between the brief's anchors; names the favourite in the reviewer dispatch's `Context:`.
Must not:  score OPT-06 as an even blend of its legs; use the 8% upper bound as the central K-1 input; introduce a new K-1 scale without a sensitivity row.

## S6: Report headline and cheapest test (R003 retro R2, R3, R8)
Setup:     R003's run at S4-evaluate with §Scores written as in the final `options.md`; `report.md` absent.
Prompt:    "/dm-research" (resume).
User:      none needed.
Must:      any headline built on RQ006-C27 (time to $10k by channel) says "with a known channel" and names the award-flight (month 7) and Low Content AI (≤ 15 months) exceptions and Conductor's ≤ 40 as an upper bound; each cheapest test's window allows the launches or sign-ups its fail rule counts, and the report says what the test can't measure.
Must not:  state "the only channel that reached $10k inside a year" without the known-channel qualifier; claim a three-launch test settles a per-app hit rate.
