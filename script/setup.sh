#!/bin/bash

# === 0. Variables ===
APP_NAME="monapp"
APP_PORT=3000
DOMAIN_NAME="votre-domaine.fr"  # À personnaliser si besoin
NODE_VERSION="18"

echo "🔧 Script d'installation pour hébergement IaaS (Ubuntu + Node.js)"

# === 1. Mise à jour du système ===
echo "📦 Mise à jour du système..."
sudo apt update && sudo apt upgrade -y

# === 2. Installation des dépendances ===
echo "📦 Installation de curl, git, nginx, etc."
sudo apt install -y curl git nginx ufw

# === 3. Installation de Node.js + npm ===
echo "⚙️ Installation de Node.js v$NODE_VERSION..."
curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION.x | sudo -E bash -
sudo apt install -y nodejs

# === 4. Installation de PM2 ===
echo "🚀 Installation de PM2 (gestionnaire de processus Node.js)..."
sudo npm install -g pm2

# === 5. Cloner le projet (ou créer un dossier HTML statique) ===
echo "📁 Clonage ou création du projet..."
mkdir -p /var/www/$APP_NAME
cd /var/www/$APP_NAME

# Exemple 1 : Hello world Node.js
echo "console.log('Hello depuis Node.js');" > index.js

# OU Exemple 2 : page HTML simple
# echo "<h1>Hello depuis un VPS IaaS !</h1>" > index.html

# === 6. Lancer l'app avec PM2 (Node.js) ===
echo "🚀 Lancement de l'application avec PM2..."
pm2 start index.js --name "$APP_NAME"
pm2 save
pm2 startup | bash

# === 7. Configuration de Nginx ===
echo "🌐 Configuration de Nginx..."
sudo tee /etc/nginx/sites-available/$APP_NAME > /dev/null <<EOL
server {
    listen 80;
    server_name $DOMAIN_NAME;

    location / {
        proxy_pass http://localhost:$APP_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL

# Activation du site
sudo ln -s /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

# === 8. Firewall (UFW) ===
echo "🔐 Configuration du pare-feu..."
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

# === 9. (Optionnel) Certificat SSL avec Certbot ===
# echo "🔒 Installation de Certbot pour SSL..."
# sudo apt install -y certbot python3-certbot-nginx
# sudo certbot --nginx -d $DOMAIN_NAME

echo "✅ Déploiement terminé ! Accédez à http://$DOMAIN_NAME ou http://<IP_SERVER>"

