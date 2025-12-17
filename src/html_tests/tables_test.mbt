///| Table HTML tests

test "html: table left align" {
  assert_html_compat("| a |\n|:--|\n| 1 |\n", "table left align")
}

test "html: table right align" {
  assert_html_compat("| a |\n|--:|\n| 1 |\n", "table right align")
}

test "html: table center align" {
  assert_html_compat("| a |\n|:-:|\n| 1 |\n", "table center align")
}

test "html: table multiple rows" {
  assert_html_compat("| a | b |\n|---|---|\n| 1 | 2 |\n| 3 | 4 |\n", "table multiple rows")
}

test "html: table with emphasis" {
  assert_html_compat("| **bold** | *italic* |\n|----------|----------|\n| text | text |\n", "table with emphasis")
}

test "html: table empty cells" {
  assert_html_compat("| a | b |\n|---|---|\n| | |\n", "table empty cells")
}
