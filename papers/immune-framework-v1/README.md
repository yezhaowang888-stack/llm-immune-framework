# Immune System for LLMs: A Five-Anchor Audit Framework with On-Chain Audit Trail

**A defense-in-depth architecture against hallucination, data poisoning, and cognitive colonization in large language models.**

[![Version](https://img.shields.io/badge/version-v1.8-blue)](../../releases/tag/v1.8)
[![PDF](https://img.shields.io/badge/PDF-download-red)](./paper.pdf)
[![License](https://img.shields.io/badge/license-MIT-green)](../../)

---

## TL;DR

LLMs hallucinate. Existing solutions treat symptoms (RLHF suppresses, RAG fills gaps, voting averages noise).  
We designed an **immune system**: multi-layer detection → cross-anchor audit → on-chain trail → failure memory that learns.

Imagine your LLM caught itself hallucinating — and you can prove it on-chain.

---

## Core Contributions

### 1. Five-Anchor Audit Framework (§4–5)
Five independent dimensions cross-verify LLM outputs:
- **Source Anchor** — Chain of custody. Where did this come from?
- **Logic Anchor** — Internal consistency. Does it survive adversarial examination?
- **Interest Anchor** — Incentive mapping. Who benefits if this is accepted as true?
- **Compliance Anchor** — Standards alignment. Conditional, not binary.
- **Cross Anchor** — Multi-source triangulation. Prevents single-tribunal errors.

### 2. Four-Tier Detection Chain (§3)
```
L1: Basic Fact Matching
L2: Semantic Consistency
L3: Logical Closure
L4: Statistical Bias Detection
L5: Causal Attribution Audit (with incentive traceback)
L6: Counter-Cognitive-Colonization Audit
```
Each tier catches what the previous one misses. L5→L6 addresses *invisible* hallucinations — outputs structurally sound but causally wrong.

### 3. Information Completeness Hypothesis (§6 — New)
We formalize a counter-intuitive prediction: **stronger models produce more attribution hallucination in info-gap scenarios**. 
When critical information is missing, powerful inference engines fill gaps with "plausible" bridges faster — making hallucinations more confident and less detectable.

**Solution**: Dual-Perspective Attribution Correction — progressive gap exposure + incentive chain traceback + Self-Interest Prior convergence.

### 4. On-Chain Audit Trail (§7)
Every audit verdict hashed to chain via MedTrustChain + AuditChain. Immutable, verifiable, trustless.

### 5. Failure Memory Layer (FML) (§8)
History-informed pre-triggering. When a new input matches stored failure patterns, the immune system activates *before* hallucination occurs.

---

## Paper Structure

| § | Title | Core Idea |
|:--|:--|:--|
| 1 | Introduction | The immune system metaphor |
| 2 | Conceptual Architecture | Cognitive sphere & layered defense |
| 3 | Threat Taxonomy | External poison → internal hallucination |
| 4 | Detection Chain | L1→L6 multi-tier detection |
| 5 | Audit Framework | Five anchors with cross-validation |
| 6 | Information Completeness | Info-gap → attribution hallucination + correction |
| 7 | False Positive Remediation | Calibration, not suppression |
| 8 | Defense Architecture | D1→D6 three-line defense |
| 9 | Unverifiable Content | Lifecycle management |
| 10 | Discussion | Limitations & future work |
| 11 | Conclusion | Immune system for AI |

---

## Citation

```bibtex
@article{huimai2026immune,
  title   = {Immune System for LLMs: A Five-Anchor Audit Framework with On-Chain Audit Trail},
  author  = {Wang, Yezhao and Duan, Wei and Sharp Agent Team},
  journal = {GitHub Preprint},
  year    = {2026},
  note    = {v1.8, available at \url{https://github.com/yezhaowang888-stack/llm-immune-framework}}
}
```

---

## Authors

**王业朝及惠迈智能体团队 (Sharp Agent Team)**

- 王业朝 (Yezhao Wang) — 项目负责人 & 架构设计
- Sharp Agent Team — 技术协调 / 数据工程 / 基础设施

Correspondence: yezhaowang@163.com

---

*Built with Tectonic. Zero compilation errors. Three-pass cross-reference convergence.*
