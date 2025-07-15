### A Pluto.jl notebook ###
# v0.20.6

using Markdown
using InteractiveUtils

# ╔═╡ 048efef7-136c-41c4-b958-b5308e709cf8
using CSV

# ╔═╡ 5eda2eaa-6136-11f0-2833-097e8c06610c
fC = CSV.File(open("subsets/adult-50-15.csv"))

# ╔═╡ baaab918-1085-4473-8b22-40f6d2a638b0
fF = CSV.File(open("subsets/adult-50-15-fac.csv"))

# ╔═╡ 71477b9d-b19d-4982-bead-af401882f991
function l2(v1,v2)
	d = 0
	for i in 1:size(v1)[1]
		d += (v1[i]-v2[i])^2
	end
	return sqrt(d)
end

# ╔═╡ 51ab9d1e-9eeb-4b19-8033-3f792187363c
costs = Dict()

# ╔═╡ dc6f6c3f-a830-412e-8156-1297dcc5e811
function process()
	Fpos = []
	dist = []
	gC = [0,0]
	groupsF = Dict()
	groupsO = Dict()

	iind = 0
	for rwi in fF
		iind += 1
		push!(Fpos, [rwi.d1, rwi.d2, rwi.d3, rwi.d4, rwi.d5, rwi.d6])
		costs[iind] = 2
	end

	jind = 0
	for rwj in fC
		jind += 1
		jdist = []
		jpos = [rwj.d1, rwj.d2, rwj.d3, rwj.d4, rwj.d5, rwj.d6]
		for iP in Fpos
			push!(jdist, l2(jpos, iP))
		end
		push!(dist, jdist)

		if rwj.c2 == "Male"
			c = 1
		elseif rwj.c2 == "Female"
			c = 2
		end
		groupsF[jind] = c
		groupsO[jind] = 1
		gC[c] += 1
	
	end
	return dist, jind, size(Fpos)[1], gC, groupsF, groupsO
		
end

# ╔═╡ 1b4ca69e-ba81-4707-88a8-56c87b7b6c9e
dist, n, m, gC, groupsF, groupsO = process()

# ╔═╡ b00f0a5f-1229-4c55-9dbb-69e63bad6dc8
st=Dict()

# ╔═╡ 901e8755-050a-4da3-8c2c-236384b56e94
om = size(gC)[1]

# ╔═╡ 69e93a45-81bc-4549-86e3-dca21303755e
function takeCensus(status)
	cens = zeros(om)
	for j in 1:n
		if status[j] == 1
			cens[groupsF[j]] += 1
		end
	end
	return cens
end

# ╔═╡ 0abac5c8-213f-44c5-9aed-687a0accf972
takeCensus(st)

# ╔═╡ c5015786-a3f5-4837-bbfa-078baac0d704
function makeTimeline()
	tl = []
	for j in 1:n
		for i in 1:m
			push!(tl, [j,i]) 
		end
	end
	sort!(tl, by = x -> dist[x[1]][x[2]])
	return tl
end

# ╔═╡ a156439f-2ca5-4600-b8b7-98e4e86c7c58
tl = makeTimeline()

# ╔═╡ 872f4d4e-1275-42d5-b9a4-4bb0a8765d01
function computeCost(cities)
	cost = 0
	for i in 1:m
		if size(cities[i])[1] != 0
			cost += costs[i]
			for j in cities[i]
				cost += dist[j][i]
			end
		end
	end
	return cost
end

# ╔═╡ 188f6e6d-b7c7-4cee-8c4f-adcd97abc142
function finishGroup(g, status, freeze, groups, t)
	for j in 1:n
		if groups[j] == g && status[j] == 2
			status[j] = 1
			freeze[j] = t
		end
	end
end

# ╔═╡ 1420383e-a76b-46e7-ba19-1a3f3302a60b
function openFac(i0, isOpen, contributors, cities, status, freeze, groups, t, lG)
	isOpen[i0] = true
	for j in contributors[i0]
		if status[j] == 2
			status[j] = 3
			push!(cities[i0], j)
			lG[groups[j]] -= 1
			if lG[groups[j]] == 0
				finishGroup(groups[j], status, freeze, groups, t)
			end
		end
	end
end

# ╔═╡ 1391118b-f3c2-411a-a07f-25093a6d3157
function event(i0, j0, isOpen, contributors, cities, status, freeze, lG, groups)
	t = dist[j0][i0]
	if status[j0] == 2 && isOpen[i0]
		status[j0] = 3
		push!(cities[i0], j0)
		lG[groups[j0]] -= 1
		if lG[groups[j0]] == 0
			finishGroup(groups[j0], status, freeze, groups, t)
		end
	elseif status[j0] == 2 && !isOpen[i0]
		push!(contributors[i0], j0)
	end

	for i in 1:m
		if !isOpen[i]
			cont = 0
			for j in contributors[i]
				if status[j] == 2
					cont += t - dist[j][i0]
				elseif status[j] == 1
					cont += maximum([0, freeze[j]-dist[j][i0]])
				end
			end
			if cont >= costs[i]
				openFac(i, isOpen, contributors, cities, status, freeze, groups, t, lG)
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
	

# ╔═╡ 4ec79d43-f37d-41ec-9fa1-e8313f2667f7
function increment(status, lG, groups)
	isOpen = Dict()
	contributors = Dict()
	cities = Dict()
	freeze = Dict()
	for i in 1:m
		isOpen[i] = false
		contributors[i] = []
		cities[i] = []
	end
	for j in 1:n
		status[j] = 2
	end
	for e in tl
		done = event(e[2],e[1], isOpen, contributors, cities, status, freeze, lG, groups)
		if done
			break
		end
	end
	return cities
end

# ╔═╡ 4ca11c4f-2ad1-40f5-b9eb-f726c7f95531
function adjustOut()
	outlier_cens = []
	fair_cens = []
	fcost = []
	ocost = []
	fopt = []
	oopt = []
	fgoal = []
	percc = []
	for p in 0:20
		#@printf("percent outliers: %d",p)
		outG = [floor((p/100)*l) for l in gC]
		covG = [gC[g]-outG[g] for g in 1:om]
		covOutL = [sum(covG)]
		statusF = Dict()
		statusO = Dict()
		finalF = increment(statusF, copy(covG), groupsF)
		finalO = increment(statusO, copy(covOutL), groupsO)
		costF = computeCost(finalF)
		costO = computeCost(finalO)
		censO = takeCensus(statusO)
		push!(outlier_cens,censO)
		push!(fair_cens,outG)
		push!(fcost,costF)
		push!(ocost,costO)
		push!(percc,p)
	end
	print(percc)
	print(outlier_cens)
	print(fair_cens)
	print(ocost)
	print(fcost)
end

# ╔═╡ 127e8d94-37b0-4d2f-a549-d5f35e076b78
adjustOut()

# ╔═╡ 1d70c763-5996-4d4b-8d7b-e384ecea5ffa
f = increment(st, [35,14], groupsF)

# ╔═╡ 7d6cda3d-8985-4271-9ad9-b2af5736960a
computeCost(f)

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
# ╠═048efef7-136c-41c4-b958-b5308e709cf8
# ╠═5eda2eaa-6136-11f0-2833-097e8c06610c
# ╠═baaab918-1085-4473-8b22-40f6d2a638b0
# ╠═71477b9d-b19d-4982-bead-af401882f991
# ╠═51ab9d1e-9eeb-4b19-8033-3f792187363c
# ╠═dc6f6c3f-a830-412e-8156-1297dcc5e811
# ╠═1b4ca69e-ba81-4707-88a8-56c87b7b6c9e
# ╠═4ca11c4f-2ad1-40f5-b9eb-f726c7f95531
# ╠═b00f0a5f-1229-4c55-9dbb-69e63bad6dc8
# ╠═1d70c763-5996-4d4b-8d7b-e384ecea5ffa
# ╠═0abac5c8-213f-44c5-9aed-687a0accf972
# ╠═7d6cda3d-8985-4271-9ad9-b2af5736960a
# ╠═901e8755-050a-4da3-8c2c-236384b56e94
# ╠═127e8d94-37b0-4d2f-a549-d5f35e076b78
# ╠═69e93a45-81bc-4549-86e3-dca21303755e
# ╠═c5015786-a3f5-4837-bbfa-078baac0d704
# ╠═a156439f-2ca5-4600-b8b7-98e4e86c7c58
# ╠═872f4d4e-1275-42d5-b9a4-4bb0a8765d01
# ╠═4ec79d43-f37d-41ec-9fa1-e8313f2667f7
# ╠═1391118b-f3c2-411a-a07f-25093a6d3157
# ╠═1420383e-a76b-46e7-ba19-1a3f3302a60b
# ╠═188f6e6d-b7c7-4cee-8c4f-adcd97abc142
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
