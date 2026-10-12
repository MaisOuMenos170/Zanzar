import assert from "node:assert/strict";
import { mkdtemp, mkdir, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";
import { checkSeals, checkStrings } from "./check-app-content.mjs";

test("a string missing English fails", () => {
  const problems = checkStrings({
    strings: {
      "map.title": {
        extractionState: "manual",
        localizations: {
          "pt-BR": { stringUnit: { state: "translated", value: "Mapa" } },
        },
      },
    },
  });
  assert.deepEqual(problems, ["map.title: falta en"]);
});

test("plural strings count as translated", () => {
  const problems = checkStrings({
    strings: {
      "count %lld": {
        localizations: {
          en: { variations: { plural: { one: { stringUnit: { state: "translated", value: "1" } } } } },
          "pt-BR": { variations: { plural: { one: { stringUnit: { state: "translated", value: "1" } } } } },
        },
      },
    },
  });
  assert.deepEqual(problems, []);
});

test("a missing seal file is reported", async () => {
  const root = await mkdtemp(path.join(tmpdir(), "seals-"));
  await mkdir(path.join(root, "PlaceCategorySealBar.imageset"), { recursive: true });
  await writeFile(
    path.join(root, "PlaceCategorySealBar.imageset", "Contents.json"),
    JSON.stringify({ images: [{ filename: "PlaceCategorySealBar.svg" }] }),
  );
  const problems = await checkSeals(root);
  assert.equal(problems.some((problem) => problem.includes("falta PlaceCategorySealBar.svg")), true);
});

test("the app tree has every category seal and translated strings", async () => {
  const problems = await checkSeals(
    "ZanzarProject/ZanzarProject/Resources/Assets.xcassets/Seals",
  );
  assert.deepEqual(problems, []);
  const { readFile } = await import("node:fs/promises");
  const catalog = JSON.parse(
    await readFile("ZanzarProject/ZanzarProject/Resources/Localizable.xcstrings", "utf8"),
  );
  assert.deepEqual(checkStrings(catalog), []);
});
