///|
test "scope parser accepts global alias" {
  assert_eq(Scope::parse("GLOBAL"), Some(System))
}
