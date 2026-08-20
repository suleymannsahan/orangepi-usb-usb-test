#!/bin/bash
# Kullanım: ./usb_test.sh /dev/sda1 "50cm"
 
DEV="$1"
LABEL="$2"
MNT="/mnt/usb"
DEST="/dev/shm/usb_copy"
 
mkdir -p "$MNT" "$DEST"
mount "$DEV" "$MNT" || { echo "Mount basarisiz"; exit 1; }
 
SRC="$MNT/testdata.bin"
EXPECTED=$(cat "$MNT/testdata.sha256")
SIZE=$(stat -c %s "$SRC")
 
sync
echo 3 > /proc/sys/vm/drop_caches
 
START=$(date +%s.%N)
cp "$SRC" "$DEST/testdata.bin"
sync
END=$(date +%s.%N)
 
ACTUAL=$(sha256sum "$DEST/testdata.bin" | awk '{print $1}')
 
awk -v s="$SIZE" -v st="$START" -v en="$END" -v lbl="$LABEL" \
    -v want="$EXPECTED" -v got="$ACTUAL" 'BEGIN {
    elapsed = en - st;
    speed = s / elapsed / 1048576;
    printf "====================================\n";
    printf "Test      : %s\n", lbl;
    printf "Boyut     : %.2f MB\n", s/1048576;
    printf "Sure      : %.2f s\n", elapsed;
    printf "Okuma Hizi: %.2f MB/s\n", speed;
    if (want == got) printf "Checksum  : GECTI\n";
    else printf "Checksum  : BASARISIZ - DATA BOZULDU\n";
    printf "====================================\n";
}'
 
if [ "$EXPECTED" == "$ACTUAL" ]; then RES="OK"; else RES="FAIL"; fi
awk -v s="$SIZE" -v st="$START" -v en="$END" -v lbl="$LABEL" -v r="$RES" 'BEGIN {
    printf "%s,%.2f,%s\n", lbl, s/(en-st)/1048576, r;
}' >> /dev/shm/usb_test_results.csv
 
rm -f "$DEST/testdata.bin"
umount "$MNT"
EOF
