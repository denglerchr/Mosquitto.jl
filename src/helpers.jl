getbytes(in::String) = transcode(UInt8, in)
getbytes(in::AbstractVector{UInt8}) = in
getbytes(in) = reinterpret(UInt8, in)