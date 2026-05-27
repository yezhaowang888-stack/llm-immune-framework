// SPDX-License-Identifier: Apache-2.0
// 
// huimai-agent-framework — Audit Chain Demo Contract
// Version: 1.0 (Demo Release)
// WARNING: This is a reference implementation. Parameter values are for
// demonstration purposes only. Deployers MUST configure production values
// via governance before going live.
//
// Built from: cn002-audit-chain-spec-20260526.md v1.1

pragma solidity ^0.8.20;

// ============================================================================
//  AuditChain_Demo
//  惠迈智能体框架 · 审计链合约（开源演示版）
// ============================================================================

contract AuditChain_Demo {

    // ─────── Enums ───────

    /// @notice 审核结论
    enum AuditConclusion {
        APPROVED,          // 0: 通过
        REJECTED,          // 1: 驳回
        REVISION_NEEDED    // 2: 需修改
    }

    /// @notice 签名阶段
    enum SignaturePhase {
        PLATFORM,          // 0: Phase 1 平台留痕
        PKI                // 1: Phase 2 PKI证书签名
    }

    /// @notice 签名算法
    enum SigAlgorithm {
        SHA256,            // 0: 纯SHA256哈希 (Phase 1)
        SHA256WITHRSA,     // 1: SHA256+RSA (Phase 2)
        SHA256WITHECDSA    // 2: SHA256+ECDSA (Phase 2备用)
    }

    /// @notice 审计类型
    enum AuditType {
        PRODUCTION,        // 0: 生产审核
        OVERSIGHT,         // 1: 监督审核
        CERT_DEGRADATION   // 2: 证书降级事件
    }

    // ─────── Structs ───────

    /// @notice 审核记录
    struct AuditEntry {
        bytes32 auditId;               // SHA256(审核ID字符串)
        bytes32 suggestionId;          // SHA256(关联建议ID)
        bytes32 evidenceSnapshotHash;  // 五元组证据链快照的SHA256
        bytes32 auditorId;             // SHA256(审核人ID)
        AuditConclusion conclusion;    // 审核结论
        bytes32 signatureHash;         // 审核人数字签名哈希
        SignaturePhase sigPhase;       // 签名阶段
        SigAlgorithm sigAlgorithm;     // 签名算法
        AuditType auditType;           // 审计类型
        uint64 timestamp;              // 审核时间戳
        bytes32 merkleRoot;            // 所属Merkle批次的根Hash（延迟填写）
        bool exists;                   // 防覆盖标记
        string reason;                 // 备注/降级原因（CERT_DEGRADATION时填写自由文字）
    }

    // ─────── Storage ───────

    /// @notice 管理员列表（三签制：至少2人同意才可执行管理操作）
    address[3] public adminAddresses;
    /// @notice 当前有效管理员人数（部署时为0，首次配置后设为3）
    uint8 public adminCount;
    /// @notice 审核记录存储
    mapping(bytes32 => AuditEntry) public auditEntries;
    /// @notice 紧急暂停开关
    bool public emergencyPaused;

    // ─────── Time-lock ───────
    /// @notice 时间锁持续时间（24小时 = 86400秒）
    uint256 public constant TIME_LOCK_DURATION = 86400;

    // ─────── Multi-sig & Pause Proposal ───────
    /// @notice 管理员替换提案
    struct PendingAdminProposal {
        uint8 oldIndex;
        address newAdmin;
        uint8 approvals;
        bool executed;
        uint64 proposedAt;
    }
    PendingAdminProposal public pendingAdminProposal;
    /// @notice 去重映射：proposalId => admin => 是否已投票
    mapping(bytes32 => mapping(address => bool)) public adminApproved;
    /// @notice 紧急暂停提案
    struct PauseProposal {
        bool pause;
        uint8 approvals;
        bool executed;
        uint64 proposedAt;
    }
    PauseProposal public pendingPauseProposal;
    /// @notice 暂停提案投票去重
    mapping(bytes32 => mapping(address => bool)) public pauseApproved;
    /// @notice 当前暂停提案ID（每次暂停提案覆盖后更新）
    bytes32 public currentPauseProposalId;

    // ─────── Events ───────

    /// @notice 审核记录事件
    event AuditRecorded(
        bytes32 indexed auditId,
        bytes32 indexed suggestionId,
        bytes32 indexed auditorId,
        AuditConclusion conclusion,
        SignaturePhase sigPhase,
        AuditType auditType,
        uint64 timestamp
    );

    /// @notice 管理员替换提案事件
    event AdminProposed(uint8 indexed oldIndex, address indexed newAdmin, uint64 proposedAt);

    /// @notice 暂停提案事件
    event PauseProposed(bool pause, uint64 proposedAt);

    /// @notice 审核记录事件
        bytes32 indexed auditId,
        bytes32 indexed suggestionId,
        bytes32 indexed auditorId,
        AuditConclusion conclusion,
        SignaturePhase sigPhase,
        AuditType auditType,
        uint64 timestamp
    );

    /// @notice 管理员变更事件
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin, uint256 indexed actionType);

    /// @notice 证书降级事件
    event CertificateDegradation(
        bytes32 indexed auditorId,
        string reason,
        uint64 timestamp
    );

    /// @notice 证书恢复事件
    event CertificateRestoration(
        bytes32 indexed auditorId,
        uint64 timestamp
    );

    /// @notice 暂停状态变更
    event PauseToggled(bool paused, address indexed operator, uint64 timestamp);

    /// @notice 暂停提案通过事件
    event PauseExecuted(bool pause, address indexed operator, uint64 timestamp);

    // ─────── Modifiers ───────

    /// @notice 仅管理员
    modifier onlyAdmin() {
        bool isAdmin = false;
        for (uint8 i = 0; i < adminCount; i++) {
            if (msg.sender == adminAddresses[i]) {
                isAdmin = true;
                break;
            }
        }
        require(isAdmin, "AUDIT_CHAIN: only admin");
        _;
    }

    /// @notice 审核记录不存在（防覆盖）
    modifier auditNotExists(bytes32 auditId) {
        require(!auditEntries[auditId].exists, "AUDIT_CHAIN: audit already exists");
        _;
    }

    /// @notice 暂停检查
    modifier notPaused() {
        require(!emergencyPaused, "AUDIT_CHAIN: contract is paused");
        _;
    }

    // ─────── Constructor ───────

    constructor() {
        // 部署时无管理员——由首次配置流程设置
        // 默认 emergencyPaused = false（Demo版不做强制暂停）
        // 生产部署时应在构造函数中传入初始管理员列表
        adminCount = 0;
        emergencyPaused = false;
    }

    // ─────── Admin Management ───────

    /// @notice 首次设置管理员列表（仅可调用一次）
    function initializeAdmins(address[3] calldata _admins) external {
        require(adminCount == 0, "AUDIT_CHAIN: admins already initialized");
        require(_admins[0] != address(0) && _admins[1] != address(0) && _admins[2] != address(0), "AUDIT_CHAIN: zero address");
        for (uint8 i = 0; i < 3; i++) {
            adminAddresses[i] = _admins[i];
        }
        adminCount = 3;
    }

    /// @notice 管理员替换流程——提案阶段（含24h时间锁）
    /// @param _oldIndex 被替换的管理员索引（0-2）
    /// @param _newAdmin 新管理员地址
    function proposeNewAdmin(uint8 _oldIndex, address _newAdmin) external onlyAdmin {
        require(_oldIndex < 3, "AUDIT_CHAIN: invalid index");
        require(_newAdmin != address(0), "AUDIT_CHAIN: zero address");
        require(adminAddresses[_oldIndex] != _newAdmin, "AUDIT_CHAIN: same address");

        bytes32 proposalId = keccak256(abi.encodePacked(_oldIndex, _newAdmin, block.timestamp));
        currentPauseProposalId = proposalId; // 复用ID存储，用于去重

        pendingAdminProposal = PendingAdminProposal({
            oldIndex: _oldIndex,
            newAdmin: _newAdmin,
            approvals: 0,
            executed: false,
            proposedAt: uint64(block.timestamp)
        });

        emit AdminProposed(_oldIndex, _newAdmin, uint64(block.timestamp));
    }

    /// @notice 管理员替换流程——批准阶段（需≥2人批准 + 24h时间锁 + 去重）
    function approveNewAdmin() external onlyAdmin {
        require(pendingAdminProposal.newAdmin != address(0), "AUDIT_CHAIN: no pending proposal");
        require(!pendingAdminProposal.executed, "AUDIT_CHAIN: already executed");
        require(block.timestamp >= pendingAdminProposal.proposedAt + TIME_LOCK_DURATION, "AUDIT_CHAIN: time lock not expired");

        bytes32 proposalId = keccak256(
            abi.encodePacked(
                pendingAdminProposal.oldIndex,
                pendingAdminProposal.newAdmin,
                pendingAdminProposal.proposedAt
            )
        );
        require(!adminApproved[proposalId][msg.sender], "AUDIT_CHAIN: already approved");
        adminApproved[proposalId][msg.sender] = true;

        pendingAdminProposal.approvals++;

        if (pendingAdminProposal.approvals >= 2) {
            address oldAdmin = adminAddresses[pendingAdminProposal.oldIndex];
            adminAddresses[pendingAdminProposal.oldIndex] = pendingAdminProposal.newAdmin;
            pendingAdminProposal.executed = true;
            emit AdminChanged(oldAdmin, pendingAdminProposal.newAdmin, 1);
        }
    }

    // ─────── Emergency Pause (两阶段多签) ───────

    /// @notice 提案紧急暂停（阶段一：发起投票，需等待24h时间锁）
    function proposePause() external onlyAdmin {
        require(!emergencyPaused, "AUDIT_CHAIN: already paused");
        pendingPauseProposal = PauseProposal({
            pause: true,
            approvals: 0,
            executed: false,
            proposedAt: uint64(block.timestamp)
        });
        currentPauseProposalId = keccak256(abi.encodePacked("pause", block.timestamp));
        emit PauseProposed(true, uint64(block.timestamp));
    }

    /// @notice 执行紧急暂停（阶段二：投票 + 24h时间锁）
    function approvePause() external onlyAdmin {
        require(!emergencyPaused, "AUDIT_CHAIN: already paused");
        require(!pendingPauseProposal.executed, "AUDIT_CHAIN: pause already executed");
        require(block.timestamp >= pendingPauseProposal.proposedAt + TIME_LOCK_DURATION, "AUDIT_CHAIN: time lock not expired");
        require(!pauseApproved[currentPauseProposalId][msg.sender], "AUDIT_CHAIN: already approved");
        pauseApproved[currentPauseProposalId][msg.sender] = true;

        pendingPauseProposal.approvals++;

        if (pendingPauseProposal.approvals >= 2) {
            emergencyPaused = true;
            pendingPauseProposal.executed = true;
            emit PauseToggled(true, msg.sender, uint64(block.timestamp));
            emit PauseExecuted(true, msg.sender, uint64(block.timestamp));
        }
    }

    /// @notice 提案解除暂停（阶段一：发起投票）
    function proposeUnpause() external onlyAdmin {
        require(emergencyPaused, "AUDIT_CHAIN: not paused");
        pendingPauseProposal = PauseProposal({
            pause: false,
            approvals: 0,
            executed: false,
            proposedAt: uint64(block.timestamp)
        });
        currentPauseProposalId = keccak256(abi.encodePacked("unpause", block.timestamp));
        emit PauseProposed(false, uint64(block.timestamp));
    }

    /// @notice 执行解除暂停（阶段二：投票 + 24h时间锁）
    function approveUnpause() external onlyAdmin {
        require(emergencyPaused, "AUDIT_CHAIN: not paused");
        require(!pendingPauseProposal.executed, "AUDIT_CHAIN: unpause already executed");
        require(block.timestamp >= pendingPauseProposal.proposedAt + TIME_LOCK_DURATION, "AUDIT_CHAIN: time lock not expired");
        require(!pauseApproved[currentPauseProposalId][msg.sender], "AUDIT_CHAIN: already approved");
        pauseApproved[currentPauseProposalId][msg.sender] = true;

        pendingPauseProposal.approvals++;

        if (pendingPauseProposal.approvals >= 2) {
            emergencyPaused = false;
            pendingPauseProposal.executed = true;
            emit PauseToggled(false, msg.sender, uint64(block.timestamp));
            emit PauseExecuted(false, msg.sender, uint64(block.timestamp));
        }
    }

    // ─────── Core Audit Recording ───────

    /// @notice 记录一条审核事件
    /// @param _suggestionId 关联诊断建议ID
    /// @param _evidenceSnapshotHash 证据快照哈希
    /// @param _auditorId 审核人ID
    /// @param _conclusion 审核结论
    /// @param _signatureHash 签名哈希
    /// @param _sigPhase 签名阶段
    /// @param _sigAlgorithm 签名算法
    /// @param _auditType 审计类型
    /// @param _reason 备注（CERT_DEGRADATION时填写原因）
    function recordAudit(
        bytes32 _suggestionId,
        bytes32 _evidenceSnapshotHash,
        bytes32 _auditorId,
        AuditConclusion _conclusion,
        bytes32 _signatureHash,
        SignaturePhase _sigPhase,
        SigAlgorithm _sigAlgorithm,
        AuditType _auditType,
        string calldata _reason
    ) external onlyAdmin notPaused returns (bytes32) {

        bytes32 auditId = keccak256(abi.encodePacked(_suggestionId, _auditorId, block.timestamp, _reason));
        require(!auditEntries[auditId].exists, "AUDIT_CHAIN: audit already exists");
        uint64 ts = uint64(block.timestamp);

        auditEntries[auditId] = AuditEntry({
            auditId: auditId,
            suggestionId: _suggestionId,
            evidenceSnapshotHash: _evidenceSnapshotHash,
            auditorId: _auditorId,
            conclusion: _conclusion,
            signatureHash: _signatureHash,
            sigPhase: _sigPhase,
            sigAlgorithm: _sigAlgorithm,
            auditType: _auditType,
            timestamp: ts,
            merkleRoot: bytes32(0),
            exists: true,
            reason: _reason
        });

        emit AuditRecorded(auditId, _suggestionId, _auditorId, _conclusion, _sigPhase, _auditType, ts);

        // 如果是证书降级事件，额外发射专用事件
        if (_auditType == AuditType.CERT_DEGRADATION) {
            emit CertificateDegradation(_auditorId, _reason, ts);
        }

        return auditId;
    }

    // ─────── Verification ───────

    /// @notice 验证一条审核记录是否存在
    function verifyAudit(bytes32 _auditId) external view returns (bool) {
        return auditEntries[_auditId].exists;
    }

    /// @notice 读取审核记录（公开查询接口）
    function getAudit(bytes32 _auditId) external view returns (AuditEntry memory) {
        require(auditEntries[_auditId].exists, "AUDIT_CHAIN: audit not found");
        return auditEntries[_auditId];
    }

    // ─────── Merkle Batch Operations ───────

    /// @notice 批量设置Merkle根（延迟填写）
    /// @param _auditId 审计ID
    /// @param _merkleRoot Merkle树的根哈希
    function setMerkleRoot(bytes32 _auditId, bytes32 _merkleRoot) external onlyAdmin notPaused {
        require(auditEntries[_auditId].exists, "AUDIT_CHAIN: audit not found");
        require(auditEntries[_auditId].merkleRoot == bytes32(0), "AUDIT_CHAIN: merkle root already set");
        auditEntries[_auditId].merkleRoot = _merkleRoot;
    }
}
