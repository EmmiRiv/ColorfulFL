### A Pluto.jl notebook ###
# v0.20.3

using Markdown
using InteractiveUtils

# ╔═╡ ea5ddfa0-ef1f-11ef-145e-7fdd349465be
blah = 1

# ╔═╡ 0c934aa5-e8b3-4786-b5da-6b8dffa752fc
mutable struct City
	next
	color
	pos
	covered
end

# ╔═╡ 6d3b4247-78b3-482d-a7db-5c71805e591e
mutable struct Facility
	costOrig
	costActive
	closest
	cities
end

# ╔═╡ Cell order:
# ╠═ea5ddfa0-ef1f-11ef-145e-7fdd349465be
# ╠═0c934aa5-e8b3-4786-b5da-6b8dffa752fc
# ╠═6d3b4247-78b3-482d-a7db-5c71805e591e
