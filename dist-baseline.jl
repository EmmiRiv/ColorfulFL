### A Pluto.jl notebook ###
# v0.20.6

using Markdown
using InteractiveUtils

# ╔═╡ b0cc5034-671d-11f0-2206-2dec6f047cfd
using CSV

# ╔═╡ b3feefa6-7335-46c7-82f1-0e06d63ba47f
fC = CSV.File(open("subsets/adult-2266-340.csv"))

# ╔═╡ 37fc5fe4-cea5-4823-a333-50260a2ab177
ctrs = [[0.14489760994325374,-0.08505955695402766,0.5473599338377136,-0.14673320201323696,4.4287665392115829,0.2839381125249544],[0.5126739685940759,-0.3899745275336789,-0.1332163141974086,0.002209579757480587,-0.21878025661028678,1.1823664779308985],[-0.04436488480945271,1.9289283823201787,0.18147176250105594,-0.08154926320816211,-0.2083326646557879,0.007564455668108261],[-1.0752902422202267,-0.1449721258493843,-0.1413039008573734,-0.12975719043817167,-0.21878025661028684,-1.7999998988029123],[0.6850925671395178,0.12231086914937854,-2.2736955577490485,-0.12912386199298118,-0.21878025661028645,-0.27015079416633888],[-0.2204720293984082,-0.12406052361805171,0.582553628981922,0.03312210206601616,-0.2187802566102858,2.660806862890496],[-0.8176110804298113,0.47398331618954428,-0.46380807141082827,-0.10914053500077484,-0.21878025661028703,-0.0458994265667755],[-0.3521149978655948,-0.7789069929049478,-0.28285490523616887,-0.11844798546756252,-0.2147818258693402,-0.02051297975473269],[1.4516312428118994,-0.2356940805670126,-0.04640300206062139,-0.07104938036053343,-0.21878025661028706,-0.43874991476918709],[-0.02243537675773213,-0.3398566365586163,1.2895981569541076,0.03537376486983355,-0.21878025661028709,0.23174535552427739]]

# ╔═╡ e92fa003-bc7a-4423-bb4a-5af946a7dbeb
function l2(v1, v2)
	d = 0
	for i in 1:size(v1)[1]
		d += (v1[i]-v2[i])^2
	end
	return sqrt(d)
end

# ╔═╡ 9aff58bf-8429-4db3-aaac-9e7115a726fe
function process()
	dist = []
	gps = Dict()
	gC = []
	groupsF = Dict()
	om = 0

	jind = 0
	for rwj in fC
		jind += 1
		jdist = []
		jpos = [rwj.d1, rwj.d2, rwj.d3, rwj.d4, rwj.d5, rwj.d6]
		for c in ctrs
			ijdist = l2(jpos, c)
			push!(jdist, ijdist)
		end
		sort!(jdist)
		
		push!(dist, jdist[1])

		if !haskey(gps, rwj.c2)
			om += 1
			gps[rwj.c2] = om
			groupsF[jind] = om
			append!(gC, 1)
		else
			groupsF[jind] = gps[rwj.c2]
			gC[gps[rwj.c2]] += 1
		end
	
	end
	return dist, jind, gC, groupsF, om
		
end

# ╔═╡ fa248643-f5b5-4fed-9435-91c8e64df5a7
dist, n, gC, groupsF, om = process()

# ╔═╡ cf83fc61-cf0f-40d3-b8d4-78a9d5263a20
function cliSort()
	cli = [j for j in 1:n]
	sort!(cli, by = x -> dist[x])
	return cli
end

# ╔═╡ a3d26db8-97b1-4a14-8475-50cf28d1c349
function computeCost(served)
	cost = 0
	for j in served
		cost += dist[j]
	end
	return cost
end

# ╔═╡ ae0a2ba3-53e1-426e-ac93-e292a03952e1
function takeCensus(outliers)
	cen = zeros(om)
	for j in outliers
		cen[groupsF[j]] += 1
	end
	return cen
end

# ╔═╡ bd9c98f4-aecf-492d-8d96-b99f1e8414fd
function controlOut(out)
	jOrder = cliSort()
	outliers = jOrder[n-out+1:end]
	served = jOrder[1:n-out]
	cens = takeCensus(outliers)
	cost = computeCost(served)
	return cens, cost
end

# ╔═╡ 9957f9b7-16f7-4498-a2de-e69245a29dce
controlOut(22)

# ╔═╡ 68e25676-bb22-40f2-a751-7a06de3db9a6
# [17,5] 2633.62

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"

[compat]
CSV = "~0.10.15"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.5"
manifest_format = "2.0"
project_hash = "d08dbc71628d7eea6366b734ca874621bf576be4"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "PrecompileTools", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings", "WorkerUtilities"]
git-tree-sha1 = "deddd8725e5e1cc49ee205a1964256043720a6c3"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.10.15"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "962834c22b66e32aa10f7611c08c8ca4e20749a9"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.8"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "8ae8d32e09f0dcf42a36b90d4e17f5dd2e4c4215"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.16.0"

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

    [deps.Compat.weakdeps]
    Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates"]
git-tree-sha1 = "3bab2c5aa25e7840a4b065805c0cdfc01f3068d2"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.24"

    [deps.FilePathsBase.extensions]
    FilePathsBaseMmapExt = "Mmap"
    FilePathsBaseTestExt = "Test"

    [deps.FilePathsBase.weakdeps]
    Mmap = "a63ad114-7e13-5084-954f-fe012c677804"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"
version = "1.11.0"

[[deps.InlineStrings]]
git-tree-sha1 = "6a9fde685a7ac1eb3495f8e812c5a7c3711c2d5e"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.3"

    [deps.InlineStrings.extensions]
    ArrowTypesExt = "ArrowTypes"
    ParsersExt = "Parsers"

    [deps.InlineStrings.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"
    Parsers = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.OrderedCollections]]
git-tree-sha1 = "cc4054e898b852042d7b503313f7ad03de99c3dd"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.0"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "44f6c1f38f77cafef9450ff93946c53bd9ca16ff"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.2"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "36d8b4b899628fb92c2749eb488d884a926614d3"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.3"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "712fb0231ee6f9120e005ccd56297abbc053e7e0"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.4.8"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "598cd7c1f68d1e205689b1c2fe65a9f85846f297"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.12.0"

[[deps.TranscodingStreams]]
git-tree-sha1 = "0c45878dcfdcfa8480052b6ab162cdd138781742"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.3"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[deps.WorkerUtilities]]
git-tree-sha1 = "cd1659ba0d57b71a464a29e64dbc67cfe83d54e7"
uuid = "76eceee3-57b5-4d4a-8e66-0e911cebbf60"
version = "1.6.1"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"
"""

# ╔═╡ Cell order:
# ╠═b0cc5034-671d-11f0-2206-2dec6f047cfd
# ╠═b3feefa6-7335-46c7-82f1-0e06d63ba47f
# ╠═37fc5fe4-cea5-4823-a333-50260a2ab177
# ╠═e92fa003-bc7a-4423-bb4a-5af946a7dbeb
# ╠═9aff58bf-8429-4db3-aaac-9e7115a726fe
# ╠═fa248643-f5b5-4fed-9435-91c8e64df5a7
# ╠═cf83fc61-cf0f-40d3-b8d4-78a9d5263a20
# ╠═bd9c98f4-aecf-492d-8d96-b99f1e8414fd
# ╠═a3d26db8-97b1-4a14-8475-50cf28d1c349
# ╠═ae0a2ba3-53e1-426e-ac93-e292a03952e1
# ╠═9957f9b7-16f7-4498-a2de-e69245a29dce
# ╠═68e25676-bb22-40f2-a751-7a06de3db9a6
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
