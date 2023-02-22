help:
	@echo "Available commands:"
	@echo "  make help         : show this help message"
	@echo "  make devdocs      : build the documentation and watch for changes"

devdocs:
	sphinx-autobuild docs docs/_build/html --watch .