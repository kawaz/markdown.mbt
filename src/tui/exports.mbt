///|
/// TUI module exports

// Re-export main functions
pub fn render(doc : @markdown.Document) -> String {
  render_tui(doc)
}

///|
pub fn from_markdown(source : String) -> String {
  md_to_tui(source)
}

///|
/// Render document with options
pub fn render_with_options(
  doc : @markdown.Document,
  options : TuiOptions,
) -> String {
  render_tui_with_options(doc, options)
}

///|
/// Parse and render with options
pub fn from_markdown_with_options(
  source : String,
  options : TuiOptions,
) -> String {
  md_to_tui_with_options(source, options)
}
