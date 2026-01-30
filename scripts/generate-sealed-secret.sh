#!/bin/bash
# Script to generate SealedSecret for Discord Bot
# Run this from a machine with kubectl access to the cluster

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SEALED_SECRETS_DIR="$PROJECT_ROOT/kubernetes/base/sealed-secrets"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Discord Bot SealedSecret Generator ===${NC}"
echo ""

# Check for kubeseal
if ! command -v kubeseal &> /dev/null; then
    echo -e "${RED}Error: kubeseal is not installed${NC}"
    echo "Install it with: brew install kubeseal"
    exit 1
fi

# Check for kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Check cluster connectivity
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
    echo "Make sure you have a valid kubeconfig"
    exit 1
fi

# Load from .env file if it exists
ENV_FILE="${PROJECT_ROOT}/../discord-bot/.env"
if [[ -f "$ENV_FILE" ]]; then
    echo -e "${GREEN}Loading values from .env file...${NC}"
    source "$ENV_FILE"
else
    echo -e "${YELLOW}No .env file found at $ENV_FILE${NC}"
    echo "Please provide the following values:"
fi

# Prompt for missing values
if [[ -z "$DISCORD_TOKEN" ]]; then
    read -p "Enter DISCORD_TOKEN: " DISCORD_TOKEN
fi

if [[ -z "$DISCORD_CLIENT_ID" ]]; then
    read -p "Enter DISCORD_CLIENT_ID: " DISCORD_CLIENT_ID
fi

if [[ -z "$ALLOWED_USER_IDS" ]]; then
    read -p "Enter ALLOWED_USER_IDS (comma-separated): " ALLOWED_USER_IDS
fi

if [[ -z "$OLLAMA_HOST" ]]; then
    OLLAMA_HOST="http://192.168.50.59:11434"
    echo -e "${YELLOW}Using default OLLAMA_HOST: $OLLAMA_HOST${NC}"
fi

if [[ -z "$OLLAMA_MODEL" ]]; then
    OLLAMA_MODEL="qwen-tools"
    echo -e "${YELLOW}Using default OLLAMA_MODEL: $OLLAMA_MODEL${NC}"
fi

if [[ -z "$OLLAMA_TIMEOUT" ]]; then
    OLLAMA_TIMEOUT="120000"
    echo -e "${YELLOW}Using default OLLAMA_TIMEOUT: $OLLAMA_TIMEOUT${NC}"
fi

# Create sealed-secrets directory
mkdir -p "$SEALED_SECRETS_DIR"

echo ""
echo -e "${GREEN}Creating SealedSecret...${NC}"

# Create the secret and pipe to kubeseal
kubectl create secret generic discord-bot-credentials \
    --namespace=discord-bot \
    --from-literal=DISCORD_TOKEN="$DISCORD_TOKEN" \
    --from-literal=DISCORD_CLIENT_ID="$DISCORD_CLIENT_ID" \
    --from-literal=ALLOWED_USER_IDS="$ALLOWED_USER_IDS" \
    --from-literal=OLLAMA_HOST="$OLLAMA_HOST" \
    --from-literal=OLLAMA_MODEL="$OLLAMA_MODEL" \
    --from-literal=OLLAMA_TIMEOUT="$OLLAMA_TIMEOUT" \
    --dry-run=client -o yaml | \
kubeseal --format yaml > "$SEALED_SECRETS_DIR/discord-bot-credentials.yaml"

echo ""
echo -e "${GREEN}✓ SealedSecret created at:${NC}"
echo "  $SEALED_SECRETS_DIR/discord-bot-credentials.yaml"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review the generated sealed secret"
echo "2. Commit and push the changes"
echo "3. ArgoCD will automatically deploy the sealed secret"
echo ""
echo -e "${GREEN}Done!${NC}"
