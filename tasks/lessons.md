# AgentOS — Lessons Learned

## L1: App Sandbox Entitlements (CRITICAL)

**Problem**: `ENABLE_APP_SANDBOX = YES` in pbxproj but no `.entitlements` file → all network blocked silently.

**Pattern**: Xcode 新项目会设置 `ENABLE_APP_SANDBOX = YES` 但不一定自动生成 `.entitlements` 文件。症状是所有 URLSession 请求静默失败，报 `URLError` — 非常难排查因为 curl 从终端可以正常工作。

**Fix**: 创建 `.entitlements` 文件 + 在 pbxproj 的 Debug/Release 都加 `CODE_SIGN_ENTITLEMENTS`。

**Verify**: `codesign -d --entitlements -` 检查签名后的 app 确实包含权限。

**Rule**: 每次建新 macOS 项目，第一件事确认 entitlements 文件存在且 wired。

---

## L2: Hardcoded Provider Assumptions

**Problem**: `apiKeyMissing` 只检查 Anthropic，但 CEO 可能配置为 Ollama（不需要 key）。

**Pattern**: 当系统支持多 provider 时，不要把 provider-specific 逻辑 hardcode 在 UI 层。

**Fix**: 删掉 stale 的 `apiKeyMissing` computed property，依赖 `sendMessage()` 里已有的 per-provider pre-flight check。

**Rule**: 验证逻辑应该集中在一个地方，不要在 ViewModel 和 View 里各写一份。

---

## L3: Raw Error Messages → User-Facing Hints

**Problem**: `error.localizedDescription` 显示的是 `URLError` 的技术文本，用户看不懂。

**Pattern**: 网络错误需要翻译成 actionable hints — 告诉用户该做什么而不是报内部错误码。

**Fix**: `friendlyErrorMessage(for:)` 静态方法，按 URLError code 分类给出建议。

**Rule**: 所有 catch block 里向用户展示的错误，都要经过一层 "friendly" 翻译。

---

## L4: Ollama API Endpoints

**Info**: Ollama 有两套 API:
- `/v1/chat/completions` — OpenAI-compatible，用于正常推理请求
- `/api/tags` — Ollama native，返回已安装模型列表（`GET`，无需 auth）

**Note**: `customBaseURL` 存的是 `/v1` 路径，调 `/api/tags` 时要 strip `/v1` suffix。

---

## L5: os.Logger for macOS Apps

**Pattern**: 用 `os.Logger(subsystem:category:)` 替代 `print()` — 可在 Console.app 按 subsystem 过滤。

**Convention**: subsystem = `"com.thomas.agentos"`, category = 类名（如 `"ClaudeProvider"`, `"CEOChat"`）。

---

## L6: pbxproj Editing

**Pattern**: `project.pbxproj` 用 `PBXFileSystemSynchronizedRootGroup` 时（Xcode 16+ 新项目），文件自动 sync，不需要手动在 pbxproj 注册每个 .swift 文件。但 build settings（如 `CODE_SIGN_ENTITLEMENTS`）仍然需要手动编辑。

**Tip**: 找到 target 的 Debug 和 Release `XCBuildConfiguration` section，两个都要改。
