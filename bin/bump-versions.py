#!/usr/bin/env python3
import os
import sys
import subprocess
import re
import json

def get_modified_files():
	"""Gets list of modified Lua files under src/ and lib/ using git status."""
	try:
		res = subprocess.run(
			["git", "status", "--porcelain"],
			check=True,
			stdout=subprocess.PIPE,
			stderr=subprocess.PIPE,
			text=True
		)
	except subprocess.CalledProcessError as e:
		print(f"Error checking git status: {e.stderr.strip()}")
		return []

	modified_files = []
	for line in res.stdout.splitlines():
		if not line.strip():
			continue
		# Status code is first 2 chars
		status = line[:2].strip()
		filepath = line[3:].strip()
		# Handle renames (e.g., "R  old -> new")
		if " -> " in filepath:
			filepath = filepath.split(" -> ")[1].strip()
		
		# Only track .lua files under src/ and lib/
		if filepath.endswith(".lua") and (filepath.startswith("src/") or filepath.startswith("lib/")):
			modified_files.append(filepath)
			
	return list(set(modified_files))

def parse_header(filepath):
	"""Reads first line of file and parses metadata JSON."""
	if not os.path.exists(filepath):
		return None, None
	try:
		with open(filepath, "r", encoding="utf-8") as f:
			first_line = f.readline().strip()
	except IOError:
		return None, None

	# Matches "-- {" or "--{" at start
	match = re.match(r"^--\s*(\{.*\})\s*$", first_line)
	if not match:
		return None, first_line

	try:
		metadata = json.loads(match.group(1))
		return metadata, first_line
	except json.JSONDecodeError:
		return None, first_line

def save_header(filepath, metadata, original_first_line):
	"""Writes updated metadata back as the first line of the file."""
	try:
		with open(filepath, "r", encoding="utf-8") as f:
			lines = f.readlines()
	except IOError:
		print(f"Error reading {filepath}")
		return False

	new_first_line = f"-- {json.dumps(metadata, separators=(',', ':'))}\n"
	lines[0] = new_first_line

	try:
		with open(filepath, "w", encoding="utf-8") as f:
			f.writelines(lines)
		return True
	except IOError:
		print(f"Error writing to {filepath}")
		return False

def bump_semver(version_str, bump_type):
	"""Bumps version string based on type: patch, minor, major."""
	# Match standard SemVer: X.Y.Z or X.Y.Z-beta etc.
	match = re.match(r"^(\d+)\.(\d+)\.(\d+)(.*)$", version_str)
	if not match:
		return None

	major = int(match.group(1))
	minor = int(match.group(2))
	patch = int(match.group(3))
	suffix = match.group(4)

	if bump_type == "patch":
		patch += 1
	elif bump_type == "minor":
		minor += 1
		patch = 0
	elif bump_type == "major":
		major += 1
		minor = 0
		patch = 0

	return f"{major}.{minor}.{patch}"

def prompt_user(filepath, current_version):
	"""Prompts user for version bump choice."""
	print(f"\nModified File: \033[1;36m{filepath}\033[0m")
	print(f"Current Version: \033[1;33m{current_version}\033[0m")
	print("Select version bump type:")
	print("  [1] Patch bump  (➔ X.Y.Z+1)")
	print("  [2] Minor bump  (➔ X.Y+1.0)")
	print("  [3] Major bump  (➔ X+1.0.0)")
	print("  [4] Custom version input")
	print("  [5] Skip this file")
	
	while True:
		try:
			choice = input("Enter option [1-5] (default 1): ").strip()
			if not choice:
				return "patch"
			if choice == "1":
				return "patch"
			elif choice == "2":
				return "minor"
			elif choice == "3":
				return "major"
			elif choice == "4":
				custom = input("Enter custom version string: ").strip()
				if custom:
					return ("custom", custom)
			elif choice == "5":
				return "skip"
			else:
				print("Invalid option. Please enter 1, 2, 3, 4, or 5.")
		except KeyboardInterrupt:
			print("\nAborted.")
			sys.exit(0)

def main():
	print("==================================================")
	print("  Tsundoku/Shosetsu Extension Auto-Version Bumper")
	print("==================================================")

	files = get_modified_files()
	if not files:
		print("No modified Lua files detected in src/ or lib/.")
		sys.exit(0)

	bumped_any = False
	for filepath in files:
		metadata, raw_header = parse_header(filepath)
		if not metadata or "ver" not in metadata:
			print(f"Skipping {filepath} (No valid JSON metadata header found on line 1)")
			continue

		current_ver = metadata["ver"]
		action = prompt_user(filepath, current_ver)
		
		if action == "skip":
			print(f"Skipped version bump for {filepath}")
			continue
			
		if isinstance(action, tuple) and action[0] == "custom":
			new_ver = action[1]
		else:
			new_ver = bump_semver(current_ver, action)
			if not new_ver:
				print(f"Error parsing version '{current_ver}'. Skipping.")
				continue

		metadata["ver"] = new_ver
		if save_header(filepath, metadata, raw_header):
			print(f"\033[1;32mUpdated {filepath} version to {new_ver}\033[0m")
			bumped_any = True

	if bumped_any:
		print("\nRegenerating index.json...")
		if os.path.exists("bin/extension-tester.jar"):
			try:
				subprocess.run(
					["java", "-jar", "bin/extension-tester.jar", "--generate-index"],
					check=True
				)
				print("\033[1;32mindex.json successfully generated and synchronized!\033[0m")
			except subprocess.CalledProcessError:
				print("\033[1;31mError running extension-tester to generate index.\033[0m")
		else:
			print("\033[1;33mWarning: bin/extension-tester.jar not found. Please run dev-setup.sh --tester\033[0m")
	else:
		print("\nNo version updates were made.")

if __name__ == "__main__":
	main()
