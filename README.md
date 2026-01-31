# LBK Launcher — Flatpak Repository

Flatpak-пакет та OSTree-репозиторій для [LBK Launcher](https://github.com/Vadko/littlebit-launcher).

## Для користувачів

### Варіант 1: Встановити через .flatpakref (найпростіше)

Просто відкрий посилання — система запропонує встановити:

```
https://flatpak.lbklauncher.com/com.lbk.launcher.flatpakref
```

Або через термінал:

```bash
flatpak install https://flatpak.lbklauncher.com/com.lbk.launcher.flatpakref
```

### Варіант 2: Додати репозиторій вручну

```bash
# Завантажити публічний GPG ключ
curl -fsSL https://flatpak.lbklauncher.com/lbk.gpg -o /tmp/lbk.gpg

# Додати репо з GPG перевіркою
flatpak remote-add --if-not-exists --gpg-import=/tmp/lbk.gpg lbk https://flatpak.lbklauncher.com/repo

# Встановити
flatpak install lbk com.lbk.launcher
```

### Запуск

```bash
flatpak run com.lbk.launcher
```

### Оновлення

```bash
# Перевірити наявність оновлень
flatpak remote-ls --updates lbk

# Оновити
flatpak update com.lbk.launcher
```

GNOME Software та KDE Discover автоматично перевіряють оновлення з усіх підключених remote — якщо репо додано, оновлення з'являться в системному центрі оновлень.

## Для розробників

### Локальна збірка

Потрібно: `flatpak`, `flatpak-builder`

```bash
# Встановити runtime та SDK
flatpak install flathub org.freedesktop.Platform//24.08 org.freedesktop.Sdk//24.08
flatpak install flathub org.electronjs.Electron2.BaseApp//24.08

# Збірка з GPG підписом
flatpak-builder --user --force-clean --gpg-sign=284A1984 --repo=repo build-dir com.lbk.launcher.yml

# Тестовий запуск
flatpak-builder --run build-dir com.lbk.launcher.yml lbk-launcher
```