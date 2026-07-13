# 分类与图标配置说明

本文档用于说明项目中“收支分类数据”与“图标配置”的来源、结构和使用方式，方便后续维护默认分类、补充图标或调整映射规则。

## 1. 相关文件

- `lib/providers/data_provider.dart`
  - 负责初始化默认支出/收入分类。
  - 默认分类写在 `_initDefaultCategories()` 中。
- `lib/models/category.dart`
  - 定义分类模型 `Category`。
- `lib/utils/icon_mapper.dart`
  - 负责把分类保存的 `iconName` 映射成真正展示的 `IconData`。
- `lib/utils/category_icons.dart`
  - 负责“新增分类”页面里的图标库分组与图标候选列表。
- `lib/screens/add_category_screen.dart`
  - 负责新增分类时选择图标、填写名称并保存分类。

## 2. 分类数据结构

项目中的分类使用 `Category` 模型表示，核心字段如下：

- `name`：分类名称，例如“餐饮”“工资”
- `iconName`：图标标识字符串，例如 `food`、`salary`
- `colorHex`：分类颜色，例如 `#F97316`
- `isExpense`：是否为支出分类
- `sortOrder`：分类排序

也就是说，分类本身并不直接保存 Flutter 的 `IconData`，而是保存一个字符串型的 `iconName`。

## 3. 默认分类配置位置

默认收支分类定义在：

- `lib/providers/data_provider.dart` 的 `_initDefaultCategories()`

这里会在首次初始化或分类数量不足时，写入一批默认分类到本地存储。

### 3.1 默认支出分类

当前默认支出分类包括：

- 餐饮：`food`
- 购物：`shopping`
- 日用：`daily`
- 交通：`transport`
- 买菜：`grocery`
- 水果：`fruit`
- 零食：`snacks`
- 通讯：`communication`
- 服饰：`clothing`
- 住房：`housing`
- 孩子：`child`
- 长辈：`elders`
- 旅行：`travel`
- 烟酒：`alcohol`
- 数码：`digital`
- 汽车：`car`
- 摩托：`motorcycle`
- 医疗：`medical`
- 书籍：`books`
- 礼金：`gift-money`
- 办公：`office`
- 彩票：`lottery`
- 星愿：`wish`
- 火车高铁：`train`
- 生活缴费：`utility`

### 3.2 默认收入分类

当前默认收入分类包括：

- 工资：`salary`
- 兼职：`part-time`
- 理财：`investment`
- 礼金：`gift-money-income`
- 其它：`other`
- 彩票：`lottery-income`

## 4. 图标是如何配置的

### 4.1 默认分类图标映射

默认分类展示图标时，走的是：

- `lib/utils/icon_mapper.dart`

页面在渲染分类图标时，通常会调用：

```dart
IconMapper.getIcon(category.iconName)
```

例如：

- `food -> MdiIcons.silverwareForkKnife`
- `grocery -> MdiIcons.cartOutline`
- `shopping -> MdiIcons.shoppingOutline`
- `transport -> MdiIcons.bus`
- `salary -> MdiIcons.cashMultiple`
- `investment -> MdiIcons.chartLine`

也就是说：

1. 分类数据里保存 `iconName`
2. 展示时通过 `IconMapper.getIcon()` 找到对应图标
3. 如果没有命中 `switch`，则回退到 `MdiIcons.fromString(name)`，再不行就使用 `helpCircleOutline`

### 4.2 新增分类页面的图标来源

新增分类页面使用的图标候选列表定义在：

- `lib/utils/category_icons.dart`

这里定义了：

- `CategoryIconGroup`
  - 用于表示一个图标分组
- `categoryIconGroups`
  - 图标库分组数据源
- `getIconData(String name)`
  - 把图标字符串直接转为 `MdiIcons.fromString(name)`

当前图标分组包括：

- 娱乐
- 饮食
- 医疗
- 学习
- 交通
- 购物
- 生活
- 个人
- 家庭
- 宝宝
- 健身
- 办公
- 收入
- 其它

注意这里的图标名称和默认分类中的 `iconName` 并不是完全同一套命名规则。

例如：

- 默认分类可能使用 `food`
- 新增分类图标库里则是 `silverware-fork-knife`

因此项目目前实际上存在两套图标标识来源：

- 一套是“默认分类专用别名”，由 `icon_mapper.dart` 负责映射
- 一套是“Material Design Icons 原始字符串名”，由 `category_icons.dart` 直接交给 `MdiIcons.fromString()`

## 5. 新增分类时的图标保存逻辑

新增分类页面位于：

- `lib/screens/add_category_screen.dart`

关键逻辑如下：

1. 用户在图标库中选择一个图标字符串，例如 `cash-multiple`
2. 页面把该值保存到 `_selectedIcon`
3. 点击“完成”后，创建 `Category`
4. `Category.iconName = _selectedIcon`
5. 保存到 `DataProvider.addCategory()`

这意味着：

- 默认分类更偏“业务别名”
- 用户新增分类更偏“原始图标名”

两者最终都能显示，是因为 `icon_mapper.dart` 的 `default` 分支会继续尝试 `MdiIcons.fromString(name)`

## 6. 页面如何使用分类图标

几个典型使用点：

- `lib/widgets/add_record/category_grid.dart`
  - 记账页分类网格图标
- `lib/widgets/categories/category_list_panel.dart`
  - 分类管理页图标
- `lib/widgets/record/record_list_item.dart`
  - 账单列表项图标
- `lib/widgets/report/report_rank_list.dart`
  - 报表排行中的分类图标
- `lib/widgets/report/report_category_detail_sheet.dart`
  - 报表分类明细弹层中的图标

这些位置基本都通过：

```dart
IconMapper.getIcon(category.iconName)
```

来统一处理。

## 7. 当前设计的特点与注意点

### 优点

- 默认分类可以使用更短、更语义化的别名。
- 新增分类可以直接复用 `material_design_icons_flutter` 的图标字符串。
- 页面层统一通过 `IconMapper` 获取图标，使用方式比较一致。

### 需要注意的问题

- 默认分类 `iconName` 与新增分类图标名不是完全统一的一套规范。
- 如果后续要批量替换图标或做图标配置后台化，建议考虑统一 `iconName` 命名策略。
- 如果新增了新的“默认分类别名”，需要同步更新 `lib/utils/icon_mapper.dart`，否则只能依赖回退逻辑。

## 8. 推荐维护方式

如果你后续要继续扩展这部分，建议遵循下面的规则：

- 新增默认分类：
  - 在 `lib/providers/data_provider.dart` 中补充 `Category(...)`
  - 同时在 `lib/utils/icon_mapper.dart` 中补充对应映射
- 调整新增分类图标库：
  - 修改 `lib/utils/category_icons.dart` 中的 `categoryIconGroups`
- 如果希望统一两套命名：
  - 可以逐步把默认分类的 `iconName` 也改成 MDI 原始字符串名
  - 这样 `IconMapper` 可以进一步简化
