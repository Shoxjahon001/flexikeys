import 'package:flutter/material.dart';
import 'trace_item_def.dart';

// Uppercase letter body sits between y≈0.15 (cap line) and y≈0.87 (baseline).
const List<TraceItemDef> kLetterTraceItems = [
  // A ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'A',
    dots: [Offset(0.30,0.87), Offset(0.50,0.15), Offset(0.70,0.87), Offset(0.37,0.56), Offset(0.63,0.56)],
    ghost: [[Offset(0.30,0.87),Offset(0.50,0.15),Offset(0.70,0.87)],[Offset(0.37,0.56),Offset(0.63,0.56)]]),
  // B ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'B',
    dots: [Offset(0.30,0.15), Offset(0.30,0.87), Offset(0.65,0.28), Offset(0.30,0.52), Offset(0.67,0.68)],
    ghost: [
      [Offset(0.30,0.15),Offset(0.30,0.87)],
      [Offset(0.30,0.15),Offset(0.58,0.18),Offset(0.65,0.28),Offset(0.62,0.40),Offset(0.30,0.52)],
      [Offset(0.30,0.52),Offset(0.60,0.56),Offset(0.68,0.68),Offset(0.60,0.80),Offset(0.30,0.87)],
    ]),
  // C ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'C',
    dots: [Offset(0.68,0.25), Offset(0.48,0.15), Offset(0.27,0.52), Offset(0.48,0.87), Offset(0.68,0.77)],
    ghost: [[Offset(0.68,0.25),Offset(0.50,0.15),Offset(0.32,0.27),Offset(0.27,0.52),Offset(0.32,0.76),Offset(0.50,0.87),Offset(0.68,0.77)]]),
  // D ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'D',
    dots: [Offset(0.30,0.15), Offset(0.30,0.87), Offset(0.68,0.66), Offset(0.68,0.35)],
    ghost: [
      [Offset(0.30,0.15),Offset(0.30,0.87)],
      [Offset(0.30,0.15),Offset(0.58,0.18),Offset(0.68,0.35),Offset(0.73,0.52),Offset(0.68,0.66),Offset(0.58,0.80),Offset(0.30,0.87)],
    ]),
  // E ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'E',
    dots: [Offset(0.65,0.15), Offset(0.30,0.15), Offset(0.30,0.87), Offset(0.65,0.87), Offset(0.30,0.52), Offset(0.58,0.52)],
    ghost: [
      [Offset(0.65,0.15),Offset(0.30,0.15),Offset(0.30,0.87),Offset(0.65,0.87)],
      [Offset(0.30,0.52),Offset(0.58,0.52)],
    ]),
  // F ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'F',
    dots: [Offset(0.30,0.15), Offset(0.30,0.87), Offset(0.63,0.15), Offset(0.30,0.52), Offset(0.57,0.52)],
    ghost: [
      [Offset(0.30,0.15),Offset(0.30,0.87)],
      [Offset(0.30,0.15),Offset(0.63,0.15)],
      [Offset(0.30,0.52),Offset(0.57,0.52)],
    ]),
  // G ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'G',
    dots: [Offset(0.68,0.25), Offset(0.48,0.15), Offset(0.27,0.52), Offset(0.48,0.87), Offset(0.68,0.70), Offset(0.50,0.52)],
    ghost: [
      [Offset(0.68,0.25),Offset(0.50,0.15),Offset(0.32,0.27),Offset(0.27,0.52),Offset(0.32,0.76),Offset(0.50,0.87),Offset(0.68,0.70)],
      [Offset(0.68,0.52),Offset(0.50,0.52)],
    ]),
  // H ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'H',
    dots: [Offset(0.30,0.15), Offset(0.30,0.87), Offset(0.70,0.15), Offset(0.70,0.87), Offset(0.30,0.52), Offset(0.70,0.52)],
    ghost: [
      [Offset(0.30,0.15),Offset(0.30,0.87)],
      [Offset(0.70,0.15),Offset(0.70,0.87)],
      [Offset(0.30,0.52),Offset(0.70,0.52)],
    ]),
  // I ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'I',
    dots: [Offset(0.50,0.15), Offset(0.50,0.87)],
    ghost: [
      [Offset(0.35,0.15),Offset(0.65,0.15)],
      [Offset(0.50,0.15),Offset(0.50,0.87)],
      [Offset(0.35,0.87),Offset(0.65,0.87)],
    ]),
  // J ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'J',
    dots: [Offset(0.35,0.15), Offset(0.65,0.15), Offset(0.57,0.78), Offset(0.43,0.87), Offset(0.28,0.78)],
    ghost: [
      [Offset(0.35,0.15),Offset(0.65,0.15)],
      [Offset(0.57,0.15),Offset(0.57,0.78),Offset(0.43,0.87),Offset(0.28,0.78)],
    ]),
  // K ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'K',
    dots: [Offset(0.30,0.15), Offset(0.30,0.87), Offset(0.70,0.15), Offset(0.30,0.52), Offset(0.70,0.87)],
    ghost: [
      [Offset(0.30,0.15),Offset(0.30,0.87)],
      [Offset(0.70,0.15),Offset(0.30,0.52)],
      [Offset(0.30,0.52),Offset(0.70,0.87)],
    ]),
  // L ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'L',
    dots: [Offset(0.30,0.15), Offset(0.30,0.87), Offset(0.67,0.87)],
    ghost: [[Offset(0.30,0.15),Offset(0.30,0.87),Offset(0.67,0.87)]]),
  // M ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'M',
    dots: [Offset(0.25,0.87), Offset(0.25,0.15), Offset(0.50,0.57), Offset(0.75,0.15), Offset(0.75,0.87)],
    ghost: [[Offset(0.25,0.87),Offset(0.25,0.15),Offset(0.50,0.57),Offset(0.75,0.15),Offset(0.75,0.87)]]),
  // N ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'N',
    dots: [Offset(0.28,0.87), Offset(0.28,0.15), Offset(0.72,0.87), Offset(0.72,0.15)],
    ghost: [[Offset(0.28,0.87),Offset(0.28,0.15),Offset(0.72,0.87),Offset(0.72,0.15)]]),
  // O ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'O',
    dots: [Offset(0.50,0.15), Offset(0.73,0.52), Offset(0.50,0.87), Offset(0.27,0.52)],
    ghost: [[
      Offset(0.50,0.15),Offset(0.68,0.22),Offset(0.75,0.40),Offset(0.75,0.63),
      Offset(0.68,0.80),Offset(0.50,0.87),Offset(0.32,0.80),Offset(0.25,0.63),
      Offset(0.25,0.40),Offset(0.32,0.22),Offset(0.50,0.15),
    ]]),
  // P ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'P',
    dots: [Offset(0.30,0.15), Offset(0.30,0.87), Offset(0.65,0.28), Offset(0.30,0.52)],
    ghost: [
      [Offset(0.30,0.15),Offset(0.30,0.87)],
      [Offset(0.30,0.15),Offset(0.58,0.18),Offset(0.65,0.30),Offset(0.62,0.42),Offset(0.30,0.52)],
    ]),
  // Q ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'Q',
    dots: [Offset(0.50,0.15), Offset(0.73,0.52), Offset(0.50,0.87), Offset(0.27,0.52), Offset(0.73,0.87)],
    ghost: [
      [Offset(0.50,0.15),Offset(0.68,0.22),Offset(0.75,0.40),Offset(0.75,0.63),
       Offset(0.68,0.80),Offset(0.50,0.87),Offset(0.32,0.80),Offset(0.25,0.63),
       Offset(0.25,0.40),Offset(0.32,0.22),Offset(0.50,0.15)],
      [Offset(0.58,0.73),Offset(0.75,0.90)],
    ]),
  // R ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'R',
    dots: [Offset(0.30,0.15), Offset(0.30,0.87), Offset(0.65,0.28), Offset(0.30,0.52), Offset(0.70,0.87)],
    ghost: [
      [Offset(0.30,0.15),Offset(0.30,0.87)],
      [Offset(0.30,0.15),Offset(0.58,0.18),Offset(0.65,0.30),Offset(0.62,0.42),Offset(0.30,0.52)],
      [Offset(0.30,0.52),Offset(0.70,0.87)],
    ]),
  // S ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'S',
    dots: [Offset(0.65,0.22), Offset(0.32,0.33), Offset(0.50,0.52), Offset(0.68,0.72), Offset(0.35,0.82)],
    ghost: [[
      Offset(0.65,0.22),Offset(0.48,0.15),Offset(0.30,0.28),Offset(0.35,0.45),
      Offset(0.52,0.52),Offset(0.68,0.60),Offset(0.68,0.75),Offset(0.50,0.87),Offset(0.32,0.80),
    ]]),
  // T ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'T',
    dots: [Offset(0.28,0.15), Offset(0.72,0.15), Offset(0.50,0.87)],
    ghost: [
      [Offset(0.28,0.15),Offset(0.72,0.15)],
      [Offset(0.50,0.15),Offset(0.50,0.87)],
    ]),
  // U ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'U',
    dots: [Offset(0.30,0.15), Offset(0.30,0.72), Offset(0.50,0.87), Offset(0.70,0.72), Offset(0.70,0.15)],
    ghost: [[
      Offset(0.30,0.15),Offset(0.30,0.72),Offset(0.38,0.82),Offset(0.50,0.87),
      Offset(0.62,0.82),Offset(0.70,0.72),Offset(0.70,0.15),
    ]]),
  // V ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'V',
    dots: [Offset(0.28,0.15), Offset(0.50,0.87), Offset(0.72,0.15)],
    ghost: [[Offset(0.28,0.15),Offset(0.50,0.87),Offset(0.72,0.15)]]),
  // W ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'W',
    dots: [Offset(0.20,0.15), Offset(0.33,0.87), Offset(0.50,0.55), Offset(0.67,0.87), Offset(0.80,0.15)],
    ghost: [[Offset(0.20,0.15),Offset(0.33,0.87),Offset(0.50,0.55),Offset(0.67,0.87),Offset(0.80,0.15)]]),
  // X ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'X',
    dots: [Offset(0.28,0.15), Offset(0.72,0.87), Offset(0.72,0.15), Offset(0.28,0.87)],
    ghost: [
      [Offset(0.28,0.15),Offset(0.72,0.87)],
      [Offset(0.72,0.15),Offset(0.28,0.87)],
    ]),
  // Y ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'Y',
    dots: [Offset(0.28,0.15), Offset(0.50,0.52), Offset(0.72,0.15), Offset(0.50,0.87)],
    ghost: [
      [Offset(0.28,0.15),Offset(0.50,0.52)],
      [Offset(0.72,0.15),Offset(0.50,0.52)],
      [Offset(0.50,0.52),Offset(0.50,0.87)],
    ]),
  // Z ─────────────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'Z',
    dots: [Offset(0.28,0.15), Offset(0.72,0.15), Offset(0.28,0.87), Offset(0.72,0.87)],
    ghost: [[Offset(0.28,0.15),Offset(0.72,0.15),Offset(0.28,0.87),Offset(0.72,0.87)]]),
];

/// 26 letters split into groups of 3-4, computed from [kLetterTraceItems]
/// (via [computeGroupSizes]/[buildLetterGroups] in trace_item_def.dart) so
/// the grouping always stays in sync with the underlying letter list and
/// its count is never hardcoded here.
final List<LetterGroup> kLetterGroups =
    buildLetterGroups(kLetterTraceItems, 'letters_group');