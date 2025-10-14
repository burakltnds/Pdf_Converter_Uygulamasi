#!/bin/sh
# Herhangi bir komut başarısız olursa scripti durdur
set -e

# --- Flutter Kurulumu ---
# Flutter'ı GitHub'dan klonla (belirttiğimiz versiyonu)
git clone https://github.com/flutter/flutter.git --depth 1 --branch $FLUTTER_VERSION flutter
# Flutter komutunu sistem yoluna ekle
export PATH="$PATH:`pwd`/flutter/bin"

# Flutter versiyonunu kontrol et
flutter --version

# --- Flutter Web Uygulamasını İnşa Etme ---
# Flutter projesinin olduğu klasöre git
cd android_kismi
# Gerekli paketleri indir
flutter pub get
# Web sitesini oluştur
flutter build web