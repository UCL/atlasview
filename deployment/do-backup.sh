# convert latest remark42 comment backup to an excel file
cd /home/ubuntu/atlasview-backups/comments
docker exec -it atlasview-remark-1 backup
/home/ubuntu/atlasview/remark42/backup2excel.py "$(ls -dAt /home/ubuntu/atlasview-data/remark/backup/* | head -n1)"

# create a timestamped backup over except caches, data files, other backups
cd /home/ubuntu
zip -r atlasview-data-$(date -d "today" +"%Y%m%d%H%M").zip atlasview-data/caddy atlasview-data/remark atlasview-data/users.csv -x atlasview-data/remark/backup/**\*
mv atlasview-data-*.zip atlasview-backups

# sync the backup directory with remote share
rclone sync atlasview-backups/ onedrive_ucl:DiseaseAtlas/atlasview-backups/
