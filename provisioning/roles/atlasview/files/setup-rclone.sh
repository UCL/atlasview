## Configure rclone to connect to Disease Atlas SharePoint
echo "Configuring rclone"

rclone --version

## Create rclone config with necessary parameters
if [[ -z "${RCLONE_ONEDRIVE_TOKEN}" ]]; then
    echo "Need to set the 'RCLONE_ONEDRIVE_TOKEN' environment variable. Aborting."
    exit 1
else
    ## This assumes that the $RCLONE_ONEDRIVE_TOKEN env var has been set
    ## The `config_driveid` is set to the default ID for the Documents folder in the SharePoint
    rclone config create sharepoint_disease_atlas onedrive \
        region='global' \
        config_refresh_token='false' \
        config_type='url' \
        config_site_url='ARCDiseaseAtlas' \
        config_driveid='b!A_CyvY0lm0e_fiFbHrAGt2_ypojUJDBOtulxPro8TMMjClih1vWfSI2YxYHYHClQ' \
        config_drive_ok='true' \
        --non-interactive
fi

