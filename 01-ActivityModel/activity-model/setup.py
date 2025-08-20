import setuptools

with open("README.md", "r") as fh:
    long_description = fh.read()

setuptools.setup(
    name="activity-model",
    version="0.1.0",
    author="Patricia Ternes",
    author_email="p.ternesdallagnollo@leeds.ac.uk",
    description="The Activity Model package",
    long_description=long_description,
    long_description_content_type="text/markdown",
    # url="#",
    # install_requires=[
    #     "numpy=1.21.2",
    #     "pandas=1.4.1",
    #     "requests=2.27.1",
    #     "causalinference==0.1.3",
    #     "scikit-learn=1.0.2",
    #     "seaborn=0.11.2",
    #     "matplotlib=3.5.1",
    #     "pyyaml=6.0",
    # ]
    packages=setuptools.find_packages(),
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Programming Language :: Python :: 3.9",
        "Intended Audience :: Science/Research",
    ],
    python_requires=">=3.9",
)
