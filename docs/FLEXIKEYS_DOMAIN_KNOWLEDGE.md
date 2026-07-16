# FlexiKeys — Domain Knowledge for Claude Code

> **What this file is.** A context/knowledge base for Claude Code (and any AI agent)
> working on FlexiKeys, a children's educational Flutter app. It encodes *principles*
> — about the learning brain, communicating with young children, motor accessibility
> (cerebral palsy), and assistive technology — and translates each into concrete,
> testable design rules for the app.
>
> **How to use it.** Load this file as context (e.g. reference it in `CLAUDE.md`, or
> paste relevant sections into a prompt) before building or reviewing any
> learning-flow, feedback, or accessibility feature. When a design decision touches
> children, learning, tone, or motor input, check the relevant "Design rules" block
> below and treat the acceptance criteria in §5 as a checklist.
>
> **Important note on sources.** The two books listed in §6 are copyrighted. This
> file does **not** reproduce their text; it distills widely-known ideas and facts
> into the author's own words as engineering guidance. The medical/assistive-tech
> facts are synthesized from the public health and open-access sources in §6.
> None of this is medical advice — it informs product design, not clinical care.

---

## 1. Product frame

FlexiKeys teaches early literacy and pre-writing skills (letters, shapes, drawing)
to young children through touch-based games. Because the users are young children —
and because the app aims to be usable by children with a range of abilities,
including motor disabilities — three constraints sit above every feature:

1. **The child is pre-literate and pre-verbal-instruction.** They cannot read help
   text, error dialogs, or menus reliably. Communication is visual, audible, and
   demonstrative.
2. **Ability varies widely.** Fine-motor precision, reaction time, attention span,
   and sensory processing differ enormously between children of the same age. The
   app should degrade gracefully, not gate-keep.
3. **Emotional safety drives learning.** A frustrated or shamed child disengages.
   Every interaction should protect the child's sense of competence.

---

## 2. The learning brain — how young children learn

**Principles (synthesized):**

- **The developing brain is shaped by experience ("plasticity").** Connections that
  are used repeatedly get stronger; unused ones fade. Learning is not a one-shot
  event — it is the gradual physical wiring of a skill through repetition.
- **Childhood is a period of massive, fast wiring.** Young brains form and prune
  connections rapidly, which is why early, repeated, multi-sensory practice is so
  effective and why *how* something is practiced matters as much as *how often*.
- **Multi-sensory input strengthens memory.** A letter that is seen, heard, traced,
  and spoken is encoded through several channels at once and is recalled better than
  one presented through a single channel.
- **Prediction and reward shape attention.** The brain constantly predicts what
  comes next; small, well-timed rewards (a sound, an animation) reinforce the
  behavior that preceded them. Reward timing must be immediate to link cause and
  effect.
- **Spacing and retrieval beat cramming.** Skills revisited over time and actively
  recalled (not just re-shown) stick better than skills drilled once in a long
  block.

**Design rules for FlexiKeys:**

- Every core skill (a letter, a shape) is practiced through **at least two senses**
  simultaneously — e.g. show the letter + speak it + let the child trace it.
- **Reward feedback fires within ~200 ms** of the correct action. Never batch praise
  to the end of a level only.
- Introduce a skill, then **re-surface it in later levels** (spaced repetition)
  rather than teaching it once and moving on.
- Prefer **active retrieval** ("which one is the letter B?") over passive display.
- Repetition should feel varied, not identical — same skill, different visual
  container — to hold attention while the underlying practice repeats.

---

## 3. Communicating with young children — tone, feedback, and autonomy

**Principles (synthesized):**

- **Acknowledge effort and feeling before correcting.** A child who feels understood
  cooperates; a child who feels dismissed resists. Feedback that first recognizes
  the attempt lands better than feedback that leads with the error.
- **Describe, don't judge.** Effective encouragement describes what the child did
  ("you traced the whole curve!") rather than labeling the child ("you're so
  smart!"). Descriptive feedback builds real competence and is not deflated by a
  later failure.
- **Offer autonomy within limits.** Children engage more when they choose *within* a
  safe, bounded set ("do you want the red star or the blue star?") than when
  everything is decided for them.
- **Avoid shame and punishment framing.** Negative labels and punitive feedback
  ("Wrong!", buzzer + red X + sad face stacked together) teach avoidance, not
  skill. Errors should be reframed as "try again," never as personal failure.
- **Engage cooperation, don't command.** Invitations and playful framing ("let's
  find the circle together") work better than instructions that assume compliance.

**Design rules for FlexiKeys:**

- **No failure states that read as shame.** A wrong answer produces a gentle,
  neutral "try again" cue (soft sound + re-highlight the target), never a harsh
  buzzer stacked with negative imagery. The existing `sound` service's "buzz" should
  be soft and non-punitive; audit it against this.
- **Praise describes the action.** TTS/voice praise says what happened ("you found
  the B!") not global judgments. Keep praise specific and earned — constant
  over-praise loses meaning.
- **Give bounded choices.** Where possible let the child pick (character, sticker
  color, which of two activities) rather than forcing a single path.
- **Never show technical or scolding text to the child.** All child-facing
  communication is visual + audio. Errors, network problems, and auth issues are
  handled silently or shown only on **parent-facing** screens.
- A child must always have a **frictionless "try again"** and a way to move on
  without being trapped on a failure.

---

## 4. Motor accessibility — designing for cerebral palsy and varied motor ability

**Background (synthesized from public-health sources):**

- Cerebral palsy (CP) is the most common motor disability of childhood: a group of
  permanent disorders of movement and posture caused by early, non-progressive
  changes in the developing brain. It affects **movement, balance, and posture**.
- CP is a *spectrum*. Motor ability ranges widely (commonly described from
  independent movement through to no independent mobility). Many children with CP
  also have co-occurring differences in **communication, vision, hearing, attention,
  or fatigue** — motor is the hallmark but rarely the only factor.
- Guidance in the field increasingly stresses **activity and participation** (can the
  child actually *do* and *join in*?) over narrow body-function metrics — and stresses
  **fun, function, and family** as first-class goals for children, not afterthoughts.
- Touch/pointer input can be affected by: reduced precision, tremor or extra
  unintended touches, slower movement, difficulty with sustained holds or fast
  taps, and easier fatigue.

**Design rules for FlexiKeys (concrete Flutter/UI requirements):**

- **Large touch targets.** Interactive targets are generously sized (aim for a large
  minimum — well above the 48dp baseline for primary game targets) with **generous
  spacing** so an imprecise tap doesn't hit the wrong element.
- **No reliance on speed or fast/precise gestures.** Avoid double-tap, long-press-
  only actions, tiny drag handles, timed taps, or "tap quickly" mechanics as the
  *only* way to succeed. Anything achievable by a drag should tolerate a slow,
  wobbly drag path.
- **Generous timing, adjustable.** No hard time limits on activities by default. If
  a timer exists, it is optional and lengthenable. Auto-advance delays are long
  enough for a slow responder.
- **Tolerant hit-testing for tracing/drawing.** Shape- and letter-tracing accept a
  *wide corridor* around the ideal path, and score progress/partial completion
  rather than demanding pixel-perfect strokes. Consider dwell-to-select as an
  alternative to precise tapping.
- **Debounce unintended input.** Filter accidental double/extra touches so a tremor
  doesn't register as a wrong answer.
- **Errorless-learning option.** Provide a mode where wrong targets are inactive or
  softly guided, so exploration never produces a "failure."
- **Multi-modal by default** (ties back to §2): because vision, hearing, or attention
  may also vary, never depend on a single channel — pair visuals with audio and
  motion cues.
- **Respect fatigue.** Keep required sessions short; make it easy to pause and resume
  exactly where the child left off (ties to local progress persistence).
- **Design for participation.** Success should be reachable for a child with low
  motor precision — measure "did they engage and progress?", not "were they fast and
  exact?"

---

## 5. Assistive-technology principles (and the accessibility acceptance checklist)

**Principles (synthesized from the assistive-technology review):**

- **User-centered fit beats one-size-fits-all.** The strongest recommendation across
  assistive-technology guidance is to match the tool to the individual and let the
  user's (and caregiver's) preferences drive configuration.
- **Digital/mainstream devices are now assistive devices.** Smartphones and tablets
  increasingly *are* the assistive technology; general consumer apps that build in
  accessibility reach children who would never get specialist hardware — a strong
  reason to bake accessibility into FlexiKeys itself.
- **Cognition and communication are the under-served gap.** Guideline coverage is
  thin exactly for cognitive/communication support — the space FlexiKeys operates
  in — so thoughtful, configurable design here has real value.
- **Caregiver involvement matters.** Parents/teachers configure, observe, and adapt;
  give them the controls.

**Accessibility acceptance checklist (use as review gates):**

- [ ] Primary touch targets are large and well-spaced; no critical action needs
      fine precision.
- [ ] No task *requires* fast, double, long-press-only, or timed gestures.
- [ ] Tracing/drawing tolerates wobble and rewards partial progress.
- [ ] No hard time limits by default; any timer is optional and extendable.
- [ ] Accidental extra touches are debounced.
- [ ] Errors are gentle, neutral, and instantly retryable — never shaming.
- [ ] Every skill is presented through ≥2 sensory channels (visual + audio at least).
- [ ] Reward feedback is immediate (~200 ms) and describes the action.
- [ ] The child never sees technical/error/auth text; those live on parent screens.
- [ ] A **parent/teacher settings** surface exposes: target size, timing/pace,
      sound on/off, difficulty/errorless mode, and TTS voice/language.
- [ ] Progress is saved locally and resumes exactly where the child stopped.
- [ ] Skills re-appear across levels (spaced repetition), not taught once.

---

## 6. Sources

**Books (copyrighted — ideas distilled, text not reproduced):**
- David Eagleman, *The Brain: The Story of You* — neuroplasticity and experience-
  driven development of the brain.
- Adele Faber & Elaine Mazlish, *How to Talk So Kids Will Listen & Listen So Kids
  Will Talk* — acknowledging feelings, descriptive praise, autonomy, alternatives to
  punishment.

**Public health / open-access (facts synthesized in the author's own words):**
- CDC — Cerebral Palsy (overview: CP as the most common childhood motor disability;
  affects movement, balance, posture). https://www.cdc.gov/cerebral-palsy/
- Damiano et al. (2021), *Systematic Review of Clinical Guidelines … Cerebral Palsy*
  (WHO Package of Interventions for Rehabilitation) — CP definition/spectrum, the
  ICF activity-and-participation emphasis, and the "F-words" (function, family,
  fitness, fun, friends, future). PMC9619294.
- Zhang & Borg (2025), *Global availability of guidelines related to assistive
  technology: a scoping review*, Front. Rehabil. Sci. — user-centered fit, the
  cognition/communication guideline gap, digital devices as assistive technology.
  doi:10.3389/fresc.2025.1581104
- Cerebral Palsy Alliance (cerebralpalsy.org.au) and CP foundations — general
  orientation on CP as a lifelong, spectrum condition.

*Additional cited literature (abstracts) reviewed for orientation:* ScienceDirect
S000399932031337X; Tandfonline 10.1080/17483107.2025.2549905; PubMed 38476029.

---

*This document is engineering guidance for product design. It is not medical,
clinical, or therapeutic advice. Decisions about a specific child's care belong with
that child's family and clinicians.*
