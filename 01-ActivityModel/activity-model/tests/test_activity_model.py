from activity_model import __version__
from activity_model.data_preparation import Epc

import requests
import pytest


def test_version():
    assert __version__ == "0.1.0"


@pytest.fixture
def epc():
    epc = Epc()
    return epc


def test_lookup_type(epc):
    assert type(epc.accommodation_lookup) is dict
    assert type(epc.age_categorical_lookup) is dict
    assert type(epc.gas_lookup) is dict
    assert type(epc.tenure_lookup) is dict
    assert type(epc.age_numerical_lookup) is list
    assert type(epc.floor_area_lookup) is list
    assert type(epc.area_lookup) is dict


def test_epc_connection(epc):
    url = epc.epc_url
    user = epc.epc_user
    key = epc.epc_key
    headers = {"Accept": "text/csv"}

    r = requests.head(url, headers=headers, auth=(user, key))
    assert (
        r.status_code == 200
    ), "Please check your EPC credentials here: config/epc_api.yaml"


# test area lookup connection?
# test spenser connection?

# test if area column has the right values
# test if floor area has the right values
# test if age has the right values
# test if gas has the right values
# test if tenure has the right values
# test if accommodation type has the right values
