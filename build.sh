#!/bin/sh
# Herhangi bir komut başarısız olursa scripti durdur
set -e

# --- Flutter Kurulumu (Önbellek Dostu Versiyon) ---
# 'flutter' adında bir klasör var mı diye kontrol et
if [ -d "flutter" ] 
then
  # Eğer klasör varsa, içine gir ve sadece güncelle (bu daha hızlıdır)
  echo "Mevcut Flutter SDK'sı güncelleniyor..."
  cd flutter
  git pull
  cd ..
else
  # Eğer klasör yoksa (örneğin ilk build), Flutter SDK'sını klonla
  echo "Flutter SDK klonlanıyor..."
  git clone https://github.com/flutter/flutter.git --depth 1 --branch $FLUTTER_VERSION flutter
fi

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