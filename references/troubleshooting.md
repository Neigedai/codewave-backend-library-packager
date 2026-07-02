# CodeWave 依赖库排障

## `callApi` 返回 401

现象：

```json
{
  "Code": 401,
  "Message": "接口无权限访问"
}
```

排查：

1. 平台页面调用路径是否写错。
2. 是否导入并发布了最新版本依赖库。
3. 依赖库函数是否被平台正确暴露。
4. 是否被平台鉴权策略拦截。

修复：

- 递增版本后重新导入。
- 使用标准相对路径。
- 确认页面入口和依赖库 API 名称一致。

## MIME 或静态资源加载失败

现象：

```text
Failed to load module script
Expected a JavaScript module script but the server responded with MIME type text/html
```

原因：

- Vite 输出了 `/assets/*.js`，平台未按静态资源方式托管。

修复：

- 构建单文件 HTML。
- 将 `dist/index.html` 复制为 `static/app.html`。
- 由 `getAppHtml` 返回完整 HTML。

## 生产发布依赖冲突

常见现象：

- `HttpSecurity` 找不到
- Spring Security 冲突
- MyBatis-Plus 启动失败
- 平台发布开发环境成功、生产环境失败

修复：

- 不把完整业务后端服务包塞进依赖库。
- 对平台已有依赖使用 `provided`。
- 避免打入 Spring Security、MyBatis-Plus 等重量冲突依赖。
- 保留必要 CodeWave/NASL 兼容依赖。

## JDK 17 构建 NASL 插件失败

现象：

```text
IllegalAccessError: class com.netease.lowcode.core.NaslCollection
cannot access class com.sun.tools.javac.processing.JavacProcessingEnvironment
```

优先方案：

- 使用 JDK 8 构建 CodeWave 依赖库。

JDK 17 临时方案：

```powershell
$env:MAVEN_OPTS='--add-exports=jdk.compiler/com.sun.tools.javac.processing=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.code=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.model=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED'
```

如果 Maven 编译器配置了 `fork=true` 且错误被吞掉，先去掉 `fork=true` 以暴露真实错误。

## 数据库插入成功但查询不到

排查：

1. 是否连接了错误数据库。
2. 是否事务未提交。
3. 查询是否带了逻辑删除或状态过滤。
4. 创建接口和列表接口是否查了不同表。

修复：

- 统一 DataSource。
- 显式提交或使用正确事务边界。
- 对齐表名、字段名和过滤条件。

## datetime 字段报时间戳错误

现象：

```text
Incorrect datetime value: '1780243200000'
```

修复：

- 前端提交前格式化为 `yyyy-MM-dd HH:mm:ss`。
- 后端写入使用 `LocalDateTime` 或 SQL `now()`。

## 图片上传后不回显

排查：

1. 返回 URL 是否能在浏览器直接访问。
2. 数据库是否保存了新 URL。
3. 保存接口是否被其他字段错误回滚。
4. 前端是否仍显示旧缓存。

修复：

- 上传接口返回 HTTPS URL。
- 数据库保存可直接访问的 URL。
- 保存成功后重新查询详情。

## 小程序环境混乱

规则：

- 正式版小程序走生产域名。
- 开发版或体验版如需走开发环境，使用独立目录或独立配置。
- 小程序操作手册截图应来自微信开发者工具模拟器或真实手机。

不要用 PC 网页截图冒充小程序截图。
