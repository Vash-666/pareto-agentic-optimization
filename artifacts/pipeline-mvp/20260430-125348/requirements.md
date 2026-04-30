# Requirements Document — Agentic AI Project Pipeline MVP

## Functional Requirements
1. FR-001: System shall execute 12 tasks across 4 phases
2. FR-002: Each task shall pass a quality gate before next task begins
3. FR-003: System shall support 3-agent coordination (Switch, QualityGuardian, Content)
4. FR-004: Each phase shall produce output artifacts in markdown format

## Non-Functional Requirements
5. NFR-001: Quality gates shall enforce thresholds (70-90%)
6. NFR-002: Pipeline shall complete within 4 days
7. NFR-003: All artifacts shall be git-versioned

## Constraints
8. C-001: macOS/bash environment
9. C-002: No external cloud dependencies
10. C-003: File-based state management (JSON)
