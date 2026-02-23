#!/usr/bin/env python3
"""noctchill-agent Web ダッシュボードサーバー"""

import os
import re
import subprocess
import glob as glob_mod
import json
from datetime import datetime
from pathlib import Path
from functools import wraps

from flask import Flask, request, jsonify, render_template, abort
import yaml

# パス設定
PROJECT_ROOT = Path(__file__).parent.parent.resolve()
INSTANCE_NAME = os.environ.get("NOCTCHILL_INSTANCE", "default")
QUEUE_DIR = PROJECT_ROOT / "instances" / INSTANCE_NAME / "queue"
STATUS_DIR = PROJECT_ROOT / "instances" / INSTANCE_NAME / "status"
SESSION_NAME = f"noctchill-{INSTANCE_NAME}"

# エージェントペイン一覧
AGENT_PANES = {
    f"{SESSION_NAME}:0":   "プロデューサー",
    f"{SESSION_NAME}:2.0": "浅倉 透",
    f"{SESSION_NAME}:2.1": "樋口 円香",
    f"{SESSION_NAME}:2.2": "福丸 小糸",
    f"{SESSION_NAME}:2.3": "市川 雛菜",
}

# 認証トークン
API_TOKEN = os.environ.get("NOCTCHILL_API_TOKEN", "")
if not API_TOKEN:
    token_file = PROJECT_ROOT / "config" / "web_token"
    if token_file.exists():
        API_TOKEN = token_file.read_text().strip()

app = Flask(__name__)


def require_auth(f):
    """Bearer Token 認証デコレータ"""
    @wraps(f)
    def decorated(*args, **kwargs):
        if not API_TOKEN:
            return f(*args, **kwargs)
        token = request.headers.get("Authorization", "").replace("Bearer ", "")
        # Cookie からもトークンを受け付ける（ブラウザ用）
        if not token:
            token = request.cookies.get("auth_token", "")
        if token != API_TOKEN:
            abort(401)
        return f(*args, **kwargs)
    return decorated


def read_yaml_safe(path):
    """YAML ファイルを安全に読み込む"""
    try:
        with open(path, "r", encoding="utf-8") as f:
            return yaml.safe_load(f) or {}
    except (FileNotFoundError, yaml.YAMLError):
        return {}


def tmux_send(target, message):
    """tmux send-keys（2回分割ルール厳守）"""
    subprocess.run(["tmux", "send-keys", "-t", target, message],
                   capture_output=True)
    subprocess.run(["tmux", "send-keys", "-t", target, "Enter"],
                   capture_output=True)


def capture_pane(target):
    """tmux ペインの内容を取得する"""
    result = subprocess.run(
        ["tmux", "capture-pane", "-t", target, "-p"],
        capture_output=True, text=True
    )
    return result.stdout if result.returncode == 0 else ""


# Claude Code の許可プロンプトパターン
_PROMPT_PATTERNS = [
    # ❯ Yes / No 形式（矢印は複数のUnicode候補）
    re.compile(r"[❯>]\s*(Yes|はい)", re.MULTILINE),
    re.compile(r"[❯>]\s*(No|いいえ)", re.MULTILINE),
    re.compile(r"[❯>]\s*(Allow|許可)", re.MULTILINE),
    # [y/n] / [y/n/a/N] 形式
    re.compile(r"\[y/n(/a(/N)?)?\]", re.IGNORECASE),
    # "Yes, don't ask again" パターン
    re.compile(r"Yes,\s*don.t ask again", re.IGNORECASE),
    # Claude Code の典型的な許可ダイアログ
    re.compile(r"Do you want to|Allow Claude|permission to|を実行してもよいですか", re.IGNORECASE),
]

# ツール名・コマンド抽出パターン
_TOOL_PATTERNS = [
    re.compile(r"Tool:\s*(.+)", re.IGNORECASE),
    re.compile(r"Command:\s*(.+)", re.IGNORECASE),
    re.compile(r"Run:\s*(.+)", re.IGNORECASE),
    re.compile(r"bash\s+(.+)", re.IGNORECASE),
]


def detect_permission_prompt(pane_content):
    """ペイン内容からClaude Codeの許可プロンプトを検出する。
    検出された場合は dict を、なければ None を返す。"""
    if not pane_content:
        return None

    # 末尾300文字に絞って検索（最新のプロンプトのみ対象）
    recent = pane_content[-300:]

    matched_pattern = None
    for pat in _PROMPT_PATTERNS:
        if pat.search(recent):
            matched_pattern = pat.pattern
            break

    if not matched_pattern:
        return None

    # ツール名やコマンドを抽出
    tool_info = ""
    for pat in _TOOL_PATTERNS:
        m = pat.search(recent)
        if m:
            tool_info = m.group(1).strip()[:200]
            break

    # 選択肢を確認（"don't ask again" があれば always/never も提示）
    has_always = bool(re.search(r"don.t ask again|always|Always", recent, re.IGNORECASE))

    return {
        "tool": tool_info,
        "snippet": recent.strip(),
        "has_always": has_always,
    }


def tmux_session_exists():
    """tmux セッションの存在確認"""
    result = subprocess.run(
        ["tmux", "has-session", "-t", SESSION_NAME],
        capture_output=True
    )
    return result.returncode == 0


# --- ページ ---

@app.route("/")
def index():
    """ダッシュボードページ"""
    return render_template("index.html",
                           instance_name=INSTANCE_NAME,
                           api_token=API_TOKEN)


@app.route("/login", methods=["POST"])
def login():
    """トークン認証（ブラウザ用）"""
    data = request.json or {}
    token = data.get("token", "")
    if not API_TOKEN or token == API_TOKEN:
        resp = jsonify({"status": "ok"})
        resp.set_cookie("auth_token", token, httponly=True, samesite="Strict")
        return resp
    return jsonify({"status": "error", "message": "Invalid token"}), 401


# --- API ---

@app.route("/api/dashboard")
@require_auth
def api_dashboard():
    """ダッシュボード内容を返す"""
    dashboard_file = STATUS_DIR / "dashboard.md"
    content = ""
    if dashboard_file.exists():
        content = dashboard_file.read_text(encoding="utf-8")
    return jsonify({"content": content})


@app.route("/api/reports")
@require_auth
def api_reports():
    """全レポートを返す"""
    reports = {}
    reports_dir = QUEUE_DIR / "reports"
    if reports_dir.exists():
        for f in sorted(reports_dir.glob("*_report.yaml")):
            name = f.stem.replace("_report", "")
            reports[name] = read_yaml_safe(f)
    return jsonify({"reports": reports})


@app.route("/api/reports/<name>")
@require_auth
def api_report(name):
    """個別レポートを返す"""
    report_file = QUEUE_DIR / "reports" / f"{name}_report.yaml"
    if not report_file.exists():
        abort(404)
    return jsonify({"report": read_yaml_safe(report_file)})


@app.route("/api/status")
@require_auth
def api_status():
    """システム状態を返す"""
    session_active = tmux_session_exists()

    # 現在のタスク入力を取得
    task_input = read_yaml_safe(QUEUE_DIR / "task_input.yaml")

    # レポートの状態
    reports_dir = QUEUE_DIR / "reports"
    report_count = 0
    if reports_dir.exists():
        for f in reports_dir.glob("*_report.yaml"):
            if f.stat().st_size > 0:
                report_count += 1

    # 承認待ちの有無
    approval_pending = False
    approval_file = QUEUE_DIR / "approvals" / "approval_request.yaml"
    response_file = QUEUE_DIR / "approvals" / "approval_response.yaml"
    if approval_file.exists() and approval_file.stat().st_size > 0:
        if not response_file.exists() or response_file.stat().st_size == 0:
            approval_pending = True

    return jsonify({
        "session_active": session_active,
        "instance_name": INSTANCE_NAME,
        "current_task": task_input,
        "reports_completed": report_count,
        "reports_total": 4,
        "approval_pending": approval_pending,
    })


@app.route("/api/task", methods=["POST"])
@require_auth
def api_submit_task():
    """タスクを投入する"""
    if not tmux_session_exists():
        return jsonify({"status": "error",
                        "message": "tmux セッションが起動していません"}), 503

    data = request.json or {}
    command = data.get("command", "").strip()
    if not command:
        return jsonify({"status": "error",
                        "message": "command は必須です"}), 400

    task_yaml = {
        "task_id": data.get("task_id",
                            f"web_{datetime.now().strftime('%Y%m%d%H%M%S')}"),
        "command": command,
        "description": data.get("description", ""),
        "priority": data.get("priority", "normal"),
        "deadline": data.get("deadline", ""),
        "notes": data.get("notes", ""),
    }

    # task_input.yaml に書き込み
    task_file = QUEUE_DIR / "task_input.yaml"
    task_file.parent.mkdir(parents=True, exist_ok=True)
    with open(task_file, "w", encoding="utf-8") as f:
        yaml.dump(task_yaml, f, allow_unicode=True, default_flow_style=False)

    # プロデューサーに通知
    msg = f"[TASK] 新しいタスクが届きました。{task_file} を確認してください。"
    tmux_send(f"{SESSION_NAME}:0", msg)

    # ntfy 通知
    subprocess.Popen([
        "bash", str(PROJECT_ROOT / "scripts" / "notify.sh"),
        "タスク送信 (Web)", f"[{INSTANCE_NAME}] {command}",
        "default", "globe_with_meridians"
    ])

    return jsonify({"status": "ok", "task_id": task_yaml["task_id"]})


@app.route("/api/approvals")
@require_auth
def api_approvals():
    """承認リクエスト一覧を返す"""
    approvals_dir = QUEUE_DIR / "approvals"
    result = {"pending": [], "history": []}

    if not approvals_dir.exists():
        return jsonify(result)

    request_file = approvals_dir / "approval_request.yaml"
    response_file = approvals_dir / "approval_response.yaml"

    if request_file.exists() and request_file.stat().st_size > 0:
        req = read_yaml_safe(request_file)
        if response_file.exists() and response_file.stat().st_size > 0:
            resp = read_yaml_safe(response_file)
            req["response"] = resp
            result["history"].append(req)
        else:
            result["pending"].append(req)

    return jsonify(result)


@app.route("/api/approvals/<request_id>/approve", methods=["POST"])
@require_auth
def api_approve(request_id):
    """承認する"""
    return _handle_approval(request_id, "approved")


@app.route("/api/approvals/<request_id>/reject", methods=["POST"])
@require_auth
def api_reject(request_id):
    """却下する"""
    return _handle_approval(request_id, "rejected")


def _handle_approval(request_id, decision):
    """承認/却下の共通処理"""
    approvals_dir = QUEUE_DIR / "approvals"
    request_file = approvals_dir / "approval_request.yaml"

    if not request_file.exists():
        abort(404)

    req = read_yaml_safe(request_file)
    if req.get("request_id") != request_id:
        abort(404)

    # レスポンスファイルに書き込み
    response_file = approvals_dir / "approval_response.yaml"
    response_data = {
        "request_id": request_id,
        "decision": decision,
        "decided_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "decided_by": "web_dashboard",
    }
    with open(response_file, "w", encoding="utf-8") as f:
        yaml.dump(response_data, f, allow_unicode=True,
                  default_flow_style=False)

    # プロデューサーに通知
    if tmux_session_exists():
        tag = "APPROVED" if decision == "approved" else "REJECTED"
        tmux_send(f"{SESSION_NAME}:0",
                  f"[{tag}] {request_id} が{('承認' if decision == 'approved' else '却下')}されました。")

    # ntfy 通知
    label = "承認" if decision == "approved" else "却下"
    subprocess.Popen([
        "bash", str(PROJECT_ROOT / "scripts" / "notify.sh"),
        f"{label}完了", f"[{INSTANCE_NAME}] {request_id}: {label}しました",
        "default", "white_check_mark" if decision == "approved" else "x"
    ])

    return jsonify({"status": decision, "request_id": request_id})


@app.route("/api/pending-approvals")
@require_auth
def api_pending_approvals():
    """許可プロンプト待ちのペイン一覧を返す"""
    if not tmux_session_exists():
        return jsonify({"pending": []})

    pending = []
    for target, agent_name in AGENT_PANES.items():
        content = capture_pane(target)
        info = detect_permission_prompt(content)
        if info:
            pending.append({
                "target": target,
                "agent": agent_name,
                "tool": info["tool"],
                "snippet": info["snippet"],
                "has_always": info["has_always"],
            })

    return jsonify({"pending": pending})


@app.route("/api/approve-pane", methods=["POST"])
@require_auth
def api_approve_pane():
    """指定ペインに応答キーを送信する"""
    data = request.json or {}
    target = data.get("target", "")
    decision = data.get("decision", "")  # "y" / "n" / "a" / "N"

    if not target or decision not in ("y", "n", "a", "N"):
        return jsonify({"status": "error",
                        "message": "target と decision(y/n/a/N) が必要です"}), 400

    if target not in AGENT_PANES:
        return jsonify({"status": "error",
                        "message": "不正なターゲットです"}), 400

    if not tmux_session_exists():
        return jsonify({"status": "error",
                        "message": "tmux セッションが起動していません"}), 503

    tmux_send(target, decision)

    # ntfy 通知
    label_map = {"y": "許可", "n": "拒否", "a": "常に許可", "N": "常に拒否"}
    label = label_map.get(decision, decision)
    agent_name = AGENT_PANES[target]
    subprocess.Popen([
        "bash", str(PROJECT_ROOT / "scripts" / "notify.sh"),
        f"操作: {label}", f"[{INSTANCE_NAME}] {agent_name}: {label}しました",
        "default", "white_check_mark" if decision in ("y", "a") else "x"
    ])

    return jsonify({"status": "ok", "target": target, "decision": decision})


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="noctchill-agent Web Dashboard")
    parser.add_argument("--host", default="0.0.0.0", help="Host to bind to")
    parser.add_argument("--port", type=int, default=5000, help="Port to listen on")
    parser.add_argument("--debug", action="store_true", help="Enable debug mode")
    args = parser.parse_args()

    print(f"noctchill Web Dashboard")
    print(f"  Instance: {INSTANCE_NAME}")
    print(f"  Session:  {SESSION_NAME}")
    print(f"  Queue:    {QUEUE_DIR}")
    print(f"  Auth:     {'enabled' if API_TOKEN else 'disabled'}")
    print(f"  Listen:   http://{args.host}:{args.port}")
    print()

    app.run(host=args.host, port=args.port, debug=args.debug)
