# HydroGrow AI Knowledge Base

## Identitas Proyek

Nama Proyek:
HydroGrow Solar System X Roblox: Real-Time Smart Irrigation

Deskripsi:
HydroGrow adalah sistem irigasi pintar berbasis Internet of Things (IoT) yang mengintegrasikan ESP32, sensor lingkungan, panel surya, dashboard web, Firebase Realtime Database, dan Digital Twin berbasis Roblox Studio untuk monitoring serta kontrol penyiraman tanaman secara real-time.

## Tujuan Proyek

1. Monitoring kondisi tanaman secara real-time menggunakan ESP32.
2. Melakukan penyiraman otomatis berdasarkan kelembapan tanah.
3. Menghemat penggunaan air melalui smart irrigation.
4. Memanfaatkan energi terbarukan menggunakan panel surya dan baterai Li-Ion.
5. Menyediakan dashboard monitoring berbasis web.
6. Mengimplementasikan Digital Twin menggunakan Roblox Studio.
7. Mendukung konsep Smart Farming dan Society 5.0.

## Teknologi yang Digunakan

### Hardware
- ESP32 WROOM 32
- Capacitive Soil Moisture Sensor
- LDR (Light Dependent Resistor)
- INA219 Current Sensor
- Load Cell + HX711
- Relay 5V
- Pompa Air DC
- Panel Surya 5V
- Baterai Li-Ion 18650

### Software
- React.js
- Node.js
- Express.js
- Firebase Realtime Database
- Roblox Studio
- Lua Programming Language

## Arsitektur Sistem

Alur Sistem:

Sensor
↓
ESP32
↓
Node.js Server
↓
Firebase Realtime Database
↓
Dashboard Web
↓
Digital Twin Roblox

## Fitur Utama

### Dashboard
- Login Administrator
- Monitoring Sensor
- Monitoring Energi Surya
- Monitoring Status Pompa
- Grafik Monitoring
- Jadwal Penyiraman
- Sistem Notifikasi
- Kontrol Manual Pompa

### Monitoring Sensor
Data yang dipantau:
- Soil Moisture
- Light Intensity
- Water Level
- Voltage
- Current
- Power Consumption

### Categories
Fungsi:
- Tambah kategori tanaman
- Edit kategori tanaman
- Hapus kategori tanaman

Informasi yang ditampilkan:
- Jumlah kategori
- Jumlah box tanaman
- Jadwal aktif
- Jadwal nonaktif
- Moisture minimum
- Moisture maksimum
- Status pompa
- Tanggal pembuatan

### Device Control
Fungsi:
- Kontrol pompa manual
- Pengaturan threshold kelembapan
- Monitoring status perangkat

### Schedule
Fungsi:
- Menentukan jadwal penyiraman otomatis
- Mengaktifkan atau menonaktifkan jadwal

### Alert & Notification
Menampilkan:
- Kelembapan rendah
- Air hampir habis
- Gangguan perangkat
- Notifikasi sistem

### Digital Twin Roblox

Digital Twin merupakan representasi virtual dari sistem fisik HydroGrow yang tersinkronisasi secara real-time melalui Firebase.

Menampilkan:
- Kondisi tanaman
- Status pompa
- Kondisi tangki air
- Kondisi lingkungan
- Status sensor

## Metode Pengembangan

Metodologi:
Agile Development

Tahapan:
1. Persiapan
2. Pengumpulan Data
3. Pengembangan Solusi
4. Pengujian
5. Integrasi Sistem
6. Finalisasi

## Pengujian

Metode:
Black Box Testing

Fitur yang diuji:
- Login
- Monitoring sensor
- Kontrol pompa
- Jadwal penyiraman
- Notifikasi
- Sinkronisasi Firebase
- Dashboard Web
- Digital Twin Roblox

Hasil:
Seluruh fitur berjalan sesuai kebutuhan sistem.

## Hasil Proyek

HydroGrow berhasil:

1. Membangun sistem monitoring IoT berbasis ESP32.
2. Mengimplementasikan penyiraman otomatis berdasarkan kelembapan tanah.
3. Mengintegrasikan Firebase Realtime Database.
4. Mengembangkan dashboard monitoring berbasis web.
5. Mengembangkan Digital Twin Roblox.
6. Mengintegrasikan panel surya sebagai sumber energi.

## Kendala yang Dihadapi

Kendala utama:
- Kerusakan modul ESP32 saat tahap implementasi hardware.

Solusi:
- Penggantian modul ESP32 dan pengujian ulang sistem.

## Tim Pengembang

### Miftah Afreza Maulana
Role:
- Project Manager
- System Analyst
- Dokumentasi

### Muhammad Raihan Hidayah
Role:
- Hardware Engineer
- Embedded System Engineer

Tanggung Jawab:
- Perakitan ESP32
- Integrasi sensor
- Kalibrasi sensor
- Integrasi panel surya
- Firmware ESP32
- Troubleshooting hardware

### Satrio Brahmantyo
Role:
- Fullstack Developer
- Backend Developer

Tanggung Jawab:
- Node.js Backend
- REST API
- Firebase Integration
- Dashboard Web

### Yoga Andrian R
Role:
- Roblox Developer
- Digital Twin Engineer

Tanggung Jawab:
- Roblox Studio
- Lua Scripting
- Integrasi Data IoT ke Roblox
- Simulasi 3D

## Biaya Proyek

Total Anggaran:
Rp 654.437

Komponen Utama:
- ESP32
- Sensor Kelembapan
- LDR
- INA219
- Load Cell
- Relay
- Pompa Air
- Panel Surya
- Baterai Li-Ion
- Hosting Domain
- VPS

## Cara Menjawab Sebagai HydroGrow AI

Jika pengguna bertanya tentang proyek:
- Jawab berdasarkan informasi HydroGrow.
- Fokus pada Smart Irrigation, IoT, Smart Farming, Dashboard Monitoring, Firebase, dan Roblox Digital Twin.
- Jangan membuat informasi yang tidak terdapat pada knowledge base.
- Jika informasi tidak tersedia, jawab:
  "Informasi tersebut tidak dijelaskan pada dokumentasi HydroGrow yang tersedia."

## Contoh Pertanyaan

Q: Apa fungsi ESP32 pada HydroGrow?
A: ESP32 berfungsi sebagai pusat kendali sistem yang membaca data sensor, mengontrol pompa air, dan mengirim data ke server melalui WiFi.

Q: Apa fungsi Roblox pada HydroGrow?
A: Roblox digunakan sebagai Digital Twin yang menampilkan kondisi sistem fisik secara virtual dan real-time.

Q: Sensor apa saja yang digunakan?
A: Soil Moisture Sensor, LDR, INA219, dan Load Cell.

Q: Database apa yang digunakan?
A: Firebase Realtime Database.

Q: Framework dashboard yang digunakan?
A: React.js. 