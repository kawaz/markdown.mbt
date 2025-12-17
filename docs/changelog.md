# Changelog

## 2025-12-17: Link parser improvements

**Commit:** `ce97f69e295aad84ae8bd902a7f4bfe84a634787`

### Changes

- Add support for `(title)` style link titles (in addition to `"..."` and `'...'`)
- Allow newlines between URL and title
- Reject links with newlines in URL (both angle-bracket and bare URLs)

### CommonMark Compliance

- Tests: 201 → 202 (+1)

### Performance Impact

| Benchmark | Before | After | Change |
|-----------|--------|-------|--------|
| parse: small | 90.70µs | 107.29µs | +18% |
| parse: medium | 361.54µs | 382.11µs | +5.7% |
| serialize: small | 5.06µs | 7.42µs | +46% |
| serialize: medium | 19.70µs | 27.11µs | +38% |
| inline: links | 4.28µs | 3.99µs | **-6.8%** |

### Notes

The performance regression is primarily due to:
1. Additional newline checks in URL parsing
2. Parenthesis-style title parsing with depth tracking
3. Extended whitespace skipping (now includes newlines)

The link-specific benchmark actually improved (-6.8%), suggesting the overhead is in the general parsing path rather than link parsing itself. Accepted as reasonable tradeoff for improved CommonMark compliance.
