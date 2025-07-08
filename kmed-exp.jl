### A Pluto.jl notebook ###
# v0.20.6

using Markdown
using InteractiveUtils

# ╔═╡ 8c7e18ba-5ad2-11f0-1618-e18a2c40d0ea
using Printf, CSV

# ╔═╡ a93974c1-2069-4f66-9cf4-9426901e700f
n = 5

# ╔═╡ fb0aa260-a0e2-45ea-9cdc-88ce959aca8b
fl = CSV.File(open("datasets/adult.ds");limit=n)

# ╔═╡ 308bb617-1387-40a7-88de-e41b3e34efff
function l2(v1,v2)
	d = 0
	for i in 1:size(v1)[1]
		d += (v1[i]-v2[i])^2
	end
	return sqrt(d)
end

# ╔═╡ b6ae339d-0547-40a9-9d8a-33f8a7e00b7b
status = Dict() #1:outlier 2:uncovered 3:covered

# ╔═╡ cc690fc2-af87-4102-bbed-b4e129d8b0f5
groups = Dict()

# ╔═╡ e95f8910-0da7-42d8-bc5a-acdeb5e1ebcf
isOpen = Dict()

# ╔═╡ 3a3e13b0-bf7b-413b-b9dd-218570f47bc0
contributors = Dict()

# ╔═╡ 865842fa-7c6e-4d15-b96f-b50157b388ae
cities = Dict()

# ╔═╡ a462e641-2069-4052-a4e3-feaebe14e77c
function process()
	dist = []
	census = [0,0]

	for j in 1:n
		jdist = []
		jpos = [fl[j].d1, fl[j].d2, fl[j].d3, fl[j].d4, fl[j].d5, fl[j].d6]
		for j2 in 1:n
			j2pos = [fl[j2].d1, fl[j2].d2, fl[j2].d3, fl[j2].d4, fl[j2].d5, fl[j2].d6]
			push!(jdist, l2(jpos, j2pos))
		end
		push!(dist, jdist)

		if fl[j].c2 == "Male"
			groups[j] = 1
			census[1] += 1
		elseif fl[j].c2 == "Female"
			groups[j] = 2
			census[2] += 1
		end

		status[j] = 2

		isOpen[j] = false
		contributors[j] = []
		cities[j] = []
	end
	return dist, census
		
end

# ╔═╡ 31f39fbb-42f6-4b38-b6fe-e679c94059eb
penalties = Dict()

# ╔═╡ f045c84e-c8af-49fb-9d70-06c058d6e61a
gam = 2

# ╔═╡ 430c4973-ac00-4873-b6b3-d5eb0ea825e2
OPT = 10

# ╔═╡ 3c4c1867-41c4-46f4-8fc7-42c3467e64d0
fCost = 0.1

# ╔═╡ 0ec8afe3-c09f-47cc-89d7-52c22aec0de8
oG = [2,1]

# ╔═╡ 49c20a64-ac9b-44d9-aeec-0428663eab5c
dist, census = process()

# ╔═╡ bf755938-1e49-4454-ad42-e6f5abbd50a0
pens = [OPT/(gam*l) for l in oG]

# ╔═╡ 6bdf13c6-9add-4adc-8712-4a94369ac94b
function makeTimeline()
	tl = []
	for j in 1:n
		for i in 1:n
			push!(tl, [j,i])
		end
	end
	sort!(tl, by = x -> dist[x[1]][x[2]])
	return tl
end

# ╔═╡ b98ffbfb-f2b7-4258-845a-dc57fbeb51ab
timeline = makeTimeline()

# ╔═╡ ee621eae-1fed-48fa-8138-51e2dc4e5b70
function openFac(i0)
	isOpen[i0] = true
	for j in contributors[i0]
		if status[j] == 2 || (status[j] == 1 && pens[groups[j0]] >= dist[j0][i0])
			status[j] = 3
			push!(cities[i0], j)
		end
	end
end

# ╔═╡ ed0a737a-d053-48ad-8b3b-5d1b50d9ec5f
function event(i0, j0)
	t = dist[j0][i0]
	
	if status[j0] == 2 && pens[groups[j0]] >= t
		status[j0] = 1
	elseif status[j0] == 2 && isOpen[i0]
		status[j0] = 3
		push!(cities[i0], j0)
	elseif status[j0] == 1 && isOpen[i0] && pens[groups[j0]] >= dist[j0][i0]
		status[j0] = 3
		push!(cities[i0], j0)
	elseif status[j0] == 2 && !isOpen[i0]
		push!(contributors[i0], j0)
	end

	for i in 1:n
		if !isOpen[i]
			cont = 0
			for j in contributors[i]
				if status[j] == 2
					cont += t - dist[j][i0]
				end
			end
			if cont >= fCost
				openFac(i)
			end
		end
	end

	for j in 1:n
		if status[j] == 2
			return false
		end
	end
	return true
end
	

# ╔═╡ 71f14388-f41f-4369-af47-b4fe33afe6ce
function increment()
	for e in timeline
		done = event(e[2],e[1]) 
		if done
			break
		end
	end
end

# ╔═╡ ae3aa4ab-b61b-4363-a39c-a45fc8e3414e
increment()

# ╔═╡ e78cfe68-e013-4726-818b-b012859091e9
status

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
Printf = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[compat]
CSV = "~0.10.15"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.5"
manifest_format = "2.0"
project_hash = "1a81d4ab6a19fa608c3e1c1dad1cdcac849d9478"

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
# ╠═8c7e18ba-5ad2-11f0-1618-e18a2c40d0ea
# ╠═fb0aa260-a0e2-45ea-9cdc-88ce959aca8b
# ╠═a93974c1-2069-4f66-9cf4-9426901e700f
# ╠═a462e641-2069-4052-a4e3-feaebe14e77c
# ╠═308bb617-1387-40a7-88de-e41b3e34efff
# ╠═b6ae339d-0547-40a9-9d8a-33f8a7e00b7b
# ╠═cc690fc2-af87-4102-bbed-b4e129d8b0f5
# ╠═e95f8910-0da7-42d8-bc5a-acdeb5e1ebcf
# ╠═3a3e13b0-bf7b-413b-b9dd-218570f47bc0
# ╠═865842fa-7c6e-4d15-b96f-b50157b388ae
# ╠═31f39fbb-42f6-4b38-b6fe-e679c94059eb
# ╠═f045c84e-c8af-49fb-9d70-06c058d6e61a
# ╠═430c4973-ac00-4873-b6b3-d5eb0ea825e2
# ╠═3c4c1867-41c4-46f4-8fc7-42c3467e64d0
# ╠═0ec8afe3-c09f-47cc-89d7-52c22aec0de8
# ╠═49c20a64-ac9b-44d9-aeec-0428663eab5c
# ╠═bf755938-1e49-4454-ad42-e6f5abbd50a0
# ╠═6bdf13c6-9add-4adc-8712-4a94369ac94b
# ╠═b98ffbfb-f2b7-4258-845a-dc57fbeb51ab
# ╠═71f14388-f41f-4369-af47-b4fe33afe6ce
# ╠═ed0a737a-d053-48ad-8b3b-5d1b50d9ec5f
# ╠═ee621eae-1fed-48fa-8138-51e2dc4e5b70
# ╠═ae3aa4ab-b61b-4363-a39c-a45fc8e3414e
# ╠═e78cfe68-e013-4726-818b-b012859091e9
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
