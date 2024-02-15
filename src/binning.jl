####
#### transformations
####

export nice_quantiles, bin_bivariate, get_x_y_w

struct NiceQuantiles{T,TB<:AbstractVector{T}} <: AbstractVector{T}
    boundaries::TB
end

Base.size(v::NiceQuantiles) = size(v.boundaries)

Base.getindex(v::NiceQuantiles, i::Int) = v.boundaries[i]

"""
$(SIGNATURES)

Make “nice” quantile boundaries from univariate data, using the following algorithm:

1. quantiles 1/(N+1), 2/(N+1), …, N/(N+1) are calculated

2. for quantiles which are closer than `(maximum(x) - minimum(x)) * relative_threshold`,
only one is kept

This algorithm is a heuristic designed for binning data that may pile up at various
locations (edges etc).
"""
function nice_quantiles(xs, N::Integer; relative_threshold::Real = 1/(5*N))
    @argcheck relative_threshold ≥ 0
    @argcheck N ≥ 1
    q = quantile(xs, range(0, 1; length = N + 1))
    threshold = (q[end] - q[begin]) * relative_threshold
    boundaries = Vector{eltype(q)}()
    if threshold > 0
        for i in 2:N
            if isempty(boundaries) || (q[i] - boundaries[end]) ≥ threshold
                push!(boundaries, q[i])
            end
        end
    end
    NiceQuantiles(boundaries)
end

####
#### binning
####

struct Mass{T}
    x::T
    y::T
    m::T
end

function merge_mass(mass1::Mass, mass2::Mass)
    (; x, y, m) = mass1
    M = m + mass2.m
    α = mass2.m / M
    Mass(x + α * (mass2.x - x), y + α * (mass2.y - y), M)
end

function Base.:(/)(mass::Mass, b::Real)
    (; x, y, m) = mass
    Mass(x, y, m / b)
end

struct BinnedBivariate{T,TX,TY,TM<:Matrix{Mass{T}}}
    x_boundaries::TX
    y_boundaries::TY
    "masses, with weighs summing to 1"
    masses::TM
    "the largest weight"
    max_w::T
end

"""
$(SIGNATURES)

Bin bivariate data `x, y` using the given boundaries.

Return a `BinnedBivariate` object. See [`get_x_y_w`](@ref).
"""
function bin_bivariate(x, x_boundaries, y, y_boundaries)
    N = length(x)
    @argcheck N == length(y)
    Nx = length(x_boundaries)
    Ny = length(y_boundaries)
    masses = fill(Mass(zero(eltype(x)), zero(eltype(y)), 0.0), Nx + 1, Ny + 1)
    for (x, y) in zip(x, y)
        ix = searchsortedfirst(x_boundaries, x)
        iy = searchsortedfirst(y_boundaries, y)
        masses[ix, iy] = merge_mass(masses[ix, iy], Mass(x, y, 1.0))
    end
    masses ./= N
    BinnedBivariate(x_boundaries, y_boundaries, masses,
                    maximum(x -> x.m, masses))
end

"""
$(SIGNATURES)

Return an iterator that yields `(x, y, w)` triplets, keeping only `w ≥ threshold`.

When `threshold == 0`, `w`s sum to 1, but this is not maintained. The purpose is to
remove outliers for plots, with `threshold = 1e-3` or similar.
"""
function get_x_y_w(bb::BinnedBivariate{T}; threshold = zero(T), scale = one(T)) where T
    ((m.x, m.y, m.m * scale) for m in bb.masses if m.m > threshold)
end

Base.length(bb::BinnedBivariate) = length(bb.masses)
