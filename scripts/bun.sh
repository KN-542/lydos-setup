#!/bin/bash

# Node.js / Bun環境セットアップスクリプト
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NVM_VERSION="0.40.3"
NODE_VERSION="22.18.0"
YARN_VERSION="1.22.22"
BUN_VERSION="1.3.6"

echo -e "${GREEN}🚀 Node.js/Bun開発環境のセットアップを開始します${NC}"
echo ""

# プロジェクトルートに移動
cd "$(dirname "$0")/.."

# ==============================================================================
# NVM のインストール
# ==============================================================================
echo -e "${BLUE}📦 NVM (Node Version Manager) をチェックしています...${NC}"

if [ -s "$HOME/.nvm/nvm.sh" ]; then
    # nvmが既にインストールされている
    source "$HOME/.nvm/nvm.sh"
    INSTALLED_NVM_VERSION=$(nvm --version 2>/dev/null || echo "unknown")
    
    if [ "$INSTALLED_NVM_VERSION" = "$NVM_VERSION" ]; then
        echo -e "${GREEN}✓${NC} NVM v$INSTALLED_NVM_VERSION は既にインストール済みです"
    else
        echo -e "${YELLOW}⚠️  NVM v$INSTALLED_NVM_VERSION がインストールされています（推奨: v$NVM_VERSION）${NC}"
        echo -e "${YELLOW}   既存のNVMをそのまま使用します${NC}"
    fi
else
    # nvmがインストールされていない
    echo "NVM v$NVM_VERSION をインストールしています..."
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh" | bash
    
    # nvmを即座に利用可能にする
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    echo -e "${GREEN}✓${NC} NVM v$NVM_VERSION をインストールしました"
fi

echo ""

# ==============================================================================
# Node.js のインストール
# ==============================================================================
echo -e "${BLUE}📦 Node.js v$NODE_VERSION をチェックしています...${NC}"

# nvmをロード
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if nvm list | grep -q "v$NODE_VERSION"; then
    echo -e "${GREEN}✓${NC} Node.js v$NODE_VERSION は既にインストール済みです"
    nvm use "$NODE_VERSION" &>/dev/null
else
    echo "Node.js v$NODE_VERSION をインストールしています..."
    nvm install "$NODE_VERSION"
    nvm use "$NODE_VERSION"
    nvm alias default "$NODE_VERSION"
    echo -e "${GREEN}✓${NC} Node.js v$NODE_VERSION をインストールしました"
fi

# 現在のNode.jsバージョンを確認
CURRENT_NODE_VERSION=$(node -v 2>/dev/null || echo "なし")
echo -e "   現在のNode.jsバージョン: ${GREEN}$CURRENT_NODE_VERSION${NC}"

echo ""

# ==============================================================================
# Yarn のインストール
# ==============================================================================
echo -e "${BLUE}📦 Yarn v$YARN_VERSION をチェックしています...${NC}"

if command -v yarn &> /dev/null; then
    INSTALLED_YARN_VERSION=$(yarn --version 2>/dev/null)
    
    if [ "$INSTALLED_YARN_VERSION" = "$YARN_VERSION" ]; then
        echo -e "${GREEN}✓${NC} Yarn v$INSTALLED_YARN_VERSION は既にインストール済みです"
    else
        echo -e "${YELLOW}⚠️  Yarn v$INSTALLED_YARN_VERSION がインストールされています${NC}"
        echo "Yarn v$YARN_VERSION に更新しています..."
        npm install -g "yarn@$YARN_VERSION"
        echo -e "${GREEN}✓${NC} Yarn を v$INSTALLED_YARN_VERSION から v$YARN_VERSION に更新しました"
    fi
else
    echo "Yarn v$YARN_VERSION をインストールしています..."
    npm install -g "yarn@$YARN_VERSION"
    echo -e "${GREEN}✓${NC} Yarn v$YARN_VERSION をインストールしました"
fi

echo ""

# ==============================================================================
# Bun のインストール
# ==============================================================================
echo -e "${BLUE}📦 Bun v$BUN_VERSION をチェックしています...${NC}"

# Bunのパスを設定
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

if command -v bun &> /dev/null; then
    INSTALLED_BUN_VERSION=$(bun --version 2>/dev/null)
    
    if [ "$INSTALLED_BUN_VERSION" = "$BUN_VERSION" ]; then
        echo -e "${GREEN}✓${NC} Bun v$INSTALLED_BUN_VERSION は既にインストール済みです"
    else
        echo -e "${YELLOW}⚠️  Bun v$INSTALLED_BUN_VERSION がインストールされています${NC}"
        echo "Bun v$BUN_VERSION に更新しています..."
        curl -fsSL https://bun.sh/install | bash -s "bun-v$BUN_VERSION"
        echo -e "${GREEN}✓${NC} Bun を v$INSTALLED_BUN_VERSION から v$BUN_VERSION に更新しました"
    fi
else
    echo "Bun v$BUN_VERSION をインストールしています..."
    curl -fsSL https://bun.sh/install | bash -s "bun-v$BUN_VERSION"
    echo -e "${GREEN}✓${NC} Bun v$BUN_VERSION をインストールしました"
    
    # シェル設定ファイルの更新を提案
    echo -e "${YELLOW}⚠️  新しいターミナルセッションでBunを使用するには、シェルを再起動してください${NC}"
fi

echo ""
echo -e "${GREEN}✅ セットアップが完了しました！${NC}"
echo ""
echo "インストールされたバージョン:"
echo -e "  NVM:    ${GREEN}$(nvm --version 2>/dev/null || echo 'エラー')${NC}"
echo -e "  Node.js: ${GREEN}$(node -v 2>/dev/null || echo 'エラー')${NC}"
echo -e "  Yarn:   ${GREEN}v$(yarn --version 2>/dev/null || echo 'エラー')${NC}"
echo -e "  Bun:    ${GREEN}v$(bun --version 2>/dev/null || echo 'エラー')${NC}"
echo ""
echo "次のコマンドを実行して、環境変数を現在のシェルに反映してください："
echo -e "  ${GREEN}source ~/.bashrc${NC}  # または source ~/.zshrc"
echo ""
