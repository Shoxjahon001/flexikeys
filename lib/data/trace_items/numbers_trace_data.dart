import 'package:flutter/material.dart';
import 'trace_item_def.dart';

// Digit body sits between y≈0.15 (cap line) and y≈0.87 (baseline), same
// coordinate convention as kLetterTraceItems. Shapes are simplified,
// straight-segment approximations — not calligraphic — suitable for a
// young child's first tracing practice.
const List<TraceItemDef> kNumberTraceItems = [
  // 0 ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: '0',
    dots: [Offset(0.50,0.15), Offset(0.73,0.52), Offset(0.50,0.87), Offset(0.27,0.52)],
    ghost: [[
      Offset(0.50,0.15),Offset(0.68,0.22),Offset(0.75,0.40),Offset(0.75,0.63),
      Offset(0.68,0.80),Offset(0.50,0.87),Offset(0.32,0.80),Offset(0.25,0.63),
      Offset(0.25,0.40),Offset(0.32,0.22),Offset(0.50,0.15),
    ]]),
  // 1 ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: '1',
    dots: [Offset(0.38,0.25), Offset(0.50,0.15), Offset(0.50,0.87)],
    ghost: [[Offset(0.38,0.25),Offset(0.50,0.15),Offset(0.50,0.87)]]),
  // 2 ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: '2',
    dots: [Offset(0.28,0.25), Offset(0.50,0.15), Offset(0.70,0.28), Offset(0.28,0.87), Offset(0.70,0.87)],
    ghost: [[Offset(0.28,0.25),Offset(0.50,0.15),Offset(0.70,0.28),Offset(0.28,0.87),Offset(0.70,0.87)]]),
  // 3 ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: '3',
    dots: [Offset(0.30,0.18), Offset(0.68,0.30), Offset(0.40,0.52), Offset(0.68,0.72), Offset(0.30,0.85)],
    ghost: [[Offset(0.30,0.18),Offset(0.68,0.30),Offset(0.40,0.52),Offset(0.68,0.72),Offset(0.30,0.85)]]),
  // 4 ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: '4',
    dots: [Offset(0.60,0.15), Offset(0.25,0.60), Offset(0.72,0.60), Offset(0.60,0.30), Offset(0.60,0.87)],
    ghost: [
      [Offset(0.60,0.15),Offset(0.25,0.60),Offset(0.72,0.60)],
      [Offset(0.60,0.30),Offset(0.60,0.87)],
    ]),
  // 5 ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: '5',
    dots: [Offset(0.68,0.15), Offset(0.30,0.15), Offset(0.30,0.52), Offset(0.60,0.52), Offset(0.68,0.72), Offset(0.30,0.87)],
    ghost: [[Offset(0.68,0.15),Offset(0.30,0.15),Offset(0.30,0.52),Offset(0.60,0.52),Offset(0.68,0.72),Offset(0.30,0.87)]]),
  // 6 ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: '6',
    dots: [Offset(0.60,0.18), Offset(0.35,0.50), Offset(0.50,0.87), Offset(0.68,0.68), Offset(0.45,0.55)],
    ghost: [
      [Offset(0.60,0.18),Offset(0.40,0.32),Offset(0.30,0.50),Offset(0.28,0.70)],
      [Offset(0.28,0.70),Offset(0.35,0.85),Offset(0.52,0.88),Offset(0.65,0.78),Offset(0.63,0.62),Offset(0.48,0.54),Offset(0.35,0.58),Offset(0.28,0.70)],
    ]),
  // 7 ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: '7',
    dots: [Offset(0.28,0.15), Offset(0.70,0.15), Offset(0.38,0.87)],
    ghost: [[Offset(0.28,0.15),Offset(0.70,0.15),Offset(0.38,0.87)]]),
  // 8 ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: '8',
    dots: [Offset(0.50,0.15), Offset(0.65,0.30), Offset(0.50,0.48), Offset(0.35,0.30), Offset(0.50,0.52), Offset(0.68,0.68), Offset(0.50,0.87), Offset(0.32,0.68)],
    ghost: [
      [Offset(0.50,0.15),Offset(0.63,0.20),Offset(0.66,0.30),Offset(0.63,0.42),Offset(0.50,0.48),Offset(0.37,0.42),Offset(0.34,0.30),Offset(0.37,0.20),Offset(0.50,0.15)],
      [Offset(0.50,0.52),Offset(0.65,0.58),Offset(0.70,0.68),Offset(0.65,0.80),Offset(0.50,0.87),Offset(0.35,0.80),Offset(0.30,0.68),Offset(0.35,0.58),Offset(0.50,0.52)],
    ]),
  // 9 ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: '9',
    dots: [Offset(0.55,0.42), Offset(0.68,0.28), Offset(0.55,0.15), Offset(0.38,0.25), Offset(0.42,0.40), Offset(0.60,0.55), Offset(0.45,0.87)],
    ghost: [
      [Offset(0.55,0.15),Offset(0.68,0.20),Offset(0.72,0.32),Offset(0.68,0.44),Offset(0.55,0.48),Offset(0.42,0.44),Offset(0.38,0.32),Offset(0.42,0.20),Offset(0.55,0.15)],
      [Offset(0.68,0.32),Offset(0.62,0.55),Offset(0.45,0.87)],
    ]),
];