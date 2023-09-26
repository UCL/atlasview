# Ensure we're in the correct working directory
WORKDIR=$HOME/atlasview
echo $WORKDIR
cd $WORKDIR

# Pull latest updates
git pull

# Check that docker is installed and build images
sudo docker --version
sudo docker compose up -d --build

