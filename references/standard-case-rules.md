# 标准案例规则

用于把源码项目整理成可复用、可公开、可导入 CodeWave 的标准案例。

## 推荐目录

```text
project/
├── frontend/
├── backend-library/
├── service-library/        # 可选
├── sql/                    # 可选
├── scripts/
└── README.md
```

## 必备能力

- 前端页面能构建为单文件 HTML。
- 后端依赖库能读取 `static/app.html` 并通过 `getAppHtml` 返回。
- 前端 API 统一走相对路径代理。
- 后端代理通过 `callApi` 分发业务接口。
- 每次打包都递增 Maven 版本。
- 打包结果是 `library-*-{version}.zip`。

## 平台页面入口

平台只需要一个承载页。页面进入时调用：

```js
(async function () {
  const res = await fetch('/api/simple_proxy/getAppHtml', { method: 'POST' }).then(r => r.json());
  const html = res.Data || res.data || '';
  document.open();
  document.write(html);
  document.close();
})();
```

根据实际依赖库名称替换 `simple_proxy`。

## 可公开内容

可以保留：

- 通用代理模式
- 示例 CRUD
- 示例上传
- 示例登录
- 环境自适应写法
- 打包脚本
- 脱敏 SQL

不能保留：

- 真实客户业务数据
- 真实数据库导出
- 真实短信、微信、OpenAI 密钥
- 真实域名和库名
- 客户名称、手机号、身份证号
- 可反推出客户项目的页面文案或截图

## 打包产物建议

如果项目需要交给他人复用，可以额外整理：

```text
dist/codewave-package-{version}/
├── packages/
│   ├── library-xxx_service-{version}.zip
│   └── library-xxx_proxy-{version}.zip
├── platform/page-entry.js
├── sql/init.sql
└── README.md
```

Skill 本身不强制生成 `dist/`，除非用户明确要求“整理标准案例交付包”。
