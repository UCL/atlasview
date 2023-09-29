# Move to atlasview in home directory
# We expect this directory to be created during initial provisioning of the runner
cd $HOME/atlasview
echo $PWD

# Update repo and show current status of the repo
git pull --tags
echo "\n*** CURRENT VERSION: $(git describe --tags) ***\n"

# Set up Remark42 engine
git submodule update --init --recursive
cd remark42/remark42
git apply ../*.patch

cd $HOME/atlasview

# Check that docker is installed and build images
sudo docker --version
sudo docker compose up -d --build
