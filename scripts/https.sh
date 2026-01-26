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

# local.lydos用の証明書の存在確認
CERT_FILE="$CERTS_DIR/local.lydos.pem"
KEY_FILE="$CERTS_DIR/local.lydos-key.pem"

if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
    echo -e "${GREEN}✓${NC} local.lydos の証明書は既に存在します"
    # 証明書にlocal.api.lydosが含まれているか確認
    if openssl x509 -in "$CERT_FILE" -text -noout | grep -q "local.api.lydos"; then
        if openssl x509 -checkend 2592000 -noout -in "$CERT_FILE" &> /dev/null; then
            echo -e "${GREEN}✓${NC} 証明書はまだ有効です"
        else
            echo -e "${YELLOW}⚠️  証明書の有効期限が近いか期限切れです。再生成します...${NC}"
            rm -f "$CERT_FILE" "$KEY_FILE"
            mkcert -cert-file "$CERT_FILE" -key-file "$KEY_FILE" local.lydos local.api.lydos "*.local.lydos" 127.0.0.1 ::1
            echo -e "${GREEN}✓${NC} 証明書を再生成しました"
        fi
    else
        echo -e "${YELLOW}⚠️  証明書にlocal.api.lydosが含まれていません。再生成します...${NC}"
        rm -f "$CERT_FILE" "$KEY_FILE"
        mkcert -cert-file "$CERT_FILE" -key-file "$KEY_FILE" local.lydos local.api.lydos "*.local.lydos" 127.0.0.1 ::1
        echo -e "${GREEN}✓${NC} 証明書を再生成しました"
    fi
else
    echo "local.lydos用の証明書を生成します..."
    mkcert -cert-file "$CERT_FILE" -key-file "$KEY_FILE" local.lydos local.api.lydos "*.local.lydos" 127.0.0.1 ::1
    echo -e "${GREEN}✓${NC} 証明書を生成しました"
fi

# localhost用の証明書も生成（Vite開発サーバー用）
LOCALHOST_CERT="$CERTS_DIR/localhost.pem"
LOCALHOST_KEY="$CERTS_DIR/localhost-key.pem"

if [ ! -f "$LOCALHOST_CERT" ] || [ ! -f "$LOCALHOST_KEY" ]; then
    echo "localhost用の証明書を生成します..."
    mkcert -cert-file "$LOCALHOST_CERT" -key-file "$LOCALHOST_KEY" localhost 127.0.0.1 ::1
    echo -e "${GREEN}✓${NC} localhost用の証明書を生成しました"
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

# nginxのインストール確認
echo ""
echo "🌐 Nginxの設定を確認しています..."
if ! command -v nginx &> /dev/null; then
    echo -e "${YELLOW}⚠️  Nginxがインストールされていません${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            echo "Homebrewを使用してNginxをインストールします..."
            brew install nginx
            echo -e "${GREEN}✓${NC} Nginxをインストールしました"
        else
            echo "❌ Homebrewがインストールされていません"
            echo "以下のコマンドでNginxを手動でインストールしてください："
            echo "  brew install nginx"
            exit 1
        fi
    else
        echo "❌ Nginxをインストールしてください"
        exit 1
    fi
else
    echo -e "${GREEN}✓${NC} Nginxは既にインストール済みです"
fi

# Nginxの設定ディレクトリを検出
if [ -d "/opt/homebrew/etc/nginx" ]; then
    NGINX_DIR="/opt/homebrew/etc/nginx"
elif [ -d "/usr/local/etc/nginx" ]; then
    NGINX_DIR="/usr/local/etc/nginx"
else
    echo -e "${YELLOW}⚠️  Nginxの設定ディレクトリが見つかりません${NC}"
    NGINX_DIR="/usr/local/etc/nginx"
    sudo mkdir -p "$NGINX_DIR/servers"
fi

NGINX_CONF_SRC="$(pwd)/nginx.conf"
NGINX_CONF_DEST="$NGINX_DIR/servers/lydos.conf"

# Nginxの設定ファイルをコピー（証明書パスを置き換え）
echo "Nginx設定ファイルを配置しています..."
sudo mkdir -p "$NGINX_DIR/servers"

# 証明書パスを実際のパスに置き換えた一時ファイルを作成
TMP_NGINX_CONF="/tmp/lydos-nginx.conf"
sed "s|CERT_PATH|$CERT_FILE|g; s|KEY_PATH|$KEY_FILE|g" "$NGINX_CONF_SRC" > "$TMP_NGINX_CONF"

# 既存の設定と比較してコピーが必要か判断
if [ -f "$NGINX_CONF_DEST" ]; then
    if diff -q "$TMP_NGINX_CONF" "$NGINX_CONF_DEST" &> /dev/null; then
        echo -e "${GREEN}✓${NC} Nginx設定ファイルは既に最新です"
    else
        echo "Nginx設定ファイルを更新します..."
        sudo cp "$TMP_NGINX_CONF" "$NGINX_CONF_DEST"
        echo -e "${GREEN}✓${NC} Nginx設定ファイルを更新しました"
        NGINX_RELOAD_NEEDED=true
    fi
else
    sudo cp "$TMP_NGINX_CONF" "$NGINX_CONF_DEST"
    echo -e "${GREEN}✓${NC} Nginx設定ファイルを配置しました"
    NGINX_RELOAD_NEEDED=true
fi

# 一時ファイルを削除
rm -f "$TMP_NGINX_CONF"

# メインのnginx.confにserversディレクトリのincludeがあるか確認
MAIN_NGINX_CONF="$NGINX_DIR/nginx.conf"
if [ -f "$MAIN_NGINX_CONF" ]; then
    if ! grep -q "include.*servers/\*" "$MAIN_NGINX_CONF" 2>/dev/null; then
        echo "メインのnginx.confにserversディレクトリのincludeを追加します..."
        sudo sed -i.bak '/http {/a\
    include servers/*;
' "$MAIN_NGINX_CONF"
        echo -e "${GREEN}✓${NC} メインのnginx.confを更新しました"
        NGINX_RELOAD_NEEDED=true
    fi
    
    # WebSocket用のmapディレクティブを追加
    if ! grep -q "map \$http_upgrade \$connection_upgrade" "$MAIN_NGINX_CONF" 2>/dev/null; then
        echo "メインのnginx.confにWebSocket用のmapディレクティブを追加します..."
        sudo sed -i.bak '/http {/a\
    # WebSocket用のConnectionヘッダーマッピング\
    map $http_upgrade $connection_upgrade {\
        default upgrade;\
        '"'"''"'"'      close;\
    }\
' "$MAIN_NGINX_CONF"
        echo -e "${GREEN}✓${NC} WebSocket用のmapディレクティブを追加しました"
        NGINX_RELOAD_NEEDED=true
    fi
fi

# /etc/hostsの更新
echo ""
echo "📝 /etc/hostsの設定を確認しています..."

HOSTS_UPDATED=false
if ! grep -q "local.lydos" /etc/hosts 2>/dev/null; then
    echo -e "${YELLOW}⚠️  /etc/hostsに local.lydos が設定されていません${NC}"
    echo "管理者権限で /etc/hosts に追加します（パスワードの入力が必要です）"
    
    if sudo sh -c "echo '127.0.0.1 local.lydos local.api.lydos' >> /etc/hosts" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} /etc/hosts に local.lydos と local.api.lydos を追加しました"
        HOSTS_UPDATED=true
    else
        echo -e "${YELLOW}⚠️  /etc/hosts の更新に失敗しました${NC}"
        echo "手動で以下を /etc/hosts に追加してください："
        echo "  127.0.0.1 local.lydos local.api.lydos"
    fi
else
    # local.lydosはあるがlocal.api.lydosがない場合
    if ! grep -q "local.api.lydos" /etc/hosts 2>/dev/null; then
        echo "local.api.lydosを追加します..."
        sudo sed -i.bak 's/127.0.0.1 local.lydos$/127.0.0.1 local.lydos local.api.lydos/' /etc/hosts
        echo -e "${GREEN}✓${NC} /etc/hosts に local.api.lydos を追加しました"
        HOSTS_UPDATED=true
    else
        echo -e "${GREEN}✓${NC} /etc/hostsに local.lydos と local.api.lydos は既に設定されています"
    fi
fi

# メインのnginx.confのデフォルトserverブロックをコメントアウト
echo ""
echo "📝 メインのnginx.confを調整しています..."
if grep -q "listen.*8080" "$MAIN_NGINX_CONF" 2>/dev/null; then
    if ! grep -q "#.*listen.*8080" "$MAIN_NGINX_CONF" 2>/dev/null; then
        echo "デフォルトの8080ポートをコメントアウトします..."
        sudo sed -i.bak 's/^\([[:space:]]*\)listen[[:space:]]*8080/\1#listen       8080/' "$MAIN_NGINX_CONF"
        sudo sed -i.bak 's/^\([[:space:]]*\)listen[[:space:]]*\[::\]:8080/\1#listen       [::]:8080/' "$MAIN_NGINX_CONF"
        echo -e "${GREEN}✓${NC} デフォルトの8080ポートを無効化しました"
        NGINX_RELOAD_NEEDED=true
    fi
fi

# Nginxの起動・リロード
echo ""
echo "🚀 Nginxの状態を確認しています..."

# 設定ファイルのテスト
if ! sudo nginx -t 2>&1 | grep -q "successful"; then
    echo -e "${YELLOW}⚠️  Nginx設定ファイルにエラーがあります${NC}"
    sudo nginx -t
    exit 1
fi

# nginxプロセスの確認（より正確に）
if sudo nginx -t &> /dev/null && ps aux | grep -v grep | grep -q "nginx: master"; then
    if [ "$NGINX_RELOAD_NEEDED" = true ]; then
        echo "Nginxをリロードしています..."
        sudo nginx -s reload 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓${NC} Nginxをリロードしました"
        else
            echo -e "${YELLOW}⚠️  Nginxのリロードに失敗しました。再起動を試みます...${NC}"
            sudo nginx -s stop 2>&1
            sleep 1
            sudo nginx 2>&1
            echo -e "${GREEN}✓${NC} Nginxを再起動しました"
        fi
    else
        echo -e "${GREEN}✓${NC} Nginxは既に起動しています"
    fi
else
    echo "Nginxを起動しています..."
    # 念のため既存のプロセスを停止
    sudo nginx -s stop 2>/dev/null || true
    sleep 1
    
    if sudo nginx 2>&1; then
        echo -e "${GREEN}✓${NC} Nginxを起動しました"
    else
        echo -e "${YELLOW}⚠️  Nginxの起動に失敗しました${NC}"
        # ポートの使用状況を確認
        echo "ポート80, 443の使用状況："
        lsof -i :80 -i :443 2>/dev/null || echo "  使用されていません"
    fi
fi

echo ""
echo -e "${GREEN}✅ セットアップが完了しました！${NC}"
echo ""
echo "次の手順で開発サーバーを起動してください："
echo ""
echo "1. APIサーバーを起動（lydos-apiディレクトリで）："
echo -e "   ${GREEN}cd ../lydos-api && bun run dev${NC}"
echo ""
echo "2. フロントエンドを起動（lydos-viewディレクトリで、別ターミナルで）："
echo -e "   ${GREEN}cd ../lydos-view && bun run dev${NC}"
echo ""
echo "ブラウザで以下のURLにアクセスしてください："
echo -e "  フロントエンド: ${GREEN}https://local.lydos/${NC}"
echo -e "  API: ${GREEN}https://local.api.lydos/${NC}"
echo -e "  APIドキュメント: ${GREEN}https://local.api.lydos/reference${NC}"
echo ""
echo "💡 Nginxの管理コマンド："
echo -e "  起動: ${GREEN}sudo nginx${NC}"
echo -e "  停止: ${GREEN}sudo nginx -s stop${NC}"
echo -e "  リロード: ${GREEN}sudo nginx -s reload${NC}"
echo -e "  設定テスト: ${GREEN}sudo nginx -t${NC}"
