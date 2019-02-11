module TestJulex

using Distributed: nprocs
using Julex

Julex.execute(::Val{:echo}, params) = params

Julex.execute(::Val{:nprocs}, _) = nprocs()

end # module
