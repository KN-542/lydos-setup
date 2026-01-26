#!/bin/bash

# HTTPS証明書セットアップスクリプト
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔒 HTTPS開発環境のセットアップを開始します${NC}"

# プロジェクトルートに移動
cd "$(dirname "$0")/.."
CERTS_DIR="$(pwd)/certs"

mkdir -p "$CERTS_DIR"

# mkcertのインストール確認
if ! command -v mkcert &> /dev/null; then
    echo -e "${YELLOW}⚠️  mkcertがインストールされていません${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            echo "Homebrewを使用してmkcertをインストールします..."
            brew install mkcert
            brew install nss
        else
            echo "❌ Homebrewがインストールされていません"
            echo "以下のコマンドでmkcertを手動でインストールしてください："
            echo "  brew install mkcert"
            exit 1
        fi
    else
        echo "❌ mkcertをインストールしてください："
        echo "  https://github.com/FiloSottile/mkcert#installation"
        exit 1
    fi
fi

# mkcertのルートCA確認・インストール
if ! mkcert -CAROOT &> /dev/null || [ ! -f "$(mkcert -CAROOT)/rootCA.pem" ]; then
    echo "ローカルCAをインストールします..."
    mkcert -install
else
    echo -e "${GREEN}✓${NC} ローカルCAは既にインストール済みです"
fi

# 証明書の存在確認
CERT_FILE="$CERTS_DIR/localhost.pem"
KEY_FILE="$CERTS_DIR/localhost-key.pem"

if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
    echo -e "${GREEN}✓${NC} 証明書は既に存在します"
    if openssl x509 -checkend 2592000 -noout -in "$CERT_FILE" &> /dev/null; then
        echo -e "${GREEN}✓${NC} 証明書はまだ有効です"
    else
        echo -e "${YELLOW}⚠️  証明書の有効期限が近いか期限切れです。再生成します...${NC}"
        rm -f "$CERT_FILE" "$KEY_FILE"
        mkcert -cert-file "$CERT_FILE" -key-file "$KEY_FILE" localhost 127.0.0.1 ::1
        echo -e "${GREEN}✓${NC} 証明書を再生成しました"
    fi
else
    echo "証明書を生成します..."
    mkcert -cert-file "$CERT_FILE" -key-file "$KEY_FILE" localhost 127.0.0.1 ::1
    echo -e "${GREEN}✓${NC} 証明書を生成しました"
fi

# .gitignoreの更新
GITIGNORE_FILE="$(pwd)/.gitignore"
if [ -f "$GITIGNORE_FILE" ]; then
    if ! grep -q "^certs/" "$GITIGNORE_FILE"; then
        echo "" >> "$GITIGNORE_FILE"
        echo "# SSL certificates" >> "$GITIGNORE_FILE"
        echo "certs/" >> "$GITIGNORE_FILE"
        echo -e "${GREEN}✓${NC} .gitignoreに証明書ディレクトリを追加しました"
    else
        echo -e "${GREEN}✓${NC} .gitignoreは既に設定済みです"
    fi
else
    echo "# SSL certificates" > "$GITIGNORE_FILE"
    echo "certs/" >> "$GITIGNORE_FILE"
    echo -e "${GREEN}✓${NC} .gitignoreを作成しました"
fi

echo ""
echo -e "${GREEN}✅ セットアップが完了しました！${NC}"
echo ""
echo "次のコマンドでHTTPS開発サーバーを起動できます："
echo -e "  ${GREEN}yarn dev${NC}"
echo ""
echo "ブラウザで以下のURLにアクセスしてください："
echo -e "  ${GREEN}https://localhost:3000${NC}"
