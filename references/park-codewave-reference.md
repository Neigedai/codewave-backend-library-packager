# CodeWave 后端依赖库打包参考

本参考只保存脱敏后的通用规则，不包含真实项目源码、业务名称、域名、数据库名、账号或密钥。

## 目标产物

用户说“帮我将这个项目打包成 CodeWave 后端依赖库”时，最终应交付可导入 CodeWave 平台的 zip 包。

成功标准：

- zip 可以在 CodeWave 依赖库管理中导入。
- 平台页面可以加载依赖库内置前端。
- 前端请求可以通过代理入口调用后端 API。
- 包内没有明显冲突依赖、构建脏内容和敏感信息。

## 标准项目结构

推荐结构：

```text
project/
├── frontend/
│   ├── package.json
│   └── dist/index.html
├── backend-library/
│   ├── pom.xml
│   └── src/main/resources/static/app.html
├── service-library/                 # 可选
│   └── pom.xml
└── scripts/package.ps1              # 可选
```

如果目录名不同，先通过 `rg --files` 查找 `package.json`、`pom.xml`、`static/app.html` 和 `nasl-metadata-maven-plugin`。

## 前端规则

平台内前端必须使用相对路径，不要写死开发或生产域名。

推荐：

```js
const API_BASE = '/simple_proxy/callApi'
```

或按实际依赖库标识替换：

```js
const API_BASE = '/<library_name>/callApi'
```

请求体推荐统一：

```json
{
  "reqPath": "/notices",
  "reqMethod": "GET",
  "reqBody": "{}"
}
```

## 页面嵌入规则

前端构建产物应复制到：

```text
backend-library/src/main/resources/static/app.html
```

后端依赖库应提供页面 HTML 读取能力，常见入口：

```text
/simple_proxy/getAppHtml
```

平台页面入口示例：

```js
(async function () {
  const res = await fetch('/api/simple_proxy/getAppHtml', { method: 'POST' }).then(r => r.json());
  const html = res.Data || res.data || '';
  document.open();
  document.write(html);
  document.close();
})();
```

## 后端代理规则

后端依赖库应提供统一代理入口，常见路径：

```text
/simple_proxy/callApi
```

代理入口负责分发：

- `reqPath`
- `reqMethod`
- `reqBody`

业务接口不要直接暴露为一批平台页面硬编码路径，优先收敛到统一代理入口。

## 打包流程

优先使用项目自带脚本：

```powershell
.\scripts\package.ps1 -Version "1.0.x"
```

没有脚本时使用本 Skill 脚本：

```powershell
<skill目录>\scripts\package-codewave-library.ps1 `
  -ProjectRoot "<项目根目录>" `
  -Version "1.0.x"
```

脚本会执行：

1. 更新 Maven 版本。
2. 安装并构建前端。
3. 复制 `frontend/dist/index.html` 到 `static/app.html`。
4. 构建可选服务依赖库。
5. 构建后端代理依赖库。
6. 检查 target 下的 zip。

## zip 验收清单

必须检查：

- zip 文件存在且大小不为 0。
- zip 包含 `static/app.html` 或等效页面资源。
- Maven 版本号已递增。
- 前端没有引用平台不可访问的 `/assets/*.js`。
- 包内没有 `node_modules`、`frontend/dist`、`.env`、`.zip` 嵌套包。
- 包内没有明显冲突依赖，例如完整业务后端服务包、平台已提供的 Spring/MyBatis 冲突依赖。

## CodeWave 导入顺序

如果同时存在服务依赖库和代理依赖库：

1. 先导入服务依赖库 zip。
2. 再导入后端代理依赖库 zip。
3. 发布开发环境。
4. 创建或更新平台页面入口。
5. 测试页面加载和 `/callApi`。
6. 再发布生产环境。

## 最终回复模板

交付时给用户：

```text
已生成依赖库：
<zip 绝对路径>

已完成：
- 前端构建
- app.html 嵌入
- 后端依赖库打包
- zip 检查

平台导入：
1. 导入 <zip>
2. 页面入口调用 /api/<library_name>/getAppHtml
3. 前端 API 走 /<library_name>/callApi
```
