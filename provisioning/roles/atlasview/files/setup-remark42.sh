# Set up the Remark42 engine
echo "Current directory: $(pwd)"

echo "Initializing remark42 submodule..."
git submodule init
git submodule update
cd remark42/remark42

echo "Applying patches..."
git apply ../*.patch
