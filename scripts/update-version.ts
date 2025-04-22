import * as fs from "fs";
import * as path from "path";

function updateVersion(customVersion?: string) {
  // Read package.json
  const packagePath = path.join(__dirname, "../package.json");
  const packageJson = JSON.parse(fs.readFileSync(packagePath, "utf8"));

  let newVersion: string;

  if (customVersion) {
    // Use custom version if provided
    newVersion = customVersion;
  } else {
    // If no version exists, start with 1.0.0
    if (!packageJson.version) {
      newVersion = "1.0.0";
    } else {
      // Parse current version
      const [major, minor, patch] = packageJson.version.split(".").map(Number);
      // Increment patch version
      newVersion = `${major}.${minor}.${patch + 1}`;
    }
  }

  // Update package.json
  packageJson.version = newVersion;
  fs.writeFileSync(packagePath, JSON.stringify(packageJson, null, 2));

  console.log(`Updated version to ${newVersion}`);
  return newVersion;
}

// Parse command line arguments
const args = process.argv.slice(2);
const customVersion = args.includes("--set-version")
  ? args[args.indexOf("--set-version") + 1]
  : undefined;

// Update version and export it for use in workflow
const newVersion = updateVersion(customVersion);
process.stdout.write(newVersion);
