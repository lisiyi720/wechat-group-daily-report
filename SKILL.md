---
name: wechat-group-daily-report
description: "Collect and summarize a user-configured list of WeChat groups, with optional Feishu/Lark chats, into a structured Markdown daily report. Use whenever the user asks for 微信群日报、群消息日报、昨天群里聊了什么、按日期汇总微信群、提取群聊中的链接/文件/观点/待办，或希望把多个聊天来源整理成可扫描的日报。This portable edition contains no preset private groups; guide first-time users to configure their own watched groups before collection."
---

# 微信群消息日报（通用分享版）

把用户自己选择的微信群消息采集为原始 JSON，再生成结构化 Markdown 日报。飞书/Lark 来源是可选项。

## 首次使用

1. 阅读 `references/setup-guide.md`，确认本机已安装并授权 `wechat-cli`。
2. 运行 `bash scripts/init_config.sh`，填写日报保存位置和要关注的微信群。
3. 或手动编辑：
   - `references/watched-groups.md`：每行一个微信群名。
   - `references/lark-sources.md`：可选，每行一个飞书群名与 `chat_id`。
   - `config/report.env`：日报目录、时区和可选通知设置。
4. 配置文件里没有任何预置真实群名。不要猜测群名；首次运行若列表为空，引导用户完成配置。

## 工作流程

用户要求生成某日或昨天的日报时：

1. 按 `config/report.env` 的 `REPORT_TIMEZONE` 解析日期；未指定日期时取该时区的昨天。
2. 运行 `scripts/collect_wechat_group_day.sh YYYY-MM-DD`。
3. 若 `references/lark-sources.md` 配置了有效来源，运行 `python3 scripts/collect_lark_chat_day.py YYYY-MM-DD`。
4. 读取当天 `raw/YYYY-MM-DD/` 与 `raw-lark/YYYY-MM-DD/` 中的 JSON。
5. 按 `references/report-format.md` 汇总，保存为 `REPORT_ROOT/YYYY-MM-DD-微信群日报.md`。
6. 完成前检查文件真实存在、日期正确，并确认没有将消息写入用户未授权的目录。

## 微信采集

推荐使用脚本：

```bash
bash scripts/collect_wechat_group_day.sh 2026-01-15
```

脚本严格读取 `references/watched-groups.md`，使用本地时区日界线，并带 `--media` 以保留可用的图片、文件和附件路径。默认原始数据写入：

```text
REPORT_ROOT/raw/YYYY-MM-DD/
```

单群临时检查：

```bash
wechat-cli history "准确群名" \
  --start-time "YYYY-MM-DD 00:00:00" \
  --end-time "次日 YYYY-MM-DD 00:00:00" \
  --format json --limit 1000 --media
```

若消息数量达到上限或疑似截断，使用 `--offset` 分页，不要把截断结果当作完整日报。

## 飞书/Lark（可选）

配置有效来源后运行：

```bash
python3 scripts/collect_lark_chat_day.py 2026-01-15
```

脚本使用 Asia/Shanghai 或配置的 IANA 时区生成 Unix 时间戳，自动分页，并保留源消息字段。没有配置飞书来源时应正常跳过，而不是让整份日报失败。

## 总结规则

1. 先按来源总结，再提炼跨群趋势；重点写变化、争议、资源、机会、风险和明确的下一步。
2. 使用编号层级：`## 1. 今日总览`、`### 2.1 群名`，节内继续用 `1. 2. 3.`。
3. 用 `==重点结论==` 高亮判断、影响或风险，不要高亮普通事实。
4. 区分事实与推断；信息不足时写“可能”“群内说法”或“尚未核验”。
5. 原消息含 URL 时直接保留。CLI 只返回卡片标题或占位时，明确写“原链接未被 CLI 解析”，禁止补造链接。
6. 飞书消息存在 `message_app_link` 且有助于回看时，附上源消息链接。
7. 忽略问候、表情、重复赞美、无上下文图片等低信息消息。
8. PDF、文件、图片、截图和链接合计最多保留 3 个高价值项；优先方法论、教程、商业案例、工作流和明确行动机会。
9. 每个有消息的已配置来源都要出现；零消息来源可集中列明。
10. 不在报告中暴露本机账号凭证、聊天数据库位置、访问令牌或与日报无关的私人信息。

## 输出与验收

使用 `references/report-format.md` 的六段式结构。报告应足够简洁，读者可以迅速判断哪些内容值得回看。

完成前确认：

1. 日期与时区明确。
2. 报告保存到用户配置的 `REPORT_ROOT`。
3. 原始微信与飞书数据分别位于 `raw/YYYY-MM-DD`、`raw-lark/YYYY-MM-DD`。
4. 所有已配置且有消息的来源均被覆盖。
5. 原始 URL、未解析链接说明和 `message_app_link` 使用正确。
6. 高价值附件与链接不超过 3 项。
7. 最终文件存在且非空。
