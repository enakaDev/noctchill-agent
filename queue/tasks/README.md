# テスト用初期タスクテンプレート

## 浅倉透用タスク

このファイルは、プロデューサーが浅倉透に指示を与えるために使用します。

```yaml
task_id: "test_001"
target: "asakura"
command: "テストファイル作成"
description: "テスト用マークダウンファイルを作成してください"
files_to_create:
  - path: "test_output/asakura_test.md"
    content: "# 浅倉透テスト完了\n\nこのファイルは透によって作成されました。"
deadline: "2026-02-05 16:00:00"
```

## 樋口円香用タスク

```yaml
task_id: "test_002"
target: "higuchi"
command: "テストファイル作成"
description: "テスト用マークダウンファイルを作成してください"
files_to_create:
  - path: "test_output/higuchi_test.md"
    content: "# 樋口円香テスト完了\n\nこのファイルは円香によって作成されました。"
deadline: "2026-02-05 16:00:00"
```

## 福丸小糸用タスク

```yaml
task_id: "test_003"
target: "fukumaru"
command: "テストファイル作成"
description: "テスト用マークダウンファイルを作成してください"
files_to_create:
  - path: "test_output/fukumaru_test.md"
    content: "# 福丸小糸テスト完了\n\nこのファイルは小糸によって作成されました。"
deadline: "2026-02-05 16:00:00"
```

## 市川雛菜用タスク

```yaml
task_id: "test_004"
target: "ichikawa"
command: "テストファイル作成"
description: "テスト用マークダウンファイルを作成してください"
files_to_create:
  - path: "test_output/ichikawa_test.md"
    content: "# 市川雛菜テスト完了\n\nこのファイルは雛菜によって作成されました。"
deadline: "2026-02-05 16:00:00"
```

---

上記のテンプレートは、実際の運用時にプロデューサーが必要に応じてカスタマイズします。
