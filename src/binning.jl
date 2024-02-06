####
#### transformations
####

export nice_quantiles, bin_bivariate

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
    α = m / M
    Mass(x + α * (mass2.x - x), y + α * (mass2.y - y), M)
end

function Base.:(/)(mass::Mass, b::Real)
    (; x, y, m) = mass
    Mass(x, y, m / b)
end

struct BinnedBivariate{TX,TY,T,TM<:Matrix{Mass{T}}} <: AbstractVector{Tuple{T,T,T}}
    x_boundaries::TX
    y_boundaries::TY
    masses::TM
end

function Base.:(/)(bb::BinnedBivariate, b::Real)
    (; x_boundaries, y_boundaries, masses) = bb
    BinnedBivariate(x_boundaries, y_boundaries, masses ./ b)
end

Base.size(bb::BinnedBivariate) = (length(bb.masses), )

Base.getindex(bb::BinnedBivariate, i::Int) = (m = bb.masses[i]; (m.x, m.y, m.m))

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
    BinnedBivariate(x_boundaries, y_boundaries, masses)
end
