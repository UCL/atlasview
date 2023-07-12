cd /home/ubuntu/atlasview-backups/comments

# connect to the remark container and trigger a backup
docker exec -it atlasview-remark-1 backup

# run script to convert backup of comments into an excel file
/home/ubuntu/atlasview/remark42/backup2excel.py "$(ls -dAt /home/ubuntu/atlasview-data/remark/backup/* | head -n1)"

# create a timestamped backup of atlasview-data except caches and data files etc
cd /home/ubuntu
zip -r atlasview-data-$(date -d "today" +"%Y%m%d%H%M").zip atlasview-data/caddy atlasview-data/remark atlasview-data/users.csv -x atlasview-data/remark/backup/**\*
mv atlasview-data-*.zip atlasview-backups

# sync the backup directory with remote share
rclone sync atlasview-backups/ onedrive_ucl:DiseaseAtlas/atlasview-backups/
