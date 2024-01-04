set -xeuo pipefail

export CI=true

echo "Selecting Xcode 15.0"
sudo xcode-select -s /Applications/Xcode15.0_15A240d.app/Contents/Developer
echo "Building and testing swift_mock_gen fat binaries..."

swift build -c release --arch x86_64
swift build -c release --arch arm64

echo "Zipping swift-mock-gen binaries"
mkdir -p .build/dist
cp .build/arm64-apple-macosx/release/swift-mock-gen .build/dist/swift-mock-gen_arm64-apple-macosx
cp .build/x86_64-apple-macosx/release/swift-mock-gen .build/dist/swift-mock-gen_x86_64-apple-macosx
zip -rj .build/dist/swift-mock-gen.zip .build/dist/*

echo "Uploading binaries to Google Cloud Storage"
gsutil cp .build/dist/swift-mock-gen.zip gs://phantom-dependency-uploads/swift-mock-gen.zip

echo "Cleaning up binaries"
rm -rf .build/dist
echo "Done! Go to https://snapengine-builder.sc-corp.net/jenkins/job/phantom-dependency-uploader/build?delay=0sec to trigger phantom dependency uploader."
echo "dependency_name: swift-mock-gen"
echo "dependency_package_url: gs://phantom-dependency-uploads/swift-mock-gen.zip"
echo "dependency_files: swift-mock-gen_arm64-apple-macosx,swift-mock-gen_x86_64-apple-macosx"
echo "dependency_owner: APPINS"
