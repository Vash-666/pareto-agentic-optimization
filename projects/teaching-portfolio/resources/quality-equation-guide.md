# Quality Equation Reference Guide

**Purpose:** Detailed reference for the deterministic quality scoring system.
**Related:** `02-quality-equation.md`, `topics/quality-assurance.md`

---

## 1. Formula

```
Quality = (Prompt Files × 0.65) + (Memory × 0.20) + (Model × 0.10) + (Tools × 0.05)
```

Each component is scored from 0.0 to 1.0, then multiplied by its weight. The final score is 0.0-1.0, displayed as a percentage (0-100).

### Example Calculation

| Component | Raw Score | Weight | Weighted Score |
|---|---|---|---|
| Prompt Files | 0.85 | × 0.65 | 0.5525 |
| Memory | 0.80 | × 0.20 | 0.1600 |
| Model | 0.90 | × 0.10 | 0.0900 |
| Tools | 0.75 | × 0.05 | 0.0375 |
| **Total** | | | **0.8400 (84/100)** |

---

## 2. Component Weights

### Why These Weights?

| Component | Weight | Rationale |
|---|---|---|
| Prompt Files | 0.65 | Prompt quality is the single largest determinant of LLM output quality. A great prompt with an average model outperforms a bad prompt with the best model 90% of the time. |
| Memory | 0.20 | Context and continuity determine whether outputs are consistent and grounded. Without memory, each task starts from zero. |
| Model | 0.10 | Model capability matters, but differences between capable models are small compared to prompt and context quality. |
| Tools | 0.05 | Tools amplify capability but depend on correct usage. This weight encourages adoption while recognizing that tools are an accelerator, not a foundation. |

Weights were empirically validated by:
1. Generating 100 outputs with varying prompt quality, keeping model constant
2. Generating 100 outputs with varying model quality, keeping prompt constant
3. Comparing the variance in output quality between the two groups
4. Setting weights proportional to measured impact on output quality

---

## 3. Scoring Methodology

### Prompt Files Scoring (0.0 - 1.0)

Evaluated on four sub-criteria, equally weighted (0.25 each):

**Structure (0.25):**
- Are prompt files well-organized with clear sections?
- Do they use consistent formatting (headings, lists, code blocks)?
- Are there template variables or parameters?

**Completeness (0.25):**
- Do prompts cover all required sections for the task type?
- Are there examples or few-shot demonstrations?
- Are edge cases addressed?

**Clarity (0.25):**
- Are instructions unambiguous?
- Are there duplicate or contradictory instructions?
- Would a new reader understand the prompt without additional context?

**Reusability (0.25):**
- Are prompts parameterized for multiple uses?
- Are there variables for inputs, outputs, or configuration?
- Can the prompt be reused for similar tasks without modification?

**Scoring method:** Each sub-criterion is scored 0.0-1.0 by comparing against a reference corpus of known-good prompts using cosine similarity (see Section 4). The four scores are averaged.

### Memory Scoring (0.0 - 1.0)

Evaluated on three sub-criteria:

**Coverage (0.40):**
- Do memory files capture all relevant context for the current task?
- Are there gaps in context that force the model to guess?

**Currency (0.35):**
- When were memory entries last updated?
- Do entries reflect the current state or an outdated one?

**Structure (0.25):**
- Are memory entries organized for fast retrieval?
- Do they use consistent formatting (key-value pairs, timestamps)?

### Model Scoring (0.0 - 1.0)

Evaluated on three sub-criteria:

**Task-Appropriate (0.40):**
- Is the model capable enough for the task's complexity?
- For high-reasoning tasks: Claude Sonnet, GPT-4, or equivalent
- For simple tasks: DeepSeek, Mixtral, or equivalent

**Cost Efficiency (0.35):**
- Is the model the cheapest option that can handle the task?
- Each model has a "cost tier" score: cheapest capable = 1.0, most expensive capable = 0.5

**Reliability (0.25):**
- What is the model's documented error/refusal rate on similar tasks?
- Models with >5% error rate on the task type are downgraded

### Tools Scoring (0.0 - 1.0)

Evaluated on three sub-criteria:

**Adoption (0.40):**
- What percentage of available tools are being used?
- If 4 of 8 tools are used, adoption = 0.50

**Correctness (0.35):**
- Are tools used according to their documented behavior?
- Are there cases of tools being called with wrong arguments?

**Efficiency (0.25):**
- Are tools reducing manual work as intended?
- Is the tool usage proportional to the task complexity?

---

## 4. Similarity Scoring (Cosine)

Cosine similarity measures how close an output is to known-good examples.

### Implementation

1. **Reference corpus:** A curated set of 50+ known-high-quality outputs (scored ≥85/100 by human experts)
2. **Embedding model:** `all-MiniLM-L6-v2` (384-dimensional vectors, fast, reasonable quality)
3. **Vector store:** ChromaDB for persistence and similarity search
4. **Query process:**
   - Embed the candidate output
   - Search the reference corpus for the top-5 most similar vectors
   - Score = average cosine similarity of top-5 results

### Scoring Details

- **1.0:** Output is identical or nearly identical to a known-high-quality reference
- **0.8-0.99:** Output follows the same structure and quality patterns as references
- **0.6-0.79:** Output is on-topic but has structural or quality differences
- **0.4-0.59:** Output is tangentially related but has significant quality gaps
- **<0.4:** Output is not comparable to known-quality references

### Limitations

- Cosine similarity measures structure and topic alignment, not factual accuracy
- Factual accuracy must be verified through separate mechanisms (tool validation, human review)
- New types of high-quality content may score lower initially until added to the reference corpus

---

## 5. Optimization Priorities

Based on the weight distribution, optimize in this order:

### 1. Improve Prompt Files (highest impact per point)
- Add structure with clear sections
- Include examples for every instruction type
- Use template variables for parameters
- Remove ambiguity and contradictions
- Reference: +0.65 per 1.0 improvement in raw score

### 2. Improve Memory Quality
- Ensure all task-relevant context is captured
- Update memory entries after every task completion
- Structure entries with clear key-value pairs
- Reference: +0.20 per 1.0 improvement in raw score

### 3. Upgrade Model Selection
- Route complex reasoning tasks to high-capability models
- Route simple tasks to cost-effective models
- Don't overpay for model capability you don't need
- Reference: +0.10 per 1.0 improvement in raw score

### 4. Adopt Tools Correctly
- Integrate available tools into workflows
- Ensure tools are called with correct parameters
- Use tools consistently, not occasionally
- Reference: +0.05 per 1.0 improvement in raw score

---

## 6. Verification Protocol

To independently verify a quality score:

1. Clone the repository and navigate to the project directory
2. Run the scoring tool: `bash tools/quality-gate.sh <project-id> <milestone>`
3. The tool reads the project context and computes the score
4. The score will match the recorded score because the computation is deterministic
5. If the scores do not match, the context store or scoring logic has been modified — investigate

**This is the core guarantee:** The same inputs always produce the same score. No subjectivity. No drift. No excuses.
