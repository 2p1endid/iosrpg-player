import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';

const read = path => readFileSync(new URL(`../${path}`, import.meta.url), 'utf8');

test('release metadata uses public version 0.1.0 without changing build 14', () => {
  const project = read('project.yml');
  assert.match(project, /MARKETING_VERSION: "0\.1\.0"/);
  assert.match(project, /CURRENT_PROJECT_VERSION: "14"/);
});

test('about screen is bilingual and exposes version author repository and license', () => {
  const about = read('App/AboutView.swift');
  for (const text of ['关于软件', 'About', '版本', 'Version', '作者', 'Author', 'GitHub', 'MIT License']) {
    assert.ok(about.includes(text), `missing ${text}`);
  }
  assert.ok(about.includes('2p1endid'));
  assert.ok(about.includes('https://github.com/2p1endid/iosrpg-player'));
  assert.ok(about.includes('CFBundleShortVersionString'));
  assert.ok(about.includes('CFBundleVersion'));
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
  assert.ok(workflow.includes('IOSRPGPlayer-unsigned.ipa'));
  assert.ok(!workflow.toLowerCase().includes('sideloadly'));
  assert.ok(!workflow.includes('codesign --sign -'));
});
