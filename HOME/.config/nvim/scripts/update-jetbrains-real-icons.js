#!/usr/bin/env node

const fs = require('fs')
const os = require('os')
const path = require('path')
const { execFileSync, spawnSync } = require('child_process')

const themeId = 'vscode-jetbrains-icon-theme-2023-dark'
const packRoot = path.resolve(__dirname, '..', 'assets', 'real-icons', 'jetbrains-2023-dark')
const iconsRoot = path.join(packRoot, 'icons')

function die(message) {
  console.error(`error: ${message}`)
  process.exit(1)
}

function hasCommand(command) {
  const result = spawnSync(command, ['--version'], { stdio: 'ignore' })
  return result.status === 0
}

function versionParts(extensionPath) {
  const match = path.basename(extensionPath).match(/-(\d+(?:\.\d+)*)$/)
  return match ? match[1].split('.').map((part) => Number(part)) : []
}

function compareVersions(left, right) {
  const a = versionParts(left)
  const b = versionParts(right)
  const length = Math.max(a.length, b.length)

  for (let i = 0; i < length; i++) {
    const diff = (a[i] || 0) - (b[i] || 0)
    if (diff !== 0) return diff
  }

  return left.localeCompare(right)
}

function extensionRoots() {
  const home = os.homedir()
  return [
    path.join(home, '.vscode', 'extensions'),
    path.join(home, '.vscode-oss', 'extensions'),
    path.join(home, '.cursor', 'extensions'),
  ]
}

function findLatestExtension() {
  const candidates = []

  for (const root of extensionRoots()) {
    if (!fs.existsSync(root)) continue

    for (const entry of fs.readdirSync(root)) {
      if (entry.startsWith('chadalen.vscode-jetbrains-icon-theme-')) {
        candidates.push(path.join(root, entry))
      }
    }
  }

  candidates.sort(compareVersions)
  return candidates.at(-1)
}

function findThemeManifest(extensionRoot) {
  const manifestPath = path.join(extensionRoot, 'package.json')
  if (!fs.existsSync(manifestPath)) {
    const directTheme = path.join(extensionRoot, 'theme.json')
    if (fs.existsSync(directTheme)) return directTheme
    die(`could not find package.json or theme.json in ${extensionRoot}`)
  }

  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'))
  const iconThemes = manifest.contributes && manifest.contributes.iconThemes
  const theme = iconThemes && iconThemes.find((item) => item.id === themeId)

  if (!theme) {
    die(`could not find icon theme ${themeId} in ${manifestPath}`)
  }

  return path.resolve(extensionRoot, theme.path)
}

function renderPack(sourceManifestPath) {
  const sourceRoot = path.dirname(sourceManifestPath)
  const theme = JSON.parse(fs.readFileSync(sourceManifestPath, 'utf8'))
  const definitions = theme.iconDefinitions || {}

  fs.rmSync(iconsRoot, { recursive: true, force: true })
  fs.mkdirSync(iconsRoot, { recursive: true })

  let rendered = 0

  for (const [key, definition] of Object.entries(definitions)) {
    if (!definition.iconPath) continue

    const sourceIcon = path.resolve(sourceRoot, definition.iconPath)
    const targetIcon = path.join(iconsRoot, `${key}.png`)

    if (!fs.existsSync(sourceIcon)) {
      die(`missing source icon for ${key}: ${sourceIcon}`)
    }

    execFileSync('rsvg-convert', ['-w', '64', '-h', '64', sourceIcon, '-o', targetIcon])
    definition.iconPath = `./icons/${key}.png`
    rendered++
  }

  fs.mkdirSync(packRoot, { recursive: true })
  fs.writeFileSync(path.join(packRoot, 'theme.json'), `${JSON.stringify(theme, null, 2)}\n`)

  return rendered
}

if (!hasCommand('rsvg-convert')) {
  die('rsvg-convert is required; install librsvg first')
}

const source = process.argv[2] || process.env.JETBRAINS_ICON_THEME || findLatestExtension()
if (!source) {
  die('could not find an installed JetBrains icon theme extension')
}

const sourceManifest = findThemeManifest(path.resolve(source))
const rendered = renderPack(sourceManifest)

console.log(`source: ${sourceManifest}`)
console.log(`target: ${packRoot}`)
console.log(`rendered ${rendered} icons`)
