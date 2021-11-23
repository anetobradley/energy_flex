# Variables description for `msm_england_epc` synthetic population

## Accommodation type

* Table: LC4402

```
"C_TYPACCOM": {
  "0": "All categories: Accommodation type",
  "1": "Whole house or bungalow: Total",
  "2": "Whole house or bungalow: Detached",
  "3": "Whole house or bungalow: Semi-detached",
  "4": "Whole house or bungalow: Terraced (including end-terrace)",
  "5": "Flat, maisonette or apartment, or mobile/temporary accommodation"
}
```

## Communal establishments

* Table: QS420EW

```
"CELL": {
      "0": "All categories: Communal establishment management and type",
      "1": "Medical and care establishment: Total",
      "2": "Medical and care establishment: NHS: Total",
      "3": "Medical and care establishment: NHS: General hospital",
      "4": "Medical and care establishment: NHS: Mental health hospital/unit (including secure units)",
      "5": "Medical and care establishment: NHS: Other hospital",
      "6": "Medical and care establishment: Local Authority: Total",
      "7": "Medical and care establishment: Local Authority: Children's home (including secure units)",
      "8": "Medical and care establishment: Local Authority: Care home with nursing",
      "9": "Medical and care establishment: Local Authority: Care home without nursing",
      "10": "Medical and care establishment: Local Authority: Other home",
      "11": "Medical and care establishment: Registered Social Landlord/Housing Association: Total",
      "12": "Medical and care establishment: Registered Social Landlord/Housing Association: Home or hostel",
      "13": "Medical and care establishment: Registered Social Landlord/Housing Association: Sheltered housing only",
      "14": "Medical and care establishment: Other: Total",
      "15": "Medical and care establishment: Other: Care home with nursing",
      "16": "Medical and care establishment: Other: Care home without nursing",
      "17": "Medical and care establishment: Other: Children's home (including secure units)",
      "18": "Medical and care establishment: Other: Mental health hospital/unit (including secure units)",
      "19": "Medical and care establishment: Other: Other hospital",
      "20": "Medical and care establishment: Other: Other establishment",
      "21": "Other establishment: Total",
      "22": "Other establishment: Defence",
      "23": "Other establishment: Prison service",
      "24": "Other establishment: Approved premises (probation/bail hostel)",
      "25": "Other establishment: Detention centres and other detention",
      "26": "Other establishment: Education",
      "27": "Other establishment: Hotel: guest house; B&B; youth hostel",
      "28": "Other establishment: Hostel or temporary shelter for the homeless",
      "29": "Other establishment: Holiday accommodation (for example holiday parks)",
      "30": "Other establishment: Other travel or temporary accommodation",
      "31": "Other establishment: Religious",
      "32": "Other establishment: Staff/worker accommodation only",
      "33": "Other establishment: Other",
      "34": "Establishment not stated"
    }
```

## Tenure

* Table: LC4402

```
"C_TENHUK11": {
    "0": "All categories: Tenure",
    "1": "Owned or shared ownership: Total",
    "2": "Owned: Owned outright",
    "3": "Owned: Owned with a mortgage or loan or shared ownership",
    "4": "Rented or living rent free: Total",
    "5": "Rented: Social rented",
    "6": "Rented: Private rented or living rent free"
}
```

## Household type (alternative)

Table: LC4408

```
"C_AHTHUK11": {
      "0": "All categories: Household type",
      "1": "married couple family",
      "2": "same-sex civil partnership couple family",
      "3": "cohabiting couple family",
      "4": "lone parent family"
}
```

## Household size

* Table: LC4404

```
"C_SIZHUK11": {
  "0": "All categories: Household size",
  "1": "1 person in household",
  "2": "2 people in household",
  "3": "3 people in household",
  "4": "4 or more people in household"
  }
```

## Number of rooms

* Table: LC4404

```
"C_ROOMS": {
  "0": "All categories: Number of rooms",
  "1": "1 room",
  "2": "2 rooms",
  "3": "3 rooms",
  "4": "4 rooms",
  "5": "5 rooms",
  "6": "6 or more rooms"
}
```
## Number of bedrooms

* Table: LC4405EW

```
"C_BEDROOMS": {
  "0": "All categories: Number of bedrooms",
  "1": "1 bedroom",
  "2": "2 bedrooms",
  "3": "3 bedrooms",
  "4": "4 or more bedrooms"
}
```

## Persons per bedroom

Table: LC4408EW

```
C_PPBROOMHEW11{

}
```

## Type of central heating in household

* Table: LC4402

```
"C_CENHEATHUK11": {
  "0": "All categories: Type of central heating in household",
  "1": "Does not have central heating",
  "2": "Does have central heating"
}
```

## NS-SeC - Household Reference Person

* Table: LC4605

```
"C_NSSEC": {
  "0": "All categories: NS-SeC",
  "1": "1. Higher managerial, administrative and professional occupations",
  "2": "2. Lower managerial, administrative and professional occupations",
  "3": "3. Intermediate occupations",
  "4": "4. Small employers and own account workers",
  "5": "5. Lower supervisory and technical occupations",
  "6": "6. Semi-routine occupations",
  "7": "7. Routine occupations",
  "8": "8. Never worked and long-term unemployed",
  "9": "L15 Full-time students",
  "10": "L17 Not classifiable for other reasons"
}
```


## Ethnic group of Household Reference Person (HRP)

* Table: LC4202

```
"C_ETHHUK11": {
  "0": "All categories: Ethnic group of HRP",
  "1": "White: Total",
  "2": "White: English/Welsh/Scottish/Northern Irish/British",
  "3": "White: Irish",
  "4": "White: Other White",
  "5": "Mixed/multiple ethnic group",
  "6": "Asian/Asian British",
  "7": "Black/African/Caribbean/Black British",
  "8": "Other ethnic group"
}
```

## Car or van availability

* Table: LC4202

```
"C_CARSNO": {
  "0": "All categories: Car or van availability",
  "1": "No cars or vans in household",
  "2": "1 car or van in household",
  "3": "2 or more cars or vans in household"
}
```

## Floor Area

Table: EPC

```
"FLOOR_AREA": {
    "0": "All categories: Total floor area",
    "1": "A <= 40 m²",
    "2": "40 < A <= 50",
    "3": "50 < A <= 60",
    "4": "60 < A <= 70",
    "5": "70 < A <= 80",
    "6": "80 < A <= 90",
    "7": "90 < A <= 100",
    "8": "100 < A <= 110",
    "9": "110 < A <= 120",
    "10": "120 < A <= 130",
    "11": "130 < A <= 140",
    "12": "140 < A <= 150",
    "13": "150 < A <= 200",
    "14": "200 < A <= 300",
    "15": "A > 300"
  }
```

## Accommodation age

Table: EPC

```
"ACCOM_AGE": {
      "0": "All categories: Construction age band",
      "1": "Pre 1930",
      "2": "1930-1949",
      "3": "1950-1966",
      "4": "1967-1975",
      "5": "1976-1982",
      "6": "1983-1990",
      "7": "1991-1995",
      "8": "1996-2002",
      "9": "2003-2006",
      "10": "Post-2007"
    }
```