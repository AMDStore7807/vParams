#!/bin/bash
set -e

# ================= CONFIGURATION =================
DB_NAME="genieacs"
COL_NAME="virtualParameters" # Nama collection di MongoDB (Default GenieACS: virtualParameters)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_FILE="$SCRIPT_DIR/genieacs/$COL_NAME.bson"
# =================================================

# Warna Style
BLUE='\033[38;5;110m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' 

clear

# Banner
echo -e "${BLUE}==========================================================${NC}"
echo -e "${BLUE}   GENIEACS VIRTUAL PARAMETERS RESTORE TOOL v2.1   ${NC}"
echo -e "${BLUE}==========================================================${NC}"

# ---------------------------------------------------------
# STEP 1: FILE CHECK
# ---------------------------------------------------------
echo -e "${YELLOW}[CHECK 1] Memeriksa file backup...${NC}"
if [ ! -f "$BACKUP_FILE" ]; then
    # Coba cek nama alternatif jika file utama tidak ketemu
    ALT_FILE="$SCRIPT_DIR/genieacs/virtual_parameters.bson"
    if [ -f "$ALT_FILE" ]; then
        BACKUP_FILE="$ALT_FILE"
        echo -e "${GREEN} [OK] File ditemukan (nama alternatif): $BACKUP_FILE${NC}"
    else
        echo -e "${RED} [ERROR] File backup tidak ditemukan di: $SCRIPT_DIR/genieacs/${NC}"
        exit 1
    fi
else
    echo -e "${GREEN} [OK] File backup siap: $BACKUP_FILE${NC}"
fi

# ---------------------------------------------------------
# STEP 2: DATABASE HEALTH CHECK (Mode: FORCE CONTINUE)
# ---------------------------------------------------------
echo -e "${YELLOW}[CHECK 2] Memeriksa status Database MongoDB...${NC}"

# Cek apakah proses mongod berjalan
if ! pgrep -x "mongod" > /dev/null; then
    echo -e "${RED} [WARNING] Service MongoDB sepertinya MATI.${NC}"
    echo -e "${YELLOW} -> Melanjutkan proses sesuai permintaan Bos...${NC}"
    # Kita coba start dulu sebentar, siapa tau bisa hidup untuk restore
    echo -e "    Mencoba start MongoDB sebentar..."
    systemctl start mongod || true
    sleep 3
else
    echo -e "${GREEN} [OK] Service MongoDB berjalan.${NC}"
fi

# Cek koneksi spesifik ke database genieacs
echo -ne " Pinging database $DB_NAME... "
if mongosh --quiet --eval "db.getMongo().getDB('$DB_NAME').runCommand({ ping: 1 })" > /dev/null 2>&1; then
    echo -e "${GREEN}[CONNECTED]${NC}"
elif mongo --quiet --eval "db.getMongo().getDB('$DB_NAME').runCommand({ ping: 1 })" > /dev/null 2>&1; then
    echo -e "${GREEN}[CONNECTED]${NC}"
else
    echo -e "${RED}[FAILED]${NC}"
    echo -e "${YELLOW} -> Koneksi DB Gagal. Melanjutkan proses restore (Force Mode)...${NC}"
fi

# Cek jumlah data (Hanya info, error diabaikan)
CURRENT_COUNT=$(mongosh --quiet --eval "db.getMongo().getDB('$DB_NAME').getCollection('$COL_NAME').countDocuments()" 2>/dev/null || echo "Unknown")
echo -e " Data '$COL_NAME' saat ini: ${BLUE}$CURRENT_COUNT records${NC}"

echo -e "${BLUE}----------------------------------------------------------${NC}"
echo -e "${YELLOW}PERINGATAN: Script akan mencoba RESTORE data dan kemudian REBOOT.${NC}"
read -p "Lanjut Bos? (y/n): " confirmation

if [ "$confirmation" != "y" ]; then
    echo -e "${RED}Dibatalkan oleh Bos.${NC}"
    exit 0
fi

# ---------------------------------------------------------
# STEP 3: EKSEKUSI RESTORE
# ---------------------------------------------------------

# 1. Stop Services GenieACS (Biar gak ganggu DB)
echo -e "\n${BLUE}[EXEC] Mematikan Service GenieACS...${NC}"
systemctl stop genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui || true

# 2. Drop Collection Lama (Pakai || true agar script tidak berhenti jika gagal drop)
echo -e "${BLUE}[EXEC] Menghapus tabel lama ($COL_NAME)...${NC}"
mongosh $DB_NAME --eval "db.$COL_NAME.drop()" > /dev/null 2>&1 || mongo $DB_NAME --eval "db.$COL_NAME.drop()" > /dev/null 2>&1 || echo -e "${RED} -> Gagal drop tabel lama (Mungkin DB mati), lanjut restore...${NC}"

# 3. Restore
echo -e "${BLUE}[EXEC] Restore data dari backup...${NC}"
if mongorestore --db $DB_NAME --collection $COL_NAME "$BACKUP_FILE"; then
    echo -e "${GREEN} [SUCCESS] Data berhasil direstore!${NC}"
else
    echo -e "${RED} [FAIL] Restore GAGAL (Kemungkinan DB mati total).${NC}"
    echo -e "${YELLOW} -> Akan tetap melakukan REBOOT untuk refresh sistem.${NC}"
fi

# ---------------------------------------------------------
# STEP 4: REBOOT
# ---------------------------------------------------------
echo -e "\n${GREEN}Proses selesai.${NC}"
echo -e "${RED}SYSTEM AKAN RESTART DALAM 5 DETIK...${NC}"
for ((i = 5; i >= 1; i--)); do
    echo -ne "Rebooting in $i... \r"
    sleep 1
done

echo -e "\n${BLUE}Good bye Bos!${NC}"
reboot