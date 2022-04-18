import yaml

from data_preparation import Epc, Spenser
from enriching_population import EnrichingPopulation

if __name__ == "__main__":
    print("hi")
    spenser = Spenser()
    epc = Epc()
    psm = EnrichingPopulation()

    list_df = []
    list_df_names = []
    lad_codes_yaml = open("config/lad_codes.yaml")
    parsed_lad_codes = yaml.load(lad_codes_yaml, Loader=yaml.FullLoader)
    lad_codes = parsed_lad_codes.get("lad_codes")

    for lad_code in lad_codes:
        spenser_df = spenser.step(lad_code)
        epc_df = epc.step(lad_code)
        rich_df = psm.step(
            spenser_df, epc_df, lad_code, psm_fig=True, validation_fig=True
        )
        list_df_names.append("_".join([lad_code, "hh_msm_epc.csv"]))
        list_df.append(rich_df)

    psm.save_enriched_pop(list_df_names, list_df)

