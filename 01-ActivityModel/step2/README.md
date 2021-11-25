# Enriched Synthetic Population <!-- omit in toc -->

## Propensity Score Matching

In order to enrich the baseline synthetic population the Propensity Score Matching (PSM) method was used. Through the PSM method each baseline individual is matched, based  on the similarity of their characteristics, to an individual in an external dataset.

### General approach

1. Concatenate the baseline and the external datasets.
2. Assign a treatment indicator (0 or 1) for each individual:
   - Baseline individual: Treatment = 0
   - External individual: Treatment = 1
3. Define the covariate matrix (desired matching variables).
4. Define the outcome variable
   - Arbitrary values
     - The treatment effect is beyond the scope of this work, so the chosen values are not important for this work;
5. Determine the Propensity Score (PS) for each individual.
6. Match individuals with similar PS.
7. PSM evaluation.

## Propensity Score Matching : EPC and SPENSER

Energy Performance Certificate (EPC) dataset provides energy performance related data about domestic accommodations.

The complete EPC/SPENSER PSM code can be found [here](EPC_propensity_score_matching.ipynb).

### Variable selection - Steps 1, 2, 3 and 4

- Treatment values:
  - SPENSER: Treatment = 0
  - EPC: Treatment = 1

- EPC/SPENSER matched variables (covariate matrix) were:
  - Area
  - Tenure
  - Accommodation type
  - Number of rooms (not used)

- EPC/SPENSER non-matching variables:
  - Floor area
  - Accommodation age
  - Main heat description (not encoded)

where the matched variables are used to define a Propensity Score for each individual, and the non-matching variables are used to enrich the baseline SPENSER.

### Propensity Score Function - Step 5

To determine the Propensity Score for each individual the [`Causalinference`](https://causalinferenceinpython.org/) package was used. The following code illustrates how to obtain the propensity score if Y (outcome), X (treatment) and Z (covariate matrix) are given:

```python
from causalinference import CausalModel

model = CausalModel(Y, X, Z)
model.est_propensity_s()
PropensityScore = model.propensity['fitted']
```

> Important: the `CausalModel` only work with numerical arrays.

### Matching Process

First, for each baseline individual (SPENSER) a list with `n` closest EPC individuals was created. The [`sklearn.neighbors`](https://scikit-learn.org/stable/modules/neighbors.html) is helpful for this task:

```python
from sklearn.neighbors import NearestNeighbors

# create the external neighbors object (p=2 means Euclidean distance)
knn = NearestNeighbors(n_neighbors=n, p=2).fit(EPC["PropensityScore"])

# for each baseline individual, find the nearest external neighbors
distances, indices = knn.kneighbors(SPENSER['PropensityScore'])
```

Then, for each baseline individual, select an external individual from the neighbour list.

- Individuals with closer PS are more likely to be selected.

The following code illustrates how to obtain the match for the individual $i$:

```python
from random import choices

indexEPC = choices(indices[i], weights=W)[0]
```

where <img src="https://render.githubusercontent.com/render/math?math=W"> is the weight array defined by

<p align="center">
<img src="https://render.githubusercontent.com/render/math?math=W(%5CDelta%20P_%7Bi%2Cj%7D)%20%3D%20N%20-%20%20%5Cdfrac%7B%5CDelta%20P_%7Bi%2Cj%7D%7D%7B%5CDelta%20P_%7Bi%2Cn%7D%7D(N-M)%2C">
</p>

where:

- $\Delta P_{i,j}$: Propensity Score difference between the MSM household $i$ and the EPC neighbor $j$ ($1 \le j \le n$)
- $\Delta P_{i,n}$: Propensity Score difference between the MSM household $i$ and the EPC neighbor $n$
- $n$: The number of neighbors (n_neighbors).
- N: Value of the highest desired weight. Here $N=100$.
- M: Value of the lowest desired weight. Here $M=5$.
