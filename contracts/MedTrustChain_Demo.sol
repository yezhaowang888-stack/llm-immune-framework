// SPDX-License-Identifier: Apache-2.0
// 
// huimai-agent-framework — MedTrustChain (Engine Registry) Demo Contract
// Version: 1.0 (Demo Release)
// WARNING: This is a reference implementation. Parameter values are for
// demonstration purposes only. Deployers MUST configure production values
// via governance before going live.
//
// Built from: medtrustchain-spec-20260526.md v1.1

pragma solidity ^0.8.20;

// ============================================================================
//  MedTrustChain_Demo
//  惠迈智能体框架 · 信证链（引擎登记+健康检查）合约（开源演示版）
// ============================================================================

contract MedTrustChain_Demo {

    // ─────── Enums ───────

    /// @notice 健康检查异常等级
    enum HealthCheckLevel {
        CLEAR,              // Level-0: 无异常
        MINOR,              // Level-1: 轻度异常
        MODERATE,           // Level-2: 中度异常
        CRITICAL            // Level-3: 重度异常
    }

    /// @notice 引擎验证状态
    enum EngineStatus {
        PENDING,
        VERIFIED,
        SUSPENDED,
        REVOKED
    }

    // ─────── Structs ───────

    /// @notice 引擎注册信息
    struct EngineInfo {
        bytes32 engineId;             // SHA256(引擎名称+注册时间)
        string  name;                 // 引擎名称
        bytes   publicKey;            // 引擎原始公钥（ECDSA约64B）
        address registrant;           // 注册人地址
        EngineStatus status;          // 引擎状态
        uint64  registeredAt;         // 注册时间戳
        uint64  lastHealthCheck;      // 最近健康检查时间
        bool    exists;               // 防覆盖
    }

    // ─────── Storage ───────

    /// @notice 管理员地址（三签制，与审计链共享相同的管理地址集）
    address[3] public adminAddresses;
    uint8 public adminCount;
    /// @notice 引擎登记表
    mapping(bytes32 => EngineInfo) public engines;
    /// @notice 按名称查询引擎ID
    mapping(string => bytes32) public engineByName;
    /// @notice 紧急暂停开关
    bool public emergencyPaused;

    // ─────── Time-lock & Multi-sig ───────
    uint256 public constant TIME_LOCK_DURATION = 86400;

    /// @notice 管理员替换提案
    struct PendingAdminProposal {
        uint8 oldIndex;
        address newAdmin;
        uint8 approvals;
        bool executed;
        uint64 proposedAt;
    }
    PendingAdminProposal public pendingAdminProposal;
    /// @notice 去重映射
    mapping(bytes32 => mapping(address => bool)) public adminApproved;

    /// @notice 紧急暂停提案
    struct PauseProposal {
        bool pause;
        uint8 approvals;
        bool executed;
        uint64 proposedAt;
    }
    PauseProposal public pendingPauseProposal;
    mapping(bytes32 => mapping(address => bool)) public pauseApproved;
    bytes32 public currentPauseProposalId;

    // ─────── Events ───────

    event EngineRegistered(
        bytes32 indexed engineId,
        string name,
        bytes publicKey,
        address indexed registrant,
        uint64 timestamp
    );

    event EngineStatusChanged(
        bytes32 indexed engineId,
        EngineStatus newStatus,
        uint64 timestamp
    );

    event HealthCheckResult(
        bytes32 indexed engineId,
        HealthCheckLevel level,
        string details,
        uint64 timestamp
    );

    event AdminChanged(address indexed oldAdmin, address indexed newAdmin, uint256 indexed actionType);
    event AdminProposed(uint8 indexed oldIndex, address indexed newAdmin, uint64 proposedAt);
    event PauseProposed(bool pause, uint64 proposedAt);
    event PauseToggled(bool paused, address indexed operator, uint64 timestamp);
    event PauseExecuted(bool pause, address indexed operator, uint64 timestamp);

    // ─────── Modifiers ───────

    modifier onlyAdmin() {
        bool isAdmin = false;
        for (uint8 i = 0; i < adminCount; i++) {
            if (msg.sender == adminAddresses[i]) {
                isAdmin = true;
                break;
            }
        }
        require(isAdmin, "MTC: only admin");
        _;
    }

    modifier notPaused() {
        require(!emergencyPaused, "MTC: contract is paused");
        _;
    }

    // ─────── Constructor ───────

    constructor() {
        adminCount = 0;
        emergencyPaused = false;
    }

    // ─────── Admin Management ───────

    function initializeAdmins(address[3] calldata _admins) external {
        require(adminCount == 0, "MTC: admins already initialized");
        require(_admins[0] != address(0) && _admins[1] != address(0) && _admins[2] != address(0), "MTC: zero address");
        for (uint8 i = 0; i < 3; i++) {
            adminAddresses[i] = _admins[i];
        }
        adminCount = 3;
    }

    // ─────── Engine Registration ───────

    /// @notice 注册一个AI诊断引擎
    /// @param _name 引擎名称
    /// @param _publicKey 引擎原始公钥
    function registerEngine(string calldata _name, bytes calldata _publicKey) external onlyAdmin notPaused returns (bytes32) {
        require(bytes(_name).length > 0, "MTC: empty name");
        require(_publicKey.length > 0, "MTC: empty public key");
        require(engineByName[_name] == bytes32(0), "MTC: engine name already registered");

        bytes32 engineId = keccak256(abi.encodePacked(_name, block.timestamp));
        uint64 ts = uint64(block.timestamp);

        engines[engineId] = EngineInfo({
            engineId: engineId,
            name: _name,
            publicKey: _publicKey,
            registrant: msg.sender,
            status: EngineStatus.PENDING,
            registeredAt: ts,
            lastHealthCheck: 0,
            exists: true
        });

        engineByName[_name] = engineId;

        emit EngineRegistered(engineId, _name, _publicKey, msg.sender, ts);
        return engineId;
    }

    // ─────── Engine State Management ───────

    function verifyEngine(bytes32 _engineId) external onlyAdmin {
        require(engines[_engineId].exists, "MTC: engine not found");
        engines[_engineId].status = EngineStatus.VERIFIED;
        emit EngineStatusChanged(_engineId, EngineStatus.VERIFIED, uint64(block.timestamp));
    }

    function suspendEngine(bytes32 _engineId) external onlyAdmin {
        require(engines[_engineId].exists, "MTC: engine not found");
        engines[_engineId].status = EngineStatus.SUSPENDED;
        emit EngineStatusChanged(_engineId, EngineStatus.SUSPENDED, uint64(block.timestamp));
    }

    function revokeEngine(bytes32 _engineId) external onlyAdmin {
        require(engines[_engineId].exists, "MTC: engine not found");
        engines[_engineId].status = EngineStatus.REVOKED;
        emit EngineStatusChanged(_engineId, EngineStatus.REVOKED, uint64(block.timestamp));
    }

    // ─────── Health Check Recording ───────

    /// @notice 记录引擎健康检查结果
    /// @param _engineId 引擎ID
    /// @param _level 异常等级
    /// @param _details 检查详情（自由文字）
    function recordHealthCheck(
        bytes32 _engineId,
        HealthCheckLevel _level,
        string calldata _details
    ) external onlyAdmin notPaused {
        require(engines[_engineId].exists, "MTC: engine not found");
        engines[_engineId].lastHealthCheck = uint64(block.timestamp);
        emit HealthCheckResult(_engineId, _level, _details, uint64(block.timestamp));
    }

    // ─────── Query Functions ───────

    function getEngine(bytes32 _engineId) external view returns (EngineInfo memory) {
        require(engines[_engineId].exists, "MTC: engine not found");
        return engines[_engineId];
    }

    function getEngineByName(string calldata _name) external view returns (bytes32, EngineInfo memory) {
        bytes32 eid = engineByName[_name];
        require(eid != bytes32(0), "MTC: engine not found");
        return (eid, engines[eid]);
    }

    // ─────── Admin Replacement Proposal (with time-lock & dedup) ───────

    function proposeNewAdmin(uint8 _oldIndex, address _newAdmin) external onlyAdmin {
        require(_oldIndex < 3, "MTC: invalid index");
        require(_newAdmin != address(0), "MTC: zero address");
        require(adminAddresses[_oldIndex] != _newAdmin, "MTC: same address");

        pendingAdminProposal = PendingAdminProposal({
            oldIndex: _oldIndex,
            newAdmin: _newAdmin,
            approvals: 0,
            executed: false,
            proposedAt: uint64(block.timestamp)
        });

        emit AdminProposed(_oldIndex, _newAdmin, uint64(block.timestamp));
    }

    function approveNewAdmin() external onlyAdmin {
        require(pendingAdminProposal.newAdmin != address(0), "MTC: no pending proposal");
        require(!pendingAdminProposal.executed, "MTC: already executed");
        require(block.timestamp >= pendingAdminProposal.proposedAt + TIME_LOCK_DURATION, "MTC: time lock not expired");

        bytes32 proposalId = keccak256(
            abi.encodePacked(pendingAdminProposal.oldIndex, pendingAdminProposal.newAdmin, pendingAdminProposal.proposedAt)
        );
        require(!adminApproved[proposalId][msg.sender], "MTC: already approved");
        adminApproved[proposalId][msg.sender] = true;

        pendingAdminProposal.approvals++;

        if (pendingAdminProposal.approvals >= 2) {
            address oldAdmin = adminAddresses[pendingAdminProposal.oldIndex];
            adminAddresses[pendingAdminProposal.oldIndex] = pendingAdminProposal.newAdmin;
            pendingAdminProposal.executed = true;
            emit AdminChanged(oldAdmin, pendingAdminProposal.newAdmin, 1);
        }
    }

    // ─────── Emergency Pause (two-phase multi-sig + time-lock) ───────

    function proposePause() external onlyAdmin {
        require(!emergencyPaused, "MTC: already paused");
        pendingPauseProposal = PauseProposal({pause: true, approvals: 0, executed: false, proposedAt: uint64(block.timestamp)});
        currentPauseProposalId = keccak256(abi.encodePacked("pause", block.timestamp));
        emit PauseProposed(true, uint64(block.timestamp));
    }

    function approvePause() external onlyAdmin {
        require(!emergencyPaused, "MTC: already paused");
        require(!pendingPauseProposal.executed, "MTC: pause already executed");
        require(block.timestamp >= pendingPauseProposal.proposedAt + TIME_LOCK_DURATION, "MTC: time lock not expired");
        require(!pauseApproved[currentPauseProposalId][msg.sender], "MTC: already approved");
        pauseApproved[currentPauseProposalId][msg.sender] = true;
        pendingPauseProposal.approvals++;
        if (pendingPauseProposal.approvals >= 2) {
            emergencyPaused = true;
            pendingPauseProposal.executed = true;
            emit PauseToggled(true, msg.sender, uint64(block.timestamp));
            emit PauseExecuted(true, msg.sender, uint64(block.timestamp));
        }
    }

    function proposeUnpause() external onlyAdmin {
        require(emergencyPaused, "MTC: not paused");
        pendingPauseProposal = PauseProposal({pause: false, approvals: 0, executed: false, proposedAt: uint64(block.timestamp)});
        currentPauseProposalId = keccak256(abi.encodePacked("unpause", block.timestamp));
        emit PauseProposed(false, uint64(block.timestamp));
    }

    function approveUnpause() external onlyAdmin {
        require(emergencyPaused, "MTC: not paused");
        require(!pendingPauseProposal.executed, "MTC: unpause already executed");
        require(block.timestamp >= pendingPauseProposal.proposedAt + TIME_LOCK_DURATION, "MTC: time lock not expired");
        require(!pauseApproved[currentPauseProposalId][msg.sender], "MTC: already approved");
        pauseApproved[currentPauseProposalId][msg.sender] = true;
        pendingPauseProposal.approvals++;
        if (pendingPauseProposal.approvals >= 2) {
            emergencyPaused = false;
            pendingPauseProposal.executed = true;
            emit PauseToggled(false, msg.sender, uint64(block.timestamp));
            emit PauseExecuted(false, msg.sender, uint64(block.timestamp));
        }
    }
}
