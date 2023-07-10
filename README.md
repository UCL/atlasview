# AtlasView

A website to view and comment on Disease Atlas results.

## Architecture

- The application is written in R using the Shiny package. 
- The [Remark](https://remark42.com/) web app, a simple and lightweight commenting engine, is used to handle comments. We applied some small patches to the source for seamless integration with the main application.
- [Caddy](https://caddyserver.com/) is used to handle web requests, and proxy those requests to the R Shiny server and Remark comment server. Caddy is simple to configure and offers zero-configuration automatic HTTPS out-of-the-box.

## Deployment

The application services have been packaged into containers, and are run using [Docker Compose](https://docs.docker.com/compose/). You need install Docker on your machine if you'd like to run a local copy of the application.

### Instructions

Two directories residing in the same folder need to be setup to run the application:

1. `atlasview` - a clone of the AtlasView repository
2. `atlasview-data` - the AtlasView results and other associated data files needed for the application. This folder is not part of the repository (changes should not be committed) but there is dummy data to get you started.

First, clone the repository and make a local copy of the data directory

```
git clone git@github.com:UCL/atlasview.git
cp atlasview/deployment/atlasview-data .
```

The Remark commenting engine is a submodule in the repository. We download the source code and patch it, ready for Docker Compose to build. Our patches remove the logout links, because the R Shiny app handles credentials and login/logout.

```
# Set up the Remark42 engine
cd atlasview
git submodule init
git submodule update
cd remark42/remark42
git apply ../*.patch
```

Two environment variables need to be set to run the application:

1. `REMARK_SECRET` - a long, hard-to-guess, string to encrypt authentication tokens for Remark
2. `SITE_ADDRESS` - the DNS name to access the website. Caddy needs this to automatically provision SSL certificates. If running on your local machine, this is simply `localhost`

Finally, start using Docker Compose from the top directory of the repository (the one containing `docker-compose.yml`). In this example, we pass the values of the environment variables in the same command:

```
REMARK_SECRET=12345 SITE_ADDRESS=localhost docker compose up
```

Once the services have started, you can visit [https://localhost/](https://localhost/) and login with username `local.user` and password `local.password`.

## Administration

### Adding users

User credentials are kept in `atlasview-data/users.csv`. There are three columns for each user, and each string is quoted:

- `user`: username styled as `<firstname>.<lastname>` by convention
- `password`: a password hashed using the R function `scrypt::hashPassword()`. Helper script located at `deployment/scrypt-password.R`
- `specialty_codes`: a regex expression specifying what specialty codes the user can see.
	- To see everything, use: `"."`
	- Specify a specialty using its code e.g.: `"CARD"`
	- Multiple codes can be separated with pipe e.g.: `"ALLE|CARD"`

### Applying updates

After pulling new changes from the repository, `docker compose down` followed by `docker compose up` will pick-up and rebuild the containers if required. Don't forget to specify the `REMARK_SECRET` and `SITE_ADDRESS` on the command-line.

You can rebuild a single container without bringing down other containers. For example, to apply changes to the Shiny container use:

```
REMARK_SECRET=12345 SITE_ADDRESS=localhost docker compose up -d --no-deps --build shiny
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


