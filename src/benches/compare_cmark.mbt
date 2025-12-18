///| Comparison benchmarks: mizchi/markdown vs rami3l/cmark

///|
/// Generate test document with n sections
fn generate_doc(sections : Int) -> String {
  let buf = StringBuilder::new()
  for i = 0; i < sections; i = i + 1 {
    buf.write_string("# Heading \{i}\n\n")
    buf.write_string(
      "This is paragraph \{i} with **bold** and *italic* text.\n\n",
    )
    buf.write_string("- Item 1\n- Item 2\n- Item 3\n\n")
    buf.write_string("```js\nconsole.log('code block \{i}');\n```\n\n")
  }
  buf.to_string()
}

///|
/// Small document (5 sections)
let small_doc : String = generate_doc(5)

///|
/// Medium document (20 sections)
let medium_doc : String = generate_doc(20)

///|
/// Large document (100 sections)
let large_doc : String = generate_doc(100)

// =============================================================================
// Parse benchmarks (mizchi/markdown)
// =============================================================================

///|
test "mizchi/markdown parse: small" (b : @bench.T) {
  b.bench(fn() {
    let result = @markdown.parse(small_doc)
    b.keep(result)
  })
}

///|
test "mizchi/markdown parse: medium" (b : @bench.T) {
  b.bench(fn() {
    let result = @markdown.parse(medium_doc)
    b.keep(result)
  })
}

///|
test "mizchi/markdown parse: large" (b : @bench.T) {
  b.bench(fn() {
    let result = @markdown.parse(large_doc)
    b.keep(result)
  })
}

// =============================================================================
// Parse benchmarks (rami3l/cmark)
// =============================================================================

///|
test "rami3l/cmark parse: small" (b : @bench.T) {
  b.bench(fn() {
    let result = @cmark.Doc::from_string(small_doc)
    b.keep(result)
  })
}

///|
test "rami3l/cmark parse: medium" (b : @bench.T) {
  b.bench(fn() {
    let result = @cmark.Doc::from_string(medium_doc)
    b.keep(result)
  })
}

///|
test "rami3l/cmark parse: large" (b : @bench.T) {
  b.bench(fn() {
    let result = @cmark.Doc::from_string(large_doc)
    b.keep(result)
  })
}

// =============================================================================
// Roundtrip benchmarks (mizchi/markdown: parse + serialize)
// =============================================================================

///|
test "mizchi/markdown roundtrip: small" (b : @bench.T) {
  b.bench(fn() {
    let result = @markdown.parse(small_doc)
    let output = @markdown.serialize(result.document)
    b.keep(output)
  })
}

///|
test "mizchi/markdown roundtrip: medium" (b : @bench.T) {
  b.bench(fn() {
    let result = @markdown.parse(medium_doc)
    let output = @markdown.serialize(result.document)
    b.keep(output)
  })
}

// =============================================================================
// HTML render benchmarks (rami3l/cmark: parse + html)
// =============================================================================

///|
test "rami3l/cmark html: small" (b : @bench.T) {
  b.bench(fn() {
    try {
      let result = @cmark_html.render(small_doc)
      b.keep(result)
    } catch {
      _ => ()
    }
  })
}

///|
test "rami3l/cmark html: medium" (b : @bench.T) {
  b.bench(fn() {
    try {
      let result = @cmark_html.render(medium_doc)
      b.keep(result)
    } catch {
      _ => ()
    }
  })
}
