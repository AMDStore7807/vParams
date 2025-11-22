#!/bin/bash
set -e

# Warna BEATCOM Style
BLUE='\033[38;5;110m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Deteksi lokasi script (agar bisa dijalankan dari folder mana saja)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_FILE="$SCRIPT_DIR/genieacs/virtualParameters.bson"

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

# Cek keberadaan file backup
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}[ERROR] File backup tidak ditemukan di:${NC}"
    echo -e "${RED}$BACKUP_FILE${NC}"
    echo -e "Pastikan struktur folder repo sudah benar (folder 'genieacs' harus ada)."
    exit 1
fi

echo -e "${BLUE}[INFO] File backup ditemukan!${NC}"
echo -e "${BLUE}[WARNING] Proses ini akan MENGHAPUS semua Virtual Parameters yang ada sekarang${NC}"
echo -e "${BLUE}          dan menggantinya dengan data dari backup.${NC}"
echo -e ""
read -p "Apakah Anda yakin ingin melanjutkan? (y/n): " confirmation

if [ "$confirmation" != "y" ]; then
    echo -e "${RED}Restore dibatalkan.${NC}"
    exit 0
fi

echo -e ""
# 1. Drop Collection Lama
echo -e "${BLUE}[1/3] Membersihkan database lama...${NC}"
mongosh genieacs --eval "db.virtual_parameters.drop()" > /dev/null 2>&1 || mongo genieacs --eval "db.virtual_parameters.drop()" > /dev/null 2>&1

# 2. Restore Data Baru
echo -e "${BLUE}[2/3] Mengembalikan data dari backup...${NC}"
if mongorestore --db genieacs --collection virtual_parameters "$BACKUP_FILE"; then
    echo -e "${GREEN}[OK] Database berhasil direstore.${NC}"
else
    echo -e "${RED}[FAIL] Gagal restore database. Cek koneksi MongoDB.${NC}"
    exit 1
fi

# 3. Restart Service (Penting supaya GenieACS reload cache VP)
echo -e "${BLUE}[3/3] Merestart GenieACS Services...${NC}"
systemctl restart genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui

echo -e "${BLUE}============================================================================${NC}"
echo -e "${GREEN}                          RESTORE SUKSES BOS!                               ${NC}"
echo -e "${BLUE}============================================================================${NC}"