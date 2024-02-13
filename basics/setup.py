from os import path
from codecs import open
from setuptools import setup, find_packages

# get current directory
here = path.abspath(path.dirname(__file__))

# get the long description from the README file
with open(path.join(here, "README.md"), encoding="utf-8") as f:
    long_description = f.read()

# setup the package
setup(
    name="v6-basics-py",
    version="1.0.0",
    description="vantage6 basics",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/IKNL/vantage6-algorithms",
    packages=find_packages(),
    python_requires=">=3.6",
    install_requires=[
        "pandas",
        "vantage6-algorithm-tools",
    ],
)
