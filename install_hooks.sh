#!/bin/bash

# Убедиться, что директория .git/hooks существует
HOOKS_DIR=".git/hooks"
if [ ! -d "$HOOKS_DIR" ]; then
    echo "Error: This script must be run from the root of a Git repository."
    exit 1
fi

# Функция для установки хука
install_hook() {
    HOOK_NAME=$1
    HOOK_CONTENT=$2

    echo "Installing $HOOK_NAME hook..."

    # Записываем содержимое хука в файл
    echo "$HOOK_CONTENT" > "$HOOKS_DIR/$HOOK_NAME"

    # Делаем его исполняемым
    chmod +x "$HOOKS_DIR/$HOOK_NAME"
}

# Содержимое хуков
POST_CHECKOUT_HOOK='#!/bin/bash
echo "Running xcodegen generate --use-cache"
xcodegen generate --use-cache
'

PRE_COMMIT_HOOK='#!/bin/bash
echo "Running xcodegen cache"
xcodegen cache
'

# Установка хуков
install_hook "post-checkout" "$POST_CHECKOUT_HOOK"
install_hook "post-rewrite" "$POST_CHECKOUT_HOOK"
install_hook "post-merge" "$POST_CHECKOUT_HOOK"
install_hook "pre-commit" "$PRE_COMMIT_HOOK"

echo "Git hooks installed successfully!"

