# Icon Setup Instructions

## Cara Setup Icon Sapu untuk APK

### 1. Buat atau Download Icon Sapu

Anda perlu membuat gambar icon sapu dengan spesifikasi berikut:
- **Ukuran**: 1024x1024 pixels
- **Format**: PNG dengan transparansi
- **Desain**: 
  - Icon sapu putih di tengah
  - Background: Gradient pink/merah (sesuai referensi)
  - Atau bisa menggunakan background solid color

### 2. Simpan Icon

Simpan gambar icon dengan nama:
- `icon.png` (1024x1024) - untuk adaptive icon foreground
- `icon_foreground.png` (1024x1024) - untuk adaptive icon foreground (bisa sama dengan icon.png)

**Lokasi**: `assets/icon/icon.png` dan `assets/icon/icon_foreground.png`

### 3. Generate Icon

Setelah icon disimpan, jalankan command:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

### 4. Build APK

Setelah icon di-generate, build APK seperti biasa:
```bash
flutter build apk --release
```

## Alternatif: Menggunakan Tool Online

Jika tidak punya gambar icon, bisa menggunakan tool online:
1. https://icon.kitchen/ - Generate icon dari emoji atau text
2. https://www.favicon-generator.org/ - Generate dari gambar
3. Atau gunakan design tool seperti Figma, Canva, dll

## Catatan

- Icon akan otomatis di-generate untuk semua ukuran (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- Adaptive icon background sudah di-set ke warna merah (#FF5252) sesuai tema app
- Jika ingin mengubah warna background, edit `adaptive_icon_background` di `pubspec.yaml`
