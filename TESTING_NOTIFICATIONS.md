# Panduan Testing Notifikasi

## 📋 Daftar Testing

### 1. Testing Local Notifications (Scheduled)

#### A. Daily Report Reminder (07:00)
**Cara Test:**
1. Login sebagai user dengan `kelompokId` (bukan admin/super admin)
2. Pastikan belum ada laporan hari ini
3. Set waktu device ke 06:59
4. Tunggu 1 menit sampai jam 07:00
5. **Expected:** Notifikasi muncul dengan judul "Jangan Lupa Mengisi Laporan"
6. **Tap notifikasi** → **Expected:** Navigasi ke halaman Report Input dengan `kelompokId` yang benar

**Quick Test (Ubah waktu di code):**
- Edit `scheduleDailyReportReminder()` di `local_notification_service.dart`
- Ubah default time dari `TimeOfDay(hour: 7, minute: 0)` ke waktu 1-2 menit dari sekarang
- Restart app dan tunggu notifikasi muncul

#### B. Sholat Dhuha Reminder (09:00)
**Cara Test:**
1. Login sebagai user apapun (bukan hanya koordinator)
2. Set waktu device ke 08:59
3. Tunggu 1 menit sampai jam 09:00
4. **Expected:** Notifikasi muncul dengan judul "Sholat Dhuha" dan body "Sudah sholat dhuha belum hari ini?"
5. **Expected:** Ada 2 action button: "V" dan "X"
6. **Tap "V"** → **Expected:** `sholatDhuha` di Firestore update menjadi `true`
7. **Tap "X"** → **Expected:** `sholatDhuha` di Firestore update menjadi `false`

**Quick Test:**
- Edit `scheduleSholatDhuhaReminder()` di `local_notification_service.dart`
- Ubah default time ke waktu 1-2 menit dari sekarang

#### C. Al-Mulk Reminder (21:30)
**Cara Test:**
1. Login sebagai user apapun
2. Set waktu device ke 21:29
3. Tunggu 1 menit sampai jam 21:30
4. **Expected:** Notifikasi muncul dengan judul "Al-Mulk" dan body "Persiapan tidur, sudah baca al-mulk belum?"
5. **Expected:** Ada 2 action button: "V" dan "X"
6. **Tap "V"** → **Expected:** `alMulk` di Firestore update menjadi `true`
7. **Tap "X"** → **Expected:** `alMulk` di Firestore update menjadi `false`

**Quick Test:**
- Edit `scheduleAlMulkReminder()` di `local_notification_service.dart`
- Ubah default time ke waktu 1-2 menit dari sekarang

---

### 2. Testing FCM Notifications

#### A. Foreground (App Terbuka)
**Cara Test:**
1. Buka aplikasi dan login
2. Pastikan app dalam keadaan terbuka (foreground)
3. Kirim FCM notification dari Firebase Console atau Postman:
   ```json
   {
     "to": "<FCM_TOKEN>",
     "notification": {
       "title": "Test Foreground",
       "body": "Ini test notifikasi saat app terbuka"
     },
     "data": {
       "type": "test"
     }
   }
   ```
4. **Expected:** Notifikasi muncul sebagai local notification dengan bunyi dan heads-up
5. **Expected:** Notifikasi menggunakan channel `high_importance_channel`

**Cara Dapatkan FCM Token:**
- Check log di console saat app start: `FCM Token: <token>`
- Atau tambahkan button debug untuk print token

#### B. Background (App di Background)
**Cara Test:**
1. Buka aplikasi dan login
2. Tekan tombol Home untuk minimize app (jangan kill)
3. Kirim FCM notification
4. **Expected:** Notifikasi muncul di notification tray dengan bunyi
5. **Tap notifikasi** → **Expected:** App terbuka dan navigasi sesuai `data.type`

#### C. Terminated (App Tertutup/Killed)
**Cara Test:**
1. Buka aplikasi dan login
2. **Kill app** (swipe away dari recent apps atau Force Stop)
3. Kirim FCM notification
4. **Expected:** Notifikasi muncul di notification tray dengan bunyi dan heads-up
5. **Expected:** Background handler (`_firebaseMessagingBackgroundHandler`) dipanggil
6. **Tap notifikasi** → **Expected:** App terbuka dan navigasi sesuai `data.type`

**Cara Test Background Handler:**
- Check log di console untuk melihat: `Background message received: <messageId>`
- Pastikan notifikasi tetap muncul meskipun app killed

---

### 3. Testing Action Buttons (V/X)

#### A. Sholat Dhuha Action Buttons
**Cara Test:**
1. Tunggu atau trigger Sholat Dhuha reminder (09:00)
2. **Expected:** Notifikasi muncul dengan 2 action button: "V" dan "X"
3. **Tap "V"** → **Expected:**
   - Notifikasi hilang
   - Data di Firestore `daily_ibadah/{userId}/{date}` → `sholatDhuha: true`
   - Check di dashboard ibadah tracker, checkbox Dhuha sudah tercentang
4. **Tap "X"** → **Expected:**
   - Notifikasi hilang
   - Data di Firestore `daily_ibadah/{userId}/{date}` → `sholatDhuha: false`
   - Check di dashboard ibadah tracker, checkbox Dhuha tidak tercentang

#### B. Al-Mulk Action Buttons
**Cara Test:**
1. Tunggu atau trigger Al-Mulk reminder (21:30)
2. **Expected:** Notifikasi muncul dengan 2 action button: "V" dan "X"
3. **Tap "V"** → **Expected:**
   - Notifikasi hilang
   - Data di Firestore `daily_ibadah/{userId}/{date}` → `alMulk: true`
   - Check di dashboard ibadah tracker, checkbox Al-Mulk sudah tercentang
4. **Tap "X"** → **Expected:**
   - Notifikasi hilang
   - Data di Firestore `daily_ibadah/{userId}/{date}` → `alMulk: false`
   - Check di dashboard ibadah tracker, checkbox Al-Mulk tidak tercentang

---

### 4. Testing Navigation dari Daily Report Reminder

**Cara Test:**
1. Login sebagai user dengan `kelompokId` (misal: koordinator kelompok 1)
2. Pastikan belum ada laporan hari ini
3. Tunggu atau trigger Daily Report reminder (07:00)
4. **Expected:** Notifikasi muncul dengan judul "Jangan Lupa Mengisi Laporan"
5. **Tap notifikasi** → **Expected:**
   - App terbuka (jika closed)
   - Navigasi ke halaman `ReportInputView`
   - Arguments berisi `{'kelompokId': <kelompokId_user>}`
   - Halaman Report Input menampilkan area tugas yang sesuai dengan kelompok dan tanggal

**Verifikasi:**
- Check log: `Navigating to report input for kelompok <id>`
- Pastikan halaman Report Input sudah ter-load dengan benar

---

### 5. Testing High Importance Channel

**Cara Test:**
1. Pastikan semua notifikasi FCM menggunakan channel `high_importance_channel`
2. **Expected:** 
   - Notifikasi muncul dengan bunyi (sound)
   - Notifikasi muncul dengan vibrasi (vibration)
   - Notifikasi muncul sebagai heads-up notification (popup di atas layar)
   - Badge muncul di app icon

**Verifikasi di Android:**
- Settings → Apps → Piket Asrama Pro → Notifications
- Check channel "High Importance Notifications" memiliki:
  - Importance: Urgent (Play sound & pop on screen)
  - Sound: Enabled
  - Vibration: Enabled
  - Badge: Enabled

---

### 6. Testing untuk Semua User (Bukan Hanya Koordinator)

**Cara Test:**
1. Login sebagai user dengan role berbeda:
   - Admin
   - Super Admin
   - Kedisiplinan
   - Koordinator
   - Santri biasa (jika ada)
2. **Expected:** Semua user mendapat reminder:
   - Sholat Dhuha (09:00)
   - Al-Mulk (21:30)
3. **Expected:** Hanya user dengan `kelompokId` yang mendapat Daily Report reminder

**Verifikasi:**
- Check log saat app start: `Sholat dhuha reminder scheduled...` dan `Al-Mulk reminder scheduled...`
- Pastikan tidak ada kondisi `if (profile.role == 'koordinator')` untuk Dhuha dan Al-Mulk

---

## 🛠️ Tools untuk Testing

### 1. Firebase Console
- **Path:** Firebase Console → Cloud Messaging → Send test message
- **Input:** FCM Token, Title, Body, Data
- **Use:** Testing FCM notifications

### 2. Postman / cURL
**cURL Example:**
```bash
curl -X POST https://fcm.googleapis.com/v1/projects/<PROJECT_ID>/messages:send \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "<FCM_TOKEN>",
      "notification": {
        "title": "Test Notification",
        "body": "Test body"
      },
      "data": {
        "type": "test"
      }
    }
  }'
```

### 3. Android Logcat
**Filter untuk notifikasi:**
```bash
adb logcat | grep -i "notification\|fcm\|firebase"
```

**Filter untuk background handler:**
```bash
adb logcat | grep -i "background message"
```

### 4. Debug Button (Optional)
Tambahkan button debug di dashboard untuk:
- Print FCM Token
- Trigger test notification
- Check pending notifications
- Reschedule reminders

---

## ✅ Checklist Testing

### Local Notifications
- [ ] Daily Report reminder muncul di 07:00
- [ ] Daily Report reminder navigasi ke Report Input
- [ ] Sholat Dhuha reminder muncul di 09:00 untuk semua user
- [ ] Al-Mulk reminder muncul di 21:30 untuk semua user
- [ ] Action button "V" update ibadah ke true
- [ ] Action button "X" update ibadah ke false
- [ ] Notifikasi muncul dengan bunyi dan vibrasi

### FCM Notifications
- [ ] FCM notification muncul saat app terbuka (foreground)
- [ ] FCM notification muncul saat app di background
- [ ] FCM notification muncul saat app terminated/killed
- [ ] Background handler dipanggil saat app terminated
- [ ] Notifikasi menggunakan high importance channel
- [ ] Tap notifikasi navigasi sesuai data.type

### Channel & Permissions
- [ ] High importance channel dibuat dengan benar
- [ ] Default notification channel meta-data ada di AndroidManifest
- [ ] Permission notification granted
- [ ] Exact alarm permission granted (Android 12+)

### User Coverage
- [ ] Admin mendapat reminder Dhuha dan Al-Mulk
- [ ] Super Admin mendapat reminder Dhuha dan Al-Mulk
- [ ] Kedisiplinan mendapat reminder Dhuha dan Al-Mulk
- [ ] Koordinator mendapat reminder Dhuha dan Al-Mulk
- [ ] Semua user dengan kelompokId mendapat Daily Report reminder

---

## 🐛 Troubleshooting

### Notifikasi tidak muncul
1. Check permission notification: Settings → Apps → Notifications
2. Check exact alarm permission (Android 12+): Settings → Apps → Special app access → Alarms & reminders
3. Check log untuk error: `adb logcat | grep -i error`
4. Pastikan timezone device: Asia/Jakarta

### Background handler tidak dipanggil
1. Pastikan handler diregistrasi di `main()` sebelum `runApp()`
2. Pastikan handler adalah top-level function dengan `@pragma('vm:entry-point')`
3. Check log saat app start: handler harus ter-register
4. Pastikan app benar-benar killed (bukan hanya minimized)

### Action button tidak bekerja
1. Check log: `Notification tapped: actionId=...`
2. Pastikan payload sesuai dengan yang di-handle
3. Check Firestore untuk update data
4. Pastikan user sudah login saat action button di-tap

### Navigation tidak bekerja
1. Check log: `Navigating to report input for kelompok...`
2. Pastikan route `AppRoutes.reportInput` sudah terdaftar
3. Pastikan arguments berisi `kelompokId`
4. Check apakah ReportInputController bisa handle arguments

---

## 📝 Notes

- Untuk testing cepat, ubah waktu reminder di code ke 1-2 menit dari sekarang
- Pastikan device timezone: Asia/Jakarta
- Untuk testing FCM, pastikan device terhubung ke internet
- Background handler hanya bekerja saat app benar-benar terminated (killed)
- Action buttons hanya bekerja saat app masih running (foreground/background)

