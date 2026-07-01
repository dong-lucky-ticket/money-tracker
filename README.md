# expensetracker

一个面向中文用户的本地记账应用，围绕“快速录入、分类管理、报表查看、数据导入导出”四条主线组织功能。

项目当前采用 Flutter + Provider + Hive：

- `Provider` 负责页面状态刷新与数据操作入口。
- `Hive` 负责本地持久化账单、分类和设置项。
- UI 以移动端记账流程为核心，强调单手操作、快速新增和可视化统计。

## 项目意图

从现有页面和交互设计来看，这个项目的目标是做一款：

- 录入路径短的记账工具：先选分类，再输入金额，减少操作步骤。
- 分类可定制的个人账本：支持新增分类、排序、删除与历史分类复用。
- 适合日常复盘的账务助手：提供首页月度流水、报表趋势、分类占比和排行。
- 具备基础数据流转能力的本地应用：支持 CSV 导入导出，方便备份和迁移。

## 目录说明

### 根目录

- `assets/`：应用静态资源，目前包含启动/展示相关图片资源。
- `android/`：Flutter Android 平台工程配置。
- `build/`：构建产物目录。
- `docs/`：项目补充文档目录，记录业务配置、结构说明和维护约定。
- `lib/`：核心业务代码目录。
- `test/`：测试代码目录，目前包含默认 Widget 测试文件。
- `.bak/`：项目内备份目录，通常用于临时保留历史文件。

### `lib/` 目录

- `main.dart`：应用入口，负责初始化 Hive、注册模型适配器、注入 `DataProvider`、配置主题与本地化。
- `models/`：数据模型层，定义账单、分类以及报表聚合结果等结构。
- `providers/`：状态与数据访问层，集中处理记录、分类、主题和 CSV 导入导出逻辑。
- `screens/`：页面层，负责组织具体业务流程与页面级交互。
- `theme/`：主题常量层，统一颜色等基础视觉变量。
- `ui/`：静态设计稿/参考页面资源，用于展示或对照视觉方案。
- `utils/`：通用工具层，放置颜色转换、图标映射、报表快照构建等纯逻辑工具。
- `widgets/`：可复用组件层，承载跨页面或按场景拆分出的 UI 片段。

### `lib/models/`

- `category.dart` / `category.g.dart`：分类模型及 Hive 适配器。
- `record.dart` / `record.g.dart`：账单模型及 Hive 适配器。
- `report_snapshot.dart`：报表页使用的聚合结果模型，降低页面内的计算复杂度。

### `lib/providers/`

- `data_provider.dart`：项目核心数据中枢，负责：
  - 初始化本地存储。
  - 提供账单/分类 CRUD。
  - 提供分类排序与默认分类初始化。
  - 处理 CSV 导入导出。
  - 管理主题模式和统计数据。

### `lib/screens/`

- `main_tab_screen.dart`：底部主导航容器，承载账单、报表、我的三个一级页面。
- `home_screen.dart`：首页账单流水，展示月度总览与按天分组的账单列表。
- `add_record_screen.dart`：新增/编辑账单入口，负责分类选择、金额输入、备注与日期填写。
- `categories_screen.dart`：分类管理页，支持支出/收入分类切换、排序和删除。
- `add_category_screen.dart`：新增分类页，负责名称录入、图标选择和历史分类关联判断。
- `report_screen.dart`：统计报表页，展示趋势、占比、柱状统计和分类排行。
- `search_screen.dart`：账单搜索页，按分类名或备注筛选历史记录。
- `settings_screen.dart`：设置与数据管理页，聚合导入、导出、主题和本地数据清理等功能。

### `lib/theme/`

- `app_colors.dart`：全局颜色常量，减少页面内硬编码颜色分散的问题。

### `lib/utils/`

- `color_utils.dart`：颜色转换工具，例如 `hex` 到 `Color` 的解析。
- `icon_mapper.dart`：分类图标名称与 Material 图标的映射入口。
- `category_icons.dart`：新增分类页使用的图标分组定义。
- `report_snapshot_builder.dart`：将原始账单列表转换为报表页可直接消费的统计快照。

### `lib/widgets/`

- `edit_record_sheet.dart`：账单编辑底部弹层。
- `common/`：通用基础组件。
  - `app_card.dart`：统一卡片容器样式。
  - `empty_state.dart`：统一空状态展示。
  - `segmented_selector.dart`：统一分段选择器。
- `record/`：账单展示相关组件。
  - `record_list_item.dart`：统一账单行，支持点击、删除、废弃切换等交互。
- `add_record/`：账单录入流程拆分组件。
  - `add_record_header.dart`：录入页顶部操作区。
  - `category_grid.dart`：分类网格选择区。
  - `record_detail_panel.dart`：金额、日期、备注信息面板。
  - `amount_keypad.dart`：自定义金额键盘。
- `categories/`：分类管理页拆分组件。
  - `category_management_header.dart`：分类页头部。
  - `category_list_panel.dart`：可拖拽分类列表。
  - `category_bottom_actions.dart`：底部新增分类与说明区域。
- `settings/`：设置页拆分组件。
  - `settings_profile_card.dart`：顶部用户信息卡片。
  - `settings_stats_bar.dart`：设置页统计条。
  - `settings_section.dart`：设置分组标题、容器和设置项。
- `report/`：报表页拆分组件。
  - `report_header.dart`：报表页顶部筛选区。
  - `report_overview_section.dart`：总收支与洞察卡片。
  - `report_trend_chart.dart`：趋势图区域。
  - `report_distribution_section.dart`：饼图与柱状图区域。
  - `report_rank_list.dart`：分类排行列表。
  - `report_category_detail_sheet.dart`：分类明细底部弹层。

## 本次代码整理说明

这次整理主要做了三件事：

- 将 `add_record_screen.dart`、`categories_screen.dart`、`settings_screen.dart`、`report_screen.dart` 中体量较大的 UI 片段拆分为独立组件。
- 提取跨页面复用能力，例如统一空状态、统一账单项、统一分段选择器、统一卡片与设置项样式。
- 增加 `theme/`、`widgets/*`、`report_snapshot` 等中间层，让页面文件更聚焦“组织流程”，把展示细节和统计计算下沉到可复用模块。

## 编码约定

- 文件读写统一使用 UTF-8 编码。
- 当前导出 CSV 时已显式按 UTF-8 写入。
