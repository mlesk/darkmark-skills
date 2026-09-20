---
name: dm-decide
description: Structured decision-making process. Intake the decision, grill the user across high-leverage dimensions (first principles, opportunity cost, second-order effects, compounding, incentives, probabilistic thinking, inversion), build a weighted rubric, score the options, iterate to refine the guidance, and deliver the options, the process used, and a final recommended decision. Use when the user faces a decision, weighs options, asks "should I..." or "which one", or wants a recommendation with reasoning. Do not use for brainstorming without a decision or one-off factual questions.
---

# Decide

Turn a decision into a directed process: intake → grill → rubric → score → iterate → recommend.

The deliverable is not a one-line answer. It is the options, the process that evaluated them, and a final recommended decision the user can defend.

## At a glance

| Phase     | Job                                                           | Gate                      |
| --------- | ------------------------------------------------------------- | ------------------------- |
| 0 Intake  | Decision contract: statement, stakes, reversibility, deadline | -                         |
| 1 Grill   | Seven lenses, one question at a time with recommendations     | Grill record confirmed    |
| 2 Rubric  | Weighted dimensions and anchors from the grill                | User approves rubric      |
| 3 Score   | Every option scored, including status quo                     | User confirms calibration |
| 4 Refine  | Stress-test leader, close evidence gap, re-score              | Stop rule                 |
| 5 Deliver | Options, process, recommendation, uncertainty                 | -                         |

## Operating principles

- **Recommendation last.** No recommendation before the rubric is approved and the options are scored.
- **Grill before rubric.** Rubric dimensions are earned in the grill, not invented after the fact.
- **Seven lenses, real probes.** Each mental model must produce an observable question about this decision, not a name-drop.
- **One question at a time.** Ask one question, with a recommended answer, and wait.
- **Facts are looked up, decisions are asked.** If the environment can answer it, do not ask the user.
- **Status quo is always an option.** Never score a choice set that omits doing nothing or staying the course.
- **Probabilities beat certainty.** Score expected outcomes, not hopes; "probably improves the odds" is a legitimate win.
- **Iterate on weak evidence, not wording.** Refinement rounds target the dimension with the weakest evidence or the closest margin.
- **Durable output.** Leave a decision record the user can revisit and defend.

## Minimum compliance

Do not claim to have used dm-decide unless you can show all of these:

1. A decision contract: statement, stakes, reversibility, deadline, decision-maker, constraints.
2. A grill record: which lenses were applied and what each surfaced.
3. An approved rubric with weighted dimensions and anchors.
4. A scorecard covering all options, including the status quo.
5. At least one refinement round with a re-score.
6. A delivery block: options, process used, final recommended decision, remaining uncertainty.

If any item is missing, the process has not happened: stop, return to the last satisfied gate, and do not emit a recommendation. Delivering a recommendation without items 1-6 is a violation of dm-decide.

## Fast path

1. Intake the decision and write the decision contract.
2. Grill one question at a time until 2-3 dominant dimensions emerge.
3. Build the rubric and wait for approval.
4. Enumerate options (including status quo) and score them.
5. Refine: stress-test the leader, close the widest evidence gap, re-score.
6. Deliver options, process, recommendation, and remaining uncertainty.

## Trigger boundary

**Positive triggers - load this skill when the user:**

- Faces a decision or dilemma and wants help choosing
- Weighs options and wants a recommendation with reasoning
- Asks "should I...", "which one...", or "is this the right call?"
- Has a shortlist of options and wants them scored or stress-tested
- Wants a defensible decision record or pre-mortem before committing

**Near misses - do NOT load this skill when the user:**

- Wants brainstorming or idea generation without a concrete choice (use a brainstorming skill)
- Asks a one-off factual question ("what does X cost?")
- Wants a plan or roadmap, not a choice between alternatives (use a planning skill)
- Wants to stress-test an idea in general rather than decide something

If overlap is unclear, ask:

> Is there a concrete decision to make here, or is this exploration?
>
> Recommended answer: use dm-decide only when there is a real choice with stakes; otherwise use the brainstorming or planning path.

**Positive trigger examples:**

- "Should I take the new job or stay?"
- "Help me decide between rebuilding the backend and refactoring in place."
- "Is it worth launching this feature now, or waiting?"
- "Score these three vendors and tell me which one to pick."

**Near-miss examples:**

- "Brainstorm product ideas for my app."
- "What does the AWS bill look like this month?"

## Phase 0 - Intake the decision

Before grilling anything, capture the decision as a contract. Look up what can be looked up; ask only for what is genuinely unknown.

```text
Decision contract
- Decision: one sentence, stated as a choice
- Options known so far: (leave room for more)
- Stakes: what is won or lost, and how badly
- Reversibility: can this be undone cheaply, or is it a one-way door?
- Deadline: when does the decision need to be made
- Decision-maker: who owns the call
- Constraints: budget, commitments, values, non-negotiables
- Non-goals: what this decision is not about
```

If the decision cannot be stated as a choice, it is not ready for dm-decide. Ask the smallest blocking question:

> What exactly is being decided, between which options, by when, and what is at stake?
>
> Recommended answer: restate the decision as "choose between X and Y by date, where Z is at stake" and correct anything that is wrong.

**Exit criteria:**

- [ ] The decision fits in one sentence and names at least two candidate options.
- [ ] Stakes and reversibility are stated.
- [ ] Deadline and decision-maker are known.
- [ ] Constraints and non-goals are listed.

## Phase 1 - Grill the dimensions

Walk the seven lenses. Each lens must produce an observable question about this decision, with a recommended answer. Ask one question at a time and wait. Skip a lens only when the answer cannot move the decision, and say so in the grill record.

**1. First principles.** What is fundamentally true here, independent of how others do it?

- "Which assumptions are we inheriting without testing?"
- Example: "We assume we need funding before building. Is that true, or do we need first customers?"

**2. Opportunity cost.** Every option forecloses the others. What does each one replace?

- "If we choose A, what are we saying no to - money, time, focus, future options?"
- Example: "The conference is not $500. It is $500 plus the work you will not do that week."

**3. Second-order thinking.** What happens next - and after that?

- "What is the first consequence, and what does that consequence cause?"
- Example: "Skipping the event saves money now; it also removes the connections that become next year's opportunities."

**4. Compounding.** What do repeated versions of this decision build toward?

- "If we made this same choice every day/week/year, where would we end up?"
- Example: "One post is nothing. One post a week for two years is an audience."

**5. Incentives.** Who benefits from each option - including the people recommending it and the decider?

- "What does each advisor or option gain if I pick it? What do my own incentives make me want to believe?"
- Example: "The vendor recommends the expensive tier. Does that serve me or their quota?"

**6. Probabilistic thinking.** Certainty is not on the menu; odds are.

- "Does this option raise the probability of the outcome we want, by how much, at what cost?"
- Example: "The launch probably will not go viral, but it raises the odds of finding one enterprise lead."

**7. Inversion.** What would guarantee failure - and are we doing any of it?

- "Run a pre-mortem: it is one year later and this decision failed. What happened?"
- Example: "The move fails if we hire the same way in the new city and burn the runway in six months."

Worked exchanges look like this:

> Q: "Which assumptions are we inheriting without testing?" (First principles)
> Recommended answer: "You are assuming the rewrite is needed because the code is old. The observable fact is that only the billing module has incident history."

> Q: "Run a pre-mortem: a year from now this failed. What happened?" (Inversion)
> Recommended answer: "We rebuilt everything, shipped nothing for six months, and lost the one customer who was paying for the new features."

> Q: "If this turns out wrong, what does undoing it cost?" (Reversibility)
> Recommended answer: "Switching vendors costs about two weeks of migration work, so it is a cheap door to reverse. Moving apartments is not."

Then add decision-shaped lenses only if they move this decision:

- **Reversibility/optionality:** which option keeps the most doors open if wrong?
  - "If this turns out wrong, what does undoing it cost?"
- **Values alignment:** which option matches what the decision-maker actually wants to be true?
  - "If I could keep only one option's outcome, which one do I actually want?"
- **Cost/effort:** what is the real price of each option, including switching costs?
  - "What is the total price beyond the sticker - switching, maintenance, attention?"
- **Timing:** is the cost of deciding now higher than the cost of waiting?
  - "Is waiting cheaper than deciding now, or does the option expire?"

**Exit criteria:**

- [ ] The 2-3 dimensions that dominate this decision are identified.
- [ ] Each applied lens left an observable finding, not a restatement of the question.
- [ ] The grill record lists lenses skipped and why.
- [ ] No question was asked that the environment could have answered.

**HARD GATE - grill record confirmation.** Show the grill record and ask:

> Does this grill record capture what we learned? Name any lens to dig deeper on before we build the rubric.
>
> Recommended answer: "Looks right - build the rubric" or name a lens to revisit.

## Phase 2 - Build the rubric

Derive 3-7 dimensions from the grill - the dimensions that actually separate the options. For each: a weight (1-10) and two anchors describing what an option looks like at 2/10 and 10/10.

Rules:

- At least one dimension must measure outcome attainment - the goal the decision serves - not surface polish.
- Anchors must be observable: "2/10: the option spends the runway with no path to first customer" beats "2/10: bad fit".
- If the grill surfaced a dominant lens (e.g., this decision is really about opportunity cost), it should carry the highest weight.
- Weights must make real tradeoffs; do not give everything the same weight.

**HARD GATE - rubric approval.** Present the rubric and wait:

```markdown
## Proposed Rubric for [decision]

### [Dimension] (weight: X)

- 2/10: ...
- 10/10: ...
```

Then ask:

> Does this rubric capture what matters for this decision? Adjust dimensions, weights, or anchors before we score.
>
> Recommended answer: "Looks right - score the options" or specific adjustments.

Do not score options before explicit approval.

**Exit criteria:**

- [ ] 3-7 dimensions derived from the grill.
- [ ] One dimension measures outcome attainment.
- [ ] Anchors are observable per option.
- [ ] The user approved the rubric.

## Phase 3 - Enumerate and score the options

List the options. Always include the status quo ("do nothing / stay the course"). If the grill suggests a materially different direction, add it as a bolder alternative.

Score every option on the same rubric, dimension by dimension:

```markdown
### Option: [name]

## Dimension Weight Score Rationale

... ... ... ...
Weighted total: XX/100
```

Then show the comparison table:

```markdown
## Option Score

[status quo] XX
... XX
```

**HARD GATE - calibration check.** Present the scorecard and ask:

> Do these scores feel calibrated? If a score feels off by more than 10 points, fix the rubric before iterating.
>
> Recommended answer: "Calibrated - refine" or a specific adjustment.

**Exit criteria:**

- [ ] All options scored, including the status quo.
- [ ] The user confirmed calibration.

## Phase 4 - Refine the guidance

Do not recommend after the first pass. Run at least one refinement round:

1. **Stress-test the leader.** Apply inversion and second-order thinking to the top-scoring option. Name the specific way it could fail.
2. **Close the widest evidence gap.** Find the dimension with the weakest evidence or the closest margin and resolve it - with a fact, a question, or a sharper anchor.
3. **Re-score.** Same rubric, same rigor. Show before/after.
4. **Decide or split.** If the leader beats the runner-up by at least 10% of the total scale, recommend it. If scores are close, either split the decision into smaller independent decisions or report the tie honestly.

Stop conditions:

- A clear margin exists and the leader survived stress-testing → recommend.
- Two consecutive rounds produce no movement → stop and report the gap.
- Hard stop at 3 refinement rounds; deliver what you have.

**Exit criteria:**

- [ ] At least one full refine → re-score round completed.
- [ ] The leading option was stress-tested with inversion.
- [ ] The stop reason is explicit: clear margin, plateau, or round cap.

## Phase 5 - Deliver

Present the decision record in this order:

### 1. The decision

Restate the decision contract.

### 2. The options

Each option with its final score and one-line rationale.

### 3. The process utilized

Which lenses were grilled, what the rubric measured, and which refinement rounds changed the scores.

### 4. Final recommendation

- The recommended decision and why it wins.
- What would have to be true for a different option to win.
- Guardrails: what to watch after committing, and the reversibility plan if it starts failing.

### 5. Remaining uncertainty

The evidence gap that still exists and what new information would change the recommendation.

Save the decision record to a durable location - a chat artifact, a note, or a decision-log file - unless the user declines. The record must survive the conversation.

## Templates

### Decision contract

```text
Decision contract
- Decision:
- Options known so far:
- Stakes:
- Reversibility:
- Deadline:
- Decision-maker:
- Constraints:
- Non-goals:
```

### Grill record

```text
Lens                 Applied?  Finding
---------------------------------------
First principles     yes/no    ...
Opportunity cost     ...
Second-order         ...
Compounding          ...
Incentives           ...
Probabilistic        ...
Inversion            ...
Other lenses:
```

### Scorecard

```text
Option: [name] - weighted total XX/100

Dimension   Weight  Score  Rationale
```

### Delivery block

```markdown
## Decision record: [decision]

Options Final score One-line rationale
...

Recommended: [option]
Process: [lenses] → [rubric] → [rounds]
Guardrails: ...
Remaining uncertainty: ...
```

Filled example:

```markdown
## Decision record: rebuild billing vs refactor in place

Options Final score One-line rationale

- Stay the course (status quo) 41/100 Incidents keep compounding
- Refactor in place 78/100 Cheaper now, caps team capacity later
- Rebuild billing module 86/100 Kills the incident source, longer path to value

Recommended: rebuild the billing module
Process: grilled all 7 lenses → rubric weighted on incident rate, cost, speed → 2 refinement rounds
Guardrails: spike the migration on the invoice job first; fall back if error rate exceeds 1%
Remaining uncertainty: real migration time over the legacy data model - revisit after the spike
```

## Anti-patterns

- **Recommendation first.** Emitting an answer, then reverse-engineering a rubric to justify it.
- **Option blindness.** Scoring two real options without the status quo, or refusing to add a bolder alternative.
- **Lens tourism.** Mentioning all seven principles while none of them changes a score.
- **Certainty theater.** Stating probabilities that were not derived from anything.
- **Question barrage.** Dumping ten questions at once instead of one at a time with recommendations.
- **Rubric drift.** Changing weights or anchors mid-scoring to make a favorite option win.
- **Polish loops.** Re-refining the wording of the delivery while an evidence gap sits unresolved.
- **Unearned confidence.** Delivering a crisp recommendation while skipping the grill or the calibration gate.
- **Gate skipping.** Continuing past a hard gate without explicit user approval and claiming the process happened.

## Final self-review

Before declaring done, verify:

- [ ] The decision contract was shown and confirmed.
- [ ] The grill record names the lenses applied and the findings.
- [ ] The rubric was approved before scoring.
- [ ] Every option was scored on the same rubric, including the status quo.
- [ ] At least one refinement round moved a score or closed an evidence gap.
- [ ] The delivery contains options, process, recommendation, and remaining uncertainty.
- [ ] The recommendation survives the inversion test.
