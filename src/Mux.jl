module Mux

export mux, stack, branch

# This might be the smallest core ever.

mux(f) = f

function mux(m, f)
	apply_mux(x) = m(f, x)
	return apply_mux
end

mux(ms...) = foldr(mux, ms)

stack(m) = m
function stack(m, n) 
	apply_stack(f, x) = m(mux(n, f), x)
	return apply_stack
end
stack(ms...) = foldl(stack, ms)

function branch(p, t) 
	function branch_check(f, x) 
		(p(x) ? t : f)(x)
	end
end

function branch(p, t...) 
	branch(p, mux(t...))
end

# May as well provide a few conveniences, though.

using Hiccup

include("server.jl")
include("basics.jl")
include("routing.jl")

include("websockets_integration.jl")

include("examples/basic.jl")
include("examples/files.jl")

defaults = stack(todict, basiccatch, splitquery, toresponse)
wdefaults = stack(todict, wcatch, splitquery)

end
