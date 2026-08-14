import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = new URL('../', import.meta.url);
const rootPath = fileURLToPath(root);
const read = path => readFileSync(new URL(path, root), 'utf8');
const excludedDirectories = new Set(['.git', 'ci-artifacts', 'design']);

function textFiles(directory) {
  const results = [];
  for (const entry of readdirSync(directory)) {
    if (excludedDirectories.has(entry)) continue;
    const path = join(directory, entry);
    if (statSync(path).isDirectory()) results.push(...textFiles(path));
    else if (/\.(swift|mjs|js|json|ya?ml|md|plist|sh)$/.test(entry) || entry === 'LICENSE') results.push(path);
  }
  return results;
}

test('native project and application use the RRPPGo identity', () => {
  const project = read('project.yml');
  const plist = read('App/Info.plist');
  const app = read('App/RRPPGoApp.swift');

  assert.match(project, /^name: RRPPGo$/m);
  assert.ok(project.includes('  RRPPGo:'));
  assert.ok(project.includes('  RRPPGoTests:'));
  assert.ok(project.includes('PRODUCT_NAME: RRPPGo'));
  assert.ok(project.includes('PRODUCT_BUNDLE_IDENTIFIER: com.example.rrppgo'));
  assert.ok(project.includes('PRODUCT_BUNDLE_IDENTIFIER: com.example.rrppgo.tests'));
  assert.ok(project.includes('TEST_HOST: "$(BUILT_PRODUCTS_DIR)/RRPPGo.app/RRPPGo"'));
  assert.ok(plist.includes('<string>RRPPGo</string>'));
  assert.ok(app.includes('struct RRPPGoApp: App'));
});

test('public documentation and about page use RRPPGo and the renamed repository', () => {
  for (const path of ['README.md', 'BUILD_IPA.md', 'PROJECT_GOAL.md', 'App/AboutView.swift']) {
    const content = read(path);
    assert.ok(content.includes('RRPPGo'), `${path} is missing RRPPGo`);
    assert.ok(!content.includes('iOS RPG Player'), `${path} still contains the old product name`);
    assert.ok(!content.includes('iosrpg-player'), `${path} still contains the old repository name`);
  }
  assert.ok(read('App/AboutView.swift').includes('https://github.com/2p1endid/rrppgo'));
});

test('CI and build scripts produce only RRPPGo unsigned artifacts', () => {
  const workflow = read('.github/workflows/ios-build.yml');
  const script = read('scripts/build-ios.sh');
  for (const content of [workflow, script]) {
    assert.ok(content.includes('RRPPGo'));
    assert.ok(!content.includes('IOSRPGPlayer'));
  }
  assert.ok(workflow.includes('RRPPGo-unsigned.ipa'));
  assert.ok(!workflow.toLowerCase().includes('sideloadly'));
});

test('tracked source and documentation contain no legacy product identity', () => {
  const legacy = ['IOSRPGPlayer', 'iOS RPG Player', 'iosrpg-player', 'iosrpgplayer', 'ios-rpg-player'];
  const offenders = [];
  for (const absolute of textFiles(rootPath)) {
    const path = relative(rootPath, absolute);
    if (path.endsWith('tests\\brand-rename.test.mjs') || path.endsWith('tests/brand-rename.test.mjs')) continue;
    const content = readFileSync(absolute, 'utf8');
    for (const term of legacy) if (content.includes(term)) offenders.push(`${path}: ${term}`);
  }
  assert.deepEqual(offenders, []);
});
