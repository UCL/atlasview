# Set up the Remark42 engine
echo "Current directory: $(pwd)"

echo "Initializing remark42 submodule..."
git submodule init
git submodule update
cd remark42/remark42

echo "Applying patches..."
## Check if patches were already applied or not
if $(git apply --check ../*.patch &> /dev/null); then
  git apply ../*.patch
fi
