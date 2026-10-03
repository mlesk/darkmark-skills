---
name: dm-debug
description: Hypothesis-driven debugging. Reproduces the failure, shrinks it to a minimal case, ranks hypotheses, runs experiments that tell them apart, fixes the root cause with a regression test that failed before the fix, and keeps a debug log so the work survives a context reset. Use when the user reports a bug, a failing or flaky test, a crash, wrong output, a performance regression, or says "debug this", "why is this failing", or "this used to work". Do NOT use for writing new features, code review without a known failure, or environment setup questions with no failure to explain.
---

# Debug

Debugging is a search problem. Guessing and patching is a random walk; each experiment here is chosen to rule out half the remaining explanations.

Keep a **debug log** at `debug/<slug>.md` (or wherever the user prefers) from Step 1. Update it after every experiment. If the session ends, the next one resumes from the log.

## Step 1 - Reproduce

Get a command that shows the failure, and run it yourself.

```text
Debug log: <slug>
Symptom:   <what is observed vs. what is expected>
Repro:     <exact command or steps>
Result:    reproduced N/M runs | not reproduced
Env:       <versions, OS, branch, commit>
```

- Look in the conversation, CI logs, issue text, and recent commits before asking the user anything.
- **Can't reproduce?** Stop and say so. Ask one question with a recommended answer, e.g. "Can you share the exact command and the full error output? Recommended: paste the CI log for the failing job." Do not fix what you can't see fail.
- **Flaky?** Run it enough times to get a failure rate (for example 20 runs) and record it. A fix must change that rate.

## Step 2 - Shrink

Make the repro smaller and faster: fewer inputs, one test instead of a suite, a script instead of the app. If it "used to work", find the commit that broke it with `git bisect run <repro>`. Note the minimal case in the log.

## Step 3 - Hypothesize

List 2-5 hypotheses. For each, write what it predicts that the others don't.

```text
H1  Cache returns stale config after reload   predicts: fails only after a reload; passes with cache off
H2  Race between writer and reader threads    predicts: rate changes with CPU load; passes when serialized
H3  Off-by-one in pagination at page size     predicts: fails only when count is a multiple of 50
```

Rank by likelihood × cheapness to test. Read the code paths involved before ranking. Include at least one hypothesis that you don't like but can't rule out.

## Step 4 - Experiment

Pick the experiment whose outcome separates the most hypotheses: a log line, an assertion, a debugger break, a changed input, a toggled flag. Then:

```text
E1  Disable cache, run repro 20×   → 0/20 failures   ⇒ H1 supported, H3 ruled out
```

- One variable per experiment.
- Write down what you expect **before** running it. An experiment with no prediction teaches nothing.
- Remove temporary instrumentation when you're done with it.

**Stop and widen** after 3 experiments that rule nothing out, or when every hypothesis is ruled out. Add instrumentation around the failure, re-read the symptom, check assumptions (right binary, right config, right branch?), and return to Step 3. After 2 widenings with no progress, stop and report what's known, what's ruled out, and the next experiment you'd run.

## Step 5 - Fix the root cause

1. **Write a regression test first** from the minimal case. Run it and watch it **fail** for the reason you expect.
2. Fix the cause, not the symptom. If you're adding a retry, a sleep, a null check, or a catch-all, write down why that's the root cause and not a hidden symptom.
3. Run the regression test (now passes), the original repro (now passes; for flaky bugs, the failure rate is now 0 over the same number of runs), and the surrounding test suite (no new failures).

## Step 6 - Report

```text
Root cause:  <one or two sentences>
Evidence:    <the experiment that proved it>
Fix:         <files changed>
Regression:  <test name> — failed before, passes after
Ruled out:   H2 (E2), H3 (E1)
Follow-ups:  <related risks found but not fixed>
```

Offer `dm-learn` if the bug came from a missing project fact (an undocumented setup step, a convention nobody wrote down).

## Anti-patterns

- **Shotgun fixes:** changing several things at once and keeping whatever turns green.
- **Fixing without reproducing:** "this looks wrong" patches for a failure you never saw.
- **Symptom patches:** retries, sleeps, or swallowed exceptions with no root cause.
- **Test after:** writing the regression test after the fix, so it was never seen failing.
- **"Flaky" as a diagnosis:** calling it flaky stops the search; measure the rate and keep going.
- **Lost trail:** experiments run but not logged, so the next session repeats them.
