# Quality Assurance — Topic Outline

**Status:** Outline
**Prerequisites:** Familiarity with automated testing concepts
**Related scripts:** `02-quality-equation.md`, `04-pipeline-orchestration.md`
**Related guide:** `resources/quality-equation-guide.md`

---

## 1. The Quality Equation

- **Formula:** Quality = (Prompt Files × 0.65) + (Memory × 0.20) + (Model × 0.10) + (Tools × 0.05)
- **Why weighted:** Not all components contribute equally to output quality. Prompt quality dominates because bad prompts produce bad outputs regardless of model strength.
- **Deterministic:** Same inputs always produce the same score. Zero subjectivity, zero ambiguity.
- **Reproducible:** Any team member can independently run the scoring and verify the result.

**Key insight:** The equation is deliberately simple. Complex scoring systems are harder to audit and more likely to have hidden biases.

---

## 2. Vector Similarity Scoring

- Use cosine similarity between generated output and reference corpus
- Implementation: ChromaDB + sentence-transformers (all-MiniLM-L6-v2)
- Process:
  1. Embed the output into a vector
  2. Compare against vectors in the reference corpus
  3. Score = average cosine similarity across top-K matches
- Score range: 0.0 (no similarity) to 1.0 (identical to reference)
- Benefits: Language-agnostic, catches structural and semantic issues

---

## 3. Independent Verification

- **Separation of concerns:** The agent that produces output must not be the agent that scores it
- **Implementation:** QualityGuardian runs as a separate process with read-only access to outputs
- **Verification protocol:**
  1. Producing agent writes output to filesystem
  2. QualityGuardian reads output independently
  3. QualityGuardian computes score using Quality Equation
  4. Score is written to context store
  5. Pipeline checks score against threshold before proceeding

**Anti-pattern:** Embedding quality checks inside the producing agent's prompt. This creates a conflict of interest — the agent is scoring its own work.

---

## 4. Gate Thresholds

- **Start (60/100):** Structure exists, all required files present, no showstoppers
- **Review (75/100):** Content is accurate, readable, formatted correctly, recruiter-ready
- **Complete (85/100):** Publication quality, independently verified, all metrics documented
- **Production (90/100):** Enterprise-ready, audited by independent process, stress-tested

**Enforcement:**
- `quality-gate.sh` checks score against threshold
- Pipeline blocks on gate failure
- Blocker report generated with specific gaps

---

## 5. Case Studies

### Case Study 1: Execution Theatre
- System claimed 9.2/10 output quality with zero verification
- Quality Equation returned 6.1/10 — found incomplete sections and factual errors
- Audit confirmed the deterministic score was correct
- **Lesson:** Always verify, never trust subjective claims

### Case Study 2: Model Switching Quality Impact
- After implementing context preservation protocol (Tier 1-3)
- Quality scores improved from 6.7 to 8.4 average (25% improvement)
- **Lesson:** Infrastructure quality (context transfer) directly impacts output quality

### Case Study 3: Independent Auditor vs Self-Review
- Outputs reviewed by the producing agent scored average 8.9/10
- Same outputs reviewed by QualityGuardian scored average 7.2/10
- Independent review found 3× more issues
- **Lesson:** Never let the writer be the reviewer

---

## 6. Optimization Priorities

From highest to lowest impact on quality score:

1. **Improve prompt files** (+0.65 per 1.0 improvement) — Write better prompts, add structure, include examples
2. **Improve memory quality** (+0.20 per 1.0 improvement) — Better context preservation, structured memory entries
3. **Upgrade model selection** (+0.10 per 1.0 improvement) — Route complex tasks to stronger models
4. **Adopt tools** (+0.05 per 1.0 improvement) — Use available tools correctly and consistently

**Practical guidance:** Focus 65% of quality improvement effort on prompt engineering. It is the single highest-leverage activity.

---

## 7. Further Reading

- `02-quality-equation.md` — Full script with results
- `resources/quality-equation-guide.md` — Detailed scoring methodology
- `03-agent-architecture.md` — QualityGuardian agent role
