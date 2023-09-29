# Ensure we're in the correct working directory
WORKDIR=$HOME/atlasview

# Copy repo to working directory and cd into it
cp -r $GITHUB_WORKSPACE $WORKDIR
cd $WORKDIR
echo $PWD

# Show current status of the repo
git describe --tags

# Check that docker is installed and build images
sudo docker --version
sudo docker compose up -d --build
