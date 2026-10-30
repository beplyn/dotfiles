# subst { name = value; } text: replaces every @name@ in text with value.
{ lib }:

vars: text:
lib.replaceStrings
  (map (n: "@${n}@") (lib.attrNames vars))
  (map toString (lib.attrValues vars))
  text
