# HarmonyOS ArkTS 开发约束

## ArkTS/ets 语法约束

- 禁止`any/unknown`，必须显式声明类型。
- 不支持索引访问、`as const`、条件类型、`infer`、解构、`!`确定性断言、索引签名、交叉类型、`is`(替换为`instanceof`)、JSX、映射类型、`var`、`with`。
- 禁止`for...in`对象遍历，对象改用类；数组使用普通 for 循环。
- 禁止`apply/call/bind`、函数表达式（使用箭头函数）、嵌套函数（使用箭头函数）、`globalThis`、`require`。
- 对象禁止`obj["key"]`动态字段访问；类字段必须在类内部声明，不能在构造函数声明。
- import 全部放在文件最顶部；不支持模块通配符导入、`export =`。
- catch 子句不要写变量类型标注；不支持`this`做类型标注。
- 展开运算符仅允许用于数组 rest 参数 / 数组字面量。
- `this`仅允许在类实例方法内使用，独立函数、静态方法禁止使用`this`。
- 对象字面量必须能推断到已定义类 / 接口，禁止赋值给`Object`等动态类型。
- 仅`Partial/Required/Readonly/Record`可使用 TS 工具类型；Record 索引取值类型为`V | undefined`。

## HarmonyOS API 使用规范

1. 优先使用官方 API，调用前确认 API Level、设备支持；不确定查阅官方文档，禁止臆造 API。
2. 使用 API 补充对应 import；需要权限则配置`module.json5`；依赖库配置`oh‑package.json5`。
3. `@Component`/`@ComponentV2`与项目现有代码保持一致。
4. UI 常量使用`$r`引用 resources 资源，禁止硬编码字面量；新增字符串、颜色资源同步多语言、适配深色主题。

## ArkUI 动画规范

1. 使用原生`animateTo`，基于`@State`驱动状态变更触发动画。
2. 复杂子组件动画开启`renderGroup(true)`。
3. 动画过程避免频繁修改`width/height/padding/margin`布局属性，防止性能恶化。

## ArkTS 代码修改安全规则

>
> 文件配套：工程根目录`CODE_CHANGE_LOG.md`，每次修改末尾追加记录，**不覆盖历史**

### 核心原则

修改已有代码**禁止直接删除、覆盖旧代码**；流程：注释留痕→标注废弃原因→下方追加修复代码，保障 git diff 可追溯。

### 执行步骤

1. 定位待修改代码块。
2. 使用`/* */`(大段) / `//`(单行) 完整注释原有代码。
3. 注释块上方强制添加标记：

```
// 【废弃/错误】问题原因，可选：时间、issue
/*
旧完整代码
*/
// ↓↓↓修复代码写下方↓↓↓
```

4. 在注释块下方编写修复后的 ArkTS 代码，禁止原地改写。
5. 更新`CODE_CHANGE_LOG.md`。

#### 单行示例

```
// 【废弃/错误】timeout写死1000，超时过短引发请求失败 2026‑08‑26
// const timeout = 1000;
const timeout = 5000;
```

#### 函数示例

```
// 【废弃/错误】缺少入参判空，undefined触发运行异常
/*
private handleMessage(msg: AgentMessage): void {
  this.session.send(msg);
}
*/
private handleMessage(msg: AgentMessage): void {
  if (!msg) {
    console.error("AgentMessage is null or undefined");
    return;
  }
  this.session.send(msg);
}
```

#### 大于 20 行大段改造

保留首尾两行上下文，中间占位，完整新逻辑写下方：

```
// 【废弃/错误】旧会话逻辑存在内存泄漏，完整修复见下方
/*
this.agentSession = new AgentSession(...);
this.agentSession.onMessage((res)=>{
// ... 此处代码已弃用，详见下方修复 ...
this.agentSession.start();
*/
// ==========修复新逻辑==========
private initAgentSession() {
  //新实现
}
```

#### 常量 / 接口

不删除旧定义，注释废弃，新增新版本。

### 禁止行为

- ❌直接删除函数、分支、变量不注释；❌原地修改代码；❌大段删除仅贴新代码；❌不更新变更日志；❌旧代码注释到其他位置。

### CODE_CHANGE_LOG.md 模板如下，每次完成后如果发现没有CODE_CHANGE_LOG.md 则新建一个写入，若有则在文件后面加上最新的。每次都加上日期时间方便我分辨是那次回答

```
## 2026‑08‑26 21点12分
- 问题描述：BUG现象
- 涉及文件：文件路径
- 修改位置：函数/代码块
- 修改说明：旧问题，修复点
- 备注：验证点、注意事项
```

### 豁免

纯新增逻辑（不改动旧代码）不需要注释旧代码，建议日志记录新增功能。

### 违规约定

若出现直接删除覆盖旧代码、无注释留痕、未更新日志，请提醒重做修改。