import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';

const read = path => readFileSync(new URL(`../${path}`, import.meta.url), 'utf8');

test('beta metadata appends counters to main version and build', () => {
  const project = read('project.yml');
  assert.match(project, /MARKETING_VERSION: "0\.1\.1\.2"/);
  assert.match(project, /CURRENT_PROJECT_VERSION: "15\.2"/);
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

test('controller editor keeps a stable canvas and uses inline color controls', () => {
  const editor = read('App/VirtualControllerEditorView.swift');
  assert.match(editor, /editorCanvasHeight/);
  assert.match(editor, /colorButton\(\.orange|colorButton\(\.blue/);
  assert.ok(!editor.includes('ColorPicker('));
  assert.match(editor, /\.frame\(height: editorCanvasHeight\)/);
});
