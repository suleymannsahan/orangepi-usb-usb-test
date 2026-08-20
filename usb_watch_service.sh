#!/bin/bash
DEV="/dev/sda1"
MNT="/mnt/usb"
LOG="/root/usb_auto.log"
DATASIZE=256   # test dosyasi boyutu (MB)
 
mkdir -p "$MNT"
echo "=== USB izleyici servisi basladi: $(date) ===" >> "$LOG"
 
while true; do
    while [ ! -b "$DEV" ]; do sleep 1; done
    echo ">>> Aygit algilandi: $DEV ($(date '+%Y-%m-%d %H:%M:%S'))" >> "$LOG"
    sleep 2
 
    if ! mount "$DEV" "$MNT" 2>>"$LOG"; then
        echo "!!! HATA: $DEV mount edilemedi (formatsiz veya NTFS/exFAT)." >> "$LOG"
        echo "    Elle formatlayin: mkfs.ext4 -F $DEV" >> "$LOG"
        echo "------------------------------------------------------------" >> "$LOG"
        while [ -b "$DEV" ]; do sleep 1; done
        continue
    fi
 
    if [ ! -f "$MNT/testdata.bin" ] || [ ! -f "$MNT/testdata.sha256" ]; then
        echo ">>> Test verisi yok, olusturuluyor (${DATASIZE}MB)..." >> "$LOG"
        dd if=/dev/urandom of="$MNT/testdata.bin" bs=1M count=$DATASIZE 2>>"$LOG"
        sha256sum "$MNT/testdata.bin" | awk '{print $1}' > "$MNT/testdata.sha256"
        sync
        echo ">>> Test verisi hazir." >> "$LOG"
    else
        echo ">>> Mevcut test verisi bulundu." >> "$LOG"
    fi
 
    umount "$MNT"
    /root/usb_test.sh "$DEV" "otomatik_$(date '+%H%M%S')" >> "$LOG" 2>&1
 
    echo ">>> Test bitti. Bellegi cikarin, tekrar takin." >> "$LOG"
    echo "------------------------------------------------------------" >> "$LOG"
    while [ -b "$DEV" ]; do sleep 1; done
    echo ">>> Bellek cikarildi. Yeni takis bekleniyor..." >> "$LOG"
done
EOF
