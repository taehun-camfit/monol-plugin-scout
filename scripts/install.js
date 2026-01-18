#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const os = require('os');

const MARKETPLACE_NAME = 'monol-plugin-scout';
const PLUGIN_NAME = 'monol-plugin-scout';

// Get the installed package location
const packageDir = path.resolve(__dirname, '..');

// Claude settings paths
const claudeDir = path.join(os.homedir(), '.claude');
const settingsPath = path.join(claudeDir, 'settings.json');
const pluginsDir = path.join(claudeDir, 'plugins');
const knownMarketplacesPath = path.join(pluginsDir, 'known_marketplaces.json');

function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function readJSON(filepath) {
  if (fs.existsSync(filepath)) {
    try {
      return JSON.parse(fs.readFileSync(filepath, 'utf8'));
    } catch (e) {
      return null;
    }
  }
  return null;
}

function writeJSON(filepath, data) {
  fs.writeFileSync(filepath, JSON.stringify(data, null, 2) + '\n');
}

function install() {
  console.log(`\n📦 Installing ${PLUGIN_NAME} Claude Code plugin...\n`);

  // Ensure directories exist
  ensureDir(claudeDir);
  ensureDir(pluginsDir);

  // Update settings.json
  let settings = readJSON(settingsPath) || {};

  if (!settings.extraKnownMarketplaces) {
    settings.extraKnownMarketplaces = {};
  }

  settings.extraKnownMarketplaces[MARKETPLACE_NAME] = {
    source: {
      source: 'npm',
      package: PLUGIN_NAME
    }
  };

  if (!settings.enabledPlugins) {
    settings.enabledPlugins = {};
  }

  settings.enabledPlugins[`${PLUGIN_NAME}@${MARKETPLACE_NAME}`] = true;

  writeJSON(settingsPath, settings);
  console.log(`✅ Updated ${settingsPath}`);

  // Update known_marketplaces.json
  let knownMarketplaces = readJSON(knownMarketplacesPath) || {};

  knownMarketplaces[MARKETPLACE_NAME] = {
    source: {
      source: 'npm',
      package: PLUGIN_NAME
    },
    installLocation: packageDir,
    lastUpdated: new Date().toISOString()
  };

  writeJSON(knownMarketplacesPath, knownMarketplaces);
  console.log(`✅ Updated ${knownMarketplacesPath}`);

  console.log(`
🎉 ${PLUGIN_NAME} installed successfully!

Available commands:
  /scout              - 프로젝트 분석 및 플러그인 추천
  /scout --quick      - 빠른 스캔 (점수 80+ 만)
  /scout compare      - 플러그인 비교
  /scout cleanup      - 미사용 플러그인 정리
  /scout explore      - 마켓플레이스 탐색
  /scout audit        - 보안/업데이트 점검
  /scout fork         - 플러그인 포크

Restart Claude Code to activate the plugin.
`);
}

try {
  install();
} catch (error) {
  console.error('❌ Installation failed:', error.message);
  process.exit(1);
}
