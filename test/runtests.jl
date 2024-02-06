using Binning2D
using Test
using PolygonOps

using Binning2D: point

####
#### bin interfaces
####

@testset "input conversions" begin
    grid = RectangleGrid()
    xy = point(0.2, 0.3)
    @test bin(grid, xy) ≡ bin(grid, Tuple(xy)) ≡ bin(grid, [xy...])
end

function test_bin_consistency(grid; N = 200, scale = 10.0)
    for _ in 1:N
        xy = point(randn() * scale, randn() * scale)
        b = bin(grid, xy)
        v = vertices(grid, b)
        p = [v..., v[1]]
        @test inpolygon(xy, p) == 1
        (; center, d1, d2) = inner_ellipse(grid, b)
        @test inpolygon(center, p) == 1
        @test inpolygon(center .+ d1, p; on = 1) == 1
        @test inpolygon(center .+ d2, p; on = 1) == 1
    end
end

@testset "rectangle grids" begin
    grid = RectangleGrid()
    test_bin_consistency(grid)
    @test bin_area(grid) == 1
end

###
### quantile-based binning
###

@testset "quantile based binning sanity checks" begin
    N = 10000
    x = abs.(randn(N))
    y = max.(randn(N), 0)
    bx = nice_quantiles(x, 10)
    @test length(bx) == 9
    by = nice_quantiles(y, 10)
    @test length(by) == 5
    bb = bin_bivariate(x, bx, y, by)
    @test sum(last, bb) == N
    @test sum(last, bb / N) ≈ 1
end

using JET
@testset "static analysis with JET.jl" begin
    @test isempty(JET.get_reports(report_package(Binning2D, target_modules=(Binning2D,))))
end

@testset "QA with Aqua" begin
    import Aqua
    Aqua.test_all(Binning2D; ambiguities = false)
    # testing separately, cf https://github.com/JuliaTesting/Aqua.jl/issues/77
    Aqua.test_ambiguities(Binning2D)
end
