# clean up Journal logs
journalctl --disk-usage
journalctl --vacuum-time=7d

# find top large files
du -hs * | sort -rh | head -5

# find top large folders
du -Sh | sort -rh | head -5

# find largest file on specific folder
find ~/your-folder -type f -exec du -hs * {} + | sort -rh | head -n 5

# create big file
dd if=/dev/zero of=1g.img bs=100M count=10

# retry command until max retry limit
TRY=1; until [[ $TRY -gt 3 ]] || rm temp.txt ; do echo retry $TRY; echo "please wait... $(date)"; TRY=$(expr $TRY + 1); sleep 5; done;
