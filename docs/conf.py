# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'vantage6-algorithms'
copyright = '2022, F.C. Martin, A. van Gestel, ...'
author = 'F.C. Martin, A. van Gestel, ...'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = ['sphinxcontrib.pseudocode', 'sphinx.ext.autosummary']

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']



# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'furo'
html_static_path = ['_static']


html_theme_options = {
    # 'logo': "logo.jpg",
    # 'logo_name': False,
    # 'github_user': 'vantage6',
    # 'github_repo': 'vantage6',
    # 'fixed_sidebar': True,
}

# The master toctree document.
master_doc = 'index'

add_module_names = False

pygments_style = None

numfig = True
math_numfig = False
math_number_all = True
math_eqref_format = '({number})'

imgmath_image_format = 'svg'

# mathjax_path = 'mathjax.js'