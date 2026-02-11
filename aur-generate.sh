#!/usr/bin/env bash
set -euo pipefail
MAINTAINER_NAME="Cruglet"
MAINTAINER_EMAIL="cruglet@gmail.com"
PKGNAME="keybox-bin"
PKGDESC="A minimal, encrypted, local password manager."
ARCH="x86_64"
LICENSE="MIT"
DEPENDS=("vulkan-icd-loader")
REPO_URL="https://github.com/cruglet/keybox"
BIN_NAME="keybox"
BIN_FILENAME="keybox-linux.x86_64.zip"
ICON_URL="https://raw.githubusercontent.com/cruglet/keybox/main/meta/full-logo_256x.png"
AUR_DIR="aur"
PKGREL_FILE="$AUR_DIR/.pkgrel"
FORCE_REL=""
BUMP=false
BUMPUP=false
FORCE_PUSH=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --rel)
      FORCE_REL="$2"
      shift 2
      ;;
    --bump)
      BUMP=true
      shift
      ;;
    --bumpup)
      BUMPUP=true
      shift
      ;;
    --force)
      FORCE_PUSH=true
      shift
      ;;
    *)
      exit 1
      ;;
  esac
done
if [[ ! -f project.godot ]]; then
  exit 1
fi
PROJECT_NAME=$(grep '^config/name=' project.godot | cut -d'"' -f2)
# Strip any accidental leading 'v' from the version in project.godot
PROJECT_VERSION=$(grep '^config/version=' project.godot | cut -d'"' -f2 | sed 's/^v//')
PKGVER="$PROJECT_VERSION"
mkdir -p "$AUR_DIR"
if [[ -f "$PKGREL_FILE" ]]; then
  read -r LAST_VER LAST_REL < "$PKGREL_FILE"
else
  LAST_VER=""
  LAST_REL=1
fi
if [[ -n "$FORCE_REL" ]]; then
  PKGREL="$FORCE_REL"
elif [[ "$PKGVER" != "$LAST_VER" ]]; then
  PKGREL=1
else
  PKGREL="$LAST_REL"
  read -r -p "pkgver unchanged ($PKGVER) Update pkgrel $LAST_REL -> $((LAST_REL+1)) [Y/n]: " ANSWER
  ANSWER="$(echo "$ANSWER" | tr '[:upper:]' '[:lower:]' | xargs)"
  if [[ -z "$ANSWER" || "$ANSWER" == "y" ]]; then
      PKGREL=$((LAST_REL+1))
  fi
fi
echo "$PKGVER $PKGREL" > "$PKGREL_FILE"
RELEASE_URL="$REPO_URL/releases/download/v$PKGVER/$BIN_FILENAME"
generate_pkgbuild() {
cat > "$AUR_DIR/PKGBUILD" <<EOF
pkgname=$PKGNAME
pkgver=$PKGVER
pkgrel=$PKGREL
pkgdesc="$PKGDESC"
arch=('$ARCH')
url="$REPO_URL"
license=('$LICENSE')
depends=(${DEPENDS[@]})
makedepends=('unzip')
source=(
  "$BIN_FILENAME::$RELEASE_URL"
  "keybox.png::$ICON_URL"
)
sha256sums=('SKIP' 'SKIP')
package() {
  unzip -o "\$srcdir/$BIN_FILENAME" -d "\$srcdir"
  install -Dm755 "\$srcdir/$BIN_NAME" "\$pkgdir/usr/bin/$BIN_NAME"
  install -Dm644 /dev/stdin "\$pkgdir/usr/share/applications/$BIN_NAME.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=$PROJECT_NAME
Comment=$PKGDESC
Exec=$BIN_NAME
Icon=$BIN_NAME
Categories=Utility;Security;
Terminal=false
DESKTOP
  install -Dm644 "\$srcdir/keybox.png" "\$pkgdir/usr/share/icons/hicolor/256x256/apps/$BIN_NAME.png"
}
EOF
}
generate_pkgbuild
(
  cd "$AUR_DIR"
  makepkg --printsrcinfo > .SRCINFO
)
if [[ "$BUMP" = true || "$BUMPUP" = true ]]; then
  # Strip the leading 'v' from the GitHub tag so it matches PKGVER format
  LATEST=$(curl -s "https://api.github.com/repos/cruglet/keybox/releases/latest" \
           | grep -Po '"tag_name": "\K.*?(?=")' \
           | sed 's/^v//')
  if [[ -n "$LATEST" && "$LATEST" != "$PKGVER" ]]; then
    PKGVER="$LATEST"
    PKGREL=1
    echo "$PKGVER $PKGREL" > "$PKGREL_FILE"
    RELEASE_URL="$REPO_URL/releases/download/v$PKGVER/$BIN_FILENAME"
    generate_pkgbuild
    (
      cd "$AUR_DIR"
      makepkg --printsrcinfo > .SRCINFO
      git add PKGBUILD .SRCINFO
      REL_TAG="$PKGVER-$PKGREL"
      git commit -m "Update PKGBUILD for upstream version $REL_TAG"
      if [[ "$BUMPUP" = true ]]; then
        if [[ "$FORCE_PUSH" = true ]]; then
          git push --force
        else
          git pull --rebase
          git push
        fi
      fi
    )
  fi
fi
echo "pkgver=$PKGVER pkgrel=$PKGREL"
