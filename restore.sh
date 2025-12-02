#!/bin/bash
set -e

# ================= CONFIGURATION =================
DB_NAME="genieacs"
COL_NAME="virtualParameters"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# =================================================

# ----- PASSWORD HASH (SHA-256) -----
# Ganti dengan hash kamu sendiri
REAL_HASH="777e935ff0b6ad5707a53b283c2aacd0f0221da1324e082d39e48a91169c40fb"
# -----------------------------------

# Warna Style
BLUE='\033[38;5;110m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear

echo -e "${BLUE}==========================================================${NC}"
echo -e "${BLUE}   GENIEACS VIRTUAL PARAMETERS RESTORE TOOL v3.0   ${NC}"
echo -e "${BLUE}==========================================================${NC}"

# =========================================================
#  PASSWORD CHECK (HASH)
# =========================================================
read -sp "Masukkan password: " USER_PASS
echo ""

USER_HASH=$(echo -n "$USER_PASS" | sha256sum | awk '{print $1}')

if [[ "$USER_HASH" != "$REAL_HASH" ]]; then
    echo -e "${RED}Password salah Bos!${NC}"
    exit 1
fi

echo -e "${GREEN}Password benar, lanjut...${NC}"

# ---------------------------------------------------------
# STEP 0: MENU PILIHAN
# ---------------------------------------------------------
echo -e "${YELLOW}Pilih sumber backup:${NC}"
echo "1) NEW (folder: genieacs/)"
echo "2) OLD (folder: old/)"
read -p "Masukkan pilihan (1/2): " choice

if [[ "$choice" == "1" ]]; then
    BACKUP_FILE="$SCRIPT_DIR/genieacs/$COL_NAME.bson"
elif [[ "$choice" == "2" ]]; then
    BACKUP_FILE="$SCRIPT_DIR/old/$COL_NAME.bson"
else
    echo -e "${RED}Pilihan tidak valid!${NC}"
    exit 1
fi

# ---------------------------------------------------------
# STEP 1: FILE CHECK
# ---------------------------------------------------------
echo -e "${YELLOW}[CHECK 1] Memeriksa file backup...${NC}"

if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}[ERROR] File tidak ditemukan: $BACKUP_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}[OK] File backup ditemukan${NC}"

# ---------------------------------------------------------
# STEP 2: DATABASE CHECK
# ---------------------------------------------------------
echo -e "${YELLOW}[CHECK 2] Mengecek status MongoDB...${NC}"

if ! pgrep -x "mongod" > /dev/null; then
    echo -e "${RED}[WARNING] MongoDB MATI${NC}"
    systemctl start mongod || true
    sleep 3
else
    echo -e "${GREEN}[OK] MongoDB berjalan${NC}"
fi

echo -ne " Ping database $DB_NAME... "
if mongosh --quiet --eval "db.getMongo().getDB('$DB_NAME').runCommand({ ping: 1 })" > /dev/null 2>&1; then
    echo -e "${GREEN}[CONNECTED]${NC}"
else
    echo -e "${RED}[FAILED]${NC}"
fi

CURRENT_COUNT=$(mongosh --quiet --eval "db.getMongo().getDB('$DB_NAME').getCollection('$COL_NAME').countDocuments()" 2>/dev/null || echo "Unknown")
echo -e " Data existing: ${BLUE}$CURRENT_COUNT records${NC}"

echo -e "${BLUE}----------------------------------------------------------${NC}"
read -p "Lanjut restore Bos? (y/n): " confirmation

if [[ "$confirmation" != "y" ]]; then
    echo -e "${RED}Dibatalkan${NC}"
    exit 0
fi

# ---------------------------------------------------------
# STEP 3: RESTORE
# ---------------------------------------------------------
echo -e "\n${BLUE}[EXEC] Stop Service GenieACS...${NC}"
systemctl stop genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui || true

echo -e "${BLUE}[EXEC] Drop collection lama...${NC}"
mongosh $DB_NAME --eval "db.$COL_NAME.drop()" >/dev/null 2>&1 || true

echo -e "${BLUE}[EXEC] Restore dari backup...${NC}"
if mongorestore --db $DB_NAME --collection $COL_NAME "$BACKUP_FILE"; then
    echo -e "${GREEN}[SUCCESS] Restore selesai${NC}"
else
    echo -e "${RED}[FAIL] Restore gagal${NC}"
fi

# ---------------------------------------------------------
# STEP 4: REBOOT
# ---------------------------------------------------------
echo -e "\n${GREEN}Proses selesai${NC}"
echo -e "${RED}SYSTEM AKAN RESTART DALAM 5 DETIK...${NC}"

for ((i = 5; i >= 1; i--)); do
    echo -ne "Rebooting in $i... \r"
    sleep 1
done

echo -e "\n${BLUE}Good bye Bos!${NC}"
reboot
