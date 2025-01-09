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

  function FlatMat{N}(vals::Vector{<:Int}) where {N}
    new{N}(vals)
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

function Base.getindex(A::FlatMat{N}, u::UnitRange) where {N}
  @inline
  i_start = u.start
  i_stop = u.stop
  stride = A.data[i_stop+1] - A.data[i_start]
  i = N + A.data[i_start]
  indices = view(A.data, i_start:i_stop+1) .- A.data[i_start] .+ 1
  a = vcat(indices, @view A.data[i+1:i+stride])
  @boundscheck checkbounds(A.data, i + stride)
  return FlatMat{length(u)}(a)
end

Base.setindex!(A::FlatMat{N}, v::Int, i::Int) where {N} = A

IndexStyle(::Type{<:FlatMat}) = IndexLinear()
