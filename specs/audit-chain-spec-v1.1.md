# 信证链（TrustChain）：审核签名 + 链上存证 — 规格文档

> **品牌名：信证链（TrustChain）**  
> 版本：v1.0  
> 作者：cn002（惠迈香港工程师）  
> 日期：2026-05-26  
> 上层产品：「全球医生」智能诊疗系统  
> 定位：医疗AI可信基础设施 — 校准、存证、审计  
> 设计原则：不可篡改 > 可追溯 > 可验证 > 可用性

---

## 目录

1. [五元组 → 审核记录数据结构映射](#1-五元组--审核记录数据结构映射)
2. [审核人签名方案](#2-审核人签名方案)
3. [FISCO BCOS存证对接](#3-fisco-bcos存证对接)
4. [审核界面原型描述](#4-审核界面原型描述)
5. [中美双法规合规映射](#5-中美双法规合规映射)
6. [实施路径](#6-实施路径)
7. [部署要求](#7-部署要求)
8. [跨院区扩展性设计](#8-跨院区扩展性设计)
9. [附录](#9-附录)

---

## 1. 五元组 → 审核记录数据结构映射

### 1.1 五元组在医疗场景中的语义定义

原始五元组（从「毒数据防御体系」借鉴而来）映射到「全球医生」智能诊疗场景：

| 五元组编号 | 原定义 | 医疗场景语义 |
|-----------|--------|------------|
| 元组① | AI建议摘要 | AI诊断建议 + 置信度 + 推断路径 |
| 元组② | 数据源 | 循证文献(PMID/DOI) / 传统医籍(书名+章节) / 临床指南 / 知识库条目 |
| 元组③ | 处理逻辑 | AI推理链路（模型版本 + Prompt版本 + 推理步骤摘要） |
| 元组④ | 文献依据 | 原文引用文本 + 被引文献的版本时间戳 |
| 元组⑤ | 版本号 | 本条建议的语义版本号（semver） |

五元组的JSON表示即为 **证据链快照**（存入审核记录的 `evidence_snapshot` 字段）。

### 1.2 审核记录数据结构（AuditRecord）

```json
{
  "audit_id": "AUD-20260526-001-abc123",
  "suggestion_id": "SUG-20260526-001-xyz789",
  
  "quintuple": {
    "ai_suggestion": {
      "diagnosis": "急性上呼吸道感染（风寒证）",
      "confidence": 0.87,
      "reasoning_path": "症状→辨证→方剂匹配→禁忌核查",
      "model_version": "deepseek-v4-pro",
      "prompt_version": "dx-v2.3.1",
      "generated_at": "2026-05-26T08:30:00Z"
    },
    "data_sources": [
      {
        "source_type": "evidence_literature",
        "source_id": "PMID:34567890",
        "title": "Evidence-based management of acute upper respiratory infection",
        "citation_format": "AMA"
      },
      {
        "source_type": "traditional_medicine",
        "source_id": "伤寒论·辨太阳病脉证并治·第12条",
        "title": "桂枝汤证",
        "citation_format": "classic_text"
      }
    ],
    "processing_logic": {
      "pipeline": "SymptomExtraction → PatternDifferentiation → FormulaMatching → ContraindicationCheck",
      "models_used": ["deepseek-v4-pro", "huimai-knowledge-graph-v1"],
      "rag_chunks_retrieved": 12,
      "similarity_threshold": 0.75
    },
    "literature_basis": [
      {
        "citation": "Smith J et al. "Clinical outcomes of ..." N Engl J Med. 2024;390(5):456-467.",
        "excerpt": "In a randomized controlled trial of 2,134 patients, treatment with ... showed significant improvement (p<0.01) ...",
        "version_timestamp": "2024-02-15T00:00:00Z",
        "evidence_level": "Level I (RCT)"
      },
      {
        "citation": "张仲景. 伤寒论·辨太阳病脉证并治. 公元200-210年.",
        "excerpt": "太阳中风，阳浮而阴弱，阳浮者热自发，阴弱者汗自出……桂枝汤主之。",
        "version_timestamp": "200-01-01T00:00:00Z",
        "evidence_level": "Classic Canon"
      }
    ],
    "suggestion_version": "1.0.0"
  },
  
  "evidence_snapshot_hash": "SHA256(上述五元组JSON的规范序列化)",
  
  "auditor": {
    "auditor_id": "MD-2023-0042",
    "auditor_name": "张明",
    "role": "主治医师",
    "license_no": "202311010421",
    "auth_method": "2FA-SMS-OK"
  },
  
  "audit_timestamp": "2026-05-26T09:15:00.000Z",
  
  "audit_conclusion": "approved",
  
  "audit_comment": "诊断逻辑清晰，方剂选择合理。建议在备注中注明患者桂枝汤使用禁忌已在辨证环节中排除。",
  
  "revision_request": null,
  
  "digital_signature": {
    "phase": "phase1_platform_log",
    "algorithm": "SHA256",
    "signature_content": "SHA256(audit_id + suggestion_id + evidence_snapshot_hash + auditor_id + audit_conclusion + audit_timestamp + nonce)",
    "nonce": "随机16字节十六进制字符串"
  }
}
```

### 1.3 数据库存储设计（链下关系型数据库）

```sql
CREATE TABLE audit_records (
    -- 主键
    audit_id VARCHAR(64) NOT NULL PRIMARY KEY COMMENT 'AUD-YYYYMMDD-序号-随机码',
    
    -- 关联
    suggestion_id VARCHAR(64) NOT NULL COMMENT '关联的AI建议ID',
    
    -- 五元组快照（完整JSON）
    evidence_snapshot JSON NOT NULL COMMENT 'AI建议生成时的完整五元组JSON',
    evidence_snapshot_hash CHAR(64) NOT NULL COMMENT 'SHA256(evidence_snapshot规范序列化)',
    
    -- 审核人信息
    auditor_id VARCHAR(32) NOT NULL,
    auditor_name VARCHAR(64) NOT NULL,
    auditor_role VARCHAR(32) NOT NULL COMMENT '主治医师/副主任医师/主任医师',
    auditor_license VARCHAR(32) NOT NULL COMMENT '执业医师编号',
    auth_method VARCHAR(32) NOT NULL COMMENT '2FA-SMS / 2FA-TOTP / PKI-CFCA',
    
    -- 审核结论
    audit_conclusion ENUM('approved','rejected','revision_needed') NOT NULL,
    audit_comment TEXT COMMENT '审核意见',
    revision_request JSON DEFAULT NULL COMMENT '修改建议: {"fields":["diagnosis"],"suggestion":"..."}',
    
    -- 时间戳
    audit_timestamp TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    
    -- 数字签名
    signature_phase ENUM('phase1_platform','phase2_pki') NOT NULL DEFAULT 'phase1_platform',
    signature_hash CHAR(64) NOT NULL COMMENT 'SHA256审核内容哈希',
    signature_pki TEXT DEFAULT NULL COMMENT 'PKI证书签名的Base64编码（第二阶段启用）',
    signature_nonce CHAR(32) NOT NULL COMMENT '随机nonce，防重放',
    
    -- 链上存证
    onchain_tx_hash VARCHAR(128) DEFAULT NULL COMMENT 'FISCO BCOS交易哈希',
    onchain_block_number BIGINT DEFAULT NULL COMMENT '存证区块号',
    onchain_timestamp TIMESTAMP(3) DEFAULT NULL COMMENT '链上确认时间',
    
    -- 操作日志
    created_at TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP(3),
    updated_at TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    
    -- 索引
    INDEX idx_suggestion (suggestion_id),
    INDEX idx_auditor (auditor_id),
    INDEX idx_conclusion (audit_conclusion),
    INDEX idx_onchain (onchain_tx_hash),
    INDEX idx_timestamp (audit_timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='审核记录 — 链下主存储';

-- 审核操作日志表（双因子认证追踪）
CREATE TABLE audit_operation_log (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    audit_id VARCHAR(64) NOT NULL,
    auditor_id VARCHAR(32) NOT NULL,
    operation VARCHAR(32) NOT NULL COMMENT 'login/2fa_verify/view_evidence/submit_audit',
    ip_address VARCHAR(45),
    user_agent VARCHAR(512),
    created_at TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP(3),
    FOREIGN KEY (audit_id) REFERENCES audit_records(audit_id),
    INDEX idx_audit_op (audit_id, created_at),
    INDEX idx_auditor_op (auditor_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='审核操作日志 — 平台留痕';
```

### 1.4 字段设计说明

| 字段 | 设计理由 |
|------|---------|
| `evidence_snapshot` (JSON) | 将五元组完整快照存入审查记录，确保审查时"所见即所有"。事后追溯不依赖外部系统状态 |
| `evidence_snapshot_hash` | JSON规范序列化后SHA256，作为Merkle树的叶子节点输入 |
| `signature_nonce` (CHARS(32)) | 防重放攻击，即使相同内容两次审核，签名哈希也不同 |
| `audit_conclusion` ENUM | 三态约束。`revision_needed` ≠ `rejected`：前者表示可以修改后重新提交，后者表示该建议永久不可用 |
| `revision_request` (JSON) | 结构化修改指令，下游AI可据此自动修正重新提交 |

---

## 2. 审核人签名方案

### 2.1 两阶段方案总览

```
第一阶段（Phase 1）         第二阶段（Phase 2）
平台留痕签名                  PKI证书签名
══════════════              ══════════════
双因子认证 (2FA)             CFCA数字证书
+                           或国际CA
操作日志全量记录             +
+                           RSA/ECDSA签名
SHA256内容哈希               +
                            证书链验证
    │                            │
    ▼                            ▼
┌─────────────────────────────────────────┐
│         都写入 audit_records.signature_hash │
│         Phase 2 额外写入 signature_pki      │
└─────────────────────────────────────────┘
```

### 2.2 Phase 1：平台留痕签名

**定位**：快速上线，满足NMPA「操作日志」基本要求，成本极低。

**技术方案**：

```
1. 审核人登录
   ├── 用户名/密码（或微信扫码）
   ├── 第二步：短信验证码（SMS 2FA） 或 TOTP（Google Authenticator）
   └── 登录成功后生成 session_token（JWT, 有效期30分钟）

2. 审核操作
   ├── 每个操作记录到 audit_operation_log
   │   (login / view_evidence / submit_audit / 2fa_renew)
   ├── 每个操作日志包含: IP、User-Agent、时间戳、操作类型
   └── 所有操作日志的 SHA256 Merkle Root 批量上链

3. 提交审核结论时
   ├── 再次验证2FA（30分钟内无需重验）
   ├── 生成签名内容:
   │   sign_content = audit_id || suggestion_id || evidence_snapshot_hash
   │                || auditor_id || audit_conclusion || timestamp || nonce
   ├── 计算 signature_hash = SHA256(sign_content)
   └── 存入 audit_records 表
```

**安全性评估**：

| 维度 | 评估 |
|------|------|
| 抗抵赖 | ⚠️ 高（平台内） — SHA256 + 链上存证 + 操作日志组合提供了很强的平台内抗抵赖。不具备法律效力的数字签名，但平台内不可否认；如需法律效力需升级至Phase 2 |
| 防篡改 | ✅ 高 — SHA256 + 链上存证，事后篡改可检测 |
| 身份验证 | ✅ 高 — 2FA + session管理 |
| 合规 | ✅ NMPA操作日志要求满足；FDA需要Phase 2 |

### 2.3 Phase 2：PKI证书签名

**定位**：具备法律效力、满足FDA 21 CFR Part 11电子签名要求。

**技术方案**：

```
签名流程:
┌─────────────────┐     ┌──────────────┐     ┌───────────────┐
│ 审核人浏览器     │ ──▶ │ 签名服务      │ ──▶ │ CA证书验证     │
│ (Web Crypto API) │     │ (后端/HSM)   │     │ (CFCA/VeriSign)│
└─────────────────┘     └──────────────┘     └───────────────┘
                              │                        │
                              ▼                        ▼
                        生成 PKCS#7          验证证书链 + CRL/OCSP
                        或 PAdES签名         检查证书是否吊销
                              │                        │
                              └────────┬───────────────┘
                                       ▼
                               签名结果存入
                               audit_records.signature_pki
```

**支持的CA机构**：

| 地区 | CA机构 | 用途 | 法律效力 |
|------|--------|------|---------|
| 中国大陆 | CFCA（中金金融认证中心） | NMPA审查 | ⚖️ 《电子签名法》认可 |
| 中国大陆 | SZCA（深圳CA） | NMPA审查 | ⚖️ 同上 |
| 国际 | DigiCert / GlobalSign | FDA / EMA | ⚖️ eIDAS / 21 CFR Part 11 |
| Web标准 | Let's Encrypt (仅TLS) | 传输层加密 | ❌ 不可用于电子签名 |

**签名格式（PKCS#7 Detached Signature）**：

```json
{
  "signature_type": "pkcs7-detached",
  "signature_algorithm": "SHA256withRSA",
  "certificate_chain": [
    "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----",
    "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----"
  ],
  "signed_attributes": {
    "content_type": "application/json",
    "signing_time": "2026-05-26T09:15:00.000Z",
    "signer_name": "张明",
    "signer_license": "202311010421"
  },
  "signature_value": "Base64编码的签名值",
  "tsa_timestamp": "Base64编码的RFC 3161时间戳令牌"
}
```

### 2.4 两阶段对比与迁移路径

| 维度 | Phase 1 平台留痕 | Phase 2 PKI签名 |
|------|-----------------|-----------------|
| **实施难度** | 低（1-2周） | 中高（4-8周 + CA采购） |
| **成本** | 几乎为零 | CA证书年费 ¥2000-5000/人 + HSM ¥5-10万 |
| **法律效力** | 平台内有效 | 法律效力（《电子签名法》/ 21 CFR Part 11） |
| **FDA合规** | ⚠️ 不满足 | ✅ 满足 Criterion 4 |
| **NMPA合规** | ✅ 操作日志可满足 | ✅ 完全满足 |
| **用户体验** | 短信验证，流畅 | 需USB Key或手机证书，稍复杂 |
| **维护成本** | 极低 | 中等（证书续期、CRL同步） |
| **适用场景** | 内部测试、低风险疾病 | 高风险处方、对外提供审核证据 |

**迁移路径**：

```
Phase 1上线（第0-4周）
    │
    ├── 所有审核记录使用 platform_signature
    ├── 审核流程跑通，界面定型
    ├── 收集审核人行为数据，优化UX
    │
    ▼
灰度阶段（第5-8周）
    │
    ├── 选取1-2名审核人开通PKI证书
    ├── 高风险处方（抗菌药、精神类药品等）使用PKI签名
    ├── 低风险处方继续使用平台签名
    │
    ▼
全量迁移（第9周+）
    │
    ├── 所有审核人完成PKI证书开通
    ├── 所有审核结论默认PKI签名
    ├── 平台签名作为PKI签名的fallback（CA故障时降级）
    └── 历史Phase 1记录保留原始签名，不做追溯重签
```

**数据兼容性**：表已预留两阶段字段，无需改表。`signature_phase` 字段标记每条记录的签名方式，审计工具据此选择验证逻辑。

---

## 3. FISCO BCOS存证对接

### 3.1 已有合约分析

当前 FISCO BCOS 已在 M4 Mini (10.0.0.2, ARM64 原生) 上部署的4个合约：

| 合约 | 定位 | 存储内容 | 查询能力 |
|------|------|---------|---------|
| `OperationLog` | 操作日志存证 | logId→LogEntry(opType, agentId, timestamp, targetHash, resultHash, extraData) | 按ID、Agent查询 |
| `DetectionHash` | 检测Hash存证 | detectionHash→DetectionRecord(chain, anchor, fileHash, confidence) | 按Hash、文件查询 |
| `VersionRegistry` | 版本记录 | binaryHash→Version(version, component, sourceHash, changeLog) | 按Hash、组件查询 |
| `WhiteHatReport` | 白帽报告注册 | reportId→Report(reporter, ipfsCid, proofHash, status) | 按ID、状态查询 |

### 3.2 复用 vs 新增决策

**决策结论：新增 `AuditRecord` 合约**，复用 `OperationLog` 记录审核事件流。

理由：
- 审核记录有独特的数据结构和业务语义，不适合硬塞进已有的4个合约
- `OperationLog` 的 `OpType` 枚举可扩展，用于记录审核操作事件（登录/查看/提交）
- `AuditRecord` 专项负责审核结论的不可变存证
- 保持单一职责原则

### 3.3 新增合约：`AuditRecord.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AuditRecord
 * @notice 「全球医生」智能诊疗系统 — 审核结论链上存证
 * @dev 部署在FISCO BCOS联盟链 (M4 Mini ARM64原生)
 *      每条审核结论写入后不可修改
 *      审核操作事件由 OperationLog 合约记录
 */
contract AuditRecord {

    // --- 枚举 ---

    // 审核结论
    enum AuditConclusion {
        APPROVED,          // 0: 通过
        REJECTED,          // 1: 驳回
        REVISION_NEEDED    // 2: 需修改
    }

    // 签名阶段
    enum SignaturePhase {
        PLATFORM,          // 0: Phase 1 平台留痕
        PKI               // 1: Phase 2 PKI证书签名
    }

    // 签名算法
    enum SigAlgorithm {
        SHA256,            // 0: 纯SHA256哈希 (Phase 1)
        SHA256WITHRSA,     // 1: SHA256+RSA (Phase 2)
        SHA256WITHECDSA    // 2: SHA256+ECDSA (Phase 2备用)
    }

    // 审计类型（用于同链部署时区分生产审核与监督审核）
    enum AuditType {
        PRODUCTION,        // 0: 生产审核——信证链的医生审核记录
        OVERSIGHT,         // 1: 监督审核——审计链的抽审/复核记录
        CERT_DEGRADATION   // 2: 证书降级事件——PKI证书过期引起的签名降级记录
    }

    // --- 数据结构 ---

    struct AuditEntry {
        bytes32 auditId;             // SHA256(审核ID字符串)
        bytes32 suggestionId;        // SHA256(关联建议ID)
        bytes32 evidenceSnapshotHash; // 五元组证据链快照的SHA256
        bytes32 auditorId;            // SHA256(审核人ID)
        AuditConclusion conclusion;   // 审核结论
        bytes32 signatureHash;        // 审核人数字签名哈希
        SignaturePhase sigPhase;      // 签名阶段
        SigAlgorithm sigAlgorithm;    // 签名算法
        AuditType auditType;          // 审计类型 (PRODUCTION/OVERSIGHT/CERT_DEGRADATION)
        uint64 timestamp;             // 审核时间戳
        bytes32 merkleRoot;           // 所属Merkle批次的根Hash（延迟填写）
        bool exists;                  // 防覆盖标记
    }

    // --- 存储 ---

    // auditId → AuditEntry
    mapping(bytes32 => AuditEntry) public auditEntries;

    // auditorId → auditId[]（按审核人追溯历史审核记录）
    mapping(bytes32 => bytes32[]) public auditorHistory;

    // 全部审核ID（按时间顺序）
    bytes32[] public allAuditIds;

    // 统计数据
    uint256 public totalAudits;
    uint256 public totalApproved;
    uint256 public totalRejected;
    uint256 public totalRevisionNeeded;

    // 管理员地址
    address public admin;

    // --- 事件 ---

    event AuditRecorded(
        bytes32 indexed auditId,
        bytes32 indexed suggestionId,
        bytes32 indexed auditorId,
        AuditConclusion conclusion,
        SignaturePhase sigPhase,
        AuditType auditType,          // PRODUCTION/OVERSIGHT/CERT_DEGRADATION
        uint64 timestamp
    );

    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    // --- 修饰符 ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier auditNotExists(bytes32 auditId) {
        require(!auditEntries[auditId].exists, "Audit already recorded");
        _;
    }

    // --- 构造函数 ---

    constructor() {
        admin = msg.sender;
    }

    // --- 核心写入函数 ---

    /**
     * @notice 记录一条审核结论（不可变存证）
     * @param auditIdStr 审核ID原始字符串的SHA256
     * @param suggestionIdStr 关联建议ID原始字符串的SHA256
     * @param evidenceSnapshotHash 五元组JSON快照的规范序列化SHA256
     * @param auditorIdStr 审核人ID原始字符串的SHA256
     * @param conclusion 审核结论枚举
     * @param signatureHash 审核签名哈希
     * @param sigPhase 签名阶段枚举
     * @param sigAlgorithm 签名算法枚举
     */
    function recordAudit(
        bytes32 auditIdStr,
        bytes32 suggestionIdStr,
        bytes32 evidenceSnapshotHash,
        bytes32 auditorIdStr,
        AuditConclusion conclusion,
        bytes32 signatureHash,
        SignaturePhase sigPhase,
        SigAlgorithm sigAlgorithm
    )
        external
        auditNotExists(auditIdStr)
    {
        require(auditIdStr != bytes32(0), "auditId cannot be zero");
        require(suggestionIdStr != bytes32(0), "suggestionId cannot be zero");
        require(evidenceSnapshotHash != bytes32(0), "evidenceSnapshotHash cannot be zero");
        require(auditorIdStr != bytes32(0), "auditorId cannot be zero");
        require(signatureHash != bytes32(0), "signatureHash cannot be zero");

        uint64 ts = uint64(block.timestamp);

        auditEntries[auditIdStr] = AuditEntry({
            auditId: auditIdStr,
            suggestionId: suggestionIdStr,
            evidenceSnapshotHash: evidenceSnapshotHash,
            auditorId: auditorIdStr,
            conclusion: conclusion,
            signatureHash: signatureHash,
            sigPhase: sigPhase,
            sigAlgorithm: sigAlgorithm,
            timestamp: ts,
            merkleRoot: bytes32(0),   // 下一轮Merkle打包时填写
            exists: true
        });

        auditorHistory[auditorIdStr].push(auditIdStr);
        allAuditIds.push(auditIdStr);

        unchecked { totalAudits++; }
        if (conclusion == AuditConclusion.APPROVED) {
            unchecked { totalApproved++; }
        } else if (conclusion == AuditConclusion.REJECTED) {
            unchecked { totalRejected++; }
        } else {
            unchecked { totalRevisionNeeded++; }
        }

        emit AuditRecorded(auditIdStr, suggestionIdStr, auditorIdStr,
                          conclusion, sigPhase, AuditType.PRODUCTION, ts);
    }

    /**
     * @notice 批量记录审核结论（减少交易数）
     * @param auditIds 审核ID数组
     * @param suggestionIds 关联建议ID数组
     * @param evidenceSnapshotHashes 证据链快照哈希数组
     * @param auditorIds 审核人ID数组
     * @param conclusions 审核结论数组
     * @param signatureHashes 签名哈希数组
     * @param sigPhases 签名阶段数组
     */
    function batchRecordAudit(
        bytes32[] calldata auditIds,
        bytes32[] calldata suggestionIds,
        bytes32[] calldata evidenceSnapshotHashes,
        bytes32[] calldata auditorIds,
        AuditConclusion[] calldata conclusions,
        bytes32[] calldata signatureHashes,
        SignaturePhase[] calldata sigPhases,
        SigAlgorithm[] calldata sigAlgorithms
    ) external {
        uint256 count = auditIds.length;
        require(
            count == suggestionIds.length &&
            count == evidenceSnapshotHashes.length &&
            count == auditorIds.length &&
            count == conclusions.length &&
            count == signatureHashes.length &&
            count == sigPhases.length &&
            count == sigAlgorithms.length,
            "Array length mismatch"
        );

        for (uint256 i = 0; i < count; i++) {
            this.recordAudit(
                auditIds[i],
                suggestionIds[i],
                evidenceSnapshotHashes[i],
                auditorIds[i],
                conclusions[i],
                signatureHashes[i],
                sigPhases[i],
                sigAlgorithms[i]
            );
        }
    }

    // --- 查询函数 ---

    /**
     * @notice 查询单条审核记录
     */
    function getAudit(bytes32 auditId) external view returns (AuditEntry memory) {
        require(auditEntries[auditId].exists, "Audit not found");
        return auditEntries[auditId];
    }

    /**
     * @notice 查询审核人的历史审核ID列表
     */
    function getAuditorHistory(bytes32 auditorId, uint256 offset, uint256 limit)
        external view returns (bytes32[] memory ids, uint256 total)
    {
        bytes32[] storage history = auditorHistory[auditorId];
        total = history.length;

        if (offset >= total) {
            return (new bytes32[](0), total);
        }

        uint256 end = offset + limit;
        if (end > total) end = total;

        ids = new bytes32[](end - offset);
        for (uint256 i = offset; i < end; i++) {
            ids[i - offset] = history[i];
        }

        return (ids, total);
    }

    /**
     * @notice 获取统计信息
     */
    function getStats() external view returns (
        uint256 _total,
        uint256 _approved,
        uint256 _rejected,
        uint256 _revision
    ) {
        return (totalAudits, totalApproved, totalRejected, totalRevisionNeeded);
    }

    /**
     * @notice 验证证据链完整性
     * @dev 给定审核ID，返回证据链快照哈希，调用方可与链下JSON重新哈希比对
     */
    function verifyEvidenceChain(bytes32 auditId) external view returns (
        bytes32 evidenceSnapshotHash,
        bytes32 signatureHash,
        uint64 timestamp,
        bool found
    ) {
        AuditEntry storage entry = auditEntries[auditId];
        found = entry.exists;
        if (found) {
            evidenceSnapshotHash = entry.evidenceSnapshotHash;
            signatureHash = entry.signatureHash;
            timestamp = entry.timestamp;
        }
    }

    // --- 管理函数 ---

    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid address");
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }
}
```

### 3.4 OperationLog OpType 扩展

在已有 `OperationLog.sol` 的 `OpType` 枚举中新增医疗审核相关操作类型：

```solidity
// 扩展 OpType 枚举 (在现有枚举基础上)

// === 「全球医生」医疗审核操作 (30-39) ===
enum OpType {
    // ... 已有枚举值 (0-29) ...
    
    // 医疗审核操作
    AUDIT_LOGIN,                 // 30: 审核人登录
    AUDIT_2FA_VERIFY,           // 31: 双因子验证通过
    AUDIT_VIEW_EVIDENCE,        // 32: 查看证据链
    AUDIT_SUBMIT_APPROVED,      // 33: 提交审核结论-通过
    AUDIT_SUBMIT_REJECTED,      // 34: 提交审核结论-驳回
    AUDIT_SUBMIT_REVISION,      // 35: 提交审核结论-需修改
    AUDIT_SESSION_EXPIRE,       // 36: 审核会话过期
    AUDIT_SIGNATURE_GENERATE,   // 37: 数字签名生成
    AUDIT_ONCHAIN_COMMIT        // 38: 上链存证完成
}
```

### 3.5 链上存证 vs 链下存储取舍建议

| 维度 | 链上 (FISCO BCOS) | 链下 (MySQL/IPFS/MinIO) | 建议 |
|------|-------------------|------------------------|------|
| **完整JSON** | ❌ Gas/存储成本高 | ✅ 经济 | 链下(MySQL) |
| **证据链快照** | ❌ 同上 | ✅ | 链下(MySQL)，链上仅存SHA256 |
| **审核结论** | ✅ 核心，需不可篡改 | ⚠️ 可被DBA修改 | **链上** |
| **签名哈希** | ✅ 同上 | ⚠️ | **链上** |
| **审核人身份** | ✅ | ⚠️ | **链上（哈希后）** |
| **操作日志** | ✅ 审计轨迹 | ⚠️ | **链上**(OperationLog) |
| **文献全文** | ❌ | ✅ IPFS/MinIO | 链下(IPFS) |
| **时间戳** | ✅ 区块链时间,不可伪造 | ⚠️ 服务器可改 | **链上** |
| **查询/统计** | ❌ 慢且复杂 | ✅ SQL/ES | 链下 + 数据导出组件 |
| **导出给监管** | ⚠️ 需定制工具 | ✅ 标准SQL/CSV导出 | 链下为主 |

**推荐架构**：

```
                            ┌─────────────────────┐
                            │   FISCO BCOS 链上    │
                            │                     │
                            │  AuditRecord 合约:   │
                            │  ├ auditId (SHA256) │
                            │  ├ evidenceHash     │
                            │  ├ auditorId (SHA256)│
                            │  ├ conclusion       │
                            │  ├ signatureHash    │
                            │  └ timestamp        │
                            │                     │
                            │  OperationLog 合约:  │
                            │  ├ 审核操作事件流    │
                            │  └ 可追溯审计轨迹    │
                            └─────────┬───────────┘
                                      │ onchain_tx_hash关联
                            ┌─────────▼───────────┐
                            │   MySQL (链下)       │
                            │                     │
                            │  audit_records:     │
                            │  ├ 完整JSON (含文献) │
                            │  ├ 审核意见文本      │
                            │  ├ onchain_tx_hash  │
                            │  └ 各种索引          │
                            └─────────────────────┘
```

**原则**：
- 链上存 **不可变的最小验证集**（结论、哈希、身份、时间戳）
- 链下存 **完整业务数据**（JSON、文本、文献全文）
- 链上链下通过 `onchain_tx_hash` 双向关联
- 验证时：从链下取出完整JSON → 重新哈希 → 与链上 evidenceHash 比对

---

## 4. 审核界面原型描述

### 4.1 布局结构

```
┌──────────────────────────────────────────────────────────────┐
│  「全球医生」审核界面                      审核人: 张明 主治医师  │
│  SUG-20260526-001 | 会话剩余: 24:35 | [退出]                  │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─ AI诊断建议 ──────────────────────────────────────────┐   │
│  │                                                     │   │
│  │  【诊断】急性上呼吸道感染（风寒证）                     │   │
│  │  【置信度】87%                                        │   │
│  │  【建议方剂】桂枝汤加减                                │   │
│  │  桂枝 9g  白芍 9g  甘草 6g  生姜 9g  大枣 4枚         │   │
│  │  【服药方式】水煎温服，日一剂，分两次                    │   │
│  │  【注意事项】服药后啜热稀粥一碗，温覆取微汗              │   │
│  │                                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─ 五元组证据链 [展开▼] ────────────────────────────────┐   │
│  │                                                     │   │
│  │  ┌─ ① 数据源 ─────────────────────────── [收起▲] ┐  │   │
│  │  │  ● 循证文献: PMID:34567890 (NEJM 2024 RCT)    │  │   │
│  │  │  ● 传统医籍: 伤寒论·辨太阳病脉证并治·第12条     │  │   │
│  │  │  ● 临床指南: 《急性上呼吸道感染诊疗指南2023》    │  │   │
│  │  └──────────────────────────────────────────────┘  │   │
│  │                                                     │   │
│  │  ┌─ ② 文献依据原文 ────────────────── [展开▼] ┐   │   │
│  │  │  [点击展开查看原文引用全文]                      │   │
│  │  └──────────────────────────────────────────────┘  │   │
│  │                                                     │   │
│  │  ┌─ ③ 处理逻辑 ────────────────────── [展开▼] ┐   │   │
│  │  │  推理链路: SymptomExtraction → ...            │   │
│  │  │  模型: deepseek-v4-pro                         │   │
│  │  │  Prompt版本: dx-v2.3.1                         │   │
│  │  └──────────────────────────────────────────────┘  │   │
│  │                                                     │   │
│  │  ┌─ ④ 版本信息 ────────────────────── [展开▼] ┐   │   │
│  │  │  建议版本: 1.0.0 | 生成时间: 2026-05-26 08:30  │   │
│  │  │  引擎版本: v2.4.1 | KB版本: 2026.03             │   │
│  │  └──────────────────────────────────────────────┘  │   │
│  │                                                     │   │
│  │  证据链哈希: a1b2c3d4...e7f8 (可点击复制)          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─ 审核意见区 ──────────────────────────────────────────┐   │
│  │                                                     │   │
│  │  ┌──────────────────────────────────────────────┐   │   │
│  │  │  审核意见:                                    │   │   │
│  │  │  [                    ]                      │   │   │
│  │  │  [                    ]                      │   │   │
│  │  │  [                    ]                      │   │   │
│  │  │  (文本区域，支持富文本，最多2000字)              │   │   │
│  │  └──────────────────────────────────────────────┘   │   │
│  │                                                     │   │
│  │  ┌─ 修改建议（审核结论为"需修改"时必填）────────┐   │   │
│  │  │  需要修改的字段:                              │   │   │
│  │  │  ☐ 诊断结论  ☐ 方剂选择  ☐ 用药剂量          │   │   │
│  │  │  ☐ 服药方式  ☐ 禁忌证  ☐ 其他               │   │   │
│  │  │  修改建议描述:                                │   │   │
│  │  │  [                    ]                      │   │   │
│  │  └──────────────────────────────────────────────┘   │   │
│  │                                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ [✓ 通过]   [✗ 驳回]   [⟳ 需修改]      [取消]      │   │
│  │                                                    │   │
│  │  驳回时必须填写驳回理由 | 需修改时建议框必填          │   │
│  │  二次确认弹窗: "确认提交审核结论？提交后将上链存证。"  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─ 历史审核记录（列表，左侧边栏）─────────────────────┐   │
│  │  AUD-20260526-001  通过  09:15  张明                │   │
│  │  AUD-20260526-002  待审  09:10  —                  │   │
│  │  AUD-20260525-015  驳回  18:30  李华                │   │
│  │  ...                                               │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### 4.2 交互规则

| 交互元素 | 规则 |
|---------|------|
| **五元组证据链** | 默认收起。点击展开/折叠。①数据源和③处理逻辑默认展开，②文献和④版本默认折叠 |
| **通过按钮** | 无需填写审核意见即可提交（意见为可选） |
| **驳回按钮** | 驳回理由必填（≥10字），提交前弹窗二次确认 |
| **需修改按钮** | 修改建议必填（选择字段+填写描述），提交后AI引擎收到结构化修改指令 |
| **证据链哈希** | 可点击复制到剪贴板；旁边显示「链上验证」链接 |
| **历史记录侧栏** | 显示最近20条审核记录，颜色标记：通过=绿、驳回=红、需修改=黄、待审=灰 |
| **会话超时** | 30分钟无操作自动退出，需重新2FA验证；超时前5分钟弹黄色提醒 |
| **并发锁定** | 同一建议同时只有一个审核人可操作，其他人看到「已被XXX锁定审核中」 |

### 4.3 审核提交完整流程

```
审核人登录 (用户名+密码)
    │
    ▼
2FA验证 (短信/TOTP)
    │
    ▼
审核队列列表（按优先级/时间排序）
    │
    ▼
点击进入 → 锁定该建议（写 audit_operation_log: AUDIT_VIEW_EVIDENCE）
    │
    ▼
查看 AI诊断建议 + 展开五元组证据链
    │
    ▼
填写审核意见（可选） + 选择结论按钮
    │
    ├── [✓ 通过] → 确认弹窗 → 生成签名哈希 → 上链 → 解锁
    ├── [✗ 驳回] → 填写理由(必填) → 确认 → 签名 → 上链 → 解锁
    └── [⟳ 需修改] → 选择字段+描述(必填) → 确认 → 签名 → 上链 → 解锁
    │
    ▼
审核提交成功提示：
「审核已提交。链上交易: 0xabcd...1234 (区块 #98765)」
    │
    ▼
返回审核队列，进入下一条
```

---

## 5. 中美双法规合规映射

### 5.1 FDA CDS Criterion 4 映射

FDA 对医疗器械软件中的临床决策支持(CDS)软件采用四准则判断是否需要监管审查。Criterion 4 要求：

> **FDA CDS Criterion 4**: The software function enables the healthcare professional to independently review the basis for the recommendations, so that it is not the intention that the healthcare professional rely primarily on the software's recommendations to make a clinical diagnosis or treatment decision.

**映射到本方案**：

| FDA要求要点 | 本方案实现 |
|------------|----------|
| 执业医师能独立审查建议依据 | ✅ 五元组证据链完整展示（数据源+文献+推理路径） |
| 医师不主要依赖软件建议 | ⚠️ 分层满足——自动通过的案例（置信度≥95% + 低风险R1）不属于CDS输出给医师做决策参考，而是系统内部低风险分流，不适用Criterion 4约束。人工审核的案例（中/高风险、置信度偏低、异常标记）适用Criterion 4，审核人必须主动点击通过/驳回/需修改 |
| 建议的透明度 | ✅ 证据链快照 + 哈希存证，事后可完整追溯 |
| 21 CFR Part 11 电子签名 | ✅ Phase 2 PKI签名满足 (21 CFR 11.50, 11.70, 11.200) |
| 审计追踪 (Audit Trail) | ✅ OperationLog + AuditRecord双合约覆盖 |
| 记录保留 | ✅ 链上永久存证 + 链下定时备份，满足7年保留要求 |
| 唯一身份识别 | ✅ 双因子认证 + PKI证书绑定执业医师编号 |

**21 CFR Part 11 具体满足点**：

| Part 11 条款 | 实现 |
|-------------|------|
| §11.10(a) 系统验证 | 合约代码审计 + 哈希验证 |
| §11.10(b) 可读记录 | 链下JSON + 文本格式 |
| §11.10(c) 记录保护 | 链上不可变 + 链下加密备份 |
| §11.10(d) 权限控制 | 2FA + session + PKI证书 |
| §11.10(e) 审计追踪 | OperationLog 合约完整记录 |
| §11.50 签名唯一性 | Phase 2: PKI证书绑定唯一执业医师 |
| §11.70 签名链接 | 签名哈希 = SHA256(审核内容+审核人) |
| §11.200 电子签名组件 | 用户名+密码+2FA 或 PKI证书 |

### 5.2 NMPA 医疗器械软件审查映射

NMPA（国家药监局）对医疗器械软件的审查要点（参照《医疗器械软件注册技术审查指导原则》及2023/2024年更新）：

| NMPA要求要点 | 本方案实现 |
|------------|----------|
| 软件版本管理 | ✅ VersionRegistry合约记录引擎版本 |
| 操作日志完整性 | ✅ OperationLog记录审核全生命周期事件 |
| 审计追踪 | ✅ 链上时间戳不可篡改 |
| 电子签名 | ✅ 平台留痕(Phase 1)满足操作日志要求；PKI(Phase 2)满足严格电子签名要求 |
| 数据安全 | ✅ 审核人身份数据哈希上链，原始数据链下加密存储 |
| 用户权限管理 | ✅ 2FA + 角色权限（主治/副主任/主任医师不同审核级别） |
| 数据备份恢复 | ✅ 链上数据自动冗余 + 链下MySQL主从备份 |
| 不良事件追溯 | ✅ 通过audit_id/suggestion_id双向追溯完整证据链 |

**NMPA特别关注的中医药审查**：

| 中医药特别要点 | 本方案处理 |
|--------------|----------|
| 辨证论治逻辑可解释 | ✅ 五元组③处理逻辑记录完整推理链路 |
| 古籍引用准确性 | ✅ 五元组④文献依据记录原文+版本时间戳 |
| 中西药交互作用风险 | ✅ 证据链包含禁忌证核对步骤 |
| 组方合理性审查 | ✅ AI建议包含方剂组成+剂量+煎服法，审核人可查对 |

---

## 6. 实施路径

### 6.1 阶段规划

```
Week 0-2: 数据层 (Phase 1)
  ├── MySQL audit_records 表建表
  ├── audit_operation_log 表建表
  ├── 五元组JSON Schema 定稿
  ├── 证据链快照序列化规范定稿
  └── SHA256签名生成模块实现

Week 2-4: 合约层 (Phase 1)
  ├── AuditRecord.sol 合约编译+部署到 FISCO BCOS
  ├── OperationLog.sol OpType扩展
  ├── 链上写入SDK封装
  ├── 链上链下双向关联验证
  └── 单元测试 + 集成测试

Week 4-5: 界面层 (Phase 1)
  ├── 审核界面原型实现(按4.1/4.2/4.3)
  ├── 2FA认证接入
  ├── 五元组折叠展示组件
  ├── 操作日志上报
  └── 内部试运行

Week 5-8: PKI集成 (Phase 2灰度)
  ├── CFCA证书采购
  ├── PKI签名服务开发
  ├── Web Crypto API / HSM集成
  ├── 高风险处方灰度审核
  └── 合规审查准备

Week 9+: 全量发布 (Phase 2)
  ├── 全部审核人PKI开通
  ├── Phase 1→Phase 2 数据兼容验证
  ├── FDA/NMPA合规材料准备
  └── 正式上线
```

### 6.2 依赖关系

```
audit_records 表 ← 审计后台
     │
     ├── AuditRecord.sol 合约 ← FISCO BCOS (M4 Mini 10.0.0.2)
     │
     ├── OperationLog.sol 扩展 ← FISCO BCOS
     │
     ├── 2FA服务 ← 短信网关/TOTP模块
     │
     ├── PKI签名服务 ← CFCA API / HSM (Phase 2)
     │
     └── 审核界面 ← React前端 + 上述所有服务
```

---

## 7. 部署要求

### 7.1 服务器要求

惠迈智能体 + FISCO BCOS 节点 + 审核界面的部署要求极低，**医院现有服务器远超最低要求**：

| 维度 | 最低要求 | 建议配置 | 说明 |
|------|---------|---------|------|
| 操作系统 | Ubuntu 22.04/Debian 12/CentOS 7 | Ubuntu 24.04 LTS | 主推Ubuntu，可适配主流Linux发行版；国产化场景支持OpenEuler |
| 架构 | x86_64 或 ARM64 | x86_64 | FISCO BCOS v3.x已原生支持ARM64（已在M4 Mini验证） |
| CPU | 2核 | 4核 | 智能体轻量运行，FISCO BCOS节点为资源大头 |
| 内存 | 4 GB | 8 GB | 4GB即可跑通，但8GB更稳定 |
| 磁盘 | 20 GB (SSD) | 50 GB (SSD) | 智能体+节点<5GB，剩余为审核记录数据增长 |
| 网络 | 医院内网 | 千兆以太网 | 无需公网IP，可配置互联网出站用于软件更新 |

**兼容性说明**：
- 物理机或虚拟机均可部署
- 支持 HPE / Dell / 华为 / 浪潮等主流服务器品牌
- macOS（Apple Silicon）可用于开发/小规模试点，生产环境推荐Linux
- ❌ 不支持 Windows Server（FISCO BCOS无官方Windows支持）

### 7.2 部署形态

#### 7.2.1 部署原则：与 HIS/LIS/PACS 解耦

惠迈智能体**不接入医院现有 HIS / LIS / PACS 系统**。这是核心设计原则：

- ❌ 不接 HIS 接口（各厂商 API 不统一，每家医院需 1-3 个月对接调试）
- ❌ 不碰原始病历、影像、检验数据（触及等保四级红线）
- ❌ 不在 HIS 内部署任何插件或模块
- ✅ 智能体只需一个**独立的审核界面**（Web 端 / 小程序）
- ✅ 只接收 AI 诊断引擎推来的**标准化审核格式 JSON**（五元组结构）

**工作流程**：

```
AI诊断引擎（推想/联影/商汤等）
    ↓ 审核格式JSON（五元组 + 证据链快照）
    ↓
惠迈智能体（同一台服务器）
    ↓ 校验 → 分流 → 路由
    ↓
医生在独立审核Web界面签名
    ↓ 签名上链
    ↓
FISCO BCOS 链上存证
```

**医生工作流**：

```
医生在HIS里看到AI诊断建议
  ↓ 评估后决定：采纳/修改/驳回
  ↓
打开智能体审核界面（新标签页或小程序）
  ↓ 2FA验证身份
  ↓ 签名确认（~2分钟）
  ↓
关闭审核界面，回HIS继续工作
```

**优势**：
- 部署最快：镜像放进医院服务器 → 对接 AI 诊断引擎 → 3 天跑通
- 不依赖 HIS 厂商配合
- 不增加等保评审复杂度

#### 7.2.2 服务器部署示意图

```
┌──────────────────────────────────────────┐
│           医院信息中心·一台服务器           │
│                                          │
│  ┌────────────┐  ┌──────────────────┐   │
│  ｜ FISCO BCOS │  │  惠迈智能体       │   │
│  ｜ 节点       │  │  (审核后端+API)   │   │
│  └────────────┘  └──────────────────┘   │
│                                          │
│  ┌────────────┐  ┌──────────────────┐   │
│  ｜ PostgreSQL│  │  审核界面(React)  │   │
│  ｜ 审核记录   │  │  (Nginx反代)     │   │
│  └────────────┘  └──────────────────┘   │
│                                          │
│  运维：医院信息科 | 物理安全：医院机房     │
└──────────────────────────────────────────┘
```

**部署方式**（三种任选）：
| 方式 | 适用场景 |
|------|---------|
| 容器部署（Docker Compose） | 推荐，一键启动，便于运维 |
| 系统服务（Systemd） | 医院要求二进制直接运行的保守场景 |
| 虚拟机镜像 | 医院VMware/OpenStack环境，直接分发OVA |

### 7.3 等保适配

- 作为医院信息系统的外挂模块，随医院信息系统整体过等保三级
- 审核记录的链上存证天然满足等保【数据完整性】要求
- 审核人双因子认证满足等保【身份鉴别】要求
- 操作日志全量留存满足等保【安全审计】要求
- **智能体不进患者数据层**，无需额外数据安全评审

### 7.4 审核运营模式：人机混合漏斗

#### 7.4.1 核心模型

> **前置约束：** 此分流模型在信证链健康检查层（排毒前置）的异常等级判定**之后执行**。健康检查 Level-2（中度异常）会覆盖分流路径强制人工审核，Level-3（重度异常）直接拒绝受理不进入此模型。详见信证链规格 §3.4 优先级规则。

AI诊断建议不经人工逐条审核——智能体在中间做自动化分流漏斗：

```
AI诊断建议出 → 智能体实时判断
        │
        ├── 自动通过（~90%）
        │    └── 置信度≥95% + 无历史争议 → 自动上链存证
        │
        ├── 人工抽审（~8%）
        │    └── 按比例抽样 + 低置信度 + 新病种/罕见诊断
        │
        └── 人工复审（~1-2%）
             └── 患者投诉 / 医疗纠纷 / 卫健委检查 / 审核人偏差触发
```

#### 7.4.2 人员配置

- **100名审核人 = 在册库总人数**，不是同时在线人数
- **日常值班**：5-10名大夫轮班，每人每天审30-80条，≈占用1-2小时
- **专家委员会**：3-5名科室主任，处理疑难/高风险病例（~2%）
- **备选池**：其余审核人按学科/科室分布，智能体按需调度

```
齐鲁医院 ≈ 4000床/天
AI建议量 ≈ 2000-5000条/天
        │
自动通过（90%）：  2700-4500条   ✅ 机器自动处理
人工抽审（8%）：   160-400条     👨‍⚕️ 5-10名值班大夫
人工复审（2%）：   40-100条      👨‍⚕️👨‍⚕️ 3-5名科室主任
```

**审核人成本**（非全职，作为工作量计算）：
```
每次人工抽审 ≈ 3-5分钟
每天总抽审工作量 ≈ 8-33小时
≈ 1-4名全职等效人力
均摊到100名在册审核人 → 每人每月约4-12小时
```

#### 7.4.3 分流规则

| 条件 | 分流结果 |
|------|---------|
| 置信度≥95% + 同类病例无拒审记录 | ✅ 自动通过，链上存证 |
| 置信度 80-95% | 🔄 人工抽审 |
| 置信度 <80% | 🔴 人工复审 |
| 新病种/首次诊断 | 🔄 人工抽审 |
| 患者投诉触发 | 🔴 人工复审 |
| 该审核人偏差系数 >0.4 | 🔴 全部复审 |
| 卫健委检查时段 | 🔄 抽审率提升至15% |

#### 7.4.4 审核人证书策略（Phase 2）

100名在册审核人中，不是所有人都需要 PKI 数字证书。根据实际角色分级签发：

| 角色 | 人数 | 证书策略 | 年成本 |
|------|------|---------|-------|
| 值班核心（日常抽审） | ~20人 | CFCA数字证书，法律效力完整 | ¥2000-5000/人/年 |
| 专家委员会（疑难复审） | ~5人 | CFCA数字证书 | ¥2000-5000/人/年 |
| 备选池（按需调度） | ~75人 | 继续Phase 1平台留痕，不上PKI | ¥0 |
| **合计** | **100人** | **首批25张证书** | **¥5-12.5万/年** |

**备选成本对照**：

| 方案 | 成本 | 法律效力 | 推荐度 |
|------|------|---------|-------|
| CFCA / SZCA 商业CA | ¥2000-5000/证/年, 25人≈¥5-12.5万/年 | ✅ 法院认可 | ⭐ 生产环境首选 |
| 自建内部CA（OpenCA） | 一次性¥1-3万 + 运维 | ⚠️ 效力存疑 | 可作开发/测试用 |
| 混合策略（核心CA+备选留痕） | ¥5-12.5万/年 + 备选¥0 | ✅ 核心层有 | ⭐⭐ 推荐 |

**原则**：核心审核层（25人）保证法律合规，备选层（75人）不上PKI不额外花钱。

**R4/R5 高风险案例特别规则：**

| 场景 | 规则 | Chain Event |
|------|------|-------------|
| 证书有效期内 | R4/R5案例必须由持有有效PKI证书的核心审核人签名，不得由备选层（Phase 1平台留痕）处理 | 正常审核事件 |
| 证书到期/部分过期 | 系统自动将R4/R5案例转入仍有有效证书的备用审核人队列 | 触发 `CERT_DEGRADATION` 审计事件，记录原始审核人ID、证书到期时间、降级原因、备用审核人ID |
| 证书到期/全部过期 | 系统暂停R4/R5案例的自动/备选处理，**不降级为Phase 1签名**。暂停队列中的R4/R5案例等待证书恢复 | 触发 `CERT_DEGRADATION` 审计事件，type = "ALL_EXPIRED", 影响案例数量 |
| 证书恢复 | 暂停队列中的R4/R5案例自动恢复处理 | 触发 `CERT_RESTORATION` 审计事件 |
| 运营要求 | 核心审核人的PKI证书过期日应在日历上分散，避免批量到期。信息科应在证书到期前60天收到首次告警 | — |

> **设计说明：**
> 1. R4/R5的高风险性质决定了这些案例的审核签名不能降级。**宁可暂停处理也不能用Phase 1签名替代**——后者在医疗纠纷中可能被质疑签名法律效力，而R4/R5恰恰是最容易引发纠纷的案例。
> 2. **降级审计事件是必须的。** 如果只做路由不做记录，审计日志查阅者无法知道当时的签名是降级后的还是正常的。将来医疗纠纷时，法官看到Phase 1签名的R4案例记录，会质疑合规性。`CERT_DEGRADATION` 事件链确保了降级全生命周期可追溯。
> 3. **节假日/非办公时间的紧急降级引导：** 如果R4/R5全部过期发生在节假日或非办公时间，且出现危急值级案例（按医院现有危急值标准判定），**不强制等待信证链恢复**——由医院现有危急值处理预案（电话+纸质+院内第二系统）接管，信证链系统恢复后补录审计事件。此降级引导仅适用于真正危急值场景，非危急值R4/R5案例仍按暂停处理。

**CERT_DEGRADATION 审计事件结构：**

```json
{
  "event_type": "CERT_DEGRADATION",
  "degradation_type": "PARTIAL" | "ALL_EXPIRED" | "RESTORATION",
  "timestamp": 1716789600,
  "affected_auditor_id": "auditor_0x3f2a...",
  "affected_cert_expiry": "2026-06-01",
  "cause": "PKI certificate expired",
  "rerouted_to": "auditor_0x7b9c...",
  "paused_case_ids": ["case_0x...", "case_0x..."],
  "recorded_by": "chain_audit_system_v1"
}
```

此事件通过 `AuditRecord` 通用结构写入链上，`auditType = "CERT_DEGRADATION"`（与PRODUCTION/OVERSIGHT并列）。

#### 7.4.5 证书费用处理模式

CA 证书的年度费用由医院承担，**惠迈不代收代缴**。理由：

1. **CA 证书是医院与 CFCA 之间的合同关系** — 医院信息科向 CFCA 提交机构资质、法人信息、审核人身份证明后直接申办，惠迈无法替代
2. **不增加客诉风险** — 若惠迈代收代缴，证书到期未续导致审核人掉线，医院追责对象是惠迈而非 CFCA
3. **利润率低不值得搭建财务系统** — 25张证书年费¥5-12.5万，即使加价20%手续费也不到¥2.5万毛利，不值得设置对账/催收/续费提醒的运营团队

**分责模型**：

| 责任方 | 事项 |
|--------|------|
| **医院** | 向CFCA提交资料、缴费、续费 |
| **惠迈** | 提供SDK集成方案、协助证书安装、智能体绑定、证书到期自动告警通知医院 |

**异常处理**：
- 医院因财务流程延迟续费导致证书过期 → **非R4/R5案例**的审核人自动降级为Phase 1平台留痕模式，审核照常进行，不中断业务。R4/R5案例按上方特别规则处理（部分过期转备用队列 / 全部过期暂停）
- **所有降级（含非R4/R5的Phase 1降级）** 均在链上记录降级审计事件，确保降级全生命周期可追溯
- 惠迈应在证书到期前30天通过系统告警通知医院信息科

#### 7.4.6 智能体与审核人关系

- **智能体 = 路由器**：不碰诊断，只做校验、存证、路由
- **审核人 = 路由后的专家**：通过智能体签名上链
- **100个审核人 ≠ 挂载100个智能体**：全连接同一个智能体实例

### 7.5 供应链依赖

```
惠迈智能体二进制         — 本地编译，SHA256上链
FISCO BCOS SDK          — 开源审计 + 版本锁定
PostgreSQL / SQLite     — 开源/本地部署
React前端               — 静态文件，无外部依赖
CFCA PKI SDK (Phase 2) — 供应商审计 + 哈希校验
```

所有组件均可脱网运行，不依赖外部云服务。

---

## 8. 跨院区扩展性设计

### 8.1 设计前提

「全球医生」的初始部署为**单院区独立链**模式：
- 每家医院部署一台服务器（兼容现有医院IT资产）
- 服务器上运行 FISCO BCOS 节点 + 惠迈智能体 + 审核界面
- 审核记录链上存证，数据**不出医院内网**
- 等保评审按单院区单独过（等保三级）

但系统设计需要预判院区互认——当华山医院与中日友好医院需要互相认可对方的审核结论时，架构如何演进。

### 8.2 跨院扩展的四级模型与选型路径

```
第四级（远期实验）
  Layer 2 / ZKP 跨链验证
      ↑
第三级（中期推荐）
  超级见证节点 + Merkle Root 汇聚
      ↑
第二级（技术可行，合规需确认）
  跨院联盟链（华山 + 中日 + 第三方见证）
      ↑
第一级（第一年起步）
  链分离 · 互认标准
```

**推荐路径**：第一级起步 → 第三级中期 → 第四级远期储备。
**不建议过早进入第二级**（跨院联盟链的合规成本和共识复杂度对早期医院客户是负担）。

---

### 8.3 第一级：链分离 · 互认标准

**模式**：

```
华山医院 ── 独立 BCOS 节点
中日医院 ── 独立 BCOS 节点

两院区链不互通。
但审核结论数据结构标准化。
院区间可链下验证对方的签名哈希。
```

**是什么**：不是"链"在互通，是"审核标准"在互通。每个医院有自己独立的链，但审核记录的JSON schema、哈希算法、签名格式完全一致。A医院拿到B医院的审核结论，可以在本地链下验证B医院的签名合法性。

**技术要求**：
- 两院区使用完全相同的 `AuditRecord` 数据结构定义
- 证据链快照的JSON规范序列化算法一致（参考附录7.1）
- SHA256哈希算法一致
- Phase 2 PKI证书的CA信任链有交叉（CFCA为公共锚点）

**等保评估**：零额外成本。链和数据均未出医院。等保评审按独立系统评审。

**跨院验证流程（链下互认）**：

```
中日医院收到华山医院转来的诊断建议副本
  ↓
中日医院通过只读接口查华山链上的存证记录
  ↓
查到 audit_id 对应记录
  ↓
中日医院本地重算 signature_hash 并比对链上值
  ↓
hash一致 → 互认成立
hash不一致 → 存证存疑，转人工处理
```

**局限性**：链下查询依赖网络连通。如果两院区之间没有专线/VPN，跨院查询依赖公网，可靠性降低。

---

### 8.4 第二级：跨院联盟链（技术可行，合规待确认）

**模式**：

```
┌──────────────────┐      ┌──────────────────┐
│ 华山医院 BCOS 节点 │      │ 中日医院 BCOS 节点 │
│ Agent-Node-1     │◄────►│ Agent-Node-2     │
└────────┬─────────┘      └────────┬─────────┘
         │                         │
         └──────────┬──────────────┘
                    │
           共识层：Raft 或 PBFT
           最小节点数：3（华山 + 中日 + 第三方见证方）
```

**共识层设计**：
- **最小节点数**：3（2个医院 + 1个第三方见证方，如卫健委或联盟运营方）
- **共识算法**：Raft（容忍1节点故障）或 PBFT（容忍1拜占庭节点）
- **见证方部署**：政务云或运营方机房，不参与审核业务，只做共识验证
- **跨院同步内容**：只同步审核记录的哈希及元数据，不同步完整证据链JSON

**等保与合规挑战**：

| 问题 | 严重程度 | 缓释方案 |
|------|---------|---------|
| 患者数据通过共识同步出院？ | ❌ 红线 | 链上只存哈希，患者隐私数据始终在院方本地数据库 |
| 审核人个人信息同步出院？ | ⚠️ 需评估 | 链上只存 SHA256(auditor_id)，姓名/执照号在外院不可逆推 |
| 跨院网络用公网还是专线？ | ⚠️ 需评估 | 推荐专线或 VPN，等保三级要求传输加密 |
| 卫健委是否认可联盟链互认？ | ❓ 待确认 | 需与卫健委信息中心提前沟通，确认联盟链作为互认基础合法性 |

**适用条件**：
- 两院区隶属于同一医联体（行政上已有协作关系）
- 或卫健委明确发文支持联盟链互认
- 等保评审时以此为前提做合规方案

**为什么不建议过早进入第二级**：
- 增加医院客户的等保评审复杂度
- 增加运维成本（共识层故障排查）
- 在中国医疗IT行业，"多院区先各自跑起来再互联" 比 "一开始就组网" 更容易被接受

---

### 8.5 第三级：超级见证节点 + Merkle Root 汇聚（中期推荐）

**模式**：

```
华山医院 BCOS 节点 ──── 定期推送 Merkle Root ────┐
                                                  ▼
中日医院 BCOS 节点 ──── 定期推送 Merkle Root ────▶ 卫健委/第三方超级见证节点
                                                  │
                                                  ▼
                                          只存 Merkle Root
                                          不含任何原始数据
                                          提供公开验证接口
```

**架构**：
- 每个医院节点独立运行，不组共识
- 医院节点定期（如每天UTC 00:00）将所有审核记录的Merkle Root推送到超级见证节点
- 超级见证节点只保存 Merkle Root 及其时间戳，不保存任何原始审核数据
- 超级见证节点提供只读查询接口：`verify(hash, timestamp) → bool`

**技术实现**：

```
医院节点内部审核记录组织：
                        ┌─────────┐
                        │ Merkle  │
                        │ Root R1 │
                        └────┬────┘
                             │
        ┌───────────┬────────┴────────┬───────────┐
        │           │                 │           │
     Hash(1)     Hash(2)           Hash(3)     Hash(4)
        │           │                 │           │
     Audit 1    Audit 2           Audit 3    Audit 4

Merkle Root 通过医院节点签名后推送给见证节点
```

**等保评估**：

| 维度 | 评估 |
|------|------|
| 数据出院 | ✅ 仅为SHA256哈希，原始数据不出院 |
| 患者隐私暴露 | ✅ 哈希不可逆推，零风险 |
| 跨院网络 | ⚠️ 见证节点部署在政务云/专线，通过TLS传输 |
| 卫健季监管 | ✅ 卫健委自己持有见证节点，监管数据一目了然 |
| 司法取证 | ✅ 见证节点可作为第三方公证人出证 |

**优势**：
- 不改变单院区独立链的等保基谁
- 卫健委主动参与，有助于监管合规
- 开销极低（每天一笔交易的带宽）

---

### 8.6 第四级：零知识跨链验证（远期实验）

**概念**：

```
华山链上的审核记录，通过零知识证明（ZK Proof）在中日链上验证，
而不需要中日链持有华山链的任何数据。

证明内容：
  1. 审核记录存在（Merkle开证明）
  2. 签名有效（ZK-SNARK验证签名算法）
  3. 审核人身份有效
  4. 时间戳正确
```

**状态**：技术可行，但工程投入大、医院信息科看不懂、运维成本高。现阶段不作为设计目标，**仅预留数据结构扩展点**：
- `AuditEntry` 结构预留 `uint256 zkAccumulator` 字段
- Merkle批次存储已预留跨链验证接口

**什么时候值得启动第四级**：
- 跨院互认成为卫健委刚需
- 医院信息化成熟度达到自建节点可配置ZKP证明器
- 市场上可采购成熟的ZKP医疗验证中间件

---

### 8.7 数据结构扩展点预留

为支持以上四级演进，核心数据结构需要预留的扩展字段：

**链上 `AuditEntry` 扩展**（Solidity）：
```solidity
struct AuditEntry {
    // 原有字段（略）
    
    // 跨院扩展
    bytes32 crossChainMerkleRoot;  // 所属跨院Merkle批次的RootHash
    uint256 crossChainBatchId;     // 跨院批次编号
    bytes32 zkAccumulator;         // ZKP跨链验证积累器（第四级预留）
    
    // 医院标识
    bytes32 hospitalId;            // SHA256(医院唯一标识)
}
```

**链下 `audit_records` 表扩展**：
```sql
ALTER TABLE audit_records ADD COLUMN
    hospital_id VARCHAR(64) NOT NULL COMMENT '所属医院唯一标识' AFTER audit_id;

ALTER TABLE audit_records ADD COLUMN
    crosschain_merkle_root CHAR(64) DEFAULT NULL COMMENT '跨院Merkle批次Root';

ALTER TABLE audit_records ADD COLUMN
    crosschain_batch_id BIGINT DEFAULT NULL COMMENT '跨院批次编号';
```

**核心原则**：一开始就带医院标识，以后不管怎么扩展都不需要回溯改造。

---

### 8.8 部署建议汇总

| 阶段 | 时间线 | 操作 | 等保复杂度 |
|------|--------|------|-----------|
| Phase 0 | 现在 | 单院区独立链，单节点部署 | 低（单系统等保三级） |
| Phase 1 | 前6个月 | 多院区独立链 + 审核格式标准化（第一级） | 低 |
| Phase 2 | 6-18个月 | 卫健委/第三方超级见证节点上线（第三级） | 中（政务云节点过等保） |
| Phase 3 | 看政策 | 视政策环境和需求进入第二级（跨院联盟链） | 高 |
| Phase 4 | 远期储备 | ZKP跨链验证，视技术成熟度决定 | 待定 |

**最稳妥路径**：Phase 0 → Phase 1 → Phase 2。第三级（超级见证节点）的价值在卫健委参与时最大，值得优先推动。

---


## 9. 附录

### 9.1 JSON规范序列化算法

用于生成 `evidence_snapshot_hash`（确保跨语言/跨平台哈希一致）：

```python
def canonical_serialize(obj) -> bytes:
    """
    规范序列化JSON对象，确保相同语义的对象产生相同哈希
    
    规则:
    1. 键按ASCII字典序排序
    2. 字符串使用UTF-8编码
    3. 数字不使用科学计数法
    4. 没有多余空白字符
    5. null值保留
    """
    return json.dumps(
        obj,
        sort_keys=True,
        ensure_ascii=False,
        separators=(',', ':'),
        default=str
    ).encode('utf-8')

# 示例
snapshot_hash = hashlib.sha256(
    canonical_serialize(evidence_snapshot)
).hexdigest()
```

### 9.2 供应链安全考虑

```
审核人签名模块的依赖链审查：

外部依赖                      内部审计
═══════                      ══════
CFCA SDK  ← 供应商审计 + 哈希校验    → 本地编译 + 二进制哈希上链
FISCO BCOS SDK → 开源审计 + 版本锁定  → VersionRegistry记录版本
OpenSSL库      → 版本追踪             → CVE监控
2FA短信网关    → SLA合同              → 失败率监控
```

### 9.3 已知风险与缓解

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|---------|
| M4 Mini硬件故障 | 低 | 高 | FISCO BCOS多节点部署（至少3节点），M4 Mini为单节点需补充冗余 |
| CA证书吊销延迟 | 中 | 中 | 实时OCSP查询 + CRL缓存 + 吊销时触发拒绝审核 |
| 2FA短信延迟/丢失 | 中 | 低 | TOTP备选通道 + 审核会话超时延长至30分钟 |
| 证据链JSON过大 | 低 | 中 | 限制文献原文摘要≤500字，正文引用IPFS CID |
| 合约升级 | 低 | 高 | 使用代理模式(可升级合约)，但新合约必须记录迁移事件 |
| 量子计算威胁 | 极低 | 远期 | Phase 3预留后量子密码(PQC)升级路径 |

### 9.4 术语表

| 术语 | 定义 |
|------|------|
| 五元组 | AI建议的五个组成维度：AI建议 / 数据源 / 处理逻辑 / 文献依据 / 版本号 |
| 证据链快照 | 五元组的JSON规范序列化表示，审核时冻结并哈希 |
| 平台留痕 | Phase 1签名方案：2FA + 操作日志 + SHA256 |
| PKI签名 | Phase 2签名方案：CA证书 + RSA/ECDSA电子签名 |
| nonce | 一次性随机值，防止签名哈希重放 |
| Merkle批次 | 多条审核记录聚合为一个Merkle树，Root锚定到Arbitrum |

---

> cn002 签发  
> 2026-05-26 09:55 → 19:20 GMT+8  
> FISCO BCOS @ M4 Mini (10.0.0.2, ARM64 Native)  
> 版本：v1.0（1480行，含部署要求+跨院扩展+审核运营模式+文档全貌）