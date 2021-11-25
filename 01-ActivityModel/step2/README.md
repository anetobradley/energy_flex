# Enriched Synthetic Population <!-- omit in toc -->

## Propensity Score Matching

In order to enrich the baseline synthetic population (SPENSER) the Propensity Score Matching (PSM) method was used. Through the PSM method each SPENSER individual was matched, based  on the similarity of their characteristics, to a individual in an external dataset, here the EPC data.

Energy Performance Certificate (EPC) dataset provides energy performance related data about domestic accommodations.

- EPC/SPENSER matched variables were:
  - Area
  - Tenure
  - Accommodation type
  - Number of rooms (not used)
- EPC/SPENSER non-matching variables:
  - Floor area
  - Accommodation age
  - Main heat description (not encoded)

where the matched variables are used to define a Propensity Score (PS) for each individual, and the non-matching variables are used to enrich the baseline SPENSER.

### General approach

1. Merge the baseline and the external datasets.
2. Assign a treatment indicator (0 or 1) for each individual:
   - Baseline individual: Treatment = 0
   - External individual: Treatment = 1
3. Define the covariate matrix (desired matching variables).
4. Define the outcome variable
   - Arbitrary values
     - The treatment effect is beyond the scope of this work, so the chosen values are not important for this work;
5. Determine the Propensity Score for each individual.
6. Match individuals with similar PS.
7. PSM evaluation.

## Propensity Score Matching : EPC and SPENSER
