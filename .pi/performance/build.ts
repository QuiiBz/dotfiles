import { spawnSync } from "node:child_process";
import {
  cpSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  realpathSync,
  renameSync,
  rmSync,
  statSync,
  symlinkSync,
} from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { pathToFileURL } from "node:url";

const agentDir = process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi/agent");
const installDir = join(homedir(), ".local/share/pi-compiled");
const miseResult = spawnSync("mise", ["which", "pi"], { encoding: "utf8" });
if (miseResult.status !== 0) throw new Error(miseResult.stderr || "Pi is not installed in mise");
const launcherPath = realpathSync(miseResult.stdout.trim());
const launcherSource = readFileSync(launcherPath, "utf8");
const cliPath = launcherSource.match(/^# cmd-shim-target=(.+)$/m)?.[1] ?? launcherPath;
const packageDir = realpathSync(resolve(dirname(cliPath), "../.."));
const resolveModule = (specifier: string) => Bun.resolveSync(specifier, packageDir);
const { DefaultPackageManager } = await import(join(packageDir, "dist/core/package-manager.js"));
const { SettingsManager } = await import(join(packageDir, "dist/core/settings-manager.js"));
const settingsManager = SettingsManager.create(homedir(), agentDir);
const packageManager = new DefaultPackageManager({ cwd: homedir(), agentDir, settingsManager });
const resources = await packageManager.resolve();
const extensionPaths: string[] = resources.extensions
  .filter((resource: { enabled: boolean; path: string }) => resource.enabled && !resource.path.startsWith("builtin:"))
  .map((resource: { path: string }) => resource.path);
const extensionRoots = extensionPaths.map((extensionPath) => dirname(realpathSync(extensionPath)));
const sourceChecks = new Map<string, Map<string, { size: number; mtimeMs: number }>>();
for (const extensionPath of extensionPaths) {
  const sourceStat = statSync(extensionPath);
  sourceChecks.set(extensionPath, new Map([[extensionPath, { size: sourceStat.size, mtimeMs: sourceStat.mtimeMs }]]));
}
const codePreviewPath = extensionPaths.find((extensionPath) => extensionPath.includes("/pi-code-previews/"));
const shikiPath = codePreviewPath ? Bun.resolveSync("shiki", dirname(realpathSync(codePreviewPath))) : undefined;
const moduleAliases = new Map<string, string>();
for (const packageName of ["pi-agent-core", "pi-tui", "pi-coding-agent"]) {
  const modulePath =
    packageName === "pi-coding-agent"
      ? join(packageDir, "dist/index.js")
      : resolveModule(`@earendil-works/${packageName}`);
  for (const scope of ["@earendil-works", "@mariozechner"]) moduleAliases.set(`${scope}/${packageName}`, modulePath);
}
for (const suffix of ["", "/compat", "/oauth", "/providers/all"]) {
  const modulePath = resolveModule(`@earendil-works/pi-ai${suffix || "/compat"}`);
  for (const scope of ["@earendil-works", "@mariozechner"]) moduleAliases.set(`${scope}/pi-ai${suffix}`, modulePath);
}
for (const suffix of ["", "/compile", "/value"]) {
  const modulePath = resolveModule(`typebox${suffix}`);
  moduleAliases.set(`typebox${suffix}`, modulePath);
  moduleAliases.set(`@sinclair/typebox${suffix}`, modulePath);
}

mkdirSync(join(installDir, "builds"), { recursive: true });
const buildDir = mkdtempSync(join(installDir, "builds/pi-"));
const sourceDir = join(buildDir, "source");
mkdirSync(join(sourceDir, "src/utils"), { recursive: true });
mkdirSync(join(sourceDir, "src/extensions/codemode"), { recursive: true });
await Bun.write(join(sourceDir, "cli.ts"), `import ${JSON.stringify(join(packageDir, "dist/bun/cli.js"))};`);
await Bun.write(
  join(sourceDir, "src/utils/image-resize-worker.ts"),
  `import ${JSON.stringify(join(packageDir, "dist/utils/image-resize-worker.js"))};`,
);
await Bun.write(
  join(sourceDir, "src/extensions/codemode/worker.ts"),
  `import ${JSON.stringify(join(packageDir, "dist/extensions/codemode/worker.js"))};`,
);

try {
  const result = await Bun.build({
    entrypoints: [
      join(sourceDir, "cli.ts"),
      join(sourceDir, "src/utils/image-resize-worker.ts"),
      join(sourceDir, "src/extensions/codemode/worker.ts"),
    ],
    root: sourceDir,
    compile: { outfile: join(buildDir, "pi"), autoloadBunfig: false, autoloadDotenv: false },
    bytecode: true,
    format: "esm",
    minify: true,
    plugins: [
      {
        name: "compiled-pi-extensions",
        setup(builder) {
          builder.onResolve(
            { filter: /^(?:@earendil-works\/pi-|@mariozechner\/pi-|@sinclair\/typebox|typebox)/ },
            ({ path }) => {
              const modulePath = moduleAliases.get(path);
              if (modulePath) return { path: modulePath };
            },
          );
          builder.onResolve({ filter: /^pi:compiled-extensions$/ }, () => ({
            path: "extensions",
            namespace: "pi-compiled",
          }));
          builder.onLoad({ filter: /.*/, namespace: "pi-compiled" }, () => ({
            contents: `export const compiledExtensions = new Map([${extensionPaths
              .map(
                (extensionPath) =>
                  `[${JSON.stringify(extensionPath)}, () => import(${JSON.stringify(extensionPath)}).then(module => module.default)]`,
              )
              .join(",")}]);`,
            loader: "js",
            resolveDir: packageDir,
          }));
          builder.onLoad({ filter: /\.[cm]?[jt]s$/ }, async ({ path }) => {
            if (/\/pi-ai\/dist\/providers\/[^/]+\.models\.js$/.test(path)) {
              const catalog = await import(path);
              const exports = Object.entries(catalog);
              if (!exports.length || exports.some(([name]) => !/^[A-Z0-9_]+_MODELS$/.test(name))) {
                throw new Error("Pi's generated model catalog changed; update the build script");
              }
              return {
                contents: exports
                  .map(
                    ([name, models]) => `export const ${name} = JSON.parse(${JSON.stringify(JSON.stringify(models))});`,
                  )
                  .join("\n"),
                loader: "js",
              };
            }
            let contents = await Bun.file(path).text();
            if (extensionRoots.some((extensionRoot) => path.startsWith(`${extensionRoot}/`))) {
              const sourceStat = statSync(path);
              for (const [extensionIndex, extensionRoot] of extensionRoots.entries()) {
                if (path.startsWith(`${extensionRoot}/`)) {
                  sourceChecks
                    .get(extensionPaths[extensionIndex])!
                    .set(path, { size: sourceStat.size, mtimeMs: sourceStat.mtimeMs });
                }
              }
              contents = contents.replaceAll("import.meta.url", JSON.stringify(pathToFileURL(path).href));
            }
            if (shikiPath && path === join(packageDir, "dist/core/extensions/virtual-modules.js")) {
              const marker = "export const VIRTUAL_MODULES = {";
              if (!contents.includes(marker))
                throw new Error("Pi's virtual module registry changed; update the build script");
              contents = `import { bundledLanguages, bundledThemes, bundledThemesInfo, createHighlighter } from ${JSON.stringify(shikiPath)};\n${contents}`;
              contents = contents.replace(
                marker,
                `${marker}\nshiki: { bundledLanguages, bundledThemes, bundledThemesInfo, createHighlighter },`,
              );
            }
            if (path.endsWith("/pi-code-previews/src/extension/index.ts")) {
              const marker = "void initializeShiki(codePreviewSettings.shikiTheme);";
              if (!contents.includes(marker))
                throw new Error("The code-preview initializer changed; update the build script");
              contents = contents.replace(
                marker,
                "setTimeout(() => { void initializeShiki(codePreviewSettings.shikiTheme); }, 50);",
              );
            }
            if (path === join(packageDir, "dist/core/extensions/loader.js")) {
              const marker = "async function loadExtensionModule(extensionPath, cacheToken) {";
              if (!contents.includes(marker)) throw new Error("Pi's extension loader changed; update the build script");
              contents = `import { compiledExtensions } from "pi:compiled-extensions";\n${contents}
              let compiledManifest;
              const compiledSourceValidity = new Map();
              function compiledSourcesCurrent(extensionPath) {
                if (compiledSourceValidity.has(extensionPath)) return compiledSourceValidity.get(extensionPath);
                let valid = false;
                try {
                  compiledManifest ??= JSON.parse(fs.readFileSync(path.join(path.dirname(process.execPath), "build.json"), "utf8"));
                  valid = Object.entries(compiledManifest.sourceChecks[extensionPath]).every(([sourcePath, expected]) => {
                    const actual = fs.statSync(sourcePath);
                    return actual.size === expected.size && actual.mtimeMs === expected.mtimeMs;
                  });
                } catch {}
                compiledSourceValidity.set(extensionPath, valid);
                return valid;
              }`;
              contents = contents.replace(
                marker,
                `${marker}
              const compiledFactory = compiledExtensions.get(extensionPath);
              if (compiledFactory && extensionCacheGeneration === 0 && compiledSourcesCurrent(extensionPath)) return compiledFactory();`,
              );
            }
            if (path === join(packageDir, "dist/bun/runtime-setup.js")) {
              const marker = 'import { bedrockProviderModule } from "@earendil-works/pi-ai/bedrock-provider";';
              if (!contents.includes(marker)) throw new Error("Pi's Bun setup changed; update the build script");
              contents = contents
                .replace(marker, "")
                .replace('import { setBedrockProviderModule } from "@earendil-works/pi-ai/compat";', "")
                .replace("setBedrockProviderModule(bedrockProviderModule);", "");
              contents = contents
                .replace('import { registerBunOAuthFlows } from "@earendil-works/pi-ai/bun-oauth";', "")
                .replace("registerBunOAuthFlows();", "");
            }
            if (path.endsWith("/pi-ai/dist/auth/oauth/load.js")) {
              contents = contents.replace(/importOAuthModule\("\.\/(.+?)\.ts"\)/g, 'import("./$1.js")');
            }
            if (path.endsWith("/pi-ai/dist/api/bedrock-converse-stream.lazy.js")) {
              const marker = 'await importNodeOnlyApi("./bedrock-converse-stream.ts")';
              if (!contents.includes(marker)) throw new Error("Pi's Bedrock loader changed; update the build script");
              contents = contents.replace(marker, 'await import("./bedrock-converse-stream.js")');
            }
            if (path === join(packageDir, "dist/modes/interactive/theme/theme-controller.js")) {
              const marker = "return this.terminalColorQuery;";
              if (!contents.includes(marker)) throw new Error("Pi's theme controller changed; update the build script");
              contents = contents.replace(
                marker,
                "return this.activeThemeName === SYSTEM_THEME_NAME || this.autoSyncEnabled ? this.terminalColorQuery : Promise.resolve();",
              );
            }
            if (path === join(packageDir, "dist/utils/tools-manager.js")) {
              const marker = /function commandExists\(cmd\) \{[\s\S]*?\n\}/;
              if (!marker.test(contents)) throw new Error("Pi's tool lookup changed; update the build script");
              contents = contents.replace(marker, "function commandExists(cmd) { return Bun.which(cmd) !== null; }");
            }
            if (path === join(packageDir, "dist/modes/interactive/interactive-mode.js")) {
              const marker = "this.ui.renderNow();\n        void loadAllHighlightLanguages()";
              if (!contents.includes(marker)) throw new Error("Pi's startup sequence changed; update the build script");
              contents = contents.replace(
                marker,
                `this.ui.renderNow();
              if (process.env.PI_STARTUP_READY === "1") process.stderr.write("PI_STARTUP_READY\\n");
              void loadAllHighlightLanguages()`,
              );
            }
            return { contents, loader: path.endsWith("ts") ? "ts" : "js" };
          });
        },
      },
    ],
  });
  if (!result.success) throw new Error(result.logs.join("\n"));
  for (const [source, destination] of [
    ["package.json", "package.json"],
    ["README.md", "README.md"],
    ["CHANGELOG.md", "CHANGELOG.md"],
    ["docs", "docs"],
    ["examples", "examples"],
    ["dist/modes/interactive/theme", "theme"],
    ["dist/modes/interactive/assets", "assets"],
    ["dist/core/export-html", "export-html"],
  ])
    cpSync(join(packageDir, source), join(buildDir, destination), { recursive: true });
  cpSync(resolveModule("@silvia-odwyer/photon-node/photon_rs_bg.wasm"), join(buildDir, "photon_rs_bg.wasm"));
  const versionResult = spawnSync(join(buildDir, "pi"), ["--version"], { encoding: "utf8" });
  const packageVersion = JSON.parse(readFileSync(join(packageDir, "package.json"), "utf8")).version;
  if (versionResult.status !== 0 || versionResult.stdout.trim() !== packageVersion) {
    throw new Error(versionResult.stderr || "Compiled Pi version check failed");
  }
  await Bun.write(
    join(buildDir, "build.json"),
    JSON.stringify(
      {
        packageVersion,
        bunVersion: Bun.version,
        extensionPaths,
        sourceChecks: Object.fromEntries(
          [...sourceChecks].map(([extensionPath, checks]) => [extensionPath, Object.fromEntries(checks)]),
        ),
      },
      null,
      2,
    ),
  );
  mkdirSync(join(installDir, "bin"), { recursive: true });
  const temporaryLink = join(installDir, `pi-${process.pid}`);
  symlinkSync(join(buildDir, "pi"), temporaryLink);
  renameSync(temporaryLink, join(installDir, "bin/pi"));
  console.log(`Installed Pi ${packageVersion} with ${extensionPaths.length} compiled extensions: ${installDir}/bin/pi`);
} catch (error) {
  rmSync(buildDir, { recursive: true, force: true });
  throw error;
} finally {
  rmSync(sourceDir, { recursive: true, force: true });
}
