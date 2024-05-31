using VLBIData
using InterferometricModels
using VLBIPlots
using GLMakie
using MakieExtra
using DataManipulation
using Unitful, UnitfulAngles
using StaticArrays
using Colors
using DirectionalStatistics
using AxisKeysExtra
using LinearAlgebra


add_conj_vis(uvtbl) = @p let
	uvtbl
	orig = __
	@modify(conj, __.visibility)
	@modify(-, __.uv)
	vcat(orig, __)
end

function uvvis(uvf, modf=nothing)
    uvtbl = table(VLBI.load(VLBI.UVData, uvf)) |> filter(x -> x.stokes ∈ (:I, :RR, :LL)) |> add_conj_vis
    model = VLBI.load(MultiComponentModel, modf)


    fig = Figure(size=(1500, 500))

    posang = Observable(0.)
    Δang = Observable(30u"°")

    colormap = Makie.ColorSchemes.cyclic_mrybm_35_75_c68_n256_s25
    curcolor = @lift get(colormap, mod($posang, 0..π)/π)
    colors = (@lift @p uvtbl map() do __
        mod(atan(__.uv...), 0..π)
        Circular.distance($posang, __, period=π) < $Δang ? RGBA(get(colormap, __/π)) : RGBA(coloralpha(Gray(0.7), 0.5))
    end)

    ax11, plt = scatter(fig[1,-1], (RadPlot(uvtbl)), color=colors, markersize=1, marker=Makie.FastPixel())
    ax21, plt = scatter(fig[2,-1], (RadPlot(uvtbl, yfunc=rad2deg∘angle)), color=colors, markersize=1, marker=Makie.FastPixel(), axis=(xtickformat=EngTicks(:symbol),))
    ax11.xlabelvisible = false
    ax11.xticklabelsvisible = false

    band!(ax11, RadPlot(0..1.2maximum(x -> norm(x.uv), uvtbl); model, nsteps=30), color=(:black, 0.15))
    lines!(ax11, (@lift ProjPlot(0..1.2maximum(x -> norm(x.uv), uvtbl), $posang; model)), color=curcolor)

    ax0, plt = scatter(fig[1:2,0], UVPlot(uvtbl), markersize=1, color=colors, axis=(xtickformat=EngTicks(:symbol), ytickformat=EngTicks(:symbol),))
    lines!(ax0, (@lift @p SVector(sincos($posang)) [__, -__] .+ Ref(SVector(0.5, 0.5))), color=:black, space=:relative)

    ax12, plt = scatter(fig[1,1], (@lift ProjPlot(uvtbl, $posang)), color=colors, markersize=1, marker=Makie.FastPixel())
    ax22, plt = scatter(fig[2,1], (@lift ProjPlot(uvtbl, $posang, yfunc=rad2deg∘angle)), color=colors, markersize=1, marker=Makie.FastPixel(), axis=(xtickformat=EngTicks(:symbol),))
    ax12.xlabelvisible = false
    ax12.xticklabelsvisible = false

    lines!(ax12, (@lift ProjPlot(0..1.2maximum(x -> norm(x.uv), uvtbl), $posang; model)), color=curcolor)
    lines!(ax22, (@lift ProjPlot(0..1.2maximum(x -> norm(x.uv), uvtbl), $posang; model, yfunc=rad2deg∘angle)), color=curcolor)

    linkxaxes!(ax11, ax21, ax12, ax22)


    on(events(fig).mouseposition, priority=10) do pos
        if is_mouseinside(ax0) && ispressed(fig, Makie.Mouse.left)
            posang[] = atan(mouseposition(ax0)...)
            return Consume()
        end
    end

    display(fig, backend=GLMakie)
    # Record(fig, range(0, 2π, length=100), framerate=20) do posang_
    #     posang[] = posang_
    # end
end

# uvvis("/Users/aplavin/work/rfc/images/J1642+6856/J1642+6856_U_2007_04_30_sok_vis.fits", "/Users/aplavin/work/images_align/objective/bk134/1642+690_u1.mod")
