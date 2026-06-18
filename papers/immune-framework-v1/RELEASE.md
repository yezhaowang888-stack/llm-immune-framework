# 排毒上链校准框架 v1.8

## 论文信息

**标题**: Immune System for LLMs: A Five-Anchor Audit Framework with On-Chain Audit Trail

**作者**: 惠迈智能体团队 (Huimai Agent Team)

**arXiv**: 暂停提交（GitHub优先）

## 核心贡献

### 五锚审计框架
将LLM输出审计系统化为五个交叉验证锚点：出处锚、逻辑锚、利益锚、合规锚、交叉锚。每个锚点独立审计一个维度，锚点间交叉验证防止单一视角误判。

### 信息完备性假说
首次形式化论证：模型推理能力越强，在信息缺口下的归因幻觉越隐蔽且越自信。提出双视角修正方法论——渐进式缺口暴露 + 激励机制回溯 + 自利先验收敛。

### 链上审计追踪
通过MedTrustChain + AuditChain将审计决策哈希上链，实现不可篡改的审计记录。

### 四层检测链
L1事实匹配 → L2语义一致性 → L3逻辑闭合 → L4统计偏差 → L5因果归因审计 → L6反认知殖民

### FML故障记忆层
存储历史故障模式，预触发检测，从"被动响应"升级为"主动免疫"。

## 文件

- `paper.pdf` — 完整论文（11章，720行LaTeX）
- `paper.tex` — LaTeX源码
- `chapter-info-completeness.tex` — 信息完备性嵌入章
- `bibliography-additions.tex` — 引用条目

## 版本历史

- v1.8 (2026-06-18): 信息完备性嵌入章 + Herrera引用架构化 + 中文清理
- v1.0 (2026-05-19): 初始五锚框架
