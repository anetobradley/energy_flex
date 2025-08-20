#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import numpy as np
import yaml
import pandas as pd
import requests
import io
import zipfile


class Epc:
    """Class to represent the SPENSER data and related parameters/methods."""

    def __init__(self) -> None:
        """Initialise an EPC class."""
        # Configure epc api related parameters from "config/epc_api.yaml"
        epc_api_yaml = open("config/epc_api.yaml")
        parsed_epc_api = yaml.load(epc_api_yaml, Loader=yaml.FullLoader)
        self.epc_user = parsed_epc_api.get("epc_user")
        self.epc_key = parsed_epc_api.get("epc_key")
        self.epc_url = parsed_epc_api.get("epc_url")
        self.epc_years = parsed_epc_api.get("epc_years")
        self.desired_headers = parsed_epc_api.get("epc_headers")

        # Using epc api info to build all base url-filter
        self.epc_filter = self.get_epc_url_filter()

        # Configure lookups
        ## Lookups from "config/lookups.yaml" file
        lookup_yaml = open("config/lookups.yaml")
        parsed_lookup = yaml.load(lookup_yaml, Loader=yaml.FullLoader)
        self.accommodation_lookup = parsed_lookup.get("accommodation")
        self.age_categorical_lookup = parsed_lookup.get("age_categorical")
        self.age_numerical_lookup = parsed_lookup.get("age_numerical")
        self.floor_area_lookup = parsed_lookup.get("floor_area")
        self.gas_lookup = parsed_lookup.get("gas")
        self.tenure_lookup = parsed_lookup.get("tenure")
        url = parsed_lookup.get("area_url")
        area_in_out = parsed_lookup.get("area_in_out")
        area_lookup = pd.read_csv(
            url,
            compression="zip",
            # usecols=[area_in, area_out],
            usecols=[area_in_out[0], area_in_out[1]],
            encoding="unicode_escape",
            engine="python",
        )
        self.area_lookup = (
            area_lookup.set_index(area_in_out[0], drop=True)
            .loc[:, area_in_out[1]]
            .to_dict()
        )

    def get_epc_url_filter(self):
        """Build a list of EPC search filters urls.

        According to EPC-API
        [documentation](https://epc.opendatacommunities.org/docs/api/domestic)
        the API is designed to return up to 10,000 records at a time, with a
        maximum page size of 5,000. If more than 10,000 records are required,
        is necessary to vary the search filters and make multiple requests.

        This method returns a list of filter urls to get the maximum possible
        volume of data. Each filter url covers 4 months.

        :return: EPC-API urls with filters.
        :rtype: list
        """

        url_filter = []
        for i in range(self.epc_years[0], self.epc_years[1], 1):
            for j in range(3):
                for k in range(2):
                    search = f"size=5000&from-year={i}&from-month={(j*4)+1}&to-year={i}&to-month={(j+1)*4}&from={k*5000}&local-authority="
                    url_filter.append(self.epc_url + search)
        return url_filter

    def get_epc_dataframe(self, lad_code) -> pd.DataFrame:
        """Get EPC data for a given local authority.

        This function uses the EPC-API to get a large amount of data.
        Due to data limitation per request, several filters are considered.

        Note 1: You need insert a valid EPC user/key (config/epc_api.yaml)

        Note 2: Some data interval return Null value (usually in early 2008) and
        an exception is used to avoid errors in this case.

        :param lad_code: Local authority code.
        :type lad_code: string
        :return: A data frame with all EPC collected data.
        :rtype: pandas.DataFrame
        """
        url_filter = [s + lad_code for s in self.epc_filter]
        headers = {"Accept": "text/csv"}
        list_df = []
        for url in url_filter:
            try:
                res = requests.get(
                    url, headers=headers, auth=(self.epc_user, self.epc_key)
                ).content
                df = pd.read_csv(
                    io.StringIO(res.decode("utf-8")), usecols=self.desired_headers
                )
                list_df.append(df)
            except pd.errors.EmptyDataError:
                """
                Some data interval return Null value (usually in early 2008).
                This Exception is raised to avoid errors in this situation.
                Warning: Problems in EPC-API may be difficult to follow.
                """
                pass
        return pd.concat(list_df)

    @staticmethod
    def remove_duplicates(df):
        """Remove EPC Duplicate Certificates

        When using the EPC datasets we need to be careful with duplicate EPCs
        for the same property. While not an enormous issue as an EPC is valid
        for up to 10 years unless the property is renovated or retrofitted,
        there may be multiple records especially for rental properties which are
        improved to meet recent regulations.

        This function removing duplicates with the same BUILDING REFERENCE 
        NUMBER by selecting the most recent record and discarding others.
        
        :param df: Raw EPC dataset.
        :type df: pandas.DataFrame
        :return: EPC dataset without duplicate Certificates.
        :rtype: pandas.DataFrame
        """
        df["lodgement-datetime"] = pd.to_datetime(df["lodgement-datetime"])
        df = df.sort_values(by=["building-reference-number", "lodgement-datetime"])
        df.drop_duplicates(
            subset=["building-reference-number"], keep="last", inplace=True
        )
        df.sort_index(inplace=True)
        df.reset_index(drop=True, inplace=True)
        drop_list = ["building-reference-number", "lodgement-datetime"]
        df.drop(drop_list, axis=1, inplace=True)
        return df

    @staticmethod
    def set_categorical_code(df, df_col, lookup, rename=False):
        """ Apply the lookup to a categorical column.
        
        Transform the values in a dataframe column using a lookup dictionary.
        This method is valid when the column values are categorical.

        :param df:  The input dataframe.
        :type df: pandas.dataframe
        :param df_col: The column in df that represents the categorical values.
        :type df_col: string
        :param lookup: A dictionary from categorical values to categorical codes.
        :type lookup: dict
        :param rename: The new column name after transformation (if false, keep 
            the current name), defaults to False.
        :type rename: bool, optional
        :return: Returns the data with the updated column.
        :rtype: pandas.DataFrame
        """

        # This looks redundant, but ensures that the function works even for
        # missing values (returning empty code).
        def augment(x, lookup):
            try:
                return lookup[x]
            except:
                return

        # setting new values according the rename_dict
        df[df_col] = df[df_col].apply(func=lambda x: augment(x, lookup))

        # remove empty rows
        df.dropna(subset=[df_col], inplace=True)

        # rename column
        if rename:
            df.rename({df_col: rename}, axis=1, inplace=True)

    @staticmethod
    def set_numerical_code(df, df_col, lookup, rename=False):
        """Apply the lookup to a numerical column

        Transform the values in a dataframe column using a lookup dictionary.
        This method is valid when the column values are numerical, following 
        the rule:
        
        if (j < value <= k), then, (value = i).

        :param df: The input dataframe.
        :type df: pandas.dataframe
        :param df_col: The column in df that represents the numerical values.
        :type df_col: string
        :param lookup: A dictionary from numerical values to numerical codes;
            The dictionary structure is [[i1, j1, k1], [i2, j2, k2], ..., 
            [iN, jN, kN]], where: iN is the desired code for band N, jN is the
            minimum value of the band N (not included), kN is the maximum value
            of the band N (included), and N is the number of bands.
        :type lookup: dict
        :param rename: The new column name after transformation (if false, keep
            the current name), defaults to False.
        :type rename: bool, optional
        """
        for band in lookup:
            df.loc[(df[df_col] > band[1]) & (df[df_col] <= band[2]), df_col] = band[0]

        # remove out bound and empty rows
        df.dropna(subset=[df_col], inplace=True)

        if rename:
            df.rename({df_col: rename}, axis=1, inplace=True)

    def set_lookups(self, df):
        """Update all columns using the lookups dictionaries.

        Update the information related with area, tenure, accommodation type,
        construction age band, main gas flag, and floor area, by using the self
        lookup variables (accommodation_lookup, age_categorical_lookup,
        age_numerical_lookup, floor_area_lookup, gas_lookup, tenure_lookup,
        area_lookup) and the set_categorical_code and set_numerical_code
        functions.

        :param df: Dataframe with EPC information.
        :type df: pandas.Dataframe
        """
        # Area: change area from postcode to output area
        self.set_categorical_code(df, "postcode", self.area_lookup, rename="Area")

        # Tenure: change the tenure from EPC to SPENSER classification
        self.set_categorical_code(df, "tenure", self.tenure_lookup)

        # Accommodation type:
        # - create an EPC accommodation type by combining "property-type" and "built-form"
        # - change the accommodation type from EPC to SPENSER classification
        # - discard "property-type" and "built-form" columns
        df["LC4402_C_TYPACCOM"] = df["property-type"] + ": " + df["built-form"]
        self.set_categorical_code(df, "LC4402_C_TYPACCOM", self.accommodation_lookup)
        df.pop("property-type")
        df.pop("built-form")

        # Construction age band:
        # - initially is a combination of categorical and numeric values
        # - convert all categorical values into absolute ages
        # - groups the absolute build age into bands
        self.set_categorical_code(
            df,
            "construction-age-band",
            self.age_categorical_lookup,
            rename="ACCOM_AGE",
        )
        df["ACCOM_AGE"] = df["ACCOM_AGE"].apply(pd.to_numeric)
        self.set_numerical_code(df, "ACCOM_AGE", self.age_numerical_lookup)

        # Main gas flag: change the values (N, Y) to (0, 1)
        self.set_categorical_code(df, "mains-gas-flag", self.gas_lookup, rename="GAS")

        # Floor Area: groups the absolute area into bands
        area_max_lim = self.floor_area_lookup[-1][2]
        df.rename({"total-floor-area": "FLOOR_AREA"}, axis=1, inplace=True)
        df.drop(df[df.FLOOR_AREA > area_max_lim].index, inplace=True)
        self.set_numerical_code(df, "FLOOR_AREA", self.floor_area_lookup)

    def step(self, lad_code):
        """EPC data preparation main step.

        For each given local authority, this functions get the raw EPC data
        using an API approach and then return a processed EPC dataset.

        :param lad_code: Local authority code.
        :type lad_code: string
        :return: processed EPC data
        :rtype: pandas.DataFrame
        """
        # Create EPC dataframe for local authority lad_code
        df = self.get_epc_dataframe(lad_code)

        df = self.remove_duplicates(df)

        # Apply all lookups
        self.set_lookups(df)

        # Change selected columns to integer values
        cols = ["FLOOR_AREA", "ACCOM_AGE", "GAS", "tenure", "LC4402_C_TYPACCOM"]
        df[cols] = df[cols].applymap(np.int64)
        return df


class Spenser:
    """Class to represent the SPENSER data and related parameters/methods."""

    def __init__(self) -> None:
        """Initialise a Spenser class."""
        # Configure SPENSER related parameters from "config/spenser.yaml"
        spenser_yaml = open("config/spenser.yaml")
        parsed_spenser = yaml.load(spenser_yaml, Loader=yaml.FullLoader)
        spenser_url = parsed_spenser.get("spenser_url")
        r = requests.get(spenser_url)
        self.spenser_zip_file = zipfile.ZipFile(io.BytesIO(r.content))

    def set_new_tenure(self, df) -> pd.DataFrame:
        """Create new temporary tenure column

        This method creates a new tenure column (following EPC values) where
        the sub-categories 
        - "Owned outright"(=2)
        - shared ownership" (=3)
        are merged into a general "Owner-occupied" (=1) category.

        :param df: original SPENSER data frame
        :type df: pandas.Dataframe
        :return: SPENSER data frame with a new column
        :rtype: pandas.DataFrame
        """
        df["tenure"] = df["LC4402_C_TENHUK11"].copy()
        df.loc[(df["tenure"] == 2), "tenure"] = 1
        df.loc[(df["tenure"] == 3), "tenure"] = 1
        df["tenure"] = df["tenure"].map(np.int64)

        return df

    def step(self, lad_code):
        """SPENSER data preparation main step.

        For each given local authority, this functions get the raw EPC data
        from a zip file and then return a processed SPENSER dataset.

        :param lad_code: Local authority code.
        :type lad_code: string
        :return: processed SPENSER data
        :rtype: pandas.DataFrame
        """

        # From the zipfile - open the local authority file
        lad_file = "_".join(["msm_england/ass_hh", lad_code, "OA11_2020.csv"])
        df = pd.read_csv(self.spenser_zip_file.open(lad_file))

        # Remove "empty" rows: empty codes (here, negative values) are a problem
        # for PSM method.
        # TODO: store the "empty" rows in other variable to be possible append
        # then at the end.
        df.drop(df[df.LC4402_C_TENHUK11 < 0].index, inplace=True)
        df.drop(df[df.LC4402_C_TYPACCOM < 0].index, inplace=True)

        # create new tenure
        df = self.set_new_tenure(df)

        return df
