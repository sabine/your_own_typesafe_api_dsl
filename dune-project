(lang dune 3.7)

(name your_own_typesafe_api_dsl)

(generate_opam_files true)

(source
 (github sabine/your_own_typesafe_api_dsl))

(authors "Sabine Schmaltz")
(maintainers "Sabine Schmaltz")

(bug_reports https://github.com/sabine/your_own_typesafe_api_dsl/issues)
(homepage https://github.com/sabine/your_own_typesafe_api_dsl)
(documentation https://github.com/sabine/your_own_typesafe_api_dsl)

(package
 (name your_own_typesafe_api_dsl)
 (synopsis "This repo illustrates how you can create your own type-safe API DSL")
 (description "")
 (depends
  ocaml
  dune
  (dream (>= "1.0.0~alpha5"))
  (yojson (>= "2.0.2"))
  (ppx_yojson_conv (>= "v0.15.1"))
  (lwt_ppx (>= "2.1.0"))
  (alcotest :with-test)
  (curly :with-test)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
