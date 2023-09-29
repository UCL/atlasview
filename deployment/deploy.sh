# Copy repo to working directory and cd into it
cp -r $GITHUB_WORKSPACE $HOME
cd $HOME/atlasview
echo $PWD

# Show current status of the repo
git describe --tags

# Check that docker is installed and build images
sudo docker --version
sudo docker compose up -d --build
