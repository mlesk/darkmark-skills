# dm-agent-team behaviour scenarios

Scenarios from retros. Each Must / Must-not line is checkable from the transcript or the run's files.

## S1: A UI dispatch that reuses a component cites the mockup (V003 retro R4)
Setup:     A brownfield run in S2. 02-ux.md names SCR-111 trays. A mockup `design/focus.html` has compact tray items (`li`: dot · title link · `Put back`) at lines 101-112. `build/handoff.md` says `clientRowSource()` builds full list rows.
Prompt:    "/dm-agent-team" (resume; next-action: dispatch PHASE-007 trays)
User:      none (yolo; no questions)
Must:      the PHASE-007 dispatch prompt that names `clientRowSource` (or any component to reuse) for the trays also cites `design/focus.html` with line numbers for the tray markup
Must not:  dispatch tells the builder to reuse full rows for trays without citing the mockup lines

## S2: A UI phase's browser check walks every traced SCR (V003 retro R5)
Setup:     A brownfield run in S2. PHASE-005 `traces:` lists SCR-102 (Saved), SCR-107, SCR-109, SCR-110. The builder has returned `done` with a PASS precheck. A running probe server is available.
Prompt:    "/dm-agent-team" (resume; next-action: on PHASE-005 return, check and commit)
User:      none
Must:      before the `PHASE-005:` commit, the Lead opens each of `/bookmarks`, the article page, `/skipped` (one per traced SCR) in the browser; the §Log row for PHASE-005 names SCR-102, SCR-107, SCR-109 and SCR-110 as checked
Must not:  commits PHASE-005 with a §Log row that omits a traced SCR

## S3: A change that lowers a count lists its readers (V003 retro R7)
Setup:     A run at the accept gate. Votes are an aggregate count read by Trending (`trendingCards`, filtered by `lastVoteAt` within 7 days), deck order (BR-101) and row counts. The human asks: "add the ability to reverse a star".
Prompt:    "add the ability to click a starred item to reverse it"
User:      accepts the recommended answers
Must:      the D-### that records the change lists Trending, deck order and row counts as readers of the vote count, and states each one's behaviour at 0 votes (e.g. Trending drops an article at 0)
Must not:  writes the un-star requirement without naming the readers of the count

## S4: §13 touches name tests that pin a list the phase adds to (V004 retro R13)
Setup:     A brownfield run in S1 writing 03 §13. PHASE-011 adds a column `sources.reader_mode`; `src/tests/store.test.ts` pins the exact `sources` column list and the `SourceRow` shape.
Prompt:    "/dm-agent-team" (resume; next-action: write 03 §13)
User:      none (yolo)
Must:      PHASE-011's `touches:` lists `src/tests/store.test.ts`
Must not:  PHASE-011 adds a column with store.test.ts absent from its touches

## S5: A shared budget gets a full-size worked example (V004 retro R16)
Setup:     S1. 01 has BR-426: run budget 40 LLM calls spent in order novelty → pool (≤40 candidates) → cluster checks → digests.
Prompt:    "/dm-agent-team" (resume; next-action: write 01/03)
User:      none
Must:      the spec carries a worked example at a 40-candidate pool showing each consumer's share, and either gives cluster checks and digests a non-zero share or records that they get 0 as an ASM/D
Must not:  BR-426 ships with no full-size example

## S6: Builder briefs forbid scripted bulk edits (V004 retro R15)
Setup:     S2, any phase dispatch.
Prompt:    "/dm-agent-team" (resume; next-action: dispatch PHASE-010)
User:      none
Must:      the dispatch prompt says targeted edits only, no scripted rewrites of large regions, and `git diff --stat` after each edit
Must not:  a dispatch without that line

## S7: An uncommitted phase under review is checkpointed (V004 retro R14)
Setup:     S2. PHASE-009 returned done (PASS precheck); risk high, so it goes `in-review` uncommitted.
Prompt:    "/dm-agent-team" (resume; next-action: dispatch the phase review)
User:      none
Must:      a WIP checkpoint commit of PHASE-009's files exists on the run branch before the review (or fix) dispatch
Must not:  the review or a fix round runs with round-1 work only in the working tree

## S8: A fix on one twin path names and checks the other (V004 retro R17)
Setup:     S2. B4 "remember passed candidates" is fixed in the daily run; `runLateRun` has its own candidate loop.
Prompt:    "/dm-agent-team" (resume; next-action: dispatch the B4 fix)
User:      none
Must:      the fix dispatch or its re-check names the late run as the twin and checks it skips passed candidates
Must not:  the daily-only fix is marked done with the late path unexamined

## S9: A UI walk that cannot run is deferred by decision (V004 retro R18)
Setup:     S2. PHASE-012 (UI) returned done; starting the server is denied in this environment.
Prompt:    "/dm-agent-team" (resume; next-action: check and commit PHASE-012)
User:      none
Must:      a D-### records the deferred SCR walk, and the walk runs at the next milestone gate (MS-n), naming each SCR
Must not:  PHASE-012 is committed with no walk and no D-### for the deferral
