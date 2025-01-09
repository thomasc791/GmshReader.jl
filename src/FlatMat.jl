struct FlatMat{N} <: AbstractArray{Int,1}
  data::Vector{<:Integer}
  # TODO:
  # list has number of elements,
  # list has offsets [0, 3, 7]
  # list has data[0] data[nelems]
  # flatmat
  # implement getindex
  function FlatMat(vals::Vector{Vector{T}}) where {T}
    N = size(vals, 1)
    flattened = reduce(vcat, vals)
    A = Array{T,1}(undef, N + 1 + size(flattened, 1))
    A[1] = 1
    A[N+2:end] = flattened
    A[2:N+1] = accumulate(+, size(i, 1) for i in vals) .+ 1
    new{N}(A)
  end
end

Base.length(::FlatMat{N}) where {N} = N

Base.size(A::FlatMat{N}) where {N} = (N,)

function Base.getindex(A::FlatMat{N}, i::Int) where {N}
  @inline
  stride = A.data[i+1] - A.data[i]
  index = N + A.data[i]
  a = @view A.data[index+1:index+stride]
  @boundscheck checkbounds(A.data, index + stride)
  return a
end

function get_elem(A::FlatMat{N}, I::Int) where {N}
  startIndex = N + 2
  return A[startIndex]
end

IndexStyle(::Type{<:FlatMat}) = IndexLinear()
