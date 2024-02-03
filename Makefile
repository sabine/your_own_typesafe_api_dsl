.DEFAULT_GOAL := all

.PHONY: all
all:
	opam exec -- dune build --root .

.PHONY: deps
deps: create_switch ## Install development dependencies
	opam install -y ocamlformat=0.26.0 ocaml-lsp-server
	opam install -y --deps-only --with-test --with-doc .

.PHONY: create_switch
create_switch: ## Create switch and pinned opam repo
	opam switch create . 5.1.0 --no-install --repos pin=git+https://github.com/ocaml/opam-repository#8cc107f96e33a4601f7c39346eb19fbbe46486d3

.PHONY: switch
switch: deps ## Create an opam switch and install development dependencies

.PHONY: install
install: all ## Install the packages on the system
	opam exec -- dune install --root .

.PHONY: start
start: all ## Run the produced executable
	opam exec -- dune exec app/main.exe

.PHONY: test
test: ## Run the unit tests
	opam exec -- dune test -j 1 --force --watch

.PHONY: clean
clean: ## Clean build artifacts and other generated files
	opam exec -- dune clean --root .

.PHONY: doc
doc: ## Generate odoc documentation
	opam exec -- dune build --root . @doc

.PHONY: fmt
fmt: ## Format the codebase with ocamlformat
	opam exec -- dune build --root . --auto-promote @fmt

.PHONY: watch
watch: ## Watch for the filesystem and rebuild on every change
	opam exec -- dune build @run -w --force --no-buffer

.PHONY: utop
utop: ## Run a REPL and link with the project's libraries
	opam exec -- dune utop --root . . -- -implicit-bindings

.PHONY: codegen
codegen: ## Generate Client SDK and Backend Endpoints
	opam exec -- dune exec codegen/main.exe