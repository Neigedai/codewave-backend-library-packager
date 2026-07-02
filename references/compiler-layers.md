# 编译器分层说明

本 Skill 的主要目标是打包依赖库，但在处理复杂源码项目时，可以借用 AICodeWave Compiler 的分层视角。

## 分层链路

```text
源码项目
-> 输入识别层
-> 代码解析层
-> 应用结构模型 IR
-> CodeWave 适配层
-> 依赖库打包层
-> 校验层
-> CodeWave 平台运行
```

## 输入识别层

识别：

- 前端目录和构建方式
- 后端目录和 Maven/NASL 配置
- 是否已有 `getAppHtml`
- 是否已有 `callApi`
- 是否存在 SQL 初始化脚本
- 是否存在上传、登录、权限、小程序等端侧逻辑

## 代码解析层

抽取：

- 页面
- 组件
- 路由
- API 调用
- 后端接口
- 数据模型
- 上传逻辑
- 登录和权限
- 环境配置

## IR 应用结构模型

复杂项目先建轻量 IR，不急着打包：

```json
{
  "appName": "",
  "pages": [],
  "components": [],
  "apis": [],
  "services": [],
  "models": [],
  "routes": [],
  "permissions": [],
  "uploads": [],
  "environments": []
}
```

IR 用于确认源码项目中哪些内容能直接打包，哪些需要适配或重写。

## CodeWave 适配层

常见映射：

| 源码内容 | CodeWave 适配 |
|---|---|
| 前端单页应用 | `static/app.html` + `getAppHtml` |
| 前端 API 请求 | `/xxx_proxy/callApi` |
| 后端 Controller | 依赖库内部路由分发 |
| 数据模型 | SQL 初始化脚本 + CRUD 映射 |
| 上传组件 | `uploadImage` / `uploadVideo` |
| 登录态 | token 参数透传或依赖库内 token |
| 权限菜单 | 后端权限数据 + 前端菜单控制 |

## 依赖库打包层

输出：

- Maven 依赖库工程
- NASL metadata
- 依赖库 jar
- 依赖库 pom
- `library-*-{version}.zip`

## 校验层

必须确认：

- zip 能导入平台
- `app.html` 在包内或内部 jar 内
- `getAppHtml` 可返回完整 HTML
- `callApi` 基础接口可返回 200
- 依赖不和平台冲突
- 开发/生产环境路径自适应

## 使用判断

- 用户只要打包：直接执行打包流程。
- 项目结构混乱：先按 IR 盘点，再改造。
- 用户要标准案例：读取 `standard-case-rules.md`。
- 打包或平台运行报错：读取 `troubleshooting.md`。
