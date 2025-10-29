# The function getbytes transforms the payload into a Vector representation of UInt8
@inline getbytes(in::String) = transcode(UInt8, in)
@inline getbytes(in::AbstractVector{UInt8}) = in
@inline getbytes(in::Number) = reinterpret(UInt8, [in])
@inline getbytes(in) = reinterpret(UInt8, in)
@inline getbytes(::Nothing) = UInt8[]
