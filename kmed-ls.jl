### A Pluto.jl notebook ###
# v0.20.3

using Markdown
using InteractiveUtils

# ╔═╡ 579f62a0-6342-11f0-1049-df88128ea9f2
using CSV, Printf

# ╔═╡ 00fc410f-c585-4a57-bb05-8593001a4daa
fC = CSV.File(open("subsets/adult-236-36.csv"))

# ╔═╡ aec87dc6-dc5d-4aa3-8c6e-e6af9bf6e991
fF = CSV.File(open("subsets/adult-236-36-fac.csv"))

# ╔═╡ 0f3e0470-55e0-4f39-80a7-672dc209c21d
function l2(v1, v2)
	d = 0
	for i in 1:size(v1)[1]
		d += (v1[i]-v2[i])^2
	end
	return sqrt(d)
end

# ╔═╡ 1a5d9599-154b-4569-a77d-ed0632dcbd73
function process()
	Fpos = []
	dist = []
	gC = [0,0]
	groupsF = Dict()
	groupsO = Dict()
	dmin = Inf
	dmax = 0

	iind = 0
	for rwi in fF
		iind += 1
		push!(Fpos, [rwi.d1, rwi.d2, rwi.d3, rwi.d4, rwi.d5, rwi.d6])
	end

	jind = 0
	for rwj in fC
		jind += 1
		jdist = []
		jpos = [rwj.d1, rwj.d2, rwj.d3, rwj.d4, rwj.d5, rwj.d6]
		for iP in Fpos
			ijdist = l2(jpos, iP)
			push!(jdist, ijdist)
			if ijdist < dmin
				dmin = ijdist
			end
			if ijdist > dmax
				dmax = ijdist
			end
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
	return dist, jind, size(Fpos)[1], gC, groupsF, groupsO, dmin, dmax
		
end

# ╔═╡ 1b19fa25-ced9-4ccc-897b-1acf01d9dbf5
dist, n, m, gC, groupsF, groupsO, dmin, dmax = process()

# ╔═╡ c42ab94a-cc34-4256-b5eb-2316b68012a0
k = 5

# ╔═╡ c56042e7-4bda-4687-aa14-39695b2bcbf7
function initLS(groups, pens)
	assignment = Dict()
	orig = [i for i in 1:m]
	init = []
	cost = 0
	
	while size(init)[1] < k
		fnd = rand(1:size(orig)[1])
		push!(init, orig[fnd])
		deleteat!(orig, fnd)
	end

	for j in 1:n
		lmin = pens[groups[j]]
		fmin = -1
		for i in init
			if dist[j][i] < lmin
				lmin = dist[j][i]
				fmin = i
			end
		end
		assignment[j] = fmin
		cost += lmin
	end

	return init, orig, assignment, cost
end

# ╔═╡ f7f7fd8f-6801-4864-afe3-4d0e52c19c50
function localSearch(X0, FX0, assignment0, cost0, groups, pens)
	for fnd in 1:k 
		fout = X0[fnd]
		xS = copy(X0)
		deleteat!(xS, fnd)
		for fndp in 1:m-k
			costN = 0
			assignmentN = Dict()
			fin = FX0[fndp]
			XN = copy(xS)
			push!(XN, fin)
			for j in 1:n
				if assignment0[j] == -1
					if dist[j][fin] < pens[groups[j]]
						assignmentN[j] = fin
						costN += dist[j][fin]
					else
						assignmentN[j] = -1
						costN += pens[groups[j]]
					end
				elseif assignment0[j] == fout
					lmin = pens[groups[j]]
					fmin = -1
					for i in XN
						if dist[j][i] < lmin
							lmin = dist[j][i]
							fmin = i
						end
					end
					assignmentN[j] = fmin
					costN += lmin
				else
					if dist[j][fin] < dist[j][assignment0[j]]
						assignmentN[j] = fin
						costN += dist[j][fin]
					else
						assignmentN[j] = assignment0[j]
						costN += dist[j][assignment0[j]]
					end
				end
			end
			if costN < cost0
				FXN = copy(FX0)
				deleteat!(FXN, fndp)
				push!(FXN, fout)
				return false, XN, FXN, assignmentN, costN
			end
		end
	end
	
	return true, X0, FX0, assignment0, cost0	
			
end

# ╔═╡ e52552b4-2075-4175-b993-cf8d603db9a9
function computeCost(assignment, C, groups)
	centers = Dict()
	census = copy(gC)
	cost = 0

	for i in C
		centers[i] = []
	end
	centers[-1] = []
	for j in 1:n
		i = assignment[j]
		push!(centers[i], j)
		if i != -1
			cost += dist[j][i]
			census[groups[j]] -= 1
		end
	end
	return centers, census, cost
end

# ╔═╡ d310f11b-2692-4ac7-b638-4ab1f20c0363
gam = 0.01

# ╔═╡ 7fea31c1-5dd1-4560-80f5-eb302caf5d95
function loopSearch(groups, guess, lG)
	pens = [guess/(l*gam) for l in lG]
	X, FX, assignment, cost = initLS(groups, pens)
	fl = false
	while !fl
		fl, X, FX, assignment, cost = localSearch(X, FX, assignment, cost, groups, pens)
	end
	return X, FX, assignment, cost
end

# ╔═╡ 5feff270-a727-4ece-8528-052a2589c406
function loopGuess(groups, lG)
	eps = size(lG)[1]/gam
	minCost = (n-sum(lG))*dmax
	minC = []
	minAssignment = Dict()
	if dmin > 0
		guess = (n-sum(lG))*dmin
	else
		guess = 1
	end

	while guess < (n-sum(lG))*dmax
		C, FC, assignment, cost = loopSearch(groups, guess, lG)
		if cost < minCost
			minCost = cost
			minC = C
			minAssignment = assignment
		end
		guess = guess*(1+eps)
	end
	return minC, minAssignment, minCost
end

# ╔═╡ ee5d9c91-0923-45dd-954b-c837a24e562d
function run()
	lG = [floor(l*0.2) for l in gC]
	outG = [sum(lG)]
	C, assignmentP, costP = loopGuess(groupsF, lG)
	grpsF, censF, costF = computeCost(assignmentP, C, groupsF)
	CO, assignmentPO, costPO = loopGuess(groupsO, outG)
	grpsO, censO, costO = computeCost(assignmentPO, CO, groupsO)
	return grpsO, grpsF, costO, costF, censO, censF
end

# ╔═╡ 98bfb941-d132-465c-8c0b-a25012a1550c
run()

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

julia_version = "1.11.1"
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
# ╠═579f62a0-6342-11f0-1049-df88128ea9f2
# ╠═00fc410f-c585-4a57-bb05-8593001a4daa
# ╠═aec87dc6-dc5d-4aa3-8c6e-e6af9bf6e991
# ╠═0f3e0470-55e0-4f39-80a7-672dc209c21d
# ╠═1a5d9599-154b-4569-a77d-ed0632dcbd73
# ╠═1b19fa25-ced9-4ccc-897b-1acf01d9dbf5
# ╠═c42ab94a-cc34-4256-b5eb-2316b68012a0
# ╠═c56042e7-4bda-4687-aa14-39695b2bcbf7
# ╠═f7f7fd8f-6801-4864-afe3-4d0e52c19c50
# ╠═7fea31c1-5dd1-4560-80f5-eb302caf5d95
# ╠═5feff270-a727-4ece-8528-052a2589c406
# ╠═e52552b4-2075-4175-b993-cf8d603db9a9
# ╠═ee5d9c91-0923-45dd-954b-c837a24e562d
# ╠═98bfb941-d132-465c-8c0b-a25012a1550c
# ╠═d310f11b-2692-4ac7-b638-4ab1f20c0363
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
