set -xeuo pipefail

export CI=true

source $(dirname $BASH_SOURCE)/utils.sh

echo "Selecting Xcode 15.0"
sudo xcode-select -s /Applications/Xcode15.0_15A240d.app/Contents/Developer
echo "Building and testing swift_mock_gen..."

bzl build //:all --disk_cache="" --remote_cache=""

deploy ""