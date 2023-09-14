# AtlasView

A website to view and comment on Disease Atlas results.

## Architecture

- The core application is written in R/Shiny.
- The [Remark42](https://remark42.com/) web app, a simple and lightweight commenting engine, is used to handle comments. We patch the app a little for seamless integration with the core R application.
- [Caddy](https://caddyserver.com/) is used to handle web requests, and proxy those requests to the R/Shiny server and Remark42 comment server. Caddy is simple to configure and offers zero-configuration automatic HTTPS out-of-the-box.

## Deployment

The application services have been packaged into containers, and are run using [Docker Compose](https://docs.docker.com/compose/). You need to have Docker installed on your machine if you'd like to run a local copy of the application.

### Clone and set up directories

Two directories residing next to each other are needed to run the application:

- `atlasview` - a clone of this AtlasView repository
- `atlasview-data` - the AtlasView results and other data files needed for the application. This folder is not part of the repository (changes should not be committed) but there is [dummy data](./deployment/atlasview-data) in the repository to get you started.

First, clone the repository and make a local copy of the data directory

```sh
git clone git@github.com:UCL/atlasview.git
cp -R atlasview/deployment/atlasview-data .
```

**Important:** don't forget to replace the dummy data files with your own files. We expect the
following files to be present:

See [below](#the-atlasview-data-directory) for more details on the data files.

```sh
atlasview-data
├── MM_2_n.csv
├── MM_for_circo_network_vis.csv
├── lkp_spe_col.csv
├── specialties.csv
└── users.csv
```

### Set up the `Remark42` engine

The Remark42 code is a submodule in the repository. We download the source code and patch it, ready for Docker to build. Our patches remove the logout links, because the R Shiny app handles credentials and login/logout.

```sh
# Set up the Remark42 engine
cd atlasview
git submodule init
git submodule update
cd remark42/remark42
git apply ../*.patch
```

### Set up environment variables

From the top of the atlasview repository (the one containing `docker-compose.yml`), we need to setup environment variables in `.env`. To run on the application on localhost, copy the example `.env` file:

```sh
cp .env.example .env
```

Three environment variables are required to run the application:

1. `ATLASVIEW_SITE_ADDRESS` - the DNS name to access the website. Caddy needs this to automatically provision SSL certificates. If running on your local machine, this is simply `localhost`
2. `REMARK42_SECRET` - a long, hard-to-guess, string to encrypt authentication tokens for Remark42
3. `REMARK42_ADMIN_PASSWD` - required to secure the endpoints if you want to do manual backup of Remark42 comments

Update the values in the `.env` file as necessary. This is automatically read by `docker compose`.

### Deploy the application

Finally, start the application containers. Note that if you want to run this on a **Mac with Apple Silicon**, you will need to install Rosetta and [enable it in the Docker Desktop settings](https://docs.docker.com/desktop/settings/mac/#use-rosetta-for-x86amd64-emulation-on-apple-silicon) (under `Features in development`). Rosetta can be installed by running `softwareupdate --install-rosetta`.

```sh
docker compose up
```

Once services have started, you can visit [https://localhost/](https://localhost/) and login with username `local.user` and password `local.password`.

## Administration

### Adding users

User credentials are kept in `atlasview-data/users.csv`. There are three columns for each user, and each string is quoted:

- `user`: username styled as `<firstname>.<lastname>` by convention
- `password`: a password hashed using the R function `scrypt::hashPassword()`. Helper script located at `deployment/scrypt-password.R`
  - `specialty_codes`: a regex expression specifying what specialty codes the user can see.
    To see everything, use: `"."`
  - Specify a specialty using its code e.g.: `"CARD"`
  - Multiple codes can be separated with pipe e.g.: `"ALLE|CARD"`

### Applying updates

After pulling new changes from the repository, `docker compose down` followed by `docker compose build` will pick-up and rebuild the containers if required.

You can rebuild a single container without bringing down other containers. For example, to apply changes to the Shiny container use:

```sh
docker compose up -d --no-deps --build shiny
```

### The `atlasview-data` directory

This directory contains data and configuration to run the application. The data is the directory should persist between restarts etc. It contains analysis of clinical data, so should not be shared with anyone without permission.

- `MM_2_n.csv`: patient counts and other stats for each index disease
- `MM_for_circo_network_vis.csv`: co-occurring diseases for every index disease
- `lkp_spe_col.csv`: colour coding for each specialty
- `specialties.csv`: full name and short code for each specialty
- `users.csv`: user credentials to login to the website
- `caddy/`: directory to hold Caddy server config and data, including TLS certificates that should be preserved between sessions
- `circos-cache/`: the circos plots are expensive to compute, so the SVG file which is generated and served is saved for future requests
- `remark/`: the Remark comment engine database of comments and backups

### Backing up and exporting comments

Remark42 will backup comments every 24 hours into `atlasview-data/remark/backup`. If you set the `REMARK42_ADMIN_PASSWD` environment variable, you can also backup by connecting to the Remark42 container and running `backup --url=http://localhost:8080`

The `backup2excel.py` Python script will read a given backup file and export the comments into an Excel file. It requires the Python `pandas` and `openpyxl` libraries:

```sh
atlasview/remark42/backup2excel.py atlasview-data/remark/backup/<gzipped-backup-file>.gz
```

## AWS setup

We've created an EC2 instance in the AWS ARC Playpen (currently named "tamuri-atlasview"), on which the containerised application is running. Installation is as above. The `.env` file is updated with the EC2 DNS name, and new Remark42 secret and admin passwords. Ports 80 and 443 are both open because they're needed for Caddy to automatically handle TLS certificates.

### Backups

Set up the environment for backups and copying over to OneDrive share

```sh
sudo apt update
sudo apt install python3-pip
sudo pip install pandas openpyxl  # we need these installed system-wide

sudo apt install rclone zip

# created a backup area, same level as atlasview folder
mkdir -p atlasview-backups/comments
```

Run `rclone config` to setup remote share as required. The [`do-backup.sh`](./deployment/do-backup.sh) script is scheduled to run every six hours (root cronjob).
