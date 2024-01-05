set -xeuo pipefail

export CI=true

source $(dirname $BASH_SOURCE)/utils.sh

echo "Selecting Xcode 15.0"
sudo xcode-select -s /Applications/Xcode15.0_15A240d.app/Contents/Developer
echo "Building and testing swift_mock_gen fat binaries..."

swift build --product swift-mock-gen -c release --arch x86_64
swift build --product swift-mock-gen -c release --arch arm64

echo "Zipping swift-mock-gen binaries"
mkdir -p .build/dist
cp .build/arm64-apple-macosx/release/swift-mock-gen .build/dist/swift-mock-gen_arm64-apple-macosx
cp .build/x86_64-apple-macosx/release/swift-mock-gen .build/dist/swift-mock-gen_x86_64-apple-macosx
zip -rj .build/dist/swift-mock-gen.zip .build/dist/*

echo "Uploading binaries to Google Cloud Storage"
gsutil cp .build/dist/swift-mock-gen.zip gs://phantom-dependency-uploads/swift-mock-gen.zip

echo "Cleaning up binaries"
rm -rf .build/dist

PHANTOM_DEP_UPLOADER_URL="https://snapengine-builder.sc-corp.net/jenkins/job/phantom-dependency-uploader/build?delay=0sec"
GS_URL="gs://phantom-dependency-uploads/swift-mock-gen.zip"
echo "Posting PR Comment..."
escaped_url=$(escape_slashes "${PHANTOM_DEP_UPLOADER_URL}")
escaped_gs_url=$(escape_slashes "${GS_URL}")
comment="Done! In order to get md5, version, and sha256, go to ${escaped_url} to trigger phantom dependency uploader and you'll receive an email when it finishes.\r\n pull_number: <Any integer>\r\n branch: master\r\n dependency_name: swift-mock-gen\r\n dependency_package_url: ${escaped_gs_url}\r\n dependency_files: swift-mock-gen_arm64-apple-macosx,swift-mock-gen_x86_64-apple-macosx\r\n dependency_owner: APPINS contact_email: <Your email>"

post_comment "${comment}"
