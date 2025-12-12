# Git Workflow untuk Piket BQ2

## Struktur Branch

### `main` (Production/Stable)
- **JANGAN DIUBAH LANGSUNG!**
- Berisi kode yang sama persis dengan APK yang dipakai user
- Hanya di-update via merge dari `develop` setelah fitur baru sudah dites
- Setiap merge ke `main` = trigger build APK baru

### `develop` (Development)
- Tempat development fitur baru
- Bebas diubah, di-test, di-rollback
- Bisa dibuat branch fitur dari `develop`

## Workflow Menambah Fitur Baru

### 1. Buat Branch Fitur dari `develop`
```bash
git checkout develop
git pull origin develop
git checkout -b feature/nama-fitur
```

### 2. Develop Fitur
- Koding fitur baru di branch `feature/nama-fitur`
- Commit dengan message yang jelas:
  ```bash
  git commit -m "feat: tambah fitur nama-fitur"
  ```

### 3. Test Fitur
- Test fitur sampai yakin tidak ada bug
- Fix bug jika ada

### 4. Merge ke `develop`
```bash
git checkout develop
git merge feature/nama-fitur
git push origin develop
```

### 5. Integration Test di `develop`
- Test semua fitur bersama-sama
- Pastikan tidak ada konflik atau bug

### 6. Merge ke `main` (Hanya jika semua OK!)
```bash
git checkout main
git merge develop
git push origin main
```

### 7. Build APK dari `main`
```bash
git checkout main
flutter build apk --release
```

### 8. Tag Versi Baru
```bash
git tag -a v1.2.0 -m "APK versi baru dengan fitur X"
git push origin --tags
```

## Hotfix (Bug Kritis di Production)

Jika ada bug kritis di APK yang sudah tersebar:

```bash
# Buat branch hotfix dari main
git checkout main
git checkout -b hotfix/bug-kritis

# Fix bug
# ... koding fix ...

# Commit fix
git commit -m "fix: perbaiki bug kritis"

# Merge langsung ke main (skip develop)
git checkout main
git merge hotfix/bug-kritis
git push origin main

# Juga merge ke develop agar develop tetap up-to-date
git checkout develop
git merge hotfix/bug-kritis
git push origin develop

# Build APK hotfix
flutter build apk --release
```

## Best Practices

1. **Jangan force push ke `main`** - bisa merusak history
2. **Gunakan commit message yang jelas:**
   - `feat: tambah fitur X`
   - `fix: perbaiki bug Y`
   - `refactor: refactor kode Z`
3. **Review code sebelum merge ke `main`**
4. **Simpan APK setiap rilis** di folder terpisah untuk backup
5. **Jangan commit file sensitif** (API keys, passwords, dll)

## Contoh Skenario

### Menambah Fitur "Export Laporan"

```bash
# 1. Buat branch fitur
git checkout develop
git pull origin develop
git checkout -b feature/export-laporan

# 2. Develop fitur
# ... koding ...

# 3. Commit
git add .
git commit -m "feat: tambah fitur export laporan ke PDF"

# 4. Merge ke develop
git checkout develop
git merge feature/export-laporan
git push origin develop

# 5. Test di develop
# ... test integration ...

# 6. Merge ke main (setelah semua OK)
git checkout main
git merge develop
git push origin main

# 7. Tag versi baru
git tag -a v1.2.0 -m "APK dengan fitur export laporan"
git push origin --tags

# 8. Build APK
flutter build apk --release
```

## Keuntungan Workflow Ini

- ✅ APK user tetap stabil: `main` tidak berubah sampai fitur baru siap
- ✅ Development aman: bisa eksperimen di `develop` tanpa risiko
- ✅ Rollback mudah: jika ada masalah, kembali ke commit sebelumnya
- ✅ Tracking jelas: tahu versi APK mana yang dipakai user
- ✅ Kolaborasi mudah: tim bisa kerja di branch berbeda tanpa konflik

## Catatan Penting

- **Branch `main` = kode yang sama dengan APK yang sudah tersebar**
- **Jangan langsung edit di `main`!**
- **Selalu develop di branch terpisah, test, baru merge ke `main`**
- **Setelah merge ke `main`, build APK baru dan sebar**
