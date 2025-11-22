# BEATCOM - GenieACS Virtual Parameters Backup

Repository ini berisi backup otomatis dari konfigurasi **Virtual Parameters** GenieACS, beserta script otomasinya untuk melakukan restore dalam satu kali perintah.

## 📋 Daftar Isi
- [Tentang](#tentang)
- [Struktur File](#struktur-file)
- [Cara Restore (Penggunaan)](#cara-restore)
- [Cara Update Backup](#cara-update-backup)

## ℹ️ Tentang
Koleksi ini berisi script Virtual Parameters "Ajaib" yang mendukung:
- **Universal Support:** TR-069 (Legacy) & TR-181 (Modern).
- **Multi-Vendor:** Huawei, ZTE, Fiberhome, Nokia, dll.
- **Fitur Cerdas:** Auto-detect logic, Wildcard search, dan efisiensi resource.

## 📂 Struktur File
Pastikan struktur folder Anda seperti ini agar script berjalan lancar:

```text
.
├── README.md           # File dokumentasi ini
├── restore.sh          # Script eksekutor (Jalankan ini!)
└── genieacs/           # Folder Data (Hasil mongodump)
    └── virtual_parameters.bson  # Data Database Utama
    └── virtual_parameters.metadata.json




## PENGGUNAAN
# copy URL

git clone https://github.com/AMDStore7807/vParams.git



# Masuk ke foldernya

`

cd vParams

`



# Berikan Izin

`

chmod +x restore.sh

`



# Jalankan

`

bash restore.sh

`