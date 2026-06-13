module SymbolicaBackend

using Libdl

const _LIB = Ref{Ptr{Cvoid}}(C_NULL)

function __init__()
    ext = if Sys.isapple()
        "dylib"
    elseif Sys.islinux()
        "so"
    elseif Sys.iswindows()
        "dll"
    else
        error("Unsupported platform")
    end
    lib_path = joinpath(@__DIR__, "..", "rust", "target", "release", "libsymbolica_jl.$ext")
    if !isfile(lib_path)
        error(
            "Symbolica native library not found at $lib_path. " *
            "Run `Pkg.build(\"Symbolica\")` first.",
        )
    end
    _LIB[] = Libdl.dlopen(lib_path)
end

function _unsafe_string_and_free(ptr::Ptr{Cchar})
    s = unsafe_string(ptr)
    ccall(
        Libdl.dlsym(_LIB[], :symbolica_free_string),
        Cvoid,
        (Ptr{Cchar},),
        ptr,
    )
    return s
end

"""
    _call_expand(input::String) -> String
"""
function _call_expand(input::String)
    ptr = ccall(
        Libdl.dlsym(_LIB[], :symbolica_expand),
        Ptr{Cchar},
        (Cstring,),
        input,
    )
    return _unsafe_string_and_free(ptr)
end

"""
    _call_factor(input::String) -> String
"""
function _call_factor(input::String)
    ptr = ccall(
        Libdl.dlsym(_LIB[], :symbolica_factor),
        Ptr{Cchar},
        (Cstring,),
        input,
    )
    return _unsafe_string_and_free(ptr)
end

"""
    _call_simplify(input::String) -> String
"""
function _call_simplify(input::String)
    ptr = ccall(
        Libdl.dlsym(_LIB[], :symbolica_simplify),
        Ptr{Cchar},
        (Cstring,),
        input,
    )
    return _unsafe_string_and_free(ptr)
end

"""
    _call_derivative(input::String, var::String) -> String
"""
function _call_derivative(input::String, var::String)
    ptr = ccall(
        Libdl.dlsym(_LIB[], :symbolica_derivative),
        Ptr{Cchar},
        (Cstring, Cstring),
        input,
        var,
    )
    return _unsafe_string_and_free(ptr)
end

"""
    _call_substitute(input::String, var::String, replacement::String) -> String
"""
function _call_substitute(input::String, var::String, replacement::String)
    ptr = ccall(
        Libdl.dlsym(_LIB[], :symbolica_substitute),
        Ptr{Cchar},
        (Cstring, Cstring, Cstring),
        input,
        var,
        replacement,
    )
    return _unsafe_string_and_free(ptr)
end

end # module SymbolicaBackend
