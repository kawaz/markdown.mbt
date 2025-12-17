#!/usr/bin/env node
/**
 * Generate CommonMark compatibility tests from spec.json
 *
 * Usage: node scripts/gen-tests.js
 *
 * This script:
 * 1. Downloads CommonMark spec.json
 * 2. Generates MoonBit test files comparing our output with remark-gfm
 */

const fs = require('fs');
const path = require('path');

const SPEC_URL = 'https://spec.commonmark.org/0.31.2/spec.json';
const OUTPUT_DIR = path.join(__dirname, '../src/cmark_tests');

// Sections to include (skip some that are HTML-specific or edge cases)
const INCLUDE_SECTIONS = [
  'Tabs',
  'Thematic breaks',
  'ATX headings',
  'Setext headings',
  'Indented code blocks',
  'Fenced code blocks',
  'Paragraphs',
  'Blank lines',
  'Block quotes',
  'List items',
  'Lists',
  'Backslash escapes',
  'Code spans',
  'Emphasis and strong emphasis',
  'Links',
  'Images',
  'Autolinks',
  'Hard line breaks',
  'Soft line breaks',
  'Textual content',
];

// Escape string for MoonBit string literal
function escapeString(s) {
  return s
    .replace(/\\/g, '\\\\')
    .replace(/"/g, '\\"')
    .replace(/\n/g, '\\n')
    .replace(/\r/g, '\\r')
    .replace(/\t/g, '\\t');
}

// Convert section name to valid MoonBit identifier
function sectionToId(section) {
  return section
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_|_$/g, '');
}

// Update .gitignore to exclude generated tests
function updateGitignore() {
  const gitignorePath = path.join(__dirname, '../.gitignore');
  const entry = 'src/cmark_tests/';

  let content = '';
  if (fs.existsSync(gitignorePath)) {
    content = fs.readFileSync(gitignorePath, 'utf-8');
  }

  if (!content.includes(entry)) {
    // Ensure file ends with newline before adding
    if (content.length > 0 && !content.endsWith('\n')) {
      content += '\n';
    }
    content += entry + '\n';
    fs.writeFileSync(gitignorePath, content);
    console.log(`Added ${entry} to .gitignore`);
  }
}

async function main() {
  // Update .gitignore first
  updateGitignore();

  console.log('Fetching CommonMark spec...');
  const response = await fetch(SPEC_URL);
  const spec = await response.json();

  console.log(`Found ${spec.length} test cases`);

  // Group by section
  const bySection = new Map();
  for (const test of spec) {
    if (!INCLUDE_SECTIONS.includes(test.section)) continue;

    if (!bySection.has(test.section)) {
      bySection.set(test.section, []);
    }
    bySection.get(test.section).push(test);
  }

  // Create output directory
  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  }

  // Generate moon.pkg.json
  const pkgJson = {
    import: ['mizchi/markdown'],
    'test-import': ['mizchi/markdown'],
  };
  fs.writeFileSync(
    path.join(OUTPUT_DIR, 'moon.pkg.json'),
    JSON.stringify(pkgJson, null, 2) + '\n'
  );

  // Generate ffi.mbt (copy from compat_tests)
  const ffiContent = `///| FFI bindings for remark compatibility testing
///| This file is JS-target only

///| Call remark with GFM support to process markdown (sync via require)
///| Returns stringified result from remark
pub extern "js" fn remark_stringify(input : String) -> String =
  #| (input) => {
  #|   const { remark } = require('remark');
  #|   const remarkGfm = require('remark-gfm').default;
  #|   const result = remark().use(remarkGfm).processSync(input);
  #|   return String(result);
  #| }
`;
  fs.writeFileSync(path.join(OUTPUT_DIR, 'ffi.mbt'), ffiContent);

  // Generate test helper
  const helperContent = `///| CommonMark spec compatibility tests
///| Generated from https://spec.commonmark.org/0.31.2/spec.json

///| Test helper: compare our output with remark's output
pub fn assert_commonmark_compat(input : String, example : Int) -> Unit {
  let our_output = @markdown.md_parse_and_render(input)
  let remark_output = remark_stringify(input)

  // Normalize trailing whitespace for comparison
  let our_normalized = our_output.trim_end(chars=" \\n\\t")
  let remark_normalized = remark_output.trim_end(chars=" \\n\\t")

  if our_normalized != remark_normalized {
    println("=== Example \\{example} ===")
    println("=== Input ===")
    println(input)
    println("=== Our output ===")
    println(our_normalized)
    println("=== Remark output ===")
    println(remark_normalized)
    panic()
  }
}
`;
  fs.writeFileSync(path.join(OUTPUT_DIR, 'helper.mbt'), helperContent);

  // Generate test files per section
  let totalTests = 0;
  for (const [section, tests] of bySection) {
    const sectionId = sectionToId(section);
    const fileName = `${sectionId}_test.mbt`;

    let content = `///| CommonMark spec tests: ${section}\n\n`;

    for (const test of tests) {
      const escapedInput = escapeString(test.markdown);
      content += `test "commonmark example ${test.example}: ${section}" {\n`;
      content += `  assert_commonmark_compat("${escapedInput}", ${test.example})\n`;
      content += `}\n\n`;
      totalTests++;
    }

    fs.writeFileSync(path.join(OUTPUT_DIR, fileName), content);
    console.log(`Generated ${fileName} with ${tests.length} tests`);
  }

  console.log(`\nTotal: ${totalTests} tests generated in ${OUTPUT_DIR}`);
  console.log('\nRun tests with: moon test --target js -p mizchi/markdown/commonmark_tests');
}

main().catch(console.error);
