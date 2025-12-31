#!/bin/bash

ENV_FILE=".env"
HTPASSWD_FILE="./data/configurations/.htpasswd"
ACME_LE="./data/acme-le.json"
ACME_BP="./data/acme-buypass.json"

echo "------------------------------------------"
echo "   Traefik 2025 Secrets & Permissions    "
echo "------------------------------------------"

# Prompt for Environmet Variables
read -p "Enter your Domain (e.g., traefik.example.com): " MY_DOMAIN
read -p "Enter your Admin Email (for SSL alerts): " MY_EMAIL

# Create/Overwrite .env file
echo "Generating $ENV_FILE..."
cat <<EOF > $ENV_FILE
DOMAIN=$MY_DOMAIN
ACME_EMAIL=$MY_EMAIL
EOF

# Handle .htpasswd (Dashboard Credentials)
echo ""
echo "Setup Dashboard Credentials"
read -p "Enter Dashboard Username: " AUTH_USER

# Read password silently
read -s -p "Enter Dashboard Password: " AUTH_PASS
echo ""

if command -v  openssl >/dev/null; then
    # Create directory if it accidentally doesn't exist
    mkdir -p "$(dirname "$HTPASSWD_FILE")"

    # Generate the MD5 hash
    HASH=$(openssl passwd -apr1 "$AUTH_PASS")
    echo "$AUTH_USER:$HASH" > "$HTPASSWD_FILE"
    chmod 600 "$HTPASSWD_FILE"
    echo "Created $HTPASSWD_FILE with restricted permissions."
else
    echo "Error: openssl not found. Cannot generate hash."
fi

# Handle ACME JSON files
echo ""
echo "Setting up ACME storage files..."

# Function to create and secure file
setup_acme_file() {
    if [ ! -f "$1" ]; then
        touch "$1"
        echo "Created $1"
    fi
    chmod 600 "$1"
    echo "Permissions set 600 for $1"
}

setup_acme_file "$ACME_LE"
setup_acme_file "$ACME_BP"

echo ""
echo "Configuration Ready!"
echo "------------------------------------------"
echo "Next Steps:"
echo "1. Ensure your docker-compose.yml uses \${DOMAIN} and \${ACME_EMAIL}"
echo "2. Run: docker compose up -d"
echo "------------------------------------------"
