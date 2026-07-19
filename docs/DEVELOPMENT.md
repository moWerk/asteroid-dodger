# Development disclosure

This app is developed LLM-aided under full disclosure, in the same
open-governance spirit as
[asteroid-docking-bay](https://github.com/moWerk/asteroid-docking-bay).

- Origin: moWerk's first vibe-coded app (2025, chat-assistant era, full
  human review of every pasted change). Ported to Qt6 and OOP-refactored
  2026 with Claude as coding agent under moWerk's maintainer review.
- Commits carry `Co-Authored-By` trailers naming the model. Refactor
  commits are single-concern with behavior-preservation statements.
- Verification: no automated UI test suite exists for AsteroidOS QML
  apps; changes are verified by cross-compilation against the Qt6
  sysroot plus on-watch smoke testing (sideload loop), with results
  recorded in PR descriptions.
- Human ownership: moWerk reviews at architecture level (ARCHITECTURE.md
  is updated in the same commit as any structural change) and gameplay
  level (plays every build); line-level diffs are single-concern and
  auditable on demand.
