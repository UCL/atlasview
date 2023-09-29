# Move to atlasview in home directory
# We expect this directory to be created during initial provisioning of the runner
cd $HOME/atlasview
echo $PWD

# Update repo and show current status of the repo
git pull --tags
git describe --tags

# Set up Remark42 engine
git submodule update --init --recursive
cd remark42/remark42
# For some reason the remark42/remark42/ files are root-owned, so need sudo
sudo git apply ../*.patch

cd $HOME/atlasview

# Check that docker is installed and build images
sudo docker --version
sudo docker compose up -d --build
