# Copy repo to working directory and cd into it
sudo cp -r $GITHUB_WORKSPACE $HOME
cd $HOME/atlasview
echo $PWD

# Show current status of the repo
git describe --tags

# Set up Remark42 engine
git submodule update --init --recursive
cd remark42/remark42
git apply ../*.patch

cd $HOME/atlasview

# Check that docker is installed and build images
sudo docker --version
sudo docker compose up -d --build
