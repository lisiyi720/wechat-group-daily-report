# WeChat Group Daily Report Skill

一个可移植的 Codex Skill：按日期采集使用者自己选择的微信群消息，并整理成结构化 Markdown 日报。可选接入飞书/Lark 群消息。

## 特点

- 不包含任何预置私人群名、聊天 ID 或本机路径。
- 首次运行时录入自己的关注群。
- 严格按配置时区划分每日消息。
- 保留原始 URL、未解析链接说明和高价值附件。
- 输出适合 Obsidian 使用的六段式 Markdown 日报。
- 飞书/Lark 为可选项，不配置也能正常运行微信日报。

## 安装

将整个 `wechat-group-daily-report` 文件夹复制到 Codex Skills 目录，不要只复制 `SKILL.md`。

首次配置：

```bash
bash scripts/init_config.sh
```

按提示填写：

1. 日报保存目录。
2. 时区，默认 `Asia/Shanghai`。
3. 要关注的微信群准确名称。

详细说明见 [`references/setup-guide.md`](references/setup-guide.md)。

## 使用

对 Codex 说：

```text
请使用 wechat-group-daily-report Skill，生成昨天的微信群日报。
```

也可运行脚本：

```bash
bash scripts/run_daily_report_agent.sh 2026-01-15
```

## 前置条件

- macOS 微信客户端及能够读取本人有权访问消息的 `wechat-cli`。
- 如需自动生成报告正文，需要 Codex CLI。
- 如需飞书/Lark 来源，需要已登录的 `lark-cli`。

本项目只应处理使用者本人有权访问的聊天数据。公开、转发或二次分享日报前，请检查个人信息、客户资料和群成员隐私。

## 目录

```text
wechat-group-daily-report/
├── SKILL.md
├── README.md
├── agents/
├── config/
├── references/
└── scripts/
```

