# AshaSathi — Claude Code Instructions

## Knowledge Graph (graphify)

A pre-built knowledge graph lives at `graphify-out/`. **Always query it before reading source files.**

### When to use graphify instead of grepping/reading

| Task | Do this |
|------|---------|
| "Where is X defined?" | `/graphify explain "X"` |
| "What depends on Y?" | `/graphify query "what depends on Y"` |
| "How does A connect to B?" | `/graphify path "A" "B"` |
| "What does this module do?" | Check community labels in `graphify-out/GRAPH_REPORT.md` |
| Understanding unfamiliar code | Read `graphify-out/GRAPH_REPORT.md` → God Nodes + Community map first |

Only open source files when the graph gives you a specific file:line to confirm details.

### Key graph facts (as of last build)

- **1369 nodes, 1651 edges, 95 communities**
- Graph files: `graphify-out/graph.json`, `graphify-out/graph.html`, `graphify-out/GRAPH_REPORT.md`

### Top god nodes (most connected — touch these carefully)

1. `flutter_riverpod` — 32 edges, bridges 15 communities (state management spine)
2. `flutter/material.dart` — 29 edges, bridges 13 communities
3. `dart:convert` — 17 edges
4. `app_localizations.dart` — 16 edges
5. `MedicalDocumentService` — 12 edges (backend hub)
6. `app_colors.dart` — 12 edges

### Community map (major clusters)

| Community | What it is |
|-----------|-----------|
| Offline Data Sync Layer | SQLite offline DB, sync engine, connectivity service |
| App Settings & Shell | AppSettings, theme mode, locale, MaterialApp shell |
| Patient Detail UI | Patient detail page, glass app bar, image viewer |
| Dashboard & Bootstrap | Home page, dashboard bootstrap, skeleton loaders |
| Family API & Services | Spring Boot family controller, repository, service |
| Add Patient Wizard (Docs) | 3-step wizard, form state, providers |
| Navigation & Routing | Main navigation, drawer, routing |
| App Theme & Styling | Dark/light themes, scroll behavior, transitions |
| Authentication UI | Login page, glass fields, Google/GitHub OAuth buttons |
| Medical Documents Backend | Spring Boot OCR controller, drug master, lab reference |
| Medical Vision Screen | Document upload UI, confidence badges, lab results |
| Add Patient State Management | AddPatientNotifier, Riverpod providers |
| JWT Auth & Security | JwtUtil, SecurityConfig, HerokuDataSourceConfig |
| Gemini AI Integration | Python Gemini service, prompt loading, retry logic |
| OCR Service Core | PaddleOCR service, image preprocessor, parser |

### Known issues flagged by graph

- **macOS icons + PWA icons still use Flutter default "F" placeholder** — not yet branded
- **852 weakly-connected nodes** — backend DTOs have few edges to Flutter models (missing cross-layer connections)
- `Offline Data Sync Layer` (cohesion=0.02) is a grab-bag — candidate for splitting

## Keeping the graph up to date

The git **post-commit hook** auto-rebuilds the graph for code-only changes (no LLM needed, runs in background after every commit).

For doc/image changes, run manually:
```
/graphify d:\Flutter_Projects\AshaSathi --update
```

For a full rebuild from scratch:
```
/graphify d:\Flutter_Projects\AshaSathi
```

## Project overview

AshaSathi is a Flutter healthcare companion app (Riverpod + SQLite offline-first) with:
- **Frontend**: Flutter/Dart (`frontend/lib/`)
- **Backend**: Spring Boot Java (`Backend/src/`)
- **OCR Service**: Python FastAPI + PaddleOCR + Gemini AI (`ocr-service/`)
