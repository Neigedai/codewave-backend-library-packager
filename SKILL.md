---
name: codewave-backend-library-packager
description: Package an existing frontend/backend project into a CodeWave-importable backend dependency library zip. Use when the user asks to "打包成 CodeWave 后端依赖库", "生成可导入平台的依赖库", "让前端页面在 CodeWave 展示", "让 API 在平台正常调用", or needs app.html embedding, /callApi proxy routing, Maven/NASL archive packaging, dependency conflict checks, and final zip validation.
---

# CodeWave 后端依赖库打包助手

目标是交付一个可直接导入 CodeWave 平台的依赖库压缩包，并让平台页面能展示前端、前端能正常调用 API。

## 执行流程

1. 识别项目结构：找出前端目录、后端依赖库目录、可选服务依赖库目录和打包脚本。
2. 检查前端请求：平台内前端必须使用相对代理路径，不写死开发或生产域名。
3. 构建前端：优先打成单文件 `dist/index.html`。
4. 嵌入页面：复制到后端依赖库 `src/main/resources/static/app.html`。
5. 检查后端入口：依赖库必须提供获取页面的接口和统一 API 代理入口。
6. 递增版本：每次导入 CodeWave 前必须升级 Maven 版本号。
7. 打包依赖库：优先运行项目已有脚本；否则使用本 Skill 的 `scripts/package-codewave-library.ps1`。
8. 验收 zip：确认 zip 存在、包含 `app.html`、没有明显冲突依赖和构建脏内容。
9. 交付导入说明：告诉用户 zip 路径、导入顺序、页面入口 JS 和 API 调用路径。

## 推荐脚本

当项目结构接近标准案例时，运行：

```powershell
<skill目录>\scripts\package-codewave-library.ps1 `
  -ProjectRoot "<项目根目录>" `
  -Version "1.0.x"
```

如果项目自带 `scripts/package.ps1`，优先使用项目脚本。

## 必读参考

读取 [references/park-codewave-reference.md](references/park-codewave-reference.md) 来确认：

- 标准目录结构
- 前端相对路径规则
- `getAppHtml` 和 `callApi` 要求
- 打包前检查项
- zip 验收清单
- CodeWave 平台导入和页面接入说明

## 交付标准

最终响应必须包含：

- 生成的依赖库 zip 绝对路径
- 是否已完成前端构建和 `app.html` 嵌入
- API 代理路径
- CodeWave 导入顺序
- 平台页面入口代码或调用说明
- 未完成项或需要用户在平台手动配置的事项
