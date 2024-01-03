"""
A lightweight package for grouping 2D data into regular bins.

Primarily for plotting, but note that this package does not contain any plotting code,
just calculations.
"""
module Binning2D

using ArgCheck: @argcheck
using DocStringExtensions: FIELDS, FUNCTIONNAME, SIGNATURES
using StaticArrays: SVector

include("generic.jl")
include("rectangle.jl")

end # module
