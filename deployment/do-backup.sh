echo "Running backup script $(date)"

cd ${HOME}/atlasview-backups/comments

# connect to the remark container and trigger a backup
docker exec atlasview-remark-1 backup

# run script to convert backup of comments into an excel file
# use the latest created backup file, whatever the name
echo "Converting comments backup to Excel file"
${HOME}/atlasview/remark42/backup2excel.py "$(ls -dAt ${HOME}/atlasview-data/remark/backup/* | head -n1)"

# create a timestamped backup of atlasview-data except caches and data files etc
cd ${HOME}
sudo zip -r atlasview-data-$(date -d "today" +"%Y%m%d%H%M").zip atlasview-data/caddy atlasview-data/remark atlasview-data/users.csv -x atlasview-data/remark/backup/**\*
mv atlasview-data-*.zip atlasview-backups

# sync the backup directory with remote share
rclone sync atlasview-backups/ sharepoint_disease_atlas:DiseaseAtlas/atlasview-backups/ --ignore-size --ignore-checksum
