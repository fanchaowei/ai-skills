# 模块文档生成器 Skill

## 功能

智能分析 Vue 3 + TypeScript 项目中的代码模块，生成面向 AI 渐进读取的 `ai-module-spec` 模块规格文档。支持 monorepo 与非 monorepo 项目。

## 使用方法

### 基础用法

```bash
/doc-gen <模块路径>
```

### 带上下文

```bash
/doc-gen <模块路径> --context "<上下文描述>"
```

### 指定归属

```bash
/doc-gen <模块路径>

这个模块属于 libs/shared-ui
```

## 使用场景

### 有设计/实施文档

```bash
/doc-gen src/store/useTreeStationConfig.ts

上下文:
这是根据 docs/skill创建/2026-03-06-树形站点配置-design.md 实现的模块
```

### 手动修改代码

```bash
/doc-gen src/components/shared/tree

上下文:
我重构了树形组件，将逻辑拆分为 8 个 hooks，支持懒加载、右键菜单、拖拽排序
```

### Monorepo 模块

```bash
/doc-gen apps/config-manage-system/src/components/manage-view/RouteCachedPage.vue
```

生成到：

```text
apps/config-manage-system/claudedocs/modules/RouteCachedPage.md
```

## 支持的模块类型

1. **综合模块** - 多文件组合（组件 + hooks + utils）
2. **Vue 组件** - 单个或简单组件
3. **Pinia Store** - 状态管理
4. **Composables/Hooks** - 组合式函数
5. **工具函数** - 纯函数工具
6. **视图页面** - 路由级别组件

## AI 渐进读取格式

新生成模块文档默认使用 `ai-module-spec` 格式。YAML frontmatter 是导航层，正文是解释层。AI 可以先读取 YAML 中的 `read_order`，再根据任务类型选择阅读 `quick_edit`、`architecture` 或 `debugging` 对应章节。

## 旧文档迁移

旧文档采用渐进迁移。只有用户明确要求更新、重写、升级格式或按新模板整理时，才将旧文档整体迁移到 `ai-module-spec`。普通补充场景优先尊重原结构。

## 输出

### Monorepo

- 模块文档：`{owner}/claudedocs/modules/{ModuleName}.md`
- owner 索引：`{owner}/claudedocs/README.md`
- 根索引：`AGENTS.md` 中的 owner 文档入口

示例 owner：

- `apps/config-manage-system`
- `packages/shared-services`
- `libs/shared-ui`

### 非 monorepo

- 模块文档：`claudedocs/modules/{ModuleName}.md`
- 根索引：`AGENTS.md` 的模块文档索引

## 文档质量

生成的文档包含（根据模块复杂度自适应）：

- YAML frontmatter 与 `read_order`
- 模块概述、AI 快速接手、AI 修改守则
- 模块边界、当前实现契约、核心流程、依赖关系
- 影响范围、已验证行为、修改指南
- 基于代码或测试确认的问题排查路径
- 待确认项与文档维护信息
