# nztt
Fun with the New Zealand Soil Texture Triangle

## Installation

To install, run:

```
remotes::install_github("manaakiwhenua/nztt")
```

## Example

```
# Load example data
data(wairau)

# Calculate texture classes
tx <- texture_class(clay = wairau$clay, sand = wairau$sand, silt = wairau$silt)

print(tx)
```
