///| Plugin system tests

test "plugin: default options" {
  let options = TuiOptions::default()
  let output = md_to_tui_with_options("# Hello\n", options)
  inspect(output.contains("Hello"), content="true")
}

test "plugin: parse_code_block_info simple lang" {
  let info = parse_code_block_info("javascript")
  inspect(info.lang, content="javascript")
  inspect(info.filename, content="")
  inspect(info.meta, content="")
}

test "plugin: parse_code_block_info with filename" {
  let info = parse_code_block_info("js:app.js")
  inspect(info.lang, content="js")
  inspect(info.filename, content="app.js")
  inspect(info.meta, content="")
}

test "plugin: parse_code_block_info with meta" {
  let info = parse_code_block_info("ts:index.ts {highlight=[1,3]}")
  inspect(info.lang, content="ts")
  inspect(info.filename, content="index.ts")
  inspect(info.meta, content="{highlight=[1,3]}")
}

test "plugin: parse_code_block_info empty" {
  let info = parse_code_block_info("")
  inspect(info.lang, content="")
  inspect(info.filename, content="")
  inspect(info.meta, content="")
}

test "plugin: custom code highlighter with CodeBlockInfo" {
  fn custom_highlighter(info : CodeBlockInfo, code : String) -> String {
    let buf = StringBuilder::new()
    buf.write_string("LANG=")
    buf.write_string(info.lang)
    if not(info.filename.is_empty()) {
      buf.write_string(" FILE=")
      buf.write_string(info.filename)
    }
    buf.write_string("\n")
    buf.write_string(code)
    buf.to_string()
  }

  let options = TuiOptions::with_highlighter(custom_highlighter)
  let output = md_to_tui_with_options("```js:app.js\ncode\n```\n", options)
  inspect(output.contains("LANG=js"), content="true")
  inspect(output.contains("FILE=app.js"), content="true")
}

test "plugin: simple highlighter" {
  fn simple_highlighter(lang : String, code : String) -> String {
    "<<" + lang + ">>\n" + code
  }

  let options = TuiOptions::with_simple_highlighter(simple_highlighter)
  let output = md_to_tui_with_options("```python\nprint('hi')\n```\n", options)
  inspect(output.contains("<<python>>"), content="true")
}

test "plugin: highlighter receives code" {
  let mut received_code = ""
  fn code_checker(_info : CodeBlockInfo, code : String) -> String {
    received_code = code
    "output"
  }

  let options = TuiOptions::with_highlighter(code_checker)
  let _ = md_to_tui_with_options("```js\nlet x = 1;\n```\n", options)
  inspect(received_code.contains("let x = 1;"), content="true")
}

test "plugin: syntax highlight simulation" {
  fn syntax_highlighter(info : CodeBlockInfo, code : String) -> String {
    let buf = StringBuilder::new()
    buf.write_string(bold)
    buf.write_string("[")
    buf.write_string(info.lang)
    buf.write_string("]\n")
    buf.write_string(reset)

    // Simple keyword highlighting
    let highlighted = code
      .replace(old="fn", new="\u001b[35mfn\u001b[0m")
      .replace(old="let", new="\u001b[35mlet\u001b[0m")
      .replace(old="const", new="\u001b[35mconst\u001b[0m")
    buf.write_string(highlighted)
    buf.to_string()
  }

  let options = TuiOptions::with_highlighter(syntax_highlighter)
  let output = md_to_tui_with_options("```rust\nfn main() {\n    let x = 1;\n}\n```\n", options)
  inspect(output.contains("[rust]"), content="true")
  inspect(output.contains("\u001b[35mfn\u001b[0m"), content="true")
  inspect(output.contains("\u001b[35mlet\u001b[0m"), content="true")
}

test "plugin: non-code blocks unaffected" {
  fn custom_highlighter(_info : CodeBlockInfo, _code : String) -> String {
    "HIGHLIGHTED"
  }

  let options = TuiOptions::with_highlighter(custom_highlighter)
  let output = md_to_tui_with_options("# Heading\n\nParagraph\n\n```js\ncode\n```\n", options)

  // Heading and paragraph should be normal
  inspect(output.contains("Heading"), content="true")
  inspect(output.contains("Paragraph"), content="true")
  // Code block should use custom highlighter
  inspect(output.contains("HIGHLIGHTED"), content="true")
}

test "plugin: filename in info string" {
  fn file_highlighter(info : CodeBlockInfo, code : String) -> String {
    if not(info.filename.is_empty()) {
      "// " + info.filename + "\n" + code
    } else {
      code
    }
  }

  let options = TuiOptions::with_highlighter(file_highlighter)
  let output = md_to_tui_with_options("```ts:utils.ts\nexport const x = 1;\n```\n", options)
  inspect(output.contains("// utils.ts"), content="true")
}

test "plugin: meta in info string" {
  fn meta_highlighter(info : CodeBlockInfo, code : String) -> String {
    let buf = StringBuilder::new()
    if not(info.meta.is_empty()) {
      buf.write_string("META: ")
      buf.write_string(info.meta)
      buf.write_string("\n")
    }
    buf.write_string(code)
    buf.to_string()
  }

  let options = TuiOptions::with_highlighter(meta_highlighter)
  let output = md_to_tui_with_options("```js {lines=[1,2]}\ncode\n```\n", options)
  inspect(output.contains("META: {lines=[1,2]}"), content="true")
}
