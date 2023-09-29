# Move to atlasview in home directory
# We expect this directory to be created during initial provisioning of the runner
cd $HOME/atlasview
echo $PWD

# Update repo and show current status of the repo
git pull --tags
echo "\n*** CURRENT VERSION: $(git describe --tags) ***\n"

# Make sure Remark42 patches were applied
cd remark42/remark42
git apply --reverse --check ../*.patch  # fails if patches were not applied
git status                              # should show changes to auth-panel.tsx and profile.tsx

cd $HOME/atlasview

# Check that docker is installed and build images
sudo docker --version
sudo docker compose up -d --build
