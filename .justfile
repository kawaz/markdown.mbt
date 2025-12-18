bench:
  moon bench

bench-accept:
  moon bench > .bench-baseline

test:
  node scripts/gen-tests.js
  node scripts/gen-gfm-tests.js
  moon test --target js -p mizchi/compat_tests
