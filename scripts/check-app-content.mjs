/**
 * Checks category seal assets and the string catalog.
 * Runs on Linux. Does not build the app.
 */
import { access, readFile } from "node:fs/promises";
import path from "node:path";

const SEAL_NAMES = [
  "PlaceCategorySealRestaurant",
  "PlaceCategorySealBar",
  "PlaceCategorySealCafe",
  "PlaceCategorySealMuseum",
  "PlaceCategorySealPark",
  "PlaceCategorySealTourist",
  "PlaceCategorySealHistoric",
  "PlaceCategorySealCuriosity",
  "PlaceCategorySealParty",
];

const LANGUAGES = ["pt-BR", "en"];

export async function checkSeals(sealsDirectory) {
  const problems = [];
  for (const name of SEAL_NAMES) {
    const imageset = path.join(sealsDirectory, `${name}.imageset`);
    const contentsPath = path.join(imageset, "Contents.json");
    let contents;
    try {
      contents = JSON.parse(await readFile(contentsPath, "utf8"));
    } catch {
      problems.push(`${name}: imageset sem Contents.json`);
      continue;
    }
    const filename = contents.images?.find((image) => image.filename)?.filename;
    if (!filename) {
      problems.push(`${name}: Contents.json não aponta um arquivo`);
      continue;
    }
    try {
      await access(path.join(imageset, filename));
    } catch {
      problems.push(`${name}: falta ${filename}`);
    }
  }
  return problems;
}

export function checkStrings(catalog) {
  const problems = [];
  for (const [key, entry] of Object.entries(catalog.strings ?? {})) {
    const localizations = entry?.localizations;
    if (!localizations) {
      if (entry?.extractionState) problems.push(`${key}: sem traduções`);
      continue;
    }
    for (const language of LANGUAGES) {
      const localization = localizations[language];
      if (!localization) {
        problems.push(`${key}: falta ${language}`);
        continue;
      }
      const states = collectStates(localization);
      if (states.length === 0) {
        problems.push(`${key}: ${language} sem texto`);
        continue;
      }
      for (const state of states) {
        if (state !== "translated") {
          problems.push(`${key}: ${language} está ${state ?? "sem estado"}`);
        }
      }
    }
  }
  return problems;
}

function collectStates(node, states = []) {
  if (!node || typeof node !== "object") return states;
  if (node.stringUnit) states.push(node.stringUnit.state);
  for (const value of Object.values(node)) {
    if (value && typeof value === "object") collectStates(value, states);
  }
  return states;
}

export function formatReport(sealProblems, stringProblems) {
  const lines = ["## Selo e tradução", ""];
  lines.push("### Selos", ...(sealProblems.length ? sealProblems.map((item) => `- ${item}`) : ["- ok"]));
  lines.push("", "### Strings", ...(stringProblems.length ? stringProblems.map((item) => `- ${item}`) : ["- ok"]), "");
  return lines.join("\n");
}

async function main() {
  const root = process.argv[2] ?? "ZanzarProject/ZanzarProject";
  const sealsDirectory = path.join(root, "Resources/Assets.xcassets/Seals");
  const catalogPath = path.join(root, "Resources/Localizable.xcstrings");
  const catalog = JSON.parse(await readFile(catalogPath, "utf8"));
  const sealProblems = await checkSeals(sealsDirectory);
  const stringProblems = checkStrings(catalog);
  const report = formatReport(sealProblems, stringProblems);
  process.stdout.write(report);
  if (process.env.GITHUB_STEP_SUMMARY) {
    const { appendFile } = await import("node:fs/promises");
    await appendFile(process.env.GITHUB_STEP_SUMMARY, report);
  }
  process.exitCode = sealProblems.length + stringProblems.length === 0 ? 0 : 1;
}

if (process.argv[1]?.endsWith("check-app-content.mjs")) {
  await main();
}
