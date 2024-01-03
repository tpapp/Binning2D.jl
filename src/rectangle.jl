export RectangleGrid

"""
A grid of rectangles with area 1, centered on the origin.
"""
struct RectangleGrid end

"""
The rectangle ``x ± 0.5, y ± 0.5``.
"""
struct RectangleBin
    x::Int
    y::Int
end

function bin(::RectangleGrid, xy::Point)
    x, y = xy
    RectangleBin(round(Int, x), round(Int, y))
end

bin_area(::Type{T}, ::RectangleGrid) where T <: AbstractFloat = one(T)

function vertices(::Type{T}, ::RectangleGrid,
                  bin::RectangleBin) where T <: AbstractFloat
    h = one(T) / 2
    (; x, y) = bin
    (point(x + h, y + h), point(x - h, y + h),
     point(x - h, y - h), point(x + h, y - h))
end

function inner_ellipse(::Type{T}, ::RectangleGrid,
                       bin::RectangleBin) where T <: AbstractFloat
    (; x, y) = bin
    circle(point(T(x), T(y)), one(T) / 2)
end
