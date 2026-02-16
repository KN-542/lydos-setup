# Lydos Setup

Lydosプロジェクト全体の開発環境をセットアップするための設定ファイルとスクリプトです。
何を作るかは未定です。

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

### 共通
| カテゴリ | 技術 |
|---|---|
| 言語 | TypeScript 5.x |
| ランタイム / パッケージマネージャ | Bun |
| Lint / Format | Biome |
| コンテナ | Docker |

### フロントエンド (lydos-view)
| カテゴリ | 技術 |
|---|---|
| UI Framework | React 19 |
| ビルドツール | Vite 7 (Rolldown) |
| ルーティング | TanStack Router (ファイルベース) |
| サーバーステート | TanStack Query 5 |
| スタイリング | Tailwind CSS 3 |
| 認証 | Clerk |
| API クライアント | openapi-fetch (型自動生成) |
| フォーム | React Hook Form |
| アイコン | lucide-react |

### バックエンド (lydos-api)
| カテゴリ | 技術 |
|---|---|
| Web Framework | Hono 4 |
| API 仕様 | OpenAPI 3.0 (@hono/zod-openapi) |
| バリデーション | Zod |
| ORM | Prisma 6 |
| DB | PostgreSQL 16 |
| キャッシュ | Redis 7 |
| 認証 | Clerk |
| 決済 | Stripe |
| LLM | Google Gemini / Groq (Llama) |

### モバイル (lydos-app)
| カテゴリ | 技術 |
|---|---|
| UI Framework | React Native 0.81 + React 19 |
| ビルドシステム | Expo 54 |
| ルーティング | Expo Router (ファイルベース) |
| スタイリング | NativeWind 4 (Tailwind CSS) |
| 認証 | Clerk (clerk-expo) |

### インフラ (lydos-iac)
| カテゴリ | 技術 |
|---|---|
| IaC | AWS CDK (TypeScript) |
| ホスティング | AWS ECS Fargate / Amplify |
| DB | Amazon RDS (PostgreSQL) |
| キャッシュ | Amazon ElastiCache (Redis) |
| CI/CD | AWS CodePipeline |

### ローカル開発環境
| カテゴリ | 技術 |
|---|---|
| HTTPS プロキシ | Nginx + mkcert |
| DB / Cache | Docker Compose |
