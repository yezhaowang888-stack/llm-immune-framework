# 信证链（TrustChain）：审核签名 + 链上存证 — 规格文档

> **品牌名：医疗信证链（MedTrustChain）**  
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
3. [数据健康检查层（排毒前置）](#3-数据健康检查层排毒前置)
4. [FISCO BCOS存证对接](#4-fisco-bcos存证对接)
5. [审核界面原型描述](#5-审核界面原型描述)
6. [中美双法规合规映射](#6-中美双法规合规映射)
7. [实施路径](#7-实施路径)
8. [部署要求](#8-部署要求)
9. [跨院区扩展性设计](#9-跨院区扩展性设计)
10. [附录](#10-附录)

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
| `onchain_timestamp` | 采用**医院机房本地服务器时间**，信证链原样记录不做校准。理由：医院机房需通过等保认证，时间准确性由信息科统一维护，属于医院自身运维责任。信证链不承担时间背书 |

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
| 抗抵赖 | ⚠️ 中等 — 平台内可追溯，但不具备法律效力的数字签名 |
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


### 2.5 审核人全生命周期管理

> 审核人从入职到离职的每次状态变更，必须在链上有审批留痕，必须有明确的审批路径和责任人。**信证链不信任"默认权限"——审核人在链上的权力是审批出来的，不是系统授予的。**

#### 2.5.1 审核人状态图谱

```mermaid
statusDiagram
    [*] --> 候选人：医务科提名
    候选人 --> 试用审核人：分管院长批准
    候选人 --> [*]：提名被驳回
    试用审核人 --> 正式审核人：完成培训+考核通过
    试用审核人 --> 冻结：考核未通过/严重违规
    正式审核人 --> 冻结：违规/认定异常
    冻结 --> 正式审核人：调查后恢复
    冻结 --> [*]：调查后离职/解聘
    正式审核人 --> [*]：离职/退休/转岗
    正式审核人 --> 冻结：证书到期未续（30天宽限期）
    证书到期未续（30天宽限期） --> 降级为Phase 1留痕模式：证书吊销
    Phase 1留痕模式 --> [*]：长期未激活
```

#### 2.5.2 各阶段审批路径

| 状态变更 | 发起人 | 审批路径 | 链上记录 |
|---------|-------|---------|---------|
| 候选人审核人提名 | 医务科 | 信息科主任发起提名 → 分管院长批准 | `OperationLog: opType=21, 提名记录` |
| 试用审核人转正 | 信息科主任 | 分管院长确认 → 信息科专员执行转正操作 | `OperationLog: opType=22, 转正记录` |
| 审核人冻结 | 质控科/系统自动 | 自动触发（连续N次不合格）→ 分管院长确认 | `OperationLog: opType=23, 冻结记录` |
| 审核人解冻 | 审核人本人申请 | 分管院长审批 → 信息科专员执行 | `OperationLog: opType=24, 解冻记录` |
| 审核人离职/解聘 | 人事科 | 分管院长审批 → 信息科专员撤销链上权限 | `OperationLog: opType=25, 离职记录` |
| 证书到期未续（30天宽限期） | 系统自动 | 系统自动将签名降级为Phase 1留痕模式 | `OperationLog: opType=26, 降级记录` |
| 证书吊销后重新签发 | 审核人本人 | 分管院长审批 → 重新走Phase 2安装流程 | `OperationLog: opType=27, 重签记录` |

#### 2.5.3 审核人离职/转岗处理细则

1. **离职确认**：人事科发起离职流程 → 分管院长签批 → 链上记录离职确认
2. **权限回收**：信息科专员在链上撤销审核人地址，移除 `onlyReviewer` 权限
3. **审核待办清空**：系统自动将已分配给离职审核人的待办重新分配到同专业其他审核人
4. **历史记录不受影响**：离职审核人已签名存证的审核记录保持完整，不可修改，不可删除
5. **离职公示期**：离职审核人的身份在链上标记为 `inactive`，保留30天公示期，公示期后ID回收
6. **数据审计**：卫健委事后审计仍可按审核人ID和历史时间戳查询其所有审核记录

```solidity
function revokeReviewer(bytes32 _auditorId) external onlyMultiAdmin {
    require(hasApproval(msg.sender, "revoke_reviewer"), "Insufficient approval");
    reviewers[_auditorId].isActive = false;
    reviewers[_auditorId].revokedAt = block.timestamp;
    emit ReviewerRevoked(_auditorId, msg.sender, block.timestamp);
}
```

#### 2.5.4 证书到期/吊销的处理

- **证书到期前30天**：系统自动通知审核人续期，同时抄送信息科主任
- **宽限期30天**：到期后自动降级为Phase 1平台留痕模式，审核人仍可工作但签名模式变更
- **宽限期后仍未续期**：审核人权限冻结，进入离职流程
- **CA吊销**：审核人证书被CA吊销时立即冻结权限，不再有宽限期
- **Phase 1至Phase 2的唯一关联**：Phase 1的审核人ID和Phase 2的证书地址在`VersionRegistry`中建立映射关系，审计时可通过任一ID查询完整的审核人生命周期

#### 2.5.5 审批链上的责任归属

- 提名审核人的责任人是分管院长
- 转正/冻结/解冻审批链上的每步操作都在`OperationLog`中记录签名，不可事后否认
- 审核人离职后30天内，如出现该审核人签名记录的争议，分管院长和信息科主任为第一责任人


## 3. 数据健康检查层（排毒前置）

### 3.1 为什么需要

AI诊断引擎可能被攻击、数据被污染、置信度被篡改。信证链不信任引擎的输出——即使引擎是合作方，输出也必须经过健康检查才能进入审核漏斗。

> **我们等的就是他们引擎被黑的那一天。**
> —— 老王，2026-05-26

那一天一定会来。不是恶意，是概率。每年都有医院面临勒索软件攻击、AI模型投毒、数据插桩。

引擎被黑了，医院会找谁？不是找推想/联影，是找那个盖章签字的系统。

**信证链要在那一天来临时，已经是医院唯一信任的层。**

### 3.2 六项前置健康检查

AI诊断引擎推来的每条审核记录，在到达审核漏斗之前，经过以下六项检查：

| # | 检查项 | 检测对象 | 异常阈值 | 异常处置 |
|---|--------|---------|---------|---------|
| 1 | **格式完整性** | 五元组JSON结构 | 字段缺失、类型错误 | → 打回引擎，不入漏斗 |
| 2 | **置信度异常** | confidence字段 | 突增>10%（如 88%→99.9%） | → 标记降级，转人工复审 |
| 3 | **文献引用核验** | 引用文献DOI/PMID | 文献不存在或已被撤稿 | → 标记为不可验证证据 |
| 4 | **历史对比异常** | 同类病例今日vs昨日输出 | 分布偏差 > 3σ | → 通知管理员，提升抽审率至15% |
| 5 | **证据链一致性** | 诊断结论 ↔ 证据摘要 | 摘要不支持结论 | → 转人工复审 |
| 6 | **注入/污染检测** | 输入文本的字符级异常 | 隐藏控制字符、Base64编码嵌入侵袭模式 | → 拒绝受理，记录到 OperationLog |

### 3.3 检测来源与策略

| 检测项 | 检测方式 | 基线来源 |
|--------|---------|---------|
| 格式完整性 | 本地JSON Schema校验 | 五元组规范硬编码 |
| 置信度异常 | 滑动窗口均值对比 | 当前医院最近24小时的同类诊断记录 |
| 文献引用核验 | DOI/PMID实时查询（离线时查本地缓存库）| PubMed / Crossref 公开数据 + 本地缓存 |
| 历史对比异常 | 直方图 + Z-Score | 当日 vs 前7天 vs 同时间段上月 |
| 证据链一致性 | 自然语言规则引擎（关键词匹配+否定词检测） | 医学诊断逻辑规则库 |
| 注入/污染检测 | 正则 + 编码检测 | OWASP输入验证规则 + 自定义医疗场景规则 |

所有检测记录写入 `OperationLog` 合约，时间戳上链。

### 3.4 检测结果的应用

```
引擎推来诊断建议
    ↓
六项健康检查
    ↓
┌───────────────┐
   异常等级判定
   L0/L1/L2/L3
└───────────────┘
    ↓         ↓         ↓         ↓
 Level-0  Level-1   Level-2   Level-3
 自动进入  提升抽审率  强制人工  拒绝受理+
 审核漏斗  +风险等级  复审+     告警+
          上升一级   通知审核   通知信息科
                     负责人
```

#### 异常等级定义表（Level-0 ~ Level-3）

| 等级 | 触发条件 | 处置策略 |
|------|---------|---------|
| Level-0 全部通过 | 六项检查全部通过，无边界值 | 正常进入审核漏斗，按风险等级分流 |
| Level-1 轻度异常 | 1-2项检查出现边界值标记（置信度偏离正常范围但未超标、文献引用稍有模糊） | 该病例风险等级自动上升一级；记录OperationLog |
| Level-2 中度异常 | 置信度异常(偏差>10%) / 证据链一致性检查命中 / 历史对比异常(>3σ) | 强制人工审核队列（绕过自动分流）；通知审核负责人 |
| Level-3 重度异常 | 注入/污染检测命中 / 引擎身份校验失败 / 格式严重异常 | **拒绝受理** + 告警医院信息科 + 暂停该引擎后续推送 |

> 异常等级的细化解决两个问题：轻度异常不拒绝数据（避免误杀），但调整后续处理路径；重度异常的警报必须直达信息科，不能只记日志。

**优先级规则：健康检查异常等级 > 审计链R级分流。**

健康检查的异常等级判定独立于审计链的R级风险分流，且前者始终优先于后者：

| 健康检查结果 | R级分流原计划 | 实际处理路径 | 理由 |
|:-----------:|:------------:|:------------:|------|
| Level-0 | 任意(R1-R5) | 按原R级分流正常进行 | 无异常，信任引擎输出 |
| Level-1 | 任意(R1-R5) | 按原R级分流，但风险等级自动升一级(R1→R2等) | 轻度异常，不阻断但提高警惕 |
| Level-2 | R1(自动通过) | **覆盖为**人工审核 | 中度异常，自动通过不可接受 |
| Level-2 | R2-R5 | 按原R级分流 | 中度异常且本来就是人工审核路径 |
| Level-3 | 任意(R1-R5) | **拒绝受理** | 重度异常，无需进入审核漏斗 |

> **设计依据：** 健康检查检测的是引擎/数据层面的即时异常（注入、格式错误、置信度突变），审计链R级评估的是诊断内容的安全风险（误诊漏诊可能性）。前者更低层、更基础，因此优先级更高。

异常记录通过 `OperationLog` 存证，供后续审计追溯。

### 3.5 与审核漏斗的关系

```
        AI诊断引擎
            ↓
   第3章 数据健康检查层（排毒前置）
        ↓ 过滤异常输入
   第7章 审核漏斗（人机混合）
        ↓ 置信度分流
   第4章 签名 + 存证
        ↓
   FISCO BCOS 上链
```

**健康检查和审核漏斗是两层：**
- **排毒层**（第3章）：防引擎被黑/数据污染——拒绝坏数据进入审核
- **漏斗层**（第7章）：按置信度分流——高效分配审核人资源
- **存证层**（第4章）：上链锁定——不可篡改

三层互不依赖，每层可独立升级。

#### 3.5.1 排毒前置延迟契约

六项健康检查中的某些项目（如外部文献数据库交叉验证）可能涉及网络请求，存在延迟。如果延迟超出阈值，会影响下层审核漏斗的响应时间。

**最大允许延迟与超时降级策略：**

| 延迟区间 | 处理策略 | 对后续影响 |
|:--------:|---------|-----------|
| ≤ 3秒 | 正常执行全部六项检查 | 无影响，审核漏斗按时接收 |
| 3-5秒 | **跳过外部依赖检查**（如文献验证、PMID存在性校验），仅执行本地检查（注入检测、格式校验、置信度突变、历史对比） | 该病例标记为"健康检查不完整(跳过外部)"；审计链R级分流时自动+1级 |
| > 5秒 | **标记为"健康检查不完整(超时)"**，强制转人工审核队列 | 不信任自动处理，宁慢勿错 |

**设计说明：**
- L0-L1的本地检查（注入检测、格式校验）无网络依赖，延迟可控在毫秒级，通常不会超时
- L2（文献验证、历史对比）是延迟高发区，需结合缓存策略优化
- **超时不等于失败**——跳过外部检查的诊断建议仍然进入审核漏斗，只是降低了审计链的自动通过率

#### 3.5.2 三层交互的时序契约

```
排毒层完成 → 判断异常等级 → 优先级裁决（与R级分流）
                 ↓
        异常等级 = Level-0/1/2/3
                 ↓
        进入审核漏斗（或拒绝受理）
                 ↓
        审核漏斗做R级分流
                 ↓
        两个层级的分流结果按优先级规则合并
```

### 3.6 引擎源身份校验

> **问题：** 第3章检查的是数据内容，不是数据来源。任何人只要有信证链API地址就能伪造AI诊断建议推数据。

**解决：每个接入信证链的AI诊断引擎，必须有链上注册的身份。**

#### 3.6.1 引擎注册

信证链实例上线时，在 `VersionRegistry` 或新增的 `EngineRegistry` 合约中注册允许接入的引擎：

```solidity
struct EngineInfo {
    bytes32 engineId;         // 引擎唯一ID (SHA256)
    string name;              // 引擎厂商名 (如"推想科技")
    address walletAddress;    // 引擎签名钱包地址
    bytes publicKey;          // 引擎原始公钥 (ECDSA约64B，RSA约256B)。存储原始公钥而非哈希，因为验签需要原始公钥
    string apiEndpoint;       // 引擎API端点 (如"https://api.infervision.com/v1")
    bool isActive;            // 是否启用
    uint64 registeredAt;      // 注册时间戳
    uint64 lastHeartbeatAt;   // 最后心跳时间
}
```

#### 3.6.2 握手流程

```
AI诊断引擎
  ├── (1) 用私钥签名请求: SHA256(requestBody + nonce)
  ├── (2) 推数据到信证链API: { requestBody, signature, nonce, engineId }
  ├── (3) 信证链验证签名 → 校验引擎是否在 EngineRegistry 白名单中
  ├── (4) 通过 → 进入第3章排毒前置检测
  └── (5) 失败 → 拒绝受理，记录到 OperationLog
```

#### 3.6.3 引擎关键信息登记内容

| 登记项 | 说明 | 示例 |
|--------|------|------|
| 引擎ID | SHA256(机构代码+引擎名+部署时间) | `0x7a9b...` |
| 厂商名 | 人类可读 | 推想科技 / 联影智能 / 自研引擎 |
| 签名钱包 | 后续每笔数据推送需用此钱包签名 | `0x3f2a...` |
| 公钥 | 原始公钥，验签依据。存储原始公钥而非哈希，因验签需原始公钥 | `0x04a1...` (ECDSA约64B) |
| API端点 | 允许推送数据的来源URL | `https://api.infervision.com/v1` |
| 活跃状态 | 管理员可随时吊销 | `true/false` |

#### 3.6.4 数据推送校验流程

每条从引擎推来的审核记录，信证链执行：

```
收到请求 → 从请求头提取 engineId + signature + nonce
        ↓
查询 EngineRegistry → engineId 是否存在且 isActive = true
        ↓
用 engineId 的 publicKey 读取原始公钥
        ↓
验签: verify(requestBody, signature, publicKey)
        ↓
防重放: nonce 是否已使用 (缓存已用nonce, 5分钟内有效)
        ↓
全部通过 → 进入第3章排毒前置 (六项检测)
否则     → 拒绝 + 告警日志
```

#### 3.6.5 引擎吊销

当引擎被入侵、厂商合同终止、或引擎出现系统性异常时，管理员吊销引擎身份：

```solidity
function revokeEngine(bytes32 _engineId) external onlyAdmin {
    engines[_engineId].isActive = false;
    emit EngineRevoked(_engineId, block.timestamp);
}
```

吊销后该引擎的所有推送请求被信证链自动拒绝。

#### 3.6.6 引擎与智能体的关系

在信证链体系中，Engine 和 Agent（智能体实例）是两类不同节点：

```
引擎 (Engine)                           智能体 (Agent)
├── 产生数据                            ├── 处理数据
├── AI诊断引擎实例                       ├── 信证链运行实例
├── 链上注册 + 私钥签名推送               ├── 链上注册 + 审核记录打标
├── 数据来源方                           ├── 数据加工方
└── 被信证链校验                        └── 审计链标记
```

两者均在链上注册身份，职责分离，不能互相冒充。

---

## 4. FISCO BCOS存证对接

### 4.1 已有合约分析

当前 FISCO BCOS 已在 M4 Mini (10.0.0.2, ARM64 原生) 上部署的4个合约：

| 合约 | 定位 | 存储内容 | 查询能力 |
|------|------|---------|---------|
| `OperationLog` | 操作日志存证 | logId→LogEntry(opType, agentId, timestamp, targetHash, resultHash, extraData) | 按ID、Agent查询 |
| `DetectionHash` | 检测Hash存证 | detectionHash→DetectionRecord(chain, anchor, fileHash, confidence) | 按Hash、文件查询 |
| `VersionRegistry` | 版本记录 | binaryHash→Version(version, component, sourceHash, changeLog) | 按Hash、组件查询 |
| `WhiteHatReport` | 白帽报告注册 | reportId→Report(reporter, ipfsCid, proofHash, status) | 按ID、状态查询 |

### 4.2 复用 vs 新增决策

**决策结论：新增 `AuditRecord` 合约**，复用 `OperationLog` 记录审核事件流。

理由：
- 审核记录有独特的数据结构和业务语义，不适合硬塞进已有的4个合约
- `OperationLog` 的 `OpType` 枚举可扩展，用于记录审核操作事件（登录/查看/提交）
- `AuditRecord` 专项负责审核结论的不可变存证
- 保持单一职责原则

### 4.3 新增合约：`AuditRecord.sol`

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

    // --- 数据结构 ---

    struct AuditEntry {
        bytes32 auditId;             // SHA256(审核ID字符串)
        bytes32 suggestionId;        // SHA256(关联建议ID)
        bytes32 evidenceSnapshotHash; // 五元组证据链快照的SHA256
        address agentInstance;        // 经手智能体实例的节点地址
        bytes32 auditorId;            // SHA256(审核人ID)
        AuditConclusion conclusion;   // 审核结论
        bytes32 signatureHash;        // 审核人数字签名哈希
        SignaturePhase sigPhase;      // 签名阶段
        SigAlgorithm sigAlgorithm;    // 签名算法
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

    // 管理员地址（多签机制 — 2/3 签名阈值）
    address public adminA;
    address public adminB;
    address public adminC;
    uint8 public constant ADMIN_THRESHOLD = 2;  // 3名管理员中需至少2人签名才能执行管理操作

    // 紧急暂停标记（用于合约升级或安全事件）
    bool public emergencyPaused;

    // 延迟时间锁（秒）：transferAdmin等敏感操作需等待此时间后才能生效
    uint256 public constant TIMELOCK_DELAY = 86400;  // 24小时
    address public pendingNewAdmin;
    uint256 public pendingTimestamp;

    // --- 事件 ---

    event AuditRecorded(
        bytes32 indexed auditId,
        bytes32 indexed suggestionId,
        bytes32 indexed auditorId,
        AuditConclusion conclusion,
        SignaturePhase sigPhase,
        uint64 timestamp
    );

    event AdminProposed(address indexed proposer, address indexed newAdmin, uint256 effectiveAfter);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    event AdminApproval(address indexed approver, address indexed newAdmin, uint256 approvalCount);
    event EmergencyPaused(address indexed caller);
    event EmergencyUnpaused(address indexed caller);

    // 管理操作批准映射
    mapping(bytes32 => mapping(address => bool)) public adminApprovals;

    // --- 修饰符 ---

    modifier onlyAdmin() {
        require(msg.sender == adminA || msg.sender == adminB || msg.sender == adminC, "Only admin");
        _;
    }

    modifier notPaused() {
        require(!emergencyPaused, "Contract paused");
        _;
    }

    modifier auditNotExists(bytes32 auditId) {
        require(!auditEntries[auditId].exists, "Audit already recorded");
        _;
    }

    // --- 构造函数 ---

    constructor(address _adminA, address _adminB, address _adminC) {
        require(_adminA != address(0) && _adminB != address(0) && _adminC != address(0), "Invalid admin");
        adminA = _adminA;
        adminB = _adminB;
        adminC = _adminC;
        emergencyPaused = false;
    }

    // --- 紧急暂停 ---

    function emergencyPause() external onlyAdmin {
        emergencyPaused = true;
        emit EmergencyPaused(msg.sender);
    }

    function emergencyUnpause() external onlyAdmin {
        emergencyPaused = false;
        emit EmergencyUnpaused(msg.sender);
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
                          conclusion, sigPhase, ts);
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

    /**
     * @notice 提议替换 adminA（多签第一阶段）
     * @dev 3名管理员中任一人可发起，发起者自动算一票。需 2/3 批准 + 24h 时间锁后方可执行
     */
    function proposeNewAdmin(address newAdmin) external onlyAdmin notPaused {
        require(newAdmin != address(0), "Invalid address");
        pendingNewAdmin = newAdmin;
        pendingTimestamp = block.timestamp + TIMELOCK_DELAY;
        emit AdminProposed(msg.sender, newAdmin, pendingTimestamp);
    }

    /**
     * @notice 批准 admin 替换提议（多签第二阶段）
     * @dev 需要至少累计 2/3 票 + 24小时时间锁已过
     */
    function approveNewAdmin(address newAdmin) external onlyAdmin notPaused {
        require(newAdmin == pendingNewAdmin, "Mismatched proposal");
        require(block.timestamp >= pendingTimestamp, "Timelock not expired");
        require(!adminApprovals[newAdmin][msg.sender], "Already approved");
        adminApprovals[newAdmin][msg.sender] = true;

        // 统计赞成票
        uint256 count;
        if (adminApprovals[newAdmin][adminA]) count++;
        if (adminApprovals[newAdmin][adminB]) count++;
        if (adminApprovals[newAdmin][adminC]) count++;
        emit AdminApproval(msg.sender, newAdmin, count);

        require(count >= ADMIN_THRESHOLD, "Insufficient approvals (need 2/3)");

        address oldAdmin = adminA;
        adminA = newAdmin;
        pendingNewAdmin = address(0);
        pendingTimestamp = 0;
        emit AdminChanged(oldAdmin, newAdmin);
    }
}
```

### 4.4 OperationLog OpType 扩展

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

### 4.5 链上存证 vs 链下存储取舍建议

| 维度 | 链上 (FISCO BCOS) | 链下 (MySQL/IPFS/MinIO) | 建议 |
|------|-------------------|------------------------|------|
| **完整JSON** | ❌ Gas/存储成本高 | ✅ 经济 | 链下(MySQL) |
| **证据链快照** | ❌ 同上 | ✅ | 链下(MySQL)，链上仅存SHA256 |
| **审核结论** | ✅ 核心，需不可篡改 | ⚠️ 可被DBA修改 | **链上** |
| **签名哈希** | ✅ 同上 | ⚠️ | **链上** |
| **审核人身份** | ✅ | ⚠️ | **链上（哈希后）** |
| **操作日志** | ✅ 审计轨迹 | ⚠️ | **链上**(OperationLog) |
| **文献全文** | ❌ | ✅ IPFS/MinIO | 链下(IPFS) |
| **时间戳** | ✅ 医院机房本地服务器时间 | 医院等保机房负责时间校准 | **链上** |
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


## 5. 审核界面原型描述

### 5.1 布局结构

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

### 5.2 交互规则

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

### 5.3 审核提交完整流程

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

## 6. 中美双法规合规映射

### 6.1 FDA CDS Criterion 4 映射

FDA 对医疗器械软件中的临床决策支持(CDS)软件采用四准则判断是否需要监管审查。Criterion 4 要求：

> **FDA CDS Criterion 4**: The software function enables the healthcare professional to independently review the basis for the recommendations, so that it is not the intention that the healthcare professional rely primarily on the software's recommendations to make a clinical diagnosis or treatment decision.

**映射到本方案**：

| FDA要求要点 | 本方案实现 |
|------------|----------|
| 执业医师能独立审查建议依据 | ✅ 五元组证据链完整展示（数据源+文献+推理路径） |
| 医师不主要依赖软件建议 | ✅ 审核人必须主动点击通过/驳回/需修改，不能自动通过 |
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

### 6.2 NMPA 医疗器械软件审查映射

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

## 7. 实施路径

### 7.1 阶段规划

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

### 7.2 依赖关系

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

## 8. 部署要求

### 8.1 服务器要求

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

### 8.2 部署形态

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

### 8.3 等保适配

- 作为医院信息系统的外挂模块，随医院信息系统整体过等保三级
- 审核记录的链上存证天然满足等保【数据完整性】要求
- 审核人双因子认证满足等保【身份鉴别】要求
- 操作日志全量留存满足等保【安全审计】要求
- **智能体不进患者数据层**，无需额外数据安全评审

### 8.4 审核运营模式：人机混合漏斗

#### 7.4.1 核心模型

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
- 医院因财务流程延迟续费导致证书过期 → 审核人自动降级为Phase 1平台留痕模式，审核照常进行，不中断业务
- 惠迈应在证书到期前30天通过系统告警通知医院信息科

#### 7.4.6 智能体与审核人关系

- **智能体 = 路由器**：不碰诊断，只做校验、存证、路由
- **审核人 = 路由后的专家**：通过智能体签名上链
- **100个审核人 ≠ 挂载100个智能体**：全连接同一个智能体实例

### 8.5 供应链依赖

```
惠迈智能体二进制         — 本地编译，SHA256上链
FISCO BCOS SDK          — 开源审计 + 版本锁定
PostgreSQL / SQLite     — 开源/本地部署
React前端               — 静态文件，无外部依赖
CFCA PKI SDK (Phase 2) — 供应商审计 + 哈希校验
```

所有组件均可脱网运行，不依赖外部云服务。

---


### 8.6 运维期事件响应流程

> 部署阶段（8.1-8.5）写的是"系统装好"。本节写的是"系统跑起来之后出事了怎么办"。

#### 8.6.1 值班架构

**建议值班矩阵（初期）**：

| 时段 | 信息科（一级响应） | 惠迈（二级响应） |
|------|------------------|-----------------|
| 工作日 08:00-18:00 | 信息科专员在线 | 惠迈运维远程待命 |
| 非工作时间/节假日 | 信息科主任手机接警 | 惠迈运维手机接警 |

**扩展期（≥3家医院）**：
- 惠迈组建运维中心（NOC），7×24小时监控各院区信证链节点状态
- 每家医院保留一级响应——即信息科作为现场第一应急人

#### 8.6.2 事件分级与响应时效

| 级别 | 定义 | 示例 | 响应时效 |
|------|------|------|---------|
| P0（重大） | 审核功能完全中断 | FISCO BCOS 节点崩溃/服务器宕机 | 信息科30分钟内到场 → 惠迈1小时内远程介入 |
| P1（严重） | 部分审核人无法签名 | 证书系统故障/审核界面不可用 | 信息科2小时内响应 → 惠迈4小时内修复 |
| P2（一般） | 单功能异常不影响核心流程 | 告警通知延迟/查询接口慢 | 信息科下一个工作日处理 |
| P3（轻微） | 可用性不受影响 | 日志记录格式微调/界面文案错误 | 下次版本更新时处理 |

#### 8.6.3 故障恢复流程

**FISCO BCOS 节点崩溃恢复**：

```
1. 信息科发现审核界面不可用（或接到告警）
2. 检查：服务器是否运行？`systemctl status fisco-bcos`
3. 如服务未运行：`systemctl restart fisco-bcos`
4. 如重启失败：检查日志 → `/var/log/fisco-bcos/error.log`
5. 如数据损坏：从备份恢复
   ├── 备份位置：/opt/huimai/backup/fisco-bcos/
   ├── 全量备份：每日00:00自动备份（保留最近7天）
   ├── 增量备份：每4小时一次（保留最近48小时）
   └── 恢复命令：`fisco-bcos --restore /opt/huimai/backup/fisco-bcos/YYYY-MM-DD/`
6. 如无法恢复 → 联系惠迈运维远程介入
7. 恢复后：验证链上数据完整性 → 通知审核人恢复工作
```

**PostgreSQL 数据库恢复**：

```
1. 检查服务：`systemctl status postgresql`
2. 重启：`systemctl restart postgresql`
3. 如数据损坏：从备份恢复
   ├── 备份位置：/opt/huimai/backup/postgresql/
   ├── 全量备份：每日00:00（保留30天）
   └── 恢复命令：`pg_restore -d medtrustchain /opt/huimai/backup/postgresql/YYYY-MM-DD.dump`
```

**服务器宕机恢复**：

```
1. 联系医院机房管理员，确认服务器硬件状态
2. 如硬件损坏 → 启动备用服务器（建议在医院机房部署双机冷备）
3. 备用服务器上安装信证链 → 从备份恢复链数据 + 数据库
4. 验证链上数据与数据库一致（Merkle Root 比对）
5. 恢复审核服务
```

#### 8.6.4 备份策略

| 数据 | 备份方式 | 频率 | 保留期 | 存储位置 |
|------|---------|------|--------|---------|
| FISCO BCOS 链数据 | 全量 + 增量 | 全量每日00:00，增量每4小时 | 全量7天，增量48小时 | 同服务器 /opt/huimai/backup/ |
| PostgreSQL 数据库 | 全量 | 每日00:00 | 30天 | 同服务器 /opt/huimai/backup/ |
| 审核人证书（Phase 2） | 全量 | 每次签发后自动备份 | 永久 | 离线U盘（信息科保管）+ 惠运维加密存档 |
| 系统配置 | 全量 | 每次变更后自动备份 | 保留最近10版本 | 同服务器 /opt/huimai/config-backup/ |

#### 8.6.5 告警通知

| 告警事件 | 通知方式 | 通知对象 | 触发条件 |
|---------|---------|---------|---------|
| 节点离线 | 短信 + 微信/企业微信 | 信息科专员 + 惠迈运维 | 节点心跳中断 > 5分钟 |
| 审核积压超过阈值 | 邮件 + 系统内通知 | 审核组长 | 待审核队列 > 50条 且 未分配超过30分钟 |
| 异常数据推送（见3.2） | 系统告警面板 | 信息科专员 + 分管院长 | 六项检测任一触发"重度异常" |
| 引擎签名失败（见3.6.4） | 系统日志 | 信息科专员 | 连续3次握手失败 |
| 管理员操作 | OperationLog 链上记录 | 全员（只读） | 如4.6.5分层审批体系中的任意操作 |
| 证书到期前30天 | 邮件 | 审核人本人 | 证书到期前30天/15天/7天/1天各提醒一次 |

#### 8.6.6 值班交接流程

```
信息科专员 A（下班）
  ├── 填写值班记录表：当日事件、处理状态、待办事项
  ├── 确认：所有P0/P1事件已闭环或已交接
  └── 通知 → 信息科专员 B（接班确认）
  ↓
信息科专员 B（接班）
  ├── 确认系统状态正常
  ├── 确认所有告警通道正常
  └── 值班开始
```

每日值班记录归档至信证链 `OperationLog`，不做书面记录（防止纸质丢失）。


## 9. 跨院区扩展性设计

### 9.1 设计前提

「全球医生」的初始部署为**单院区独立链**模式：
- 每家医院部署一台服务器（兼容现有医院IT资产）
- 服务器上运行 FISCO BCOS 节点 + 惠迈智能体 + 审核界面
- 审核记录链上存证，数据**不出医院内网**
- 等保评审按单院区单独过（等保三级）

但系统设计需要预判院区互认——当华山医院与中日友好医院需要互相认可对方的审核结论时，架构如何演进。

### 9.2 跨院扩展的四级模型与选型路径

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

### 9.3 第一级：链分离 · 互认标准

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

### 9.4 第二级：跨院联盟链（技术可行，合规待确认）

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

### 9.5 第三级：超级见证节点 + Merkle Root 汇聚（中期推荐）

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

### 9.x （置于 9.5 与 9.6 之间）数据隐私熔断设计

#### 设计原则：**数据不出院，出院的只有哈希。即使 Leaf 被反推，原文仍安全。**

#### 9.x.1 熔断：叶子节点的内容不是原文，是哈希

Merkle 树的叶子节点内容不是审核记录 JSON 原文，而是 `SHA256(evidence_snapshot_hash || recordId || timestamp)`：

```
叶子节点内容          = SHA256(evidence_snapshot_hash || recordId || timestamp)
不可逆推原文          = ✅ SHA256 是单向函数
即使暴力枚举还原叶子  = 拿到的是哈希，不是原文
原文在何处            = 各院区 PostgreSQL 链下存储，永不跨院传出
```

即使见证节点获得全部 Merkle 树叶子的哈希，也读不到任何审核记录原文。

#### 9.x.2 熔断验证流程

```
A医院（华山）                          B医院（中日）
    │                                       │
    │ 审核记录原文 ← PostgreSQL              │
    │ SHA256(原文) ← 叶子节点                 │
    │ Merkle Root ← SHA256(所有叶子)          │
    │ 将 Merkle Root 推给见证节点              │
    │        ────────── Merkle Root ─────────→ 见证节点存证 Merkle Root
    │                                       │
    │ B医院需要验证A医院的一条审核记录          │
    │        ←── 请求验证 (传递审核记录ID) ─────│
    │                                        │
    │ B医院自己知道审核记录原文                │
    │ B医院计算 SHA256(原文) → leafHash       │
    │ B医院从见证节点获取 Merkle Root         │
    │ B医院从A医院获取 Merkle Path            │
    │        ←── Merkle Path (不含原文) ──────│
    │                                        │
    │ B医院验证: leafHash + Merkle Path = Root?│
    │ 通过 ✅ "这条记录确实在A医院的链上"       │
    │ 但不知道原文                            │
```

**B医院验证时只看哈希，不看原文。拿到 Merkle Path 也读不到任何临床数据。**

#### 9.x.3 熔断：见证节点不得反推叶子

见证节点只存 Merkle Root，不存叶子。但即使见证节点通过某种途径获取了部分叶子：

| 场景 | 风险 | 缓解 |
|------|------|------|
| 见证节点拥有全部叶子哈希 | 可统计该医院的审核总量 | 审核总量是合规公开信息，不是隐私 |
| 见证节点试图暴力枚举反推原文 | 单向函数不可逆，推不出 | SHA256 保证计算不可行 |
| 见证节点与外部攻击者合谋 | 只能拿到哈希，原文在院内 | 原文不出院是物理隔离 |
| 攻击者获取 Merkle Root + 已知某个审核的 evidence hash | 可确认该审核确实在链上 | 确认存在性本身是验证功能，不是泄漏 |

**结论：** 技术上，SHA256 保证叶子不可逆；制度上，见证节点的《节点协议》明确禁止反推尝试，违者取消见证节点资格。数据隐私的最终防线是"原文不出院"的物理隔离。

#### 9.x.4 熔断触发条件与处置

| 触发条件 | 检测方式 | 处置 |
|---------|---------|------|
| 见证节点在单日内对同一 Root 请求 Merkle Path 超过 100 次 | OperationLog 统计 | 自动告警通知医院管理员和见证节点管理者，临时冻结该节点 24 小时 |
| 发现 Merkle Root 被非授权节点持有 | VersionRegistry 查询记录 | 追溯链上记录，定位泄漏源头 |
| 攻击者批量尝试 SHA256 爆破叶子 | 不构成实际威胁（见 9.x.3） | 无需处置 |

#### 9.x.5 熔断设计总纲

> **跨院验证时，B 医院只输出：** SHA256(原文) + Merkle Path  
> **跨院验证时，B 医院不输出：** 审核记录原文、五元组原文、审核人身份原文  
> **原子验证原则：** 每一笔跨院验证请求独立处理，不批量导出，不留缓存

---



---

### 9.6 第四级：零知识跨链验证（远期实验）

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

### 9.7 数据结构扩展点预留

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

### 9.8 部署建议汇总

| 阶段 | 时间线 | 操作 | 等保复杂度 |
|------|--------|------|-----------|
| Phase 0 | 现在 | 单院区独立链，单节点部署 | 低（单系统等保三级） |
| Phase 1 | 前6个月 | 多院区独立链 + 审核格式标准化（第一级） | 低 |
| Phase 2 | 6-18个月 | 卫健委/第三方超级见证节点上线（第三级） | 中（政务云节点过等保） |
| Phase 3 | 看政策 | 视政策环境和需求进入第二级（跨院联盟链） | 高 |
| Phase 4 | 远期储备 | ZKP跨链验证，视技术成熟度决定 | 待定 |

**最稳妥路径**：Phase 0 → Phase 1 → Phase 2。第三级（超级见证节点）的价值在卫健委参与时最大，值得优先推动。

---


## 10. 附录

### 10.1 JSON规范序列化算法

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

### 10.2 供应链安全考虑

```
审核人签名模块的依赖链审查：

外部依赖                      内部审计
═══════                      ══════
CFCA SDK  ← 供应商审计 + 哈希校验    → 本地编译 + 二进制哈希上链
FISCO BCOS SDK → 开源审计 + 版本锁定  → VersionRegistry记录版本
OpenSSL库      → 版本追踪             → CVE监控
2FA短信网关    → SLA合同              → 失败率监控
```

### 10.3 已知风险与缓解

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|---------|
| M4 Mini硬件故障 | 低 | 高 | FISCO BCOS多节点部署（至少3节点），M4 Mini为单节点需补充冗余 |
| CA证书吊销延迟 | 中 | 中 | 实时OCSP查询 + CRL缓存 + 吊销时触发拒绝审核 |
| 2FA短信延迟/丢失 | 中 | 低 | TOTP备选通道 + 审核会话超时延长至30分钟 |
| 证据链JSON过大 | 低 | 中 | 限制文献原文摘要≤500字，正文引用IPFS CID |
| 合约升级 | 低 | 高 | 使用代理模式(可升级合约)，但新合约必须记录迁移事件 |
| 量子计算威胁 | 极低 | 远期 | Phase 3预留后量子密码(PQC)升级路径 |

### 10.4 术语表

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