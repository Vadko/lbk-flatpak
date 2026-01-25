# LBK Launcher — Flatpak Repository

Flatpak-пакет та OSTree-репозиторій для [LBK Launcher](https://github.com/Vadko/littlebit-launcher).

## Для користувачів

### Додати репозиторій

```bash
flatpak remote-add --if-not-exists lbk https://YOUR_COOLIFY_DOMAIN/repo --gpg-import=<(curl -s https://YOUR_COOLIFY_DOMAIN/repo/key.gpg)
```

### Встановити

```bash
flatpak install lbk com.lbk.launcher
```

### Оновити

```bash
flatpak update com.lbk.launcher
```

### Запустити

```bash
flatpak run com.lbk.launcher
```

## Для розробників

### Локальна збірка

Потрібно: `flatpak`, `flatpak-builder`

```bash
# Встановити runtime та SDK
flatpak install flathub org.freedesktop.Platform//24.08 org.freedesktop.Sdk//24.08
flatpak install flathub org.electronjs.Electron2.BaseApp//24.08

# Збірка
flatpak-builder --user --force-clean --repo=repo build-dir com.lbk.launcher.yml

# Тестовий запуск
flatpak-builder --run build-dir com.lbk.launcher.yml lbk-launcher
```

### CI/CD

GitHub Actions автоматично:
1. Завантажує останній AppImage з релізів littlebit-launcher
2. Збирає Flatpak
3. Генерує OSTree repo з GPG-підписом
4. Пакує в Docker-образ (Nginx) та пушить до `ghcr.io`

### Coolify

Додай Docker-образ `ghcr.io/vadko/lbk-flatpak:latest` як сервіс у Coolify.
Налаштуй домен (наприклад `flatpak.littlebit.org.ua`).

### GPG ключ

Для продакшну — згенеруй постійний GPG ключ та додай приватну частину як секрет `GPG_PRIVATE_KEY` в GitHub Actions.

```bash
gpg --batch --gen-key <<EOF
Key-Type: RSA
Key-Length: 4096
Name-Real: LBK Flatpak Repo
Name-Email: flatpak@littlebit.org.ua
Expire-Date: 0
%no-protection
EOF

# Експортувати приватний ключ для GitHub Secrets
gpg --export-secret-keys --armor "LBK Flatpak Repo"
```
