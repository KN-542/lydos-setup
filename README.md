# Lydos Setup

Lydosプロジェクト全体の開発環境をセットアップするための設定ファイルとスクリプトです。
Lydosで何を作るかは未定です。

## セットアップ

```bash
# Bunインストール
./scripts/bun.sh

# HTTPS証明書・Nginx設定
./scripts/https.sh

# PostgreSQL & Redis起動
docker compose up -d
```

## アクセス

- フロントエンド: `https://local.lydos`
- API: `https://local.api.lydos`
- API Reference: `https://local.api.lydos/reference`

## 技術スタック

Bun, React 19, Vite, TanStack Router, TanStack Query, Tailwind CSS, Hono, OpenAPI, Zod, Prisma, PostgreSQL, Redis, TypeScript, Biome, mkcert, Nginx, Docker
