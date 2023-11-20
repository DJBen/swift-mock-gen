import os
import re
import sys
import subprocess
import time

def find_swift_files_with_protocol(root_dir):
    protocol_pattern = r'\bprotocol\s+\w+'
    swift_files_with_protocol = []

    for dirpath, dirnames, filenames in os.walk(root_dir):
        for file in filenames:
            if file.endswith('.swift'):
                file_path = os.path.join(dirpath, file)
                with open(file_path, 'r', encoding='utf-8') as f:
                    if re.search(protocol_pattern, f.read()):
                        swift_files_with_protocol.append(os.path.abspath(file_path))

    return swift_files_with_protocol

def run_swift_build(dry_run):
    command = ["swift", "build"]
    print(f"Running command: {' '.join(command)}")
    if not dry_run:
        subprocess.run(command, check=True)

def generate_mock_files(swift_files, dry_run, extra_args):
    start_time = time.time()  # Start timing

    for file_path in swift_files:
        output_path = f"{file_path[:-6]}.mock.swift"
        command = f".build/debug/swift-mock-gen gen '{file_path}' {' '.join(extra_args)} > '{output_path}'"
        print(f"Executing command: {command}")
        if not dry_run:
            subprocess.run(command, shell=True)

    end_time = time.time()  # End timing
    print(f"Total mock generation time: {end_time - start_time:.2f} seconds")

def main():
    dry_run = '--dry-run' in sys.argv
    extra_args = [arg for arg in sys.argv if arg not in [sys.argv[0], sys.argv[1], '--dry-run']]

    if len(sys.argv) < 2:
        print("Usage: gen_mock_under_dir.py <path> [--dry-run] [extra args for swift-mock-gen]")
        sys.exit(1)

    root_directory = sys.argv[1]
    run_swift_build(dry_run)
    swift_files = find_swift_files_with_protocol(root_directory)
    generate_mock_files(swift_files, dry_run, extra_args)

if __name__ == "__main__":
    main()