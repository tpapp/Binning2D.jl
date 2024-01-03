export bin_area, bin, vertices, Ellipse, inner_ellipse

####
#### point
####

"Representation of a point, for internal use. Use `point` to construct."
const Point{T} = SVector{2,T}

"""
$(SIGNATURES)

Convenience function to construct a point from two coordinates. Internal.
"""
function point(x::T, y::T) where T
    if T <: AbstractFloat
        SVector(x, y)
    else
        SVector(float(x), float(y))
    end
end

point(x, y) = point(promote(x, y)...)

function point(xy::Point{T}) where T
    if T <: AbstractFloat
        xy
    else
        float.(xy)
    end
end

function point(xy::AbstractVector)
    @argcheck length(xy) == 2
    point(xy[1], xy[2])
end

point(xy::Tuple{Any,Any}) = point(Point(xy))

####
#### ellipse
####

"""
Representation of an ellipse.

$(FIELDS)

Parametrically, the ellipse is the points `@. center + d1 * cos(θ) + d2 * sin(θ)` for
real numbers `θ`.
"""
struct Ellipse{T<:AbstractFloat}
    "center"
    center::Point{T}
    "conjugate axis 1"
    d1::Point{T}
    "conjugate axis 2"
    d2::Point{T}
end

"""
$(SIGNATURES)

Convenience function to create a circle. Internal.
"""
circle(center::Point{T}, r::T) where T = Ellipse(center, point(r, 0), point(0, r))

####
#### generic API
####

"""
$(SIGNATURES)
$(FUNCTIONNAME)(T, grid)

Calculate the area of a bin in `grid` using type `T` (default = `Float64`).

Note: all bins in a grid have the same area.
"""
bin_area(grid) = area(Float64, grid)

"""
$(FUNCTIONNAME)(bin, xy)

Find the bin that contains `xy` in `grid`.

The return value is opaque and should be used in conjuction with `grid`.

Valid values for `xy` are 2-element tuples and `AbstractVector`s, SVector{2} is
preferred.
"""
function bin end

bin(grid, xy) = bin(grid, point(xy))

"""
$(SIGNATURES)
$(FUNCTIONNAME)(T, grid, bin)

Return the vertices of `bin` in `grid` as a `Tuple` of coordinates (xy pairs).

Uses element type `T` (default = `Float64`).
"""
vertices(grid, bin) = vertices(Float64, grid, bin)

"""
$(SIGNATURES)
$(FUNCTIONNAME)(T, grid, bin)

Return the [`Ellipse`](@ref) that can be inscribed into a bin.

Uses element type `T` (default = `Float64`).
"""
inner_ellipse(grid, bin) = inner_ellipse(Float64, grid, bin)
