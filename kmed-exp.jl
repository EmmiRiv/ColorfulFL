### A Pluto.jl notebook ###
# v0.20.6

using Markdown
using InteractiveUtils

# ╔═╡ 8c7e18ba-5ad2-11f0-1618-e18a2c40d0ea
using Printf, CSV, Statistics

# ╔═╡ fb0aa260-a0e2-45ea-9cdc-88ce959aca8b
fC = CSV.File(open("subsets/adult-001-15.csv"))

# ╔═╡ 308bb617-1387-40a7-88de-e41b3e34efff
function l2(v1,v2)
	d = 0
	for i in 1:size(v1)[1]
		d += (v1[i]-v2[i])^2
	end
	return sqrt(d)
end

# ╔═╡ a462e641-2069-4052-a4e3-feaebe14e77c
function process()
	dist = []
	gC = [0,0]
	recallID = Dict()
	groupsF = Dict()
	groupsO = Dict()

	jind = 0
	for rwj in fC
		jind += 1
		recallID[jind] = rwj.id
		jdist = []
		jpos = [rwj.d1, rwj.d2, rwj.d3, rwj.d4, rwj.d5, rwj.d6]
		for rwj2 in fC
			j2pos = [rwj2.d1, rwj2.d2, rwj2.d3, rwj2.d4, rwj2.d5, rwj2.d6]
			push!(jdist, l2(jpos, j2pos))
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
	return dist, jind, gC, recallID, groupsF, groupsO
end

# ╔═╡ f045c84e-c8af-49fb-9d70-06c058d6e61a
gam = 2

# ╔═╡ a5ff97b1-f4f0-46eb-88c8-4f095f505b2e
k = 7

# ╔═╡ 49c20a64-ac9b-44d9-aeec-0428663eab5c
dist, n, gC, recallID, groupsF, groupsO = process()

# ╔═╡ 39e32c4a-40b5-4713-8f21-f855959b0001
function findStats()
	qs = [h/10 for h in 0:10]
	dta = []
	for j in 1:n
		append!(dta,dist[j][j+1:n])
	end
	return quantile(dta, qs)
end

# ╔═╡ c1203d1d-c49e-44b2-9afb-00828bdb44a2
quants = findStats()

# ╔═╡ 7b28d394-b759-4f69-ace6-60d03e6bf900
om = size(gC)[1]

# ╔═╡ 7895cb7b-0f01-4642-944e-a3482a2a0f36
"""
50 coverage
[18.0, 7.0][25.0]
12.388676 fair cost
12.251621 outlier cost
[18.0, 7.0][17.0, 8.0]

55 coverage
[16.0, 6.0][22.0]
14.975955 fair cost
16.115001 outlier cost
[16.0, 6.0][17.0, 5.0]

60 coverage
[14.0, 5.0][19.0]
24.057986 fair cost
18.897474 outlier cost
[14.0, 5.0][13.0, 6.0]

65 coverage
[12.0, 4.0][16.0]
24.788051 fair cost
24.617221 outlier cost
[12.0, 4.0][12.0, 4.0]

70 coverage
[10.0, 4.0][14.0]
27.911066 fair cost
26.528883 outlier cost
[10.0, 4.0][9.0, 5.0]

75 coverage
[9.0, 3.0][12.0]
35.637462 fair cost
30.808123 outlier cost
[9.0, 3.0][7.0, 5.0]

80 coverage
[7.0, 2.0][9.0]
42.591117 fair cost
34.093969 outlier cost
[7.0, 2.0][4.0, 5.0]

85 coverage
[5.0, 2.0][7.0]
42.390802 fair cost
38.177108 outlier cost
[5.0, 2.0][5.0, 2.0]

90 coverage
[3.0, 1.0][4.0]
48.772820 fair cost
44.254931 outlier cost
[3.0, 1.0][3.0, 1.0]

95 coverage
[1.0, 0.0][1.0]
60.459227 fair cost
52.970004 outlier cost
[1.0, 0.0][1.0, 0.0]

100 coverage
[0.0, 0.0][0.0]
64.720403 fair cost
63.473375 outlier cost
[0.0, 0.0][0.0, 0.0]
"""

# ╔═╡ baf87245-01cb-4554-b84f-f6cd8f35e429
function takeCensus(status)	
	cen = zeros(om)	
	for j in 1:n		
		if status[j] == 2
			cen[groupsF[j]] += 1		
		end	
	end	
	return cen
end

# ╔═╡ 6bdf13c6-9add-4adc-8712-4a94369ac94b
function makeTimeline()
	tl = []
	for j in 1:n
		for i in j:n
			push!(tl, [j,i])
		end
	end
	sort!(tl, by = x -> dist[x[1]][x[2]])
	return tl
end

# ╔═╡ b98ffbfb-f2b7-4258-845a-dc57fbeb51ab
timeline = makeTimeline() #1<=2

# ╔═╡ ee621eae-1fed-48fa-8138-51e2dc4e5b70
function openFac(i0, isOpen, contributors, cities, status, fCost, pens, groups)
	isOpen[i0] = true
	for j in contributors[i0]
		if status[j] == 2 || (status[j] == 1 && pens[groups[j]] >= dist[j][i0])
			status[j] = 3
			push!(cities[i0], j)
		end
	end
end

# ╔═╡ ed0a737a-d053-48ad-8b3b-5d1b50d9ec5f
function event(i0, j0, isOpen, contributors, cities, status, fCost, pens, groups)
	t = dist[j0][i0]
	
	if status[j0] == 2 && pens[groups[j0]] <= t
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
				openFac(i, isOpen, contributors, cities, status, fCost, pens, groups)
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
function increment(fCost, pens, groups)
	isOpen = Dict()
	contributors = Dict()
	cities = Dict()
	status = Dict()
	for j in 1:n
		isOpen[j] = false
		contributors[j] = []
		cities[j] = []
		status[j] = 2
	end
	for e in timeline
		done = event(e[2],e[1], isOpen, contributors, cities, status, fCost, pens, groups) 
		if done
			break
		end
		done = event(e[1],e[2], isOpen, contributors, cities, status, fCost, pens, groups) 
		if done
			break
		end
	end
	return cities
end

# ╔═╡ e78cfe68-e013-4726-818b-b012859091e9
function computeCost(cities, fCost)
	cost = 0
	cens = []
	for i in 1:n
		if size(cities[i])[1] != 0
			cost += fCost
			push!(cens, i)
			for j in cities[i]
				cost += dist[j][i]
			end
		end
	end
	return cost, cens
end

# ╔═╡ 822d7306-6273-417f-8aca-61adb450c87e
function k1k2(pens, groups)
	mIts = 1
	eps = maximum(pens)

	#initialize
	low = 0
	high = maximum(pens) + quants[11] #opening a facility is as expensive as paying the highest penalty and connecting the farthest points, so paying all penalties is better
	censL = [j for j in 1:n]
	kL = n
	costL = 0
	if kL == k
		return true, 0, censL
	end
	finalH = increment(high, pens, groups)
	costH, censH = computeCost(finalH, high)
	kH = size(censH)[1]
	if kH == k
		return true, 0, censH
	end

	#averaging loop
	for _ in 1:mIts
		mid = (low+high)/2
		finalM = increment(mid, pens, groups)
		costM, censM = computeCost(finalM, mid)
		kM = size(censM)[1]

		if kM < k
			if abs(costM-costH) < eps
				return false, censL, censM
			else
				high = mid
				censH = censM
			end
		elseif kM > k
			if abs(costM-costL) < eps
				return false, censM, censH
			else
				low = mid
				censL = censM
			end
		else 
			return true, costM, censM
		end
	end
	return false, censL, censH
			
end

# ╔═╡ 11791b86-e878-483d-9541-92a975e9589b
function findBpr(A, B)
	Bpr = []
	BminBpr = copy(B)

	for c in A
		distC = dist[c]
		mn = quants[11]+1
		mni = -1
		for i in B
			if distC[i] < mn
				mn = distC[i]
				mni = i
			end
		end
		if !in(mni, Bpr)
			append!(Bpr, mni)
			deleteat!(BminBpr, findall(x->x==mni, BminBpr))
		end
	end

	while size(Bpr)[1] < size(A)[1]
		ind = rand(1:size(BminBpr)[1])
		if !in(BminBpr[ind], Bpr)
			push!(Bpr, BminBpr[ind])
			deleteat!(BminBpr, ind)
		end
	end
	return Bpr, BminBpr
			
end

# ╔═╡ c5730edc-3c52-46ee-bfd4-5df284f66cd4
function findCenters(pens, groups)
	fl, B, A = k1k2(pens, groups)

	if fl
		return A
	end
	
	a = (size(B)[1]-k)/(size(B)[1]-size(A)[1])
	b = (k-size(A)[1])/(size(B)[1]-size(A)[1])
	Bpr, BminBpr = findBpr(A, B)

	if rand()<a
		C = A
	else
		C = Bpr
	end
	while size(C)[1] < k
		c = rand(BminBpr)
		if !in(c, C)
			push!(C, c)
		end
	end

	
	return C
end

# ╔═╡ 3ab1084a-e304-4cb2-8d02-cc2c5f49307b
function assign(C, groups, cG)
	oC = zeros(size(cG)[1])
	st = Dict()
	ct = Dict()
	cost = 0
	for j in 1:n
		st[j] = 2
	end
	for c in C
		ct[c] = []
	end
	tl = []
	for j in 1:n
		for i in C
			push!(tl, [j,i])
		end
	end
	sort!(tl, by = x -> dist[x[1]][x[2]])
	
	for e in tl
		cen = e[2]
		cli = e[1]
		if st[cli] == 2
			st[cli] = 3
			push!(ct[cen], cli)
			oC[groups[cli]] += 1
			cost += dist[cen][cli]
		end
		if oC == cG
			break
		end
	end	
	return st, ct, cost
end

# ╔═╡ 0b267dab-823f-4987-96ef-c40552e97a70
function loopOPT(groups, oG, cG)
	eps = om/gam
	guess = 1
	maxG = quants[11]*(n-sum(oG))
	minC = maxG
	minF = Dict()
	minS = Dict()

	while guess < maxG
		pens = [guess/(gam*l) for l in oG]
		cens = findCenters(pens, groups)
		st, final, cst = assign(cens, groups, cG)
		if cst < minC
			minC = cst
			minF = final
			minS = st
		end
		guess = guess*(1+eps)
	end
	return minC, minF, minS
	
end

# ╔═╡ 5076c2ae-5d03-4059-adfc-72a6c8ece3a8
function changeCoverage()
	pct = 50
	while pct<=100
		oG = [floor(((100-pct)/100)*l) for l in gC]
		cG = [gC[i]-oG[i] for i in 1:om]
		outL = [sum(oG)]
		outC = [n-outL[1]]
		fC, fF, fS = loopOPT(groupsF, oG, cG)
		oC, oF, oS = loopOPT(groupsO, outL, outC)
		fCen = takeCensus(fS)
		oCen = takeCensus(oS)
		@printf("%d coverage\n", pct)
		print(oG,outL,"\n")
		@printf("%f fair cost\n", fC)
		@printf("%f outlier cost\n", oC)
		print(fCen, oCen)
		print("\n\n")
		pct += 5
	end
end

# ╔═╡ 2554c16d-c9d8-4540-b5a3-2cc7fcf40388
changeCoverage()

# ╔═╡ c50e3887-d801-4a69-9cb1-b238186d4614
function hm()
	pct = 60
	oG = [trunc(((100-pct)/100)*l) for l in gC]
	cG = [gC[i]-oG[i] for i in 1:om]
	outL = [sum(oG)]
	outC = [n-outL[1]]
	fC, fF, fS = loopOPT(groupsF, oG, cG)
	oC, oF, oS = loopOPT(groupsO, outL, outC)
	fCen = takeCensus(fS)
	oCen = takeCensus(oS)
	@printf("%d coverage\n", pct)
	print(oG,outL,"\n")
	@printf("%f fair cost\n", fC)
	@printf("%f outlier cost\n", oC)
	print(fCen, oCen)
	return fS, fF
end

# ╔═╡ 6d04a139-7b4c-4bea-bf29-623f733b5d9c
hm()

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
Printf = "de0858da-6303-5e67-8744-51eddeeeb8d7"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[compat]
CSV = "~0.10.15"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.5"
manifest_format = "2.0"
project_hash = "76a80bec1fbbf6c69dd4073c8e0ba34cc9409bc6"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

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
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

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

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.11.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.27+1"

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

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

    [deps.Statistics.weakdeps]
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

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

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"
"""

# ╔═╡ Cell order:
# ╠═8c7e18ba-5ad2-11f0-1618-e18a2c40d0ea
# ╠═fb0aa260-a0e2-45ea-9cdc-88ce959aca8b
# ╠═a462e641-2069-4052-a4e3-feaebe14e77c
# ╠═308bb617-1387-40a7-88de-e41b3e34efff
# ╠═39e32c4a-40b5-4713-8f21-f855959b0001
# ╠═c1203d1d-c49e-44b2-9afb-00828bdb44a2
# ╠═f045c84e-c8af-49fb-9d70-06c058d6e61a
# ╠═a5ff97b1-f4f0-46eb-88c8-4f095f505b2e
# ╠═49c20a64-ac9b-44d9-aeec-0428663eab5c
# ╠═7b28d394-b759-4f69-ace6-60d03e6bf900
# ╠═b98ffbfb-f2b7-4258-845a-dc57fbeb51ab
# ╠═2554c16d-c9d8-4540-b5a3-2cc7fcf40388
# ╠═7895cb7b-0f01-4642-944e-a3482a2a0f36
# ╠═5076c2ae-5d03-4059-adfc-72a6c8ece3a8
# ╠═c50e3887-d801-4a69-9cb1-b238186d4614
# ╠═6d04a139-7b4c-4bea-bf29-623f733b5d9c
# ╠═baf87245-01cb-4554-b84f-f6cd8f35e429
# ╠═6bdf13c6-9add-4adc-8712-4a94369ac94b
# ╠═71f14388-f41f-4369-af47-b4fe33afe6ce
# ╠═ed0a737a-d053-48ad-8b3b-5d1b50d9ec5f
# ╠═ee621eae-1fed-48fa-8138-51e2dc4e5b70
# ╠═e78cfe68-e013-4726-818b-b012859091e9
# ╠═822d7306-6273-417f-8aca-61adb450c87e
# ╠═11791b86-e878-483d-9541-92a975e9589b
# ╠═c5730edc-3c52-46ee-bfd4-5df284f66cd4
# ╠═3ab1084a-e304-4cb2-8d02-cc2c5f49307b
# ╠═0b267dab-823f-4987-96ef-c40552e97a70
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
