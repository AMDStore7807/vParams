#!/bin/bash
set -e

# Warna BEATCOM Style
BLUE='\033[38;5;110m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Deteksi lokasi script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# PASTIKAN NAMA FILE INI SESUAI DENGAN ISI FOLDER GENIEACS BOS
# (Biasanya virtual_parameters.bson atau virtualParameters.bson, sesuaikan ya Bos)
BACKUP_FILE="$SCRIPT_DIR/genieacs/virtual_parameters.bson" 

clear

# ============================================================
# BEATCOM Banner (Restore Edition)
# ============================================================
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}=========== BBBBB   EEEEE       AAA     TTTTT   CCCC   OOO    M    M ===============${NC}"    
echo -e "${BLUE}========== B    B E           AAAAA      T    C      O    O  MM MM ===============${NC}" 
echo -e "${BLUE}=========  BBBBB  EEEE       AA    AA    T    C      O    O  M M M ===============${NC}"
echo -e "${BLUE}========== B    B E         AAAAA     T    C      O    O  M    M ===============${NC}"
echo -e "${BLUE}=========== BBBBB  EEEEE   AA      AA    T     CCCC   OOO    M    M ===============${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}=================== RESTORE VIRTUAL PARAMETERS TOOL ========================${NC}"
echo -e "${BLUE}============================================================================${NC}"

# Cek keberadaan file backup (Handle nama file camelCase atau snake_case)
if [ ! -f "$BACKUP_FILE" ]; then
    # Coba cek nama alternatif (virtualParameters.bson)
    BACKUP_FILE="$SCRIPT_DIR/genieacs/virtualParameters.bson"
    if [ ! -f "$BACKUP_FILE" ]; then
        echo -e "${RED}[ERROR] File backup tidak ditemukan!${NC}"
        echo -e "Cari file .bson di folder: $SCRIPT_DIR/genieacs/"
        exit 1
    fi
fi

echo -e "${BLUE}[INFO] File backup ditemukan: $BACKUP_FILE${NC}"
echo -e "${BLUE}[WARNING] Script ini akan melakukan:${NC}"
echo -e "${BLUE}          1. STOP Service GenieACS.${NC}"
echo -e "${BLUE}          2. HAPUS parameter lama & RESTORE backup.${NC}"
echo -e "${RED}          3. RESTART SYSTEM (VPS/Server) SECARA OTOMATIS.${NC}"
echo -e ""
read -p "Apakah Anda yakin ingin melanjutkan? (y/n): " confirmation

if [ "$confirmation" != "y" ]; then
    echo -e "${RED}Restore dibatalkan.${NC}"
    exit 0
fi

echo -e ""

# 0. Matikan Service DULU (Supaya tidak ada cache nyangkut / write conflict)
echo -e "${BLUE}[1/4] Mematikan GenieACS Services...${NC}"
systemctl stop genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui || true

# 1. Drop Collection Lama
echo -e "${BLUE}[2/4] Membersihkan database lama...${NC}"
mongosh genieacs --eval "db.virtual_parameters.drop()" > /dev/null 2>&1 || mongo genieacs --eval "db.virtual_parameters.drop()" > /dev/null 2>&1

# 2. Restore Data Baru
echo -e "${BLUE}[3/4] Mengembalikan data dari backup...${NC}"
if mongorestore --db genieacs --collection virtual_parameters "$BACKUP_FILE"; then
    echo -e "${GREEN}[OK] Database berhasil direstore.${NC}"
else
    echo -e "${RED}[FAIL] Gagal restore database. Cek koneksi MongoDB.${NC}"
    # Nyalakan lagi service kalau gagal biar gak mati total
    systemctl start genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui
    exit 1
fi

# 3. Full System Reboot
echo -e "${BLUE}[4/4] SYSTEM AKAN RESTART DALAM 5 DETIK...${NC}"
echo -e "${GREEN}Simpan pekerjaan Anda jika ada koneksi SSH lain!${NC}"

for ((i = 5; i >= 1; i--)); do
    echo -ne "Rebooting in $i... \r"
    sleep 1
done

echo -e "\n${BLUE}Good bye Bos! Sampai jumpa setelah restart!${NC}"
reboot