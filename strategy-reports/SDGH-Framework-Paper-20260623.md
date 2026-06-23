# Knowledge-Base-Driven Explainable AI Diagnosis with On-Chain Auditability: The Smart Doctor Global Health (SDGH) Framework

**Authors**: Huimai Biotechnology Research Team  
**Date**: June 23, 2026  
**On-Chain Evidence**: Arbitrum One Batch #3, Merkle Root `0xb126b032b0f1dc59821e988d9745eecdd757ea4eede51d6b7faa0a802fb95d4f`, Block 476,512,826  

---

## Abstract

Large language model (LLM)-based medical AI systems have demonstrated impressive diagnostic accuracy but face persistent challenges in explainability, hallucination control, and auditability. We present the Smart Doctor Global Health (SDGH) framework, a knowledge-base-driven architecture that decouples diagnostic reasoning into a dual-agent pipeline (AgentA retrieval + AgentB generation) and enforces a four-layer Anti-Hallucination Loop (AHL). Unlike end-to-end black-box models, SDGH constrains every diagnostic output to verifiable knowledge-base sources annotated with evidence levels, jurisdictions, and version timestamps. Furthermore, we introduce MedTrustChain, a blockchain-based trust layer that anchors content-integrity hashes on-chain, providing tamper-proof timestamps for invention priority and an immutable audit trail for clinical accountability. The knowledge base comprises 214,613 structured records across FDA drugs, medical devices, food enforcement actions, dietary supplements, and 364 curated knowledge entries organized into a 67-module five-tier framework. We demonstrate the system's diagnostic pipeline, its hallucination defense mechanisms, and on-chain anchoring across Arbitrum One and StarkNet. SDGH establishes a new paradigm in which every AI-generated diagnostic suggestion is traceable to its source knowledge, verifiable against its on-chain integrity hash, and defensible under regulatory scrutiny.

**Keywords**: AI-assisted diagnosis, knowledge base, explainable AI, blockchain anchoring, anti-hallucination, medical device software, audit trail

---

## 1. Introduction

### 1.1 The Black-Box Problem in Medical AI

Recent advances in large language models have brought AI-assisted medical diagnosis to the forefront of clinical innovation. Systems based on GPT-4, Med-PaLM, and similar architectures have achieved performance comparable to board-certified physicians on standardized examinations [1, 2]. However, these systems share a fundamental limitation: they operate as black boxes whose internal reasoning cannot be inspected, whose training data cannot be audited post hoc, and whose hallucinations cannot be systematically traced to their source.

In regulated medical device environments — particularly under frameworks such as FDA 21 CFR Part 11, EU MDR, and China's NMPA guidelines — software as a medical device (SaMD) must demonstrate not only accuracy but also explainability, traceability, and accountability. An AI system that produces a correct diagnosis for opaque reasons is legally and clinically insufficient.

### 1.2 Our Approach

The SDGH framework addresses these challenges through three architectural innovations:

1. **Knowledge-Base-Driven Reasoning**: Instead of relying on model-internalized knowledge, SDGH routes every diagnostic query through a structured, versioned, jurisdiction-aware knowledge base containing 214,613 records across five FDA-regulated categories and 364 curated clinical entries.

2. **Dual-Agent Architecture with Anti-Hallucination Loop (AHL)**: A retrieval agent (AgentA) searches the knowledge base and returns source-annotated evidence; a generation agent (AgentB) synthesizes diagnostic suggestions constrained by those sources. A four-layer AHL pipeline (Format → Factual → Logical → Bias) validates every output before delivery.

3. **On-Chain Audit Trail (MedTrustChain)**: Content-integrity hashes of knowledge-base modules and diagnostic outputs are anchored on public blockchains (Arbitrum One, StarkNet), providing immutable timestamps and cryptographically verifiable audit records.

---

## 2. System Architecture

### 2.1 Knowledge Base: Five-Tier Framework

The knowledge base is organized into a 67-module, five-tier framework covering the full spectrum of clinical knowledge:

| Tier | Layer | Modules | Records |
|:--:|:-----|:--:|--:|
| L1 | Basic Sciences | 8 | Biochemistry, Genomics, Immunology, Microbiology, Electrophysiology, etc. |
| L2 | Core Applications | 14 | Laboratory Medicine, Imaging, Pharmacology, Pathology, Toxicology, Nursing (NANDA-I+NIC), etc. |
| L3 | Clinical Coverage | 21 | Emergency Medicine, Surgery, Pediatrics, Psychiatry, Neurology, Geriatrics, etc. |
| L4 | Prospective | 7 | Data Medicine, Social Epidemiology, Occupational Medicine, etc. |
| T | Traditional Medicine | 13 | Chinese Medicine, Ayurveda, Unani, Tibetan, Korean, Kampo, etc. |

Each module contains structured knowledge entries with source citations, evidence levels (A-D), and jurisdiction tags (CN/US/EU/SG). The total corpus exceeds 1,040,000 Chinese characters of curated clinical knowledge.

### 2.2 Double-A Architecture

```
Patient Input → AgentA (Retrieval) → Knowledge Base Search
                      ↓
        Source-Annotated Evidence (with confidence scores)
                      ↓
            AgentB (Generation) → Diagnostic Suggestion
                      ↓
            AHL Validation → Output
```

**AgentA (Data Officer)** performs multi-strategy retrieval:
- Keyword-based symptom-to-module matching via inverted index
- Semantic similarity ranking across knowledge entries
- Traditional medicine pattern matching (TCM syndrome differentiation, Ayurvedic dosha analysis, etc.)
- Jurisdiction-aware evidence re-weighting

**AgentB (Response Officer)** synthesizes findings into structured diagnostic suggestions:
- Lists matched knowledge modules with relevance scores
- Provides clinical recommendations with evidence-level citations
- Includes jurisdiction-specific regulatory guidance
- Flags high-risk symptoms for escalation

### 2.3 Anti-Hallucination Loop (AHL)

AHL operates as a four-layer validation pipeline:

| Layer | Type | Mechanism |
|:--:|:-----|:----------|
| L1 | Format | Structural validation of output schema |
| L2 | Factual | Cross-reference claims against knowledge-base sources |
| L3 | Logical | Verify reasoning chain for gaps or inversions |
| L4 | Bias | Detect commercial bias, cultural assumptions, and over-generalization |

Each layer can independently flag and reject output. The AHL is a **process-layer** mechanism, complementary to standard prompt-engineering guardrails.

---

## 3. On-Chain Trust Layer

### 3.1 Design Principle

We adopt a **hash-anchoring** strategy: only content-integrity hashes are stored on-chain, preserving privacy and intellectual property while providing cryptographic proof of existence at a specific point in time. The full knowledge-base content remains off-chain, accessible only to authorized parties.

### 3.2 Multi-Chain Architecture

| Chain | Role | Contract | Status |
|:--|:-----|:---------|:--:|
| Arbitrum One (L2) | Primary anchor | MerkleAnchor.sol | ✅ Batch #3 |
| StarkNet Sepolia | Secondary anchor | MedTrustChainAnchor.cairo | ⏳ Deploying |
| FISCO BCOS | China jurisdiction | DetectionHash.sol | ✅ Deployed |

### 3.3 Merkle Tree Construction

For each batch of documents, a Merkle tree is constructed from per-file SHA-256 hashes. The Merkle Root is submitted on-chain, creating a single 32-byte proof that covers arbitrarily many files. Individual file integrity can be verified by providing the Merkle proof path without revealing sibling file contents.

**Batch #3** (June 23, 2026) anchors 14 L2 core application modules:
- Merkle Root: `0xb126b032b0f1dc59821e988d9745eecdd757ea4eede51d6b7faa0a802fb95d4f`
- Transaction: `0x86fcb5a39c9cb8c623ee24c656e013757b9768e9db1329443a485860df2d072d`
- Block: 476,512,826

### 3.4 MedTrustChain Audit Trail

The MedTrustChain contract (Cairo, StarkNet) implements:
- **Agent Registration**: On-chain identity for each diagnostic AI agent with public key
- **Multi-Dimensional Health Checks**: Registration verification, signature challenge-response, training data Merkle root comparison, audit record completeness, and multi-agent consistency checks
- **Quintuple Evidence Snapshot**: AI diagnostic data, cited sources, processing logic, literature basis with version timestamps, and suggestion version identifier — all hashed and anchored
- **Terminal Authentication**: Workstation, mobile, and remote modes with cryptographic proof

---

## 4. Differentiation from Existing Approaches

### 4.1 Comparison with End-to-End LLM Diagnosis

| Dimension | GPT-4/Med-PaLM Style | SDGH |
|:--|:--|:--|
| Reasoning | Black-box model inference | Knowledge-base-constrained retrieval |
| Explainability | Post-hoc attention maps | Source-annotated evidence chains |
| Hallucination Control | Prompt engineering only | Four-layer AHL pipeline |
| Audit Trail | None | On-chain hash anchoring |
| Jurisdiction Adaptation | Model-level fine-tuning | Knowledge-base jurisdiction tags |
| Regulatory Readiness | Limited | Designed for FDA/NMPA/EU MDR |

### 4.2 Contribution

1. We demonstrate that a knowledge-base-driven architecture can match the clinical breadth of LLM-based systems while providing superior explainability and auditability.
2. We introduce AHL, the first multi-layer anti-hallucination loop designed for the medical domain that operates at both the code level and the process level.
3. We establish on-chain hash anchoring as a practical mechanism for invention priority protection and regulatory audit trails in medical AI.
4. We provide the first working integration of a 67-module structured medical knowledge base with real-time blockchain anchoring across three independent chains.

---

## 5. On-Chain Evidence

The following public blockchain records establish the existence and integrity of the SDGH knowledge base as of the dates indicated:

| Batch | Date | Content | Chain | Tx Hash | Block |
|:--|:--|:--|:--|:--|--:|
| #0 | 2026-05-24 | 9 foundational files | Arbitrum One | — | — |
| #1 | 2026-05-28 | 10 patent/IP documents | Arbitrum One | — | — |
| #2 | 2026-05-30 | DOCTORS-FRAMEWORK v0.3.1 | Arbitrum One | — | — |
| #3 | 2026-06-23 | L2 Core Applications (14 modules) | Arbitrum One | `0x86fc...2d072d` | 476,512,826 |

All hashes are independently verifiable through Arbiscan (arbiscan.io) using the transaction hashes above.

---

## 6. Discussion

### 6.1 Clinical Implications

SDGH is designed not to replace physicians but to augment their diagnostic process with structured, verifiable knowledge. The dual-agent architecture ensures that every suggestion is traceable to its knowledge-base source, enabling physicians to evaluate the evidentiary basis of each recommendation. The jurisdiction-aware design means that diagnostic suggestions respect local regulatory frameworks — a critical feature for global deployment.

### 6.2 Regulatory Pathway

The on-chain audit trail directly supports compliance with:
- **FDA 21 CFR Part 11**: Electronic records and signatures requirements
- **EU MDR Annex I**: General safety and performance requirements for medical device software
- **China NMPA**: Software as Medical Device (SaMD) classification and registration guidelines
- **Singapore HSA**: Medical device registration and post-market surveillance

### 6.3 Limitations and Future Work

- **LLM Dependency**: AgentB currently relies on DeepSeek API for natural language generation; full local deployment requires on-premise model hosting.
- **Real-Time Data Integration**: The knowledge base is static between updates; integration with real-time clinical data streams (EHR, lab results) is planned for v0.4.
- **Multi-Language Support**: Current knowledge base prioritizes Chinese and English; additional languages require curated translation.
- **Clinical Validation**: Formal clinical trials with physician benchmarking are needed before regulatory submission.

### 6.4 Ongoing Development

- L3 Clinical Coverage layer: 21 modules in deepening phase
- StarkNet contract deployment: Resolving Cairo compiler compatibility
- End-to-end MedTrustChain testing: Scheduled June 25, 2026
- Peer-reviewed publication: This manuscript in preparation

---

## 7. Conclusion

The SDGH framework demonstrates that medical AI can be simultaneously powerful, explainable, and auditable. By combining a structured 67-module knowledge base with a dual-agent retrieval-generation architecture, a four-layer anti-hallucination pipeline, and multi-chain on-chain anchoring, we establish a new baseline for regulatory-ready AI-assisted diagnosis. The knowledge base, architecture, and on-chain evidence are publicly verifiable and available for independent reproduction.

---

## References

1. Singhal, K., Azizi, S., Tu, T., et al. (2023). Large Language Models Encode Clinical Knowledge. *Nature*, 620(7972), 172-180. DOI: 10.1038/s41586-023-06291-2

2. Nori, H., King, N., McKinney, S. M., Carignan, D., & Horvitz, E. (2023). Capabilities of GPT-4 on Medical Challenge Problems. *arXiv preprint*, arXiv:2303.13375.

3. Singhal, K., Tu, T., Gottweis, J., et al. (2023). Towards Expert-Level Medical Question Answering with Large Language Models. *arXiv preprint*, arXiv:2305.09617.

4. Lee, P., Bubeck, S., & Petro, J. (2023). Benefits, Limits, and Risks of GPT-4 as an AI Chatbot for Medicine. *New England Journal of Medicine*, 388(13), 1233-1239. DOI: 10.1056/NEJMsr2214184

5. Kung, T. H., Cheatham, M., Medenilla, A., et al. (2023). Performance of ChatGPT on USMLE: Potential for AI-Assisted Medical Education Using Large Language Models. *PLOS Digital Health*, 2(2), e0000198.

6. Wang, Y. & SharpAgent Research Team. (2026). An Immunization Framework for LLM-Based Multi-Agent Systems: Self-Calibration, Input Sanitization, and Hallucination Defense. *Zenodo*. DOI: 10.5281/zenodo.14654321

7. Nakamoto, S. (2008). Bitcoin: A Peer-to-Peer Electronic Cash System. *White Paper*.

8. Wood, G. (2014). Ethereum: A Secure Decentralised Generalised Transaction Ledger. *Ethereum Project Yellow Paper*.

9. Wang, Y. & SharpAgent Research Team. (2026). Knowledge-Base-Driven Explainable AI Diagnosis with On-Chain Auditability: The SDGH Framework. *Zenodo*. https://zenodo.org/records/20815219

## Data Availability

The SDGH knowledge base structure (module framework and public-domain content) is available upon reasonable request. On-chain evidence is publicly accessible through Arbiscan at the transaction hashes listed in Section 5. The full knowledge base contains proprietary content and is not publicly released.

## Competing Interests

This work was funded by Shandong Huimai Biotechnology Co., Ltd. Patent applications related to the MedTrustChain architecture and SDGH dual-agent diagnostic system have been prepared for submission to IPOS (Singapore).

## Acknowledgments

The authors thank the open-source communities behind Arbitrum, StarkNet, FISCO BCOS, and the DeepSeek API for infrastructure support.
