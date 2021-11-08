#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from glob import glob
import pandas as pd
import zipfile

def get_england_epc_file_names(epc_zip_file):
    '''
     domestic-EXXXXXXXX-local-authority-name/certificates.csv
    '''
    # get the path of all certificate files
    epc_files = [text_file.filename for text_file in epc_zip_file.infolist() if text_file.filename.endswith('certificates.csv')]
    # return just the England local authorities
    return [folder for folder in epc_files if folder.split('-')[1][0] is 'E']

def get_epc_dfs(epc_zip_file, file):
    return pd.read_csv(epc_zip_file.open(file), usecols=get_epc_desired_headers(), low_memory=False)

def get_epc_desired_headers():
    return [
        'POSTCODE',
        'LOCAL_AUTHORITY',
        'PROPERTY_TYPE',
        'BUILT_FORM',        
        'CONSTRUCTION_AGE_BAND',
        'TENURE',    
        'TOTAL_FLOOR_AREA',  # m²
        'NUMBER_HABITABLE_ROOMS',
        'ENERGY_CONSUMPTION_CURRENT',
        'CURRENT_ENERGY_RATING'
        ]

def get_msoa_rename_dict(msoa_zip_file, local_authority):

    desired_headers = ["pcds", "msoa11cd", "ladcd"]
    pc_msoa = pd.read_csv(msoa_zip_file, usecols=desired_headers, low_memory=False)
    grouped = pc_msoa.groupby(pc_msoa.ladcd)
    pc_msoa = grouped.get_group(local_authority)
    pc_msoa.pop('ladcd')

    return pc_msoa.set_index('pcds').to_dict()['msoa11cd']

def set_msoa(epc_df, msoa_zip_file, local_authority, rename=False):
    '''
    Convert the 'POSTCODE' column into a MSOA column.
    - If a postcode has no MSOA math, remove the row.
    - If a new column name is given, rename the column.
    '''
    epc_df.loc[:, 'POSTCODE'].replace(get_msoa_rename_dict(msoa_zip_file, local_authority), inplace=True)
    cond = epc_df.POSTCODE.str.len() < 9
    rows = epc_df.loc[cond, :]
    epc_df.drop(rows.index, inplace=True)
    if rename:  # rename the POSTCODE column
        epc_df.rename({'POSTCODE': rename}, axis=1, inplace=True)
    print(epc_df.shape)
    return epc_df

def set_categorical_code(df, column, rename_dict, empty=-1):
    '''
     Function to transform a categorical column using 
     a rename dictionary.
     
     inputs:
     - df: pandas dataframe
     - column: name of the desired column (string)
     - rename_dict_df: pandas index
     - empty: value to be used in empty items
    '''    
    # setting new values according the rename_dict
    df[column] = df[column].replace(rename_dict)
    
    # fill empty columns
    df[column].fillna(empty, inplace=True)
    
    return df

def set_numerical_code(df, column, band_dict, empty=-1):
    '''
     Function to transform a numerical column using 
     a transformation list (band_dict), following 
     the rule:
     - if (j < value <= k), then, (value = i)
     
     inputs:
     - df: pandas dataframe
     - column: name of the desired column (string)
     - empty: value to be used in empty items
     - band_dict = [[i, j, k], [i, j, k], ...] (list)
       where:
       * i: desired code
       * j: minimum value of the band (not included)
       * k: maximum value of the band (included)
    '''        
    for band in band_dict:
        df.loc[(df[column] > band[1]) & (df[column] <= band[2]), column] = band[0]
    df[column].fillna(empty, inplace=True)
    return df

def get_tenure_rename_dict():
    all_tenures = [
            # 1?
            'Owner-occupied', 
            'owner-occupied', 
            # 5
            'rental (social)', 
            'Rented (social)', 
            # 6
            'rental (private)', 
            'Rented (private)', 
            # -9
            'Not defined - use in the case of a new dwelling for which the intended tenure in not known. It is no', 
            'unknown', 
            'NO DATA!'
            ]

    tenures_codes = [
            1, 1,
            5, 5,
            6, 6,
            -9, -9, -9
            ]

    tenure_df = pd.DataFrame({'all_tenures':all_tenures, 'tenures_codes':tenures_codes})
    return tenure_df.set_index('all_tenures').to_dict()['tenures_codes']

def get_accommodation_rename_dict():
    all_accommodations = [
            # 2
            'House: Detached',
            'Bungalow: Detached',
            # 3
            'House: Semi-Detached',
            'Bungalow: Semi-Detached',
            # 4
            'House: Mid-Terrace',
            'House: End-Terrace',
            'House: Enclosed Mid-Terrace',
            'House: Enclosed End-Terrace',
            'Bungalow: Mid-Terrace',
            'Bungalow: End-Terrace',
            'Bungalow: Enclosed Mid-Terrace',
            'Bungalow: Enclosed End-Terrace',
            # 5
            'Flat: NO DATA!',
            'Flat: Detached',
            'Flat: Semi-Detached',
            'Flat: Mid-Terrace',
            'Flat: End-Terrace',
            'Flat: Enclosed Mid-Terrace',
            'Flat: Enclosed End-Terrace',
            'Maisonette: NO DATA!',
            'Maisonette: Detached',
            'Maisonette: Semi-Detached',
            'Maisonette: Mid-Terrace',
            'Maisonette: End-Terrace',
            'Maisonette: Enclosed Mid-Terrace',
            'Maisonette: Enclosed End-Terrace',
            'Park home: Detached',
            'Park home: Semi-Detached',
            # -9?
            'House: NO DATA!',
            'Bungalow: NO DATA!',
            ]

    accommodations_codes = [
            2,2,
            3,3,
            4,4,4,4,4,4,4,4,
            5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
            -9,-9,
            ]

    accommodation_df = pd.DataFrame({'all_accommodations':all_accommodations, 'accommodations_codes':accommodations_codes})
    return accommodation_df.set_index('all_accommodations').to_dict()['accommodations_codes']

def get_number_rooms_band_dict():
    '''
        Define a list as follows:
        - number_rooms_band_dict =[[i, j, k], [i, j, k], ...]
        
        where:
        - i: desired code
        - j: lower band (not included)
        - k: upper band (included)
    '''
    return [[1, 0, 1],
            [2, 1, 2],
            [3, 2, 3],
            [4, 3, 4],
            [5, 4, 5],
            [6, 5, 10000]]

def get_floor_area_band_dict():
    '''
        Define a list as follows:
        - number_rooms_band_dict =[[i, j, k], [i, j, k], ...]
        
        where:
        - i: desired code
        - j: lower band (not included)
        - k: upper band (included)
    '''
    return [[1, 0, 40],
            [2, 40, 50],
            [3, 50, 60],
            [4, 60, 70],
            [5, 70, 80],
            [6, 80, 90],
            [7, 90, 100],
            [8, 100, 110],
            [9, 110, 120],
            [10, 120, 100000]]

def get_accommodation_age_rename_dict():
    all_accommodations_ages = [
            "England and Wales: before 1900", "England and Wales: 1900-1929",
            "England and Wales: 1930-1949",
            "England and Wales: 1950-1966",
            "England and Wales: 1967-1975",
            "England and Wales: 1976-1982",
            "England and Wales: 1983-1990",
            "England and Wales: 1991-1995",
            "England and Wales: 1996-2002",
            "England and Wales: 2003-2006",
            "England and Wales: 2007-2011", "England and Wales: 2007 onwards", "England and Wales: 2012 onwards",
            "INVALID!", "Not applicable", "NO DATA!"
            ]

    accommodations_age_codes = [1, 1, 1930, 1950, 1967, 1976, 1983, 1991, 1996, 2003, 2007, 2007, 2007, -9, -9, -9]
    # note that first we are going to assign a numerical age 
    # inside the band, and then, the band code will be assigned.

    accommodation_df = pd.DataFrame({'all_accommodations':all_accommodations_ages, 'accommodations_codes':accommodations_age_codes})
    return accommodation_df.set_index('all_accommodations').to_dict()['accommodations_codes']

def get_accommodation_age_band_dict():
    return [[1, 0, 1929],
            [2, 1929, 1949],
            [3, 1949, 1966],
            [4, 1966, 1975],
            [5, 1975, 1982],
            [6, 1982, 1990],
            [7, 1990, 1995],
            [8, 1995, 2002],
            [9, 2002, 2006],
            [10, 2006, 3000]]

def set_transform_columns(file, epc_zip_file, msoa_zip_file, empty):
        epc_df = get_epc_dfs(epc_zip_file, file)
        local_authority = epc_df.LOCAL_AUTHORITY[0]
        epc_df.pop('LOCAL_AUTHORITY')

        epc_df = set_msoa(epc_df, msoa_zip_file, local_authority, 'Area')

        # Accomodation type
        epc_df['LC4402_C_TYPACCOM'] = epc_df['PROPERTY_TYPE'] + ': ' + epc_df['BUILT_FORM']
        epc_df = set_categorical_code(epc_df, 'LC4402_C_TYPACCOM', get_accommodation_rename_dict(), empty)
        epc_df.pop('PROPERTY_TYPE')
        epc_df.pop('BUILT_FORM')
        
        # Tenure
        epc_df = set_categorical_code(epc_df, 'TENURE', get_tenure_rename_dict(), empty)
        epc_df.rename({'TENURE': 'LC4402_C_TENHUK11'}, axis=1, inplace=True) # renaming the tenure colum
        
        # Number of rooms
        epc_df = set_numerical_code(epc_df, 'NUMBER_HABITABLE_ROOMS', get_number_rooms_band_dict(), empty)
        epc_df.rename({'NUMBER_HABITABLE_ROOMS': 'LC4404_C_ROOMS'}, axis=1, inplace=True) # renaming

        # Floor Area
        epc_df = set_numerical_code(epc_df, 'TOTAL_FLOOR_AREA', get_floor_area_band_dict(), empty)
        epc_df.rename({'TOTAL_FLOOR_AREA': 'FLOOR_AREA'}, axis=1, inplace=True) # renaming

        # CONSTRUCTION_AGE_BAND
        epc_df = set_categorical_code(epc_df, 'CONSTRUCTION_AGE_BAND', get_accommodation_age_rename_dict(), empty)
        epc_df['CONSTRUCTION_AGE_BAND'] = epc_df['CONSTRUCTION_AGE_BAND'].apply(pd.to_numeric)
        epc_df = set_numerical_code(epc_df, 'CONSTRUCTION_AGE_BAND', get_accommodation_age_band_dict(), empty)
        epc_df.rename({'CONSTRUCTION_AGE_BAND': 'ACCOM_AGE'}, axis=1, inplace=True) # renaming
        return epc_df, "".join(['data/eps_england/', local_authority,'.csv'])

def main():
    epc_zip_file = zipfile.ZipFile('data/all-domestic-certificates.zip')
    msoa_zip_file = "data/PCD_OA_LSOA_MSOA_LAD_NOV20_UK_LU.zip"
    epc_files = get_england_epc_file_names(epc_zip_file)
    #epc_files = ['domestic-E07000044-South-Hams/certificates.csv', 'domestic-E09000014-Haringey/certificates.csv', 'hi']
    epc_files = epc_files[0:2]

    empty = -1
    list_df = []
    list_df_names = []
    error_list = []
    from time import time
    t0 = time()
    for file in epc_files:
        try:
            df, name = set_transform_columns(file, epc_zip_file, msoa_zip_file, empty)
            #list_df.append(df)
            #list_df_names.append(name)
                # Saving
            df.to_csv (name, index = False, header=True)
            print(file)
        except:
            error_list.append(file)

        '''
        try:
            epc_df = get_epc_dfs(epc_zip_file, file)
            local_authority = epc_df.LOCAL_AUTHORITY[0]
            epc_df.pop('LOCAL_AUTHORITY')

            epc_df = set_msoa(epc_df, msoa_zip_file, local_authority, 'Area')

            # Accomodation type
            epc_df['LC4402_C_TYPACCOM'] = epc_df['PROPERTY_TYPE'] + ': ' + epc_df['BUILT_FORM']
            epc_df = set_categorical_code(epc_df, 'LC4402_C_TYPACCOM', get_accommodation_rename_dict(), empty)
            epc_df.pop('PROPERTY_TYPE')
            epc_df.pop('BUILT_FORM')
            
            # Tenure
            epc_df = set_categorical_code(epc_df, 'TENURE', get_tenure_rename_dict(), empty)
            epc_df.rename({'TENURE': 'LC4402_C_TENHUK11'}, axis=1, inplace=True) # renaming the tenure colum
            
            # Number of rooms
            epc_df = set_numerical_code(epc_df, 'NUMBER_HABITABLE_ROOMS', get_number_rooms_band_dict(), empty)
            epc_df.rename({'NUMBER_HABITABLE_ROOMS': 'LC4404_C_ROOMS'}, axis=1, inplace=True) # renaming

            # Floor Area
            epc_df = set_numerical_code(epc_df, 'TOTAL_FLOOR_AREA', get_floor_area_band_dict(), empty)
            epc_df.rename({'TOTAL_FLOOR_AREA': 'FLOOR_AREA'}, axis=1, inplace=True) # renaming

            # CONSTRUCTION_AGE_BAND
            epc_df = set_categorical_code(epc_df, 'CONSTRUCTION_AGE_BAND', get_accommodation_age_rename_dict(), empty)
            epc_df['CONSTRUCTION_AGE_BAND'] = epc_df['CONSTRUCTION_AGE_BAND'].apply(pd.to_numeric)
            epc_df = set_numerical_code(epc_df, 'CONSTRUCTION_AGE_BAND', get_accommodation_age_band_dict(), empty)
            epc_df.rename({'CONSTRUCTION_AGE_BAND': 'ACCOM_AGE'}, axis=1, inplace=True) # renaming

            list_df.append(epc_df)
            list_df_names.append("".join([local_authority,'.csv']))
            print(file)
        except:
            print('--------------', file)
        '''

    with zipfile.ZipFile('data/eps_england.zip', 'w') as csv_zip:
        for i in range(len(list_df_names)):
            csv_zip.writestr(list_df_names[i], list_df[i].to_csv(index = False, header=True))
    print(error_list)
    print(time() - t0)
if __name__ == '__main__':
    main()