#!/bin/bash

# --- CONFIGURATION ---
DATA_DIR="./data"
CONF_DIR="./data/configurations"
ACME_FILES=("$DATA_DIR/acme-le.json" "$DATA_DIR/acme-buypass.json")
HTPASSWD_FILE="$CONF_DIR/.htpasswd"

echo "------------------------------------------"
echo "   Traefik 2025 Maintenance & Updates    "
echo "------------------------------------------"

# Fix Permissions (The most common cause of Traefik failure)
echo "Enforcing strict file permissions (600)..."
for file in "${ACME_FILES[@]}"; do
    if [ -f "$file" ]; then
        chmod 600 "$file"
        echo "Secured $file"
    else
        echo "Warning: $file not found."
    fi
done

if [ -f "$HTPASSWD_FILE" ]; then
    chmod 600 "$HTPASSWD_FILE"
    echo "Secured $HTPASSWD_FILE"
fi

# Refresh Credentials
read -p "Do you want to change the Dashboard password? (y/N): " change_pass
if [[ "$change_pass" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    read -p "Enter New Username: " NEW_USER
    read -s -p "Enter New Password: " NEW_PASS
    echo ""
    HASH=$(openssl passwd -apr1 "$NEW_PASS")
    echo "$NEW_USER:$HASH" > "$HTPASSWD_FILE"
    chmod 600 "$HTPASSWD_FILE"
    echo "Password updated."
fi

# Apply Changes
echo "Restarting Traefik to apply updates..."
docker compose up -d --remove-orphans

# Health Check
echo "Waiting for Traefik to initialize..."
sleep 3
if docker ps | grep -q traefik; then
    echo "Traefik is UP and running."
    echo "Recent Logs:"
    docker compose logs --tail=5 traefik
else
    echo "Traefik failed to start. Check logs with: docker compose logs traefik"
fi

echo "------------------------------------------"
