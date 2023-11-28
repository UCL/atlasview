echo "Running backup script $(date)"

cd ${HOME}/atlasview-backups/comments

# connect to the remark container and trigger a backup
docker exec atlasview-remark-1 backup

# run script to convert backup of comments into an excel file
# use the latest created backup file, whatever the name
echo "Converting comments backup to Excel file"

## Remark backup dir is root-owned, need to give user access
REMARK_BKUP_DIR="${HOME}/atlasview-data/remark/backup"
sudo chmod -R a+rX ${REMARK_BKUP_DIR}

BKUP_FILE=$(ls -dAt ${REMARK_BKUP_DIR}/* | head -n 1)
${HOME}/atlasview/remark42/backup2excel.py "${BKUP_FILE}"

# create a timestamped backup of atlasview-data except caches and data files etc
cd ${HOME}
sudo zip -r atlasview-data-$(date -d "today" +"%Y%m%d%H%M").zip atlasview-data/caddy atlasview-data/remark atlasview-data/users.csv -x atlasview-data/remark/backup/**\*
mv atlasview-data-*.zip atlasview-backups

# sync the backup directory with remote share
rclone sync atlasview-backups/ sharepoint_disease_atlas:DiseaseAtlas/atlasview-backups/ --ignore-size --ignore-checksum --ignore-existing
