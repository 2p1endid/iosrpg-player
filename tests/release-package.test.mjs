import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';

const read = path => readFileSync(new URL(`../${path}`, import.meta.url), 'utf8');

test('beta metadata appends counters to main version and build', () => {
  const project = read('project.yml');
  assert.match(project, /MARKETING_VERSION: "0\.1\.1\.4"/);
  assert.match(project, /CURRENT_PROJECT_VERSION: "15\.4"/);
});

test('about screen uses the app icon and omits build metadata', () => {
  const about = read('App/AboutView.swift');
  const language = read('shared/AppLanguage.swift');
  for (const text of ['版本', 'Version', '作者', 'Author', 'GitHub', 'MIT License']) {
    assert.ok(about.includes(text) || language.includes(text), `missing ${text}`);
  }
  assert.ok(about.includes('2p1endid'));
  assert.ok(about.includes('https://github.com/2p1endid/rrppgo'));
  assert.ok(about.includes('CFBundleShortVersionString'));
  assert.ok(about.includes('AppIcon'));
  assert.ok(!about.includes('CFBundleVersion'));
  assert.ok(!about.includes('（构建'));
  assert.ok(!about.includes('(Build'));
});

test('application exposes a persistent global Chinese and English language switch', () => {
  const language = read('shared/AppLanguage.swift');
  const content = read('App/ContentView.swift');
  const app = read('App/RRPPGoApp.swift');
  assert.ok(language.includes('case chinese'));
  assert.ok(language.includes('case english'));
  assert.ok(language.includes('AppStorage'));
  assert.ok(content.includes('LanguageSettingsView'));
  assert.ok(app.includes('locale'));
});

test('README is Chinese first English second and documents third-party open source projects', () => {
  const readme = read('README.md');
  const chinese = readme.indexOf('## 中文');
  const english = readme.indexOf('## English');
  assert.ok(chinese >= 0 && english > chinese);
  for (const text of ['ZIPFoundation', 'XcodeGen', 'actions/checkout', 'actions/upload-artifact', 'MIT License']) {
    assert.ok(readme.includes(text), `README missing ${text}`);
  }
});

test('repository contains the MIT license', () => {
  assert.ok(existsSync(new URL('../LICENSE', import.meta.url)));
  const license = read('LICENSE');
  assert.ok(license.includes('MIT License'));
  assert.ok(license.includes('Copyright (c) 2026 2p1endid'));
});

test('CI packages and uploads only the unsigned IPA', () => {
  const workflow = read('.github/workflows/ios-build.yml');
  assert.ok(workflow.includes('RRPPGo-unsigned.ipa'));
  assert.ok(!workflow.toLowerCase().includes('sideloadly'));
  assert.ok(!workflow.includes('codesign --sign -'));
});

test('virtual controller defaults are generated from the legacy adaptive layout', () => {
  const layout = read('shared/GameControllerLayout.swift');
  const profile = read('shared/VirtualControllerProfile.swift');
  assert.match(layout, /static func defaultButtons/);
  assert.match(profile, /GameControllerLayout\.defaultButtons/);
  assert.ok(!profile.includes('x: 0.20, y: 0.70'));
});

test('controller profiles are stored independently for portrait and landscape', () => {
  const profile = read('shared/VirtualControllerProfile.swift');
  const content = read('App/ContentView.swift');
  assert.match(profile, /enum VirtualControllerOrientation/);
  assert.match(profile, /orientation: VirtualControllerOrientation/);
  assert.match(content, /handleControllerGeometryChange/);
  assert.match(content, /controllerOrientation/);
});

test('controller editor uses inline colors without a system color picker', () => {
  const content = read('App/ContentView.swift');
  assert.match(content, /inlineControllerColorButton/);
  assert.ok(!content.includes('ColorPicker('));
});

test('controller editing happens directly over the live game canvas', () => {
  const content = read('App/ContentView.swift');
  assert.match(content, /isEditingController/);
  assert.match(content, /EditableConfiguredGameButton/);
  assert.ok(!content.includes('.sheet(isPresented: $showsControllerEditor)'));
});

test('custom buttons accept typed keyboard mappings through a safe parser', () => {
  const mapping = read('shared/VirtualInputMapping.swift');
  const profile = read('shared/VirtualControllerProfile.swift');
  assert.match(mapping, /KeyboardInputDescriptor/);
  assert.match(mapping, /parse\(_ input: String\)/);
  assert.match(profile, /keyboardInput/);
});

test('My Games exposes per-game save management without launching the player', () => {
  const content = read('App/ContentView.swift');
  const saves = read('App/SaveManagementView.swift');
  const language = read('shared/AppLanguage.swift');
  assert.match(content, /saveManagementGame/);
  assert.match(content, /SaveManagementView\(game:/);
  assert.match(content, /externaldrive/);
  assert.match(saves, /init\(game: ImportedGame\)/);
  assert.match(saves, /allowsCapture/);
  assert.ok(language.includes('恢复后的存档会在下次启动该游戏时生效。'));
  assert.ok(language.includes('The restored save takes effect the next time this game starts.'));
});
