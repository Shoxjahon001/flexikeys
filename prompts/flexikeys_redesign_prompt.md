# FlexiKeys — Full App Visual Redesign (Claude Code Prompt)

> **How to use:** open Claude Code in the FlexiKeys repo root, drag the reference mockup image into the prompt, then paste everything below the line.

---

## 0. ROLE

You are the Lead Product Designer + Senior Flutter Engineer for **FlexiKeys**, a children's educational app (ages 3–7) built with Flutter (frontend) and FastAPI (backend), localized in **English, Uzbek and Russian**.

Your combined experience: Apple HIG, Duolingo, Khan Academy Kids, Nintendo, Linear, Material 3, WCAG 2.2.

**Mission:** the app currently looks inconsistent and generic. The attached mockup (the "My Voice" / AAC module) is the **single source of truth** for the new visual language. Your job is to extract that design system, codify it, and roll it out across **every screen in the app** — with production-grade quality, not a quick reskin.

If a screen ends up looking like an AI-generated template, redesign it.

---

## 1. ABSOLUTE RULES (read before touching anything)

1. **Do NOT start writing UI code immediately.** Phase 0 is an audit. I want to read your plan before you refactor.
2. **Do not break existing business logic.** TTS, SQLite/offline-first storage, localization, navigation, audio recording, level progression — all behaviour must keep working identically. This is a *presentation layer* refactor.
3. **No hardcoded colors, sizes, radii, shadows or font sizes anywhere in widgets.** Everything comes from design tokens. If you find a raw `Color(0xFF...)` or `fontSize: 18` in a screen file, it is a bug.
4. **No new dependencies** without asking me first.
5. **Work in phases.** Finish a phase, run `flutter analyze`, show me the result, wait for my go-ahead. Never dump 20 file rewrites at once.
6. **Reuse before you create.** If a component already exists, extend it. Don't create `CardWidget2`, `NewButton`, `CustomCardV3`.
7. Every string must go through the existing localization layer. **Zero hardcoded user-facing text.**
8. Delete the old widget once it is fully replaced. No dead code, no `_old.dart` files left behind.

---

## 2. PHASE 0 — AUDIT (do this first, no code)

Scan the whole `lib/` tree and produce a written report:

- **Screen inventory** — every screen/route: file path, purpose, current state (matches new design / partially / not at all).
- **Widget inventory** — every reusable widget, plus a list of duplicated widgets that should be merged into one.
- **Design debt list** — hardcoded colors, magic numbers, inconsistent paddings, inconsistent corner radii, mixed font sizes, inconsistent button styles, screens with different background colors.
- **Navigation map** — how screens connect; where the bottom nav / sidebar is defined.
- **Localization check** — any hardcoded strings, any place where Cyrillic or long Uzbek strings would overflow.
- **Risk list** — screens where a redesign could break logic.

Then propose a **phased rollout plan** ordered by user impact, and stop. Wait for my approval.

---

## 3. THE DESIGN LANGUAGE (extracted from the reference mockup)

Study the attached image carefully. This is what defines FlexiKeys now:

**Feel:** warm, calm, friendly, premium. Soft lavender-white canvas, white floating cards, one strong purple accent, pastel category colors, generous whitespace, big rounded corners, large illustrations, huge touch targets.

**Structural patterns visible in the mockup:**

- **Home:** greeting header with child's name + avatar, a question prompt, then a 2-column grid of large pastel category cards (label top-left, illustration bottom-right).
- **Category screen:** back button + title + favorite icon, horizontal scrollable filter chips (first chip active = filled purple, others = light pill), 2-column grid of white cards with an illustration, a caption, and a circular purple speaker button in the corner.
- **Detail / speak screen:** back + star + overflow menu, one large illustration in a rounded frame, the phrase in very large bold type, a large purple circular play button flanked by two smaller secondary actions (Repeat / Next), page indicator `1 / 8` beneath.
- **My cards:** search + filter icons, filter chips, photo cards, and a full-width purple primary button pinned at the bottom.
- **Create card:** a numbered step form (1 photo → 2 voice → 3 name → 4 category → 5 color) laid out in soft grey-lavender step containers, each step visually separated, with a full-width primary save button.
- **Tablet/landscape:** the bottom bar becomes a **left sidebar** with icon + label rows, active item highlighted with a soft purple pill, and the child's profile card pinned at the bottom.
- **Bottom nav (phone):** 4 items + a raised circular purple mic FAB in the center notch.
- **Related items list:** row = small rounded thumbnail + label + chevron, separated by hairlines.

Adopt these patterns as the app's standard layouts and reuse them everywhere.

---

## 4. DESIGN TOKENS (create these first — Phase 1)

Create `lib/design_system/` with:

```
lib/design_system/
  tokens/
    app_colors.dart
    app_typography.dart
    app_spacing.dart
    app_radius.dart
    app_shadows.dart
    app_motion.dart
  theme/
    app_theme.dart          // light + dark ThemeData built from tokens
  components/               // see section 5
  design_system.dart        // barrel export
```

### Colors

| Token | Value | Use |
|---|---|---|
| `primary` | `#6D4AFF` | play buttons, primary CTA, active nav, active chip |
| `primaryPressed` | `#5533E0` | pressed state |
| `primarySoft` | `#EFE9FF` | selected chip bg, icon bg, sidebar active pill |
| `background` | `#F7F6FB` | app canvas |
| `surface` | `#FFFFFF` | cards, sheets, app bar |
| `surfaceMuted` | `#F2F1F7` | step containers, input fields |
| `textPrimary` | `#1C1B2E` | headings, card words |
| `textSecondary` | `#6B6880` | subtitles, captions |
| `textTertiary` | `#9A97AD` | placeholders, page indicator |
| `border` | `#E8E6F0` | hairlines, dividers, input borders |
| `success` | `#34C77B` · `successSoft #E3F7EC` | privacy/safe, correct |
| `warning` | `#FFB020` · `warningSoft #FFF3DA` | |
| `danger` | `#FF5A5F` · `dangerSoft #FFE5E6` | delete, recording dot |
| `info` | `#3DA9FC` · `infoSoft #E3F1FE` | |

**Category pastel palette** (`AppColors.categoryPalette`) — each entry is a `(background, foreground/accent)` pair, used for category cards and as the user-selectable card color in Create Card:

- Blue `#D9EAFB` / `#1F5D8F`
- Yellow `#FDF0CE` / `#8A6412`
- Green `#DCF2DE` / `#256B37`
- Lilac `#EADDF9` / `#5B3A8C`
- Peach `#FBE3D3` / `#8F4C22`
- Pink `#FBD9DE` / `#8F2C41`

Never place these pastels behind small text without their paired foreground color.

### Typography

Font: **Nunito** (full Latin + Cyrillic support — critical for RU/UZ). Weights 400/600/700/800.

| Token | Size / Line / Weight | Use |
|---|---|---|
| `display` | 34 / 40 / 800 | the spoken phrase on detail screens |
| `h1` | 28 / 34 / 800 | greeting |
| `h2` | 22 / 28 / 700 | screen titles |
| `h3` | 18 / 24 / 700 | section headers, category card labels |
| `bodyLarge` | 16 / 24 / 600 | list rows, buttons |
| `body` | 15 / 22 / 500 | descriptions |
| `caption` | 13 / 18 / 600 | card captions, chips |
| `label` | 12 / 16 / 700 | nav labels, step numbers |

Rules: max 2 lines for any card caption with ellipsis; never below 12sp; letterSpacing `-0.2` on `display`/`h1` only.

### Spacing, Radius, Shadows, Motion

- **Spacing** (4pt scale): `xs 4, sm 8, md 12, lg 16, xl 20, xxl 24, xxxl 32, huge 40`. Screen horizontal padding = `lg (16)` on phone, `xxxl (32)` on tablet. Grid gutter = `md (12)`.
- **Radius:** `sm 12` (chips, inputs) · `md 16` (small cards, list rows) · `lg 20` (grid cards) · `xl 28` (hero image frames, sheets) · `pill 999`.
- **Shadows:** `soft` = `rgba(28,27,46,0.06)`, blur 16, y 6 · `lifted` = `rgba(28,27,46,0.10)`, blur 24, y 10 (pressed/hover/FAB) · `primaryGlow` = `rgba(109,74,255,0.28)`, blur 20, y 8 (play button + FAB only). **Never** use `Colors.black` shadows.
- **Motion:** `fast 150ms` · `base 250ms` · `slow 400ms`. Curves: `Curves.easeOutCubic` for entrances, `Curves.easeInOutCubic` for transitions, spring for press. Press feedback = scale to `0.96` + shadow lift. Every card entrance = fade + 12px slide up, staggered 40ms per item. **All animations must respect `MediaQuery.disableAnimations` / reduced-motion.**

---

## 5. COMPONENT LIBRARY (Phase 2)

Build these in `lib/design_system/components/`. Each must: be `const`-constructible where possible, take zero hardcoded values, expose semantic labels, have a disabled state, and have a documented public API.

| Component | Spec |
|---|---|
| `FkScaffold` | standard background, safe areas, optional app bar, optional bottom nav; every screen uses this |
| `FkAppBar` | back button (48×48 tap target), centered title `h2`, up to 2 trailing icon actions |
| `FkPrimaryButton` | full-width or intrinsic, height 56, radius `pill`, primary fill, `primaryGlow`, press-scale, loading + disabled states, optional leading icon |
| `FkSecondaryButton` | white fill, 1px `border`, `textPrimary` label |
| `FkIconButton` | circular, sizes 40 / 48 / 56, soft or filled variants |
| `FkCategoryCard` | pastel bg from palette, label top-left `h3` in paired foreground, illustration bottom-right, radius `lg`, press-scale, min height 132 |
| `FkContentCard` | white card: image area (aspect 1:1, radius `md`), caption `caption` max 2 lines, corner `FkSpeakButton` |
| `FkSpeakButton` | circular purple speaker, 40dp visual / 48dp tap, animated pulse rings while playing |
| `FkPlayButton` | large hero play button, 72dp, `primaryGlow`, morphs play↔pause, radial pulse while speaking |
| `FkFilterChipBar` | horizontal scroll, selected = primary fill + white text, unselected = `primarySoft` + `textSecondary`, height 36, radius `pill`, keeps selection on scroll |
| `FkListRow` | thumbnail 44 rounded + label `bodyLarge` + chevron, height ≥ 64, hairline divider |
| `FkStepContainer` | numbered step block for forms: `surfaceMuted` bg, radius `lg`, badge with step number, title, slot for content |
| `FkTextField` | radius `sm`, `surfaceMuted` fill, no harsh borders, focus = 2px primary ring, error state |
| `FkColorPicker` | row of category palette swatches, selected shows a check |
| `FkBottomNav` | 4 items + center circular primary FAB, active = filled icon + primary label, inactive = outline icon + `textTertiary` |
| `FkSideNav` | tablet/landscape sidebar: icon + label rows, active = `primarySoft` pill, profile card pinned bottom |
| `FkPageIndicator` | `1 / 8` in `caption` `textTertiary`, plus optional dot variant |
| `FkEmptyState` | illustration + title + description + optional primary action |
| `FkSkeleton` | shimmer placeholders matching real card shapes — never a bare spinner on content screens |
| `FkAvatar` | circular, sizes 32/40/56, initials fallback |
| `FkSectionHeader` | `h3` title + optional trailing text action |

Build a **`/design-gallery` debug route** that renders every component in every state (default / pressed / disabled / loading / selected / RTL-safe / 1.3× text scale / dark mode). This is how I review the system before it ships.

---

## 6. SCREEN ROLLOUT (Phase 3+)

Redesign **every** screen using only the tokens and components above. One phase per group; show me screenshots or a summary after each.

1. **Home / Dashboard** — greeting header (`h1` + child name + avatar), prompt line, 2-column category grid, bottom nav.
2. **My Voice / AAC module** — align it fully with the mockup: category screen, speak/detail screen, my cards, create card form. This is the reference; make it pixel-consistent.
3. **Learning levels (the 16 game levels)** — level cards use `FkCategoryCard` rhythm; locked/active/completed states; progress ring; keep all existing game logic untouched.
4. **Letters / Shapes / Drawing activities** — same canvas, same chrome (`FkScaffold` + `FkAppBar`), same button language. Only the activity surface itself is custom.
5. **Results / reward screens** — big illustration, celebratory but calm, one primary action.
6. **Settings** — grouped `FkListRow` sections, language switcher (EN/UZ/RU) as a clear segmented control, TTS voice + speed, accessibility section.
7. **Profile / progress / history** — simple charts using token colors, no dashboard energy.
8. **Onboarding / first run** — 3 slides max, one primary action per slide.
9. **All modals, dialogs, bottom sheets, toasts, error states, empty states, loading states.** These are usually the ugliest part of an app — treat them as first-class screens.

---

## 7. RESPONSIVE

Breakpoints: `< 600` phone (bottom nav, 2-column grid) · `600–1024` tablet (side nav, 3-column grid, wider padding) · `> 1024` large tablet / desktop (side nav, 4-column grid, max content width 1100 centered).

Rules: no fixed pixel widths; grids adapt by column count, not by squeezing cards; test portrait **and** landscape; the sidebar layout in the mockup is the tablet target.

---

## 8. ACCESSIBILITY (non-negotiable — this app serves children with speech difficulties)

- Minimum touch target **48×48**; primary child-facing actions **≥ 64**. Speak buttons and play buttons get the largest targets on screen.
- Contrast **≥ 4.5:1** for text, **≥ 3:1** for icons and interactive borders. Verify every pastel/foreground pair.
- Every interactive widget has a `Semantics` label from the localization file — never a raw English string.
- Support text scaling up to **1.3×** without overflow. Test it. Cards must grow, not clip.
- Respect reduced motion, and provide a **high-contrast** toggle in Settings.
- Keep the existing AAC accessibility features intact and re-style them: **dwell-time activation**, **switch access**, large touch mode.
- Never encode meaning in color alone (locked/completed states need an icon too).
- Dark mode: full token parity, no pure black — use `#14131C` canvas, `#1E1D2A` surface.

---

## 9. LOCALIZATION

- All three languages must be visually verified: **English, Uzbek (Latin), Russian (Cyrillic)**.
- Russian and Uzbek strings run ~30% longer than English — layouts must flex, never truncate mid-word on primary buttons.
- Nunito must render Cyrillic correctly at every weight; check the greeting, card captions, chips and the large `display` phrase.
- Keep the existing `shared_preferences` language persistence working; the switcher must instantly rebuild the UI.

---

## 10. QUALITY GATE

Before you report a phase as done, self-score it:

- Visual Quality /10
- Design-System Consistency /10
- Originality (does it look handcrafted?) /10
- Accessibility /10
- Child Engagement /10
- Animation Quality /10
- Code Quality (reuse, no magic numbers, readable) /10

**If any score is below 9, fix it before showing me.** Report the scores with a one-line justification each.

Also, per phase, confirm:
- `flutter analyze` → 0 issues
- App builds and runs on iOS + Android
- No hardcoded colors / sizes / strings introduced
- Old widgets deleted, no dead code
- Tested at 1.3× text scale, in all 3 languages, in light + dark, on phone + tablet

---

## 11. DELIVERABLE FORMAT PER PHASE

1. What changed (file-by-file, one line each)
2. New/updated component APIs
3. Anything that surprised you or that you deliberately deviated on, and why
4. Self-review scores
5. What's next + anything you need me to decide

---

**Start now with Phase 0 (audit only). No code yet.**
