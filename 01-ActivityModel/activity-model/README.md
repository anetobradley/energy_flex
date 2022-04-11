# Activity Model

This is the code repository for the Activity Model package.

The Activity Model returns a synthetic population to represent the England
household population. This model, however, does not create the population from
scratch, it uses a well-known synthetic population, the SPENSER, and adds the
following information for each household:

- Accommodation floor area (band)
- Accommodation age (band)
- Gas (flag: Y/N)

The accommodation information is originally obtained from Domestic Energy
Performance Certificates (EPC) and then, codified in this package.

To enrich the SPENSER population with the EPC data, the Propensity Score
Matching (PSM) method is applied.

The main output is an enriched synthetic population that we use as input for
energy estimation models developed by the Energy Flexibility Project.

## Environment setup

This package currently supports running on Linux.  <!-- and macOS. -->

To start working with this repository you need to clone it onto your local
machine:

```bash
$ git clone https://github.com/anetobradley/energy_flex.git
$ cd energy_flex/01-ActivityModel
```

This package requires a specific
[conda](https://docs.anaconda.com/anaconda/install/) environment.
You can create an environment for this project using the provided
environment file:

```bash
$ conda env create -f environment.yml
$ conda activate energyflex
```

## Configuring the model

### Required

#### EPC Credentials

To retrieve data to run the model you will need to have EPC-API credentials.
You can register [here](https://epc.opendatacommunities.org/#register).
Next you need to add your credentials into the
[epc_api](./config/epc_api.yaml) file (you can use your favourite text
editor for this):

```bash
$ nano config/user.yaml
#  EPC credentials
epc_user: "user@email"
epc_key: "user_key"
```

#### Local Authority codes

You need provide the code for all Local Authorities that you want a synthetic
population. Please, insert the values [here](./config/lad_codes.yaml).
If you not provide any additional value, the default is return the population
just for Haringey.

You can find
[here](https://epc.opendatacommunities.org/docs/api/domestic#domestic-local-authority)
all LAD codes available in the EPC data.

### Optional

#### Year

You can define [here](./config/epc_api.yaml) a different range of the EPC
lodgement date (the default is 2008-2022).

#### EPC variables

If you want to enrich the synthetic population with more EPC variables you
need to add them in two lists:

- [epc_api config file](./config/epc_api.yaml) under `epc_headers`.
- [psm config file](./config/psm.yaml) under `matches_columns`.

You can find a complete EPC Glossary
[here](https://epc.opendatacommunities.org/docs/guidance#glossary),
but be aware that there is a difference between the spellings of the terms
described in this list and how they are used in the API. In our experience the
differences are:

- capital letters must be written in lowercase letters.
- underscore must be replaced by a hyphen.

We also warn that most of the information is unencoded, which can make it
difficult to use (as well as making the output file unnecessarily large).
The default variables (accommodation floor area, accommodation age, gas)
are properly encoded and organized by this package.

#### Data url

Three dataset are obtained through urls:

- EPC data
- SPENSER data
- Area lookup data

If you want to use different urls, you can change then in:

- EPC url [here](./config/epc_api.yaml) under `epc_url`
- SPENSER url [here](./config/spenser.yaml) under `spenser_url`
- Area lookup url [here](./config/lookups.yaml) under `area_url`

Note: You ca obtain data from other places, after all new
versions are expected, but it is necessary to ensure that the data structure
is similar or the code will not work.

#### Area granularity

The default granularity is Output Areas, but you can use others, like:

- Lower Layer Super Output Areas (`lsoa11cd`)
- Middle Layer Super Output Areas (`msoa11cd`)
- Local authority districts (`ladcd`)

To change this, please use the `area_in_out` variable
[here](./config/lookups.yaml).

Note that if you change the Area lookup url, the granularities code may also
change!

## Installation & Usage

Next we install the Activity Model package into the environment using `setup.py`:

```bash
# for using the code base use
$ python setup.py install
```

## Running the model

If you installed the package with the `setup.py` file, to run the model:

```bash
$ python activity_model
```

If you did not install the package with the `setup.py` file, you can run the
code through

```bash
# for using the code base use
$ python activity_model/__main__.py
```

## Outputs

The outputs are stored at `data/output/`. Three outputs are expected:

1. Propensity score distribution images for each local authority.
2. Internal validation images for each local authority.
3. Enriched synthetic population for each local authority (CSV file).
   All CSV files are compressed into a zip file.
