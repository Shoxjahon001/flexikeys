import 'package:flutter/material.dart';
import 'trace_item_def.dart';

// Same coordinate convention as kLetterTraceItems — normalized 0-1, content
// roughly between y≈0.15 and y≈0.87. Five simple, recognizable outlines.
const List<TraceItemDef> kObjectTraceItems = [
  // Uy (House) ─────────────────────────────────────────────────────────────────
  TraceItemDef(label: 'Uy', ruLabel: 'Дом',
    dots: [Offset(0.22,0.85), Offset(0.22,0.50), Offset(0.50,0.20), Offset(0.78,0.50), Offset(0.78,0.85)],
    ghost: [[Offset(0.22,0.85),Offset(0.22,0.50),Offset(0.50,0.20),Offset(0.78,0.50),Offset(0.78,0.85),Offset(0.22,0.85)]]),
  // Yurak (Heart) ──────────────────────────────────────────────────────────────
  TraceItemDef(label: 'Yurak', ruLabel: 'Сердце',
    dots: [Offset(0.50,0.35), Offset(0.30,0.18), Offset(0.15,0.40), Offset(0.50,0.85), Offset(0.85,0.40), Offset(0.70,0.18)],
    ghost: [[
      Offset(0.50,0.35),
      Offset(0.42,0.20),Offset(0.28,0.15),Offset(0.16,0.24),Offset(0.15,0.40),Offset(0.22,0.55),
      Offset(0.50,0.85),
      Offset(0.78,0.55),Offset(0.85,0.40),Offset(0.84,0.24),Offset(0.72,0.15),Offset(0.58,0.20),
      Offset(0.50,0.35),
    ]]),
  // Yulduz (Star) ──────────────────────────────────────────────────────────────
  TraceItemDef(label: 'Yulduz', ruLabel: 'Звезда',
    dots: [Offset(0.50,0.12), Offset(0.82,0.38), Offset(0.70,0.80), Offset(0.30,0.80), Offset(0.18,0.38)],
    ghost: [[
      Offset(0.50,0.12),Offset(0.60,0.38),Offset(0.82,0.38),Offset(0.63,0.55),Offset(0.70,0.80),
      Offset(0.50,0.65),Offset(0.30,0.80),Offset(0.37,0.55),Offset(0.18,0.38),Offset(0.40,0.38),
      Offset(0.50,0.12),
    ]]),
];