---
name: domain-model-standards
description: Standards for discovering, shaping, and validating domain models using Object Modeling in Color and the Law of Demeter.
scope: Domain Model, Domain Modeling, Object Modeling in Color, Law of Demeter, Domain Neutral Component, Project Composition
---

# Domain Model Standards

> **Sources:**
>
> - [Object Modeling in Color - Wikipedia](https://en.wikipedia.org/wiki/Object_Modeling_in_Color)
> - Peter Coad, Eric Lefebvre, Jeff De Luca, _Java Modeling in Color with UML: Enterprise Components and Process_ - Chapter 1, "Archetypes, Color, and the Domain-Neutral Component"
> - David J. Anderson, _Color Modeling and the Law of Demeter_

---

## 1. Domain Modeling

Domain modeling is the discipline of identifying the business concepts a system must represent, the responsibilities those concepts carry, the way they relate to each other, and the facts or activities the business needs to remember over time. A domain model is not primarily a database design, an API schema, or a UI structure. It is a structured representation of business meaning.

In practical terms, domain modeling answers questions like these:

- What business activities matter enough that the system must remember them?
- What people, organizations, places, and things participate in those activities?
- When does participation itself need to be modeled separately from the participant?
- Which descriptions, defaults, policies, and classifications apply repeatedly across many individual things?
- Where should responsibilities live so the model reflects the real business instead of a technical convenience?

This standard uses color modeling as the core classification system for answering those questions. Color modeling matters here because it gives a repeatable way to identify the main kinds of domain classes, separate them cleanly, and review whether the model is carrying the right responsibilities.

Color modeling is not about decoration. The colors are visual labels for four recurring kinds of domain classes that appear across business domains. Those labels make it easier to see the overall model shape, especially the remembered business activities, participation contexts, reusable descriptions, and individually tracked things that define the problem space.

The key contextual idea is this: if the model correctly separates these four class types, it becomes easier to assign responsibilities, spot missing concepts, reduce coupling, and compose the project around the actual business shape rather than around technical layers or premature packaging decisions.

## 2. Archetype Primer

An archetype is a recurring class form that domain classes more or less follow. It is a discovery and review aid. It is not a superclass, not a framework base type, and not a rigid taxonomy that every code class must literally implement.

In this standard, the colors are shorthand labels for the four recurring archetype classes:

```text
Pink   -> Moment-Interval
Yellow -> Role
Blue   -> Description
Green  -> Party / Place / Thing
```

The important part is not the color itself. The important part is the kind of business concept the class represents, the responsibilities it usually carries, and the order in which you ask the classification questions.

### 2.1 Moment-Interval Class

A moment-interval class represents something that happens at a moment in time or over an interval of time that the business needs to remember, track, assess, or act on. This is usually the first archetype to look for because it reveals the actual business activity the system exists to support.

Typical signs of a moment-interval class:

- The business talks about it as something that happened, is underway, completes, cancels, expires, or is compared with another occurrence.
- It has a meaningful date, date-time, or interval.
- The system must remember it for business, operational, audit, or legal reasons.
- It often carries status, priority, totals, or other outcome-bearing facts.
- It often has parts or details.

Typical examples include sales, rentals, reservations, refresh runs, analysis runs, evaluations, reviews, and executions. A moment-interval is not just anything with a date. The test is whether the business cares about the occurrence itself as a first-class thing to remember and work with.

### 2.2 Role Class

A role class is a way a party, place, or thing participates in something else. It is the hat worn by another class in a particular business context. You model a role separately when that participation has its own responsibilities, status, or rules that are not just the same as the underlying role player.

Typical signs of a role class:

- The same person, organization, place, or thing can participate in different ways in different contexts.
- The participation itself has business meaning.
- The participation has its own status, number, permissions, or behavior.
- The business language distinguishes the role from the thing playing it.

Typical examples include customer, cashier, owner, reviewer, seller, or venue-for-an-event. A role is not merely an association label. If the participation has no separate responsibilities or state, do not invent a role class just to rename a relationship.

Purpose of a Role class is to provide a purpose role specific interface into an underlying domain object. The prevalence of roles in a system is moderately rare and SHOULD be carefully considered before using because of the additional implementation complexity they introduce.

### 2.3 Description Class

A description class is a catalog-entry-like description: a reusable grouping of values, defaults, classifications, or assessment behavior that applies again and again across multiple individually tracked things. It represents the descriptive pattern, not one concrete occurrence.

Typical signs of a description class:

- Many individual things share the same descriptive facts.
- The business uses it as a reusable type, catalog entry, policy definition, or classification.
- It supplies defaults, shared calculations, availability logic, or assessment behavior across corresponding concrete things.
- The business needs to talk about the description separately from any one instance.

Typical examples include product descriptions, instrument descriptions, parameter definitions, and strategy descriptions. A description class is not the individually tracked thing itself. It is the reusable descriptive pattern applied to many such things.

### 2.4 Party, Place, Or Thing Class

A party, place, or thing class is the individually identifiable person, organization, place, or thing the business needs to track. This archetype carries durable identity and often serves as the role player for one or more roles.

Typical signs of a party, place, or thing class:

- The business needs to identify it individually.
- It has its own serial number, name, address, symbol, or other identity-bearing facts.
- It may participate in multiple roles and multiple activities over time.
- It persists as the same thing across contexts.

Typical examples include people, organizations, instruments, accounts, venues, workspaces, and physical or logical assets. This is the default archetype only after the class has failed the earlier pink, yellow, and blue tests.

### 2.5 Why The Classification Order Matters

Classify candidate classes in this order:

1. Moment-interval
2. Role
3. Description
4. Party / place / thing

This order matters because green is the fallback. If you start by labeling everything as a thing, you will hide the business events, participation contexts, and reusable descriptions that give the model its shape.

### 2.6 Archetypes Are About Responsibilities, Not Just Labels

The archetypes matter because they suggest common responsibilities:

- Pink classes often make, add detail, calculate, complete, cancel, and compare with related pink classes.
- Yellow classes often assess or summarize participation across related pink classes.
- Blue classes often provide defaults, reusable calculations, or assessments across corresponding green classes.
- Green classes often carry identity and coordinate with the roles they play.

The goal is not to color every class for its own sake. The goal is to discover the right class responsibilities, the right coupling shape, and the right project composition.

## 3. Modeling Posture

- `[MUST]` Build the domain model around business meaning, remembered business activity, and business responsibilities rather than around tables, screens, endpoints, or frameworks.
- `[MUST]` Start with the problem domain itself before deciding packages, components, or implementation structure.
- `[MUST]` Use the model as an active thinking tool for discovering missing concepts, responsibilities, and coupling problems.
- `[MUST]` Keep the model aligned with the business language used in the specifications and domain discussions.
- `[MUST-NOT]` treat the model as a passive documentation artifact or a renamed database schema.
- `[SHOULD]` use Object Modeling in Color as the primary discovery lens for finding the recurring class categories in the domain.
- `[SHOULD]` use the model to discover what must be remembered, what participates, what is described repeatedly, and what has durable identity.

## 4. Four Archetypes As The Primary Discovery Lens

- `[MUST]` Classify important domain classes using the four archetypes from Object Modeling in Color:

  ```text
  Pink   -> Moment-Interval
  Yellow -> Role
  Blue   -> Description
  Green  -> Party / Place / Thing
  ```

- `[MUST]` Ask the archetype questions in this order when classifying a class:
  1. Is it a moment in time or an interval in time that the business must remember or work with?
  2. If not, is it a catalog-entry-like description whose values apply again and again?
  3. If not, it is a party, place, or thing.
  4. If not, is it a role played by a party, place, or thing?
  5. Otherwise it is a utility class and has no color.
- `[MUST]` Start discovery with pink moment-intervals because they typically reveal the business areas, process progressions, and most interesting responsibilities.
- `[MUST]` Model yellow roles separately only when participation itself carries responsibilities, status, or rules that differ from the underlying party, place, or thing. Be absoluty sure it is a role and not another archetype.
- `[MUST]` Model blue descriptions when a reusable set of values, defaults, or assessment behavior applies across many green things.
- `[MUST]` Model green parties, places, and things when the business needs to identify and track them individually.
- `[MUST-NOT]` force classes into a more elaborate archetype than the domain requires. Green remains the default only after pink, yellow, and blue have been ruled out.
- `[MUST-NOT]` implement archetypes as inheritance hierarchies or framework base classes. The sources describe archetypes as modeling forms, not code superclasses.
- `[SHOULD]` preserve archetype labels in model reviews and design notes even when the codebase does not literally use color.
- `[SHOULD]` treat missing pinks, yellows, or blues as review signals that the model may be hiding business activity, participation context, or reusable description.

## 5. The Domain-Neutral Component Shape

- `[MUST]` Recognize the default Domain-Neutral Component progression:

  ```text
  Description -> Party/Place/Thing -> Role -> Moment-Interval -> Moment-Interval Detail
  ```

- `[MUST]` Use the progression as a discovery and review aid, not as a rigid template that every area must fully instantiate.
- `[MUST]` Drop classes along the chain when the business does not need that level of specificity.
- `[MUST]` When a class is omitted, treat the remaining classes as immediate neighbors for dependency and responsibility purposes.
- `[MUST]` Keep prior/next and plan/actual pink-to-pink relationships explicit when the domain depends on sequence, comparison, or progression over time.
- `[SHOULD]` model moment-interval details when a pink class has meaningful parts that affect calculation, assessment, or traceability.
- `[SHOULD]` review a model by walking the blue-green-yellow-pink chain and checking whether values, identity, participation, and remembered activity have been separated clearly.

## 6. Responsibilities And Behavior

- `[MUST]` Model responsibilities on domain classes, not just attributes.
- `[MUST]` use the archetype responsibility patterns from the source material as prompts during modeling:
  - Blue descriptions assess across corresponding green objects, provide defaults, and support reusable calculations.
  - Green parties, places, and things manage their own identity and interact with corresponding roles.
  - Yellow roles assess across corresponding pink moment-intervals.
  - Pink moment-intervals make, add detail, calculate totals, complete, cancel, and compare with related pinks when the business requires it.
- `[MUST]` make time-bearing behavior explicit whenever business meaning depends on dates, intervals, priority, status, total, or progression.
- `[MUST]` keep business-significant calculations, assessments, and completions visible in the model rather than burying them in data access or transport code.
- `[MUST-NOT]` reduce the model to CRUD-only classes with no business behavior.
- `[MUST-NOT]` hide business rules in controllers, endpoints, repositories, or UI components.
- `[SHOULD]` introduce explicit plug-in points only where the domain genuinely needs alternative business behavior or algorithmic variation over time.
- `[SHOULD]` review method names against business language. If the business speaks about calculating, assessing, completing, canceling, or comparing, the model should expose corresponding behavior.

## 7. Law Of Demeter And Dependency Shape

- `[MUST]` apply the Law of Demeter to domain interactions: each class should depend only on closely related classes and immediate neighbors.
- `[MUST]` treat each class as a component with a deliberate interface and deliberate degree of coupling.
- `[MUST]` keep dynamic dependencies limited to immediate neighbors in the chosen Domain-Neutral Component chain or equivalent local structure.
- `[MUST]` ask a direct collaborator to answer a question or perform a behavior instead of traversing accessor chains to reach distant objects.
- `[MUST]` prefer loose coupling at the class level so packaging and coarse-grained componentization can be postponed until the last responsible moment.
- `[MUST-NOT]` reach through one object to manipulate or interrogate distant objects in business logic.
- `[MUST-NOT]` expose deep object graphs merely so callers can ask questions several hops away.
- `[SHOULD]` accept contextual message forwarding when it preserves loose coupling and keeps the receiving object responsible for its own knowledge.
- `[SHOULD]` use design reviews to spot non-Demeter accessor chains and overly knowledgeable classes.

## 8. Project Composition From The Model

- `[MUST]` derive packaging and componentization decisions from the modeled business areas rather than from technical layers.
- `[MUST]` use pink moment-intervals and their neighboring classes to identify coherent business areas that belong together.
- `[MUST]` keep classes that collaborate tightly around one remembered business activity close together in the same local package or component.
- `[MUST]` use loose coupling between neighboring classes so larger packaging decisions can be delayed until the model shape is stable.
- `[MUST-NOT]` package by framework role first when that hides the business shape of the model.
- `[MUST-NOT]` force early coarse-grained component boundaries before the class model has stabilized enough to reveal them naturally.
- `[SHOULD]` treat packaging as a later consequence of good class-level modeling, not as the starting point.
- `[SHOULD]` use the model to reason about where coupling is acceptable and where future refactoring risk is being created.

## 9. Review And Validation

- `[MUST]` review the model for missing pink moment-intervals first.
- `[MUST]` review whether yellow roles are genuine responsibilities rather than renamed relationships.
- `[MUST]` review whether blue descriptions capture reusable values and behavior that would otherwise be duplicated.
- `[MUST]` review whether green parties, places, and things are carrying role or event responsibilities that should be separated.
- `[MUST]` review class interactions for Law of Demeter compliance and immediate-neighbor dependencies.
- `[MUST]` review whether the current packaging follows business areas revealed by the model rather than technical convenience.
- `[MUST-NOT]` accept models that cannot explain what the business needs to remember over time.
- `[SHOULD]` use color, diagrams, tables, or similar visual devices to make the model readable at both overview and detail levels.
- `[SHOULD]` keep notes on rejected modeling alternatives so later packaging or refactoring decisions have context.

---

## Completion Checklist - Archetypes

- [ ] The important business-significant moments and intervals have been identified first
- [ ] Each major class has an explicit archetype classification or a conscious reason not to classify it
- [ ] Roles exist only where participation changes responsibilities or status
- [ ] Reusable descriptions and defaults are modeled explicitly where needed
- [ ] Green parties, places, and things are not silently carrying pink or yellow responsibilities

## Completion Checklist - Coupling And Composition

- [ ] Dynamic dependencies are limited to immediate collaborators ← COMMONLY MISSED
- [ ] Accessor chains are not being used to reach distant knowledge ← COMMONLY MISSED
- [ ] Packaging follows business areas visible in the model
- [ ] Coarse-grained componentization has not been forced prematurely
- [ ] The model can explain why classes belong together before implementation structure is finalized

## Completion Checklist - Source Discipline

- [ ] The rules applied here come from color modeling and Law of Demeter rather than unrelated DDD terminology ← COMMONLY MISSED
- [ ] Clean Architecture, if used, is treated as a separate layering reference rather than a dependency of this modeling approach
- [ ] Execution planning concerns have been kept out of this document and moved to build-fdd-standards.md
