# 安装与首次配置

## 1. 前置条件

1. macOS 本机已经登录微信，并能通过 `wechat-cli` 读取本人有权访问的群消息。
2. 终端中运行 `wechat-cli --help` 能正常返回帮助。
3. 如需飞书来源，另行安装并登录 `lark-cli`；不用飞书可以跳过。
4. 如需一键生成正文，安装并登录 Codex CLI；仅采集原始消息时不需要。

本 Skill 只应处理使用者本人有权访问的聊天内容。分享日报前应检查其中是否含私人信息、客户资料或群成员身份信息。

## 2. 安装 Skill

把整个 `wechat-group-daily-report` 文件夹复制到所用 Agent 的 Skills 目录。不要只复制 `SKILL.md`，脚本和 `references` 都是运行所需文件。

## 3. 配置

最简单的方式：

```bash
bash scripts/init_config.sh
```

脚本会：

1. 创建 `config/report.env`。
2. 询问日报保存目录。
3. 逐个录入要关注的微信群名称。
4. 保留空的飞书来源模板，供以后配置。

也可以把 `config/report.env.example` 复制为 `config/report.env` 后手动编辑。

## 4. 验证采集

先选择消息较少的一天测试：

```bash
bash scripts/collect_wechat_group_day.sh 2026-01-15
```

检查 `REPORT_ROOT/raw/2026-01-15/` 是否为每个群生成了 JSON。若为空或报错，优先检查：

1. 群名是否完全一致。
2. `wechat-cli` 是否已授权。
3. 当天是否确实有消息。
4. 当前用户是否能读取微信本地数据。

## 5. 生成日报

手动对 Agent 说：

> 请使用 wechat-group-daily-report Skill，生成昨天的微信群日报。

也可以运行：

```bash
bash scripts/run_daily_report_agent.sh 2026-01-15
```

## 6. 修改关注群

随时编辑 `references/watched-groups.md`：

```markdown
- 群名 A
- 群名 B
```

删除一行代表以后不再采集该群，不会自动删除已生成的历史 raw 数据和日报。

