# Ensure we're in the correct working directory
WORKDIR=$HOME/atlasview

# Copy repo to working directory if it doesn't exist yet
if [ ! -d "$WORKDIR" ]; then
    cp -r $GITHUB_WORKSPACE $WORKDIR
fi
cd $WORKDIR
echo $PWD

# Pull latest updates
git pull

# Check that docker is installed and build images
sudo docker --version
sudo docker compose up -d --build
