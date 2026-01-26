# lydos-setup

Lydos開発環境のセットアップリポジトリ

## 概要

このリポジトリには、Lydosプロジェクトの開発環境に必要なDocker、Nginx、SSL証明書の設定が含まれています。

## セットアップ手順

### 1. 自動セットアップスクリプトの実行

```bash
bash scripts/https.sh
```

このスクリプトは以下を自動的に実行します：
- **mkcert**のインストール確認と自動インストール
- `local.lydos`と`localhost`用のSSL証明書の生成
- 証明書を`certs/`ディレクトリに保存
- **Nginx**のインストール確認と自動インストール
- Nginx設定ファイルの配置
- `/etc/hosts`に`local.lydos`と`local.api.lydos`を自動追加
- Nginxの起動

すべて冪等性を持っているため、何度実行しても安全です。

### 2. Dockerサービスの起動（データベース・キャッシュ）

```bash
docker-compose up -d
```

起動するサービス：
- **postgres**: データベース（ポート5433）
- **redis**: キャッシュ（ポート6379）

### 3. アプリケーションの起動

#### APIサーバー（lydos-apiディレクトリで実行）
```bash
cd ../lydos-api
bun run dev
```
- ポート: 3001
- URL: http://localhost:3001

#### フロントエンド（lydos-viewディレクトリで実行）
```bash
cd ../lydos-view
bun run dev
```
- ポート: 5173
- URL: https://localhost:5173

## アクセスURL

Nginxを通じて以下のURLでアクセスできます：

- **フロントエンド**: https://local.lydos/
- **API**: https://local.api.lydos/
- **APIドキュメント**: https://local.api.lydos/reference

## アーキテクチャ

```
┌─────────────────────┐
│   ブラウザ          │
└──────┬──────────┬───┘
       │          │
       │ HTTPS    │ HTTPS
       │          │
       ▼          ▼
┌─────────────────────┐
│  Nginx (Host)       │
│  ┌───────────────┐  │
│  │ local.lydos   │  │
│  └───────┬───────┘  │
│  ┌───────▼─────────┐│
│  │local.api.lydos  ││
│  └───────┬─────────┘│
└──────────┼──────────┘
     HTTPS │    HTTP
      │    └──────────┐
      ▼               ▼
┌──────────┐    ┌──────────┐
│  Vite    │    │  Hono    │
│  :5173   │    │  :3001   │
│(フロント)│    │  (API)   │
└──────────┘    └──────────┘
```

## ファイル構成

```
lydos-setup/
├── docker-compose.yml    # Dockerサービス定義
├── nginx.conf           # Nginx設定
├── certs/              # SSL証明書（自動生成）
│   ├── local.lydos.pem
│   ├── local.lydos-key.pem
│   ├── localhost.pem
│   └── localhost-key.pem
└── scripts/
    ├── https.sh        # SSL証明書生成・Nginxセットアップスクリプト
    └── bun.sh          # Bunインストールスクリプト
```

## Nginxの管理

セットアップスクリプトで自動的にNginxが起動されますが、手動で管理する場合は以下のコマンドを使用します：

```bash
# 起動
sudo nginx

# 停止
sudo nginx -s stop

# リロード（設定変更後）
sudo nginx -s reload

# 設定のテスト
sudo nginx -t

# エラーログの確認
tail -f /opt/homebrew/var/log/nginx/error.log
# または
tail -f /usr/local/var/log/nginx/error.log
```

## トラブルシューティング

### 証明書のエラーが出る場合

```bash
# 証明書を再生成
rm -rf certs/
bash scripts/https.sh
```

### Nginxが起動しない場合

```bash
# 設定ファイルをテスト
sudo nginx -t

# エラーログを確認
tail -f /opt/homebrew/var/log/nginx/error.log

# セットアップスクリプトを再実行
bash scripts/https.sh
```

### ポートが既に使用されている場合

```bash
# ポート使用状況を確認
lsof -i :80
lsof -i :443
lsof -i :3001
lsof -i :5173
```

## 注意事項

- このセットアップは開発環境用です
- 本番環境では適切なSSL証明書と設定を使用してください
- `certs/`ディレクトリは`.gitignore`に含まれており、Gitにコミットされません