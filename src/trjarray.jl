import Base: convert, copy, length, show, getindex, start, next, done, isempty,
             endof, size, eachindex, ==, isequal, hash

abstract type AbstractTrajectory end

struct TrjArray <: AbstractTrajectory

    #TODO: support for x, y, z = nothing, nothing, nothing
    #TODO: natom, nframe
    #TODO: revert to parametric type
    x::Union{Matrix{Float64}, Nothing}
    y::Union{Matrix{Float64}, Nothing}
    z::Union{Matrix{Float64}, Nothing}
    chainname::Union{Vector{String}, Nothing}
    chainid::Union{Vector{Int64}, Nothing}
    resname::Union{Vector{String}, Nothing}
    resid::Union{Vector{Int64}, Nothing}
    atomname::Union{Vector{String}, Nothing}
    atomid::Union{Vector{Int64}, Nothing}
    boxsize::Union{Matrix{Float64}, Nothing}
    mass::Union{Vector{Float64}, Nothing}
    charge::Union{Vector{Float64}, Nothing}
    # bond::Union{Matrix{Int64}, Nothing}
    # angle::Union{Matrix{Int64}, Nothing}
    # dihedral::Union{Matrix{Int64}, Nothing}
    meta::Any

    function TrjArray(
            x::Union{Matrix{T}, Nothing}, 
            y::Union{Matrix{T}, Nothing}, 
            z::Union{Matrix{T}, Nothing}, 
            chainname::Union{Vector{S}, Nothing}, 
            chainid::Union{Vector{I}, Nothing}, 
            resname::Union{Vector{S}, Nothing}, 
            resid::Union{Vector{I}, Nothing}, 
            atomname::Union{Vector{S}, Nothing}, 
            atomid::Union{Vector{I}, Nothing}, 
            boxsize::Union{Matrix{F}, Nothing}, 
            mass::Union{Matrix{F}, Nothing}, 
            charge::Union{Matrix{F}, Nothing}, 
            meta::Any) where {T <: Real, S <: AbstractString, I <: Integer, F <: Real}

        # nrow, ncol = (size(trj, 1), size(trj, 2))
        # natom = Int64(ncol/3)
        #@show natom
        # ischecked && return new(trj, atomname, atomid, meta)
        # natom != length(chainname) && throw(DimensionMismatch("chainname must match width of trajectory"))
        # natom != length(chainid) && throw(DimensionMismatch("chainid must match width of trajectory"))

        x2 = x == nothing ? nothing : map(Float64, x)
        y2 = y == nothing ? nothing : map(Float64, y)
        z2 = z == nothing ? nothing : map(Float64, z)
        chainname2 = chainname == nothing ? nothing : map(strip, map(string, chainname))
        chainid2 = chainid == nothing ? nothing : map(Int64, chainid)
        resname2 = resname == nothing ? nothing : map(strip, map(string, resname))
        resid2 = resid == nothing ? nothing : map(Int64, resid)
        atomname2 = atomname == nothing ? nothing : map(strip, map(string, atomname))
        atomid2 = atomid == nothing ? nothing : map(Int64, atomid)
        boxsize2 = boxsize == nothing ? nothing : map(Float64, boxsize)
        mass2 = mass == nothing ? nothing : map(Float64, mass)
        charge2 = charge == nothing ? nothing : map(Float64, charge)

        return new(x2, y2, z2, chainname2, chainid2, resname2, resid2, atomname2, atomid2, boxsize2, mass2, charge2, meta)
    end
end

###### outer constructors ########

TrjArray(;x = x::Matrix{T},
         y = y::Matrix{T},
         z = z::Matrix{T}, 
         chainname = nothing, 
         chainid = nothing, 
         resname = nothing, 
         resid = nothing, 
         atomname = nothing, 
         atomid = nothing, 
         boxsize = nothing, 
         mass = nothing, 
         charge = nothing, 
         meta = nothing) where {T <: Real} =
             TrjArray(x, y, z, chainname, chainid, resname, resid, atomname, atomid, boxsize, mass, charge, meta)

TrjArray(x::Matrix{T}, y::Matrix{T}, z::Matrix{T}, ta::TrjArray) where {T <: Real} =
             TrjArray(x = x, y = y, z = z, 
                      chainname = ta.chainname,
                      chainid = ta.chainid,
                      resname = ta.resname,
                      resid = ta.resid,
                      atomname = ta.atomname,
                      atomid = ta.atomid,
                      boxsize = ta.boxsize,
                      mass = ta.mass,
                      charge = ta.charge,
                      meta = ta.meta)

###### getindex #################

# all element indexing
getindex(ta::TrjArray, ::Colon) = ta
getindex(ta::TrjArray, ::Colon, ::Colon) = ta

# single row
getindex(ta::TrjArray, n::Int) = TrjArray(ta.x[n:n, :], ta.y[n:n, :], ta.z[n:n, :], ta)
getindex(ta::TrjArray, n::Int, ::Colon) = getindex(ta, n)

# range of rows
getindex(ta::TrjArray, r::UnitRange{Int}) = TrjArray(ta.x[r, :], ta.y[r, :], ta.z[r, :], ta)
getindex(ta::TrjArray, r::UnitRange{Int}, ::Colon) = getindex(ta, r)

# array of rows (integer)
getindex(ta::TrjArray, a::AbstractVector{S}) where {S <: Integer} = TrjArray(ta.x[a, :], ta.y[a, :], ta.z[a, :], ta)
getindex(ta::TrjArray, a::AbstractVector{S}, ::Colon) where {S <: Integer} = getindex(ta, a)

# array of rows (bool)
#getindex(ta::TrjArray, a::AbstractVector{S}) where {S <: Bool} = TrjArray(ta.x[a, :], ta.y[a, :], ta.z[a, :], ta)
#getindex(ta::TrjArray, a::AbstractVector{S}, ::Colon) where {S <: Bool} = getindex(ta, a)
getindex(ta::TrjArray, a::AbstractVector{Bool}) = TrjArray(ta.x[a, :], ta.y[a, :], ta.z[a, :], ta)
getindex(ta::TrjArray, a::AbstractVector{Bool}, ::Colon) = getindex(ta, a)

# single column
getindex(ta::TrjArray, ::Colon, n::Int) = TrjArray(x = ta.x[:, n:n], y = ta.y[:, n:n], z = ta.z[:, n:n],
             chainname = ta.chainname == nothing ? nothing : ta.chainname[n:n], 
             chainid = ta.chainid == nothing ? nothing : ta.chainid[n:n], 
             resname = ta.resname == nothing ? nothing : ta.resname[n:n], 
             resid = ta.resid == nothing ? nothing : ta.resid[n:n], 
             atomname = ta.atomname == nothing ? nothing : ta.atomname[n:n], 
             atomid = ta.atomid == nothing ? nothing : ta.atomid[n:n], 
             boxsize = ta.boxsize, 
             mass = ta.mass == nothing ? nothing : ta.mass[n:n], 
             charge = ta.charge == nothing ? nothing : ta.charge[n:n], 
             meta = ta.meta)

# range of columns
getindex(ta::TrjArray, ::Colon, r::UnitRange{Int}) = TrjArray(x = ta.x[:, r], y = ta.y[:, r], z = ta.z[:, r],
             chainname = ta.chainname == nothing ? nothing : ta.chainname[r], 
             chainid = ta.chainid == nothing ? nothing : ta.chainid[r], 
             resname = ta.resname == nothing ? nothing : ta.resname[r], 
             resid = ta.resid == nothing ? nothing : ta.resid[r], 
             atomname = ta.atomname == nothing ? nothing : ta.atomname[r], 
             atomid = ta.atomid == nothing ? nothing : ta.atomid[r], 
             boxsize = ta.boxsize, 
             mass = ta.mass == nothing ? nothing : ta.mass[r], 
             charge = ta.charge == nothing ? nothing : ta.charge[r], 
             meta = ta.meta)

# array of columns (integer)
getindex(ta::TrjArray, ::Colon, r::AbstractVector{S}) where {S <: Integer} = TrjArray(x = ta.x[:, r], y = ta.y[:, r], z = ta.z[:, r],
             chainname = ta.chainname == nothing ? nothing : ta.chainname[r], 
             chainid = ta.chainid == nothing ? nothing : ta.chainid[r], 
             resname = ta.resname == nothing ? nothing : ta.resname[r], 
             resid = ta.resid == nothing ? nothing : ta.resid[r], 
             atomname = ta.atomname == nothing ? nothing : ta.atomname[r], 
             atomid = ta.atomid == nothing ? nothing : ta.atomid[r], 
             boxsize = ta.boxsize, 
             mass = ta.mass == nothing ? nothing : ta.mass[r], 
             charge = ta.charge == nothing ? nothing : ta.charge[r], 
             meta = ta.meta)

# array of rows (bool)
getindex(ta::TrjArray, ::Colon, r::AbstractVector{Bool}) = TrjArray(x = ta.x[:, r], y = ta.y[:, r], z = ta.z[:, r],
             chainname = ta.chainname == nothing ? nothing : ta.chainname[r], 
             chainid = ta.chainid == nothing ? nothing : ta.chainid[r], 
             resname = ta.resname == nothing ? nothing : ta.resname[r], 
             resid = ta.resid == nothing ? nothing : ta.resid[r], 
             atomname = ta.atomname == nothing ? nothing : ta.atomname[r], 
             atomid = ta.atomid == nothing ? nothing : ta.atomid[r], 
             boxsize = ta.boxsize, 
             mass = ta.mass == nothing ? nothing : ta.mass[r], 
             charge = ta.charge == nothing ? nothing : ta.charge[r], 
             meta = ta.meta)

# combinations
getindex(ta::TrjArray, rows, cols) = ta[rows, :][:, cols]

###### atom selection #################

function unfold(A)
    V = []
    if typeof(A) <: AbstractString
        push!(V, A)
    else
        for x in A
            if x === A
                push!(V, x)
            else
                append!(V, unfold(x))
            end
        end
    end
    V
end

function match_query(some_array, query)
    natom = length(some_array)
    index = fill(false, natom)
    if some_array == Nothing
        return index
    elseif typeof(some_array[1]) == String
        query = split(query)
    else
        query = Meta.eval(Meta.parse(replace("[" * query * "]", r"(\d)\s" => s"\1, ")))
    end
    query = unique(unfold(query))
    for q in query
        index = index .| (some_array .== q) # conversion occurs because Vector{Bool} .| BitArray{1}
    end
    index
end

function replace_ex!(ex::Expr)
    for (i, arg) in enumerate(ex.args)
        if arg == :(match_query)
            ex.args[i] = :($match_query)
        end
        if isa(arg, Expr)
            replace_ex!(arg)
        end
    end
    ex
end

function getindex(ta::TrjArray, s::AbstractString)
    s_init = s
    s = strip(s)
    s = replace(s, "chainid" => "match_query($(ta.chainid), \" ")
    s = replace(s, "chainname" => "match_query($(ta.chainname), \" ")
    s = replace(s, "resid" => "match_query($(ta.resid), \" ")
    s = replace(s, "resname" => "match_query($(ta.resname), \" ")
    s = replace(s, "atomid" => "match_query($(ta.atomid), \" ")
    s = replace(s, "atomname" => "match_query($(ta.atomname), \" ")

    s = replace(s, r"\)(\s+)and" => "\" ) ) .& ")
    s = replace(s, r"([^\)])(\s+)and" => s"\1 \" ) .& ")
    s = replace(s, r"\)(\s+)or" => "\" ) ) .| ")
    s = replace(s, r"([^\)])(\s+)or" => s"\1 \" ) .| ")

    if s[end] == ')'
        s = s[1:end-1] * " \" ) )"
    elseif s[end-length("all")+1:end] != "all" && s[end-length("backbone")+1:end] != "backbone"
        s = s * " \" )"
    end

    #println(s)
    ex = Meta.parse(s)
    replace_ex!(ex)
    index = Meta.eval(ex)
    #println(index')
    ta[:, index]
end

# combinations
getindex(ta::TrjArray, ::Colon, s::AbstractString) = getindex(ta, s)
getindex(ta::TrjArray, rows, s::AbstractString) = ta[rows, :][:, s]

###### accessors to field values #################

###### merge #################

# vertical merge
# horizontal merge

###### end keyword #################

endof(ta::TrjArray) = ta.x == nothing ? nothing : size(ta.x, 1)
eachindex(ta::TrjArray) = Base.OneTo(size(ta.x, 1))

###### iterator #################

###### conversion #################

# conversion(Float64, ta:TrjArray)

###### mathematical operators #################

###### show #####################

function alignment_xyz(io::IO, X::AbstractVecOrMat,
        rows::AbstractVector, cols::AbstractVector,
        cols_if_complete::Integer, cols_otherwise::Integer, sep::Integer)
    a = Tuple{Int, Int}[]
    for j in cols
        l = 14
        r = 13
        push!(a, (l, r))
        if length(a) > 1 && sum(map(sum,a)) + sep*length(a) >= cols_if_complete
            pop!(a) 
            break
        end
    end
    if 1 < length(a) < length(axes(X,2))
        while sum(map(sum,a)) + sep*length(a) >= cols_otherwise
            pop!(a)
        end
    end
    return a
end


function print_matrix_xyz(io::IO,
        X::AbstractVecOrMat, Y::AbstractVecOrMat, Z::AbstractVecOrMat,
        columnwidth::Vector,
        i::Integer, cols::AbstractVector, sep::AbstractString)
    for (k, j) = enumerate(cols)
        k > length(columnwidth) && break
        # if X[i,j] < 10^6 && X[i,j] > -10^5
        #     print_x = Printf.@sprintf " %8.2f" X[i,j]
        # else
        #     print_x = Printf.@sprintf " %8.2e" X[i,j]
        # end
        # TODO: treatment for very large or small values
        print_x = Printf.@sprintf " %8.2f" X[i,j]
        print_y = Printf.@sprintf " %8.2f" Y[i,j]
        print_z = Printf.@sprintf " %8.2f" Z[i,j]
        print(io, print_x, print_y, print_z, sep) # 27 characters + sep
        #if k < length(columnwidth); print(io, sep); end
    end
end

function string_column(x, y, j)
    if x == nothing
        string_x = ""
    else
        string_x = string(x[j])
    end
    if y == nothing
        string_y = ""
    else
        string_y = string(y[j])
    end
    s = " " * string_x * string_y
    if length(s) > 24
        s = " " * s[1:24] * "~" * " "
    else
        s = rpad(s, 27)
    end
    s
end

function print_column(io::IO,
                      x, y, columnwidth::Vector, cols::AbstractVector,
                      sep::AbstractString)
    for (k, j) = enumerate(cols)
        k > length(columnwidth) && break
        s = string_column(x, y, j)
        print(io, s, sep) # 27 characters + sep
    end
end


function print_matrix_vdots(io::IO, vdots::AbstractString,
        A::Vector, sep::AbstractString)
    for k = 1:length(A)
        w = A[k][1] + A[k][2]
        l = repeat(" ", max(0, A[k][1]-length(vdots)))
        r = repeat(" ", max(0, w-length(vdots)-length(l)))
        print(io, l, vdots, r)
        if k <= length(A); print(io, sep); end
    end
end


function show(io::IO, ta::TrjArray)
    pre = "|"  # pre-matrix string
    sep = " |" # separator between elements
    post = ""  # post-matrix string
    hdots = "  \u2026  "
    vdots = "\u22ee"
    ddots = "  \u22f1  "
    hmod = 5

    # summary line
    nrow, ncol = (size(ta.x, 1), size(ta.x, 2))
    @printf(io, "%dx%d %s\n", nrow, ncol, typeof(ta))

    X = ta.x
    Y = ta.y
    Z = ta.z

    sz = displaysize(io)
    screenheight, screenwidth = sz[1] - 4, sz[2]
    screenwidth -= length(pre)

    if ta.chainid != nothing || ta.chainname != nothing
        screenheight -= 1
    end

    if ta.resid != nothing || ta.resname != nothing
        screenheight -= 1
    end

    if ta.chainid != nothing || ta.chainname != nothing
        screenheight -= 1
    end

    @assert textwidth(hdots) == textwidth(ddots)
    
    rowsA, colsA = UnitRange(axes(X,1)), UnitRange(axes(X,2))
    m, n = length(rowsA), length(colsA)

    # To figure out alignments, only need to look at as many rows as could
    # fit down screen. If screen has at least as many rows as A, look at A.
    # If not, then we only need to look at the first and last chunks of A,
    # each half a screen height in size.
    halfheight = div(screenheight,2)
    if m > screenheight
        rowsA = [rowsA[(0:halfheight-1) .+ firstindex(rowsA)]; rowsA[(end-div(screenheight-1,2)+1):end]]
    end
    # Similarly for columns, only necessary to get alignments for as many
    # columns as could conceivably fit across the screen
    maxpossiblecols = div(screenwidth, 3+length(sep))
    if n > maxpossiblecols
        colsA = [colsA[(1:maxpossiblecols)]; colsA[(end-maxpossiblecols+1):end]]
    end
    columnwidth = alignment_xyz(io, X, rowsA, colsA, screenwidth, screenwidth, length(sep))

    # Nine-slicing is accomplished using print_matrix_row repeatedly
    if n <= length(columnwidth) # rows and cols fit so just print whole matrix in one piece
        if ta.chainid != nothing || ta.chainname != nothing
            print(io, pre)
            print_column(io, ta.chainid, ta.chainname, columnwidth, colsA, sep)
            println(io)
        end
        if ta.resid != nothing || ta.resname != nothing
            print(io, pre)
            print_column(io, ta.resid, ta.resname, columnwidth, colsA, sep)
            println(io)
        end
        if ta.atomid != nothing || ta.atomname != nothing
            print(io, pre)
            print_column(io, ta.atomid, ta.atomname, columnwidth, colsA, sep)
            println(io)
        end
    else # rows fit down screen but cols don't, so need horizontal ellipsis
        c = div(screenwidth-length(hdots)+1,2)+1  # what goes to right of ellipsis
        Rcolumnwidth = reverse(alignment_xyz(io, X, rowsA, reverse(colsA), c, c, length(sep))) # alignments for right
        c = screenwidth - sum(map(sum,Rcolumnwidth)) - (length(Rcolumnwidth)-1)*length(sep) - length(hdots)
        Lcolumwidth = alignment_xyz(io, X, rowsA, colsA, c, c, length(sep)) # alignments for left of ellipsis
        if ta.chainid != nothing || ta.chainname != nothing
            print(io, pre)
            #print_matrix_xyz(io, X, Y, Z, Lcolumwidth, i, colsA[1:length(Lcolumwidth)], sep)
            print_column(io, ta.chainid, ta.chainname, Lcolumwidth, colsA[1:length(Lcolumwidth)], sep)
            print(io, hdots)
            #print_matrix_xyz(io, X, Y, Z, Rcolumnwidth, i, (n - length(Rcolumnwidth)) .+ colsA, sep)
            print_column(io, ta.chainid, ta.chainname, Rcolumnwidth, (n - length(Rcolumnwidth)) .+ colsA, sep)
            println(io)
        end
        if ta.resid != nothing || ta.resname != nothing
            print(io, pre)
            #print_matrix_xyz(io, X, Y, Z, Lcolumwidth, i, colsA[1:length(Lcolumwidth)], sep)
            print_column(io, ta.resid, ta.resname, Lcolumwidth, colsA[1:length(Lcolumwidth)], sep)
            print(io, hdots)
            #print_matrix_xyz(io, X, Y, Z, Rcolumnwidth, i, (n - length(Rcolumnwidth)) .+ colsA, sep)
            print_column(io, ta.resid, ta.resname, Rcolumnwidth, (n - length(Rcolumnwidth)) .+ colsA, sep)
            println(io)
        end
        if ta.atomid != nothing || ta.atomname != nothing
            print(io, pre)
            #print_matrix_xyz(io, X, Y, Z, Lcolumwidth, i, colsA[1:length(Lcolumwidth)], sep)
            print_column(io, ta.atomid, ta.atomname, Lcolumwidth, colsA[1:length(Lcolumwidth)], sep)
            print(io, hdots)
            #print_matrix_xyz(io, X, Y, Z, Rcolumnwidth, i, (n - length(Rcolumnwidth)) .+ colsA, sep)
            print_column(io, ta.atomid, ta.atomname, Rcolumnwidth, (n - length(Rcolumnwidth)) .+ colsA, sep)
            println(io)
        end
    end
    
    if m <= screenheight # rows fit vertically on screen
        if n <= length(columnwidth) # rows and cols fit so just print whole matrix in one piece
            for i in rowsA
                print(io, pre)
                print_matrix_xyz(io, X, Y, Z, columnwidth, i, colsA, sep)
                if i != last(rowsA); println(io); end
            end
        else # rows fit down screen but cols don't, so need horizontal ellipsis
            c = div(screenwidth-length(hdots)+1,2)+1  # what goes to right of ellipsis
            Rcolumnwidth = reverse(alignment_xyz(io, X, rowsA, reverse(colsA), c, c, length(sep))) # alignments for right
            c = screenwidth - sum(map(sum,Rcolumnwidth)) - (length(Rcolumnwidth)-1)*length(sep) - length(hdots)
            Lcolumwidth = alignment_xyz(io, X, rowsA, colsA, c, c, length(sep)) # alignments for left of ellipsis
            for i in rowsA
                print(io, pre)
                print_matrix_xyz(io, X, Y, Z, Lcolumwidth, i, colsA[1:length(Lcolumwidth)], sep)
                print(io, (i - first(rowsA)) % hmod == 0 ? hdots : repeat(" ", length(hdots)))
                print_matrix_xyz(io, X, Y, Z, Rcolumnwidth, i, (n - length(Rcolumnwidth)) .+ colsA, sep)
                if i != last(rowsA); println(io); end
            end
        end
    else # rows don't fit so will need vertical ellipsis
        if n <= length(columnwidth) # rows don't fit, cols do, so only vertical ellipsis
            for i in rowsA
                print(io, pre)
                print_matrix_xyz(io, X, Y, Z, columnwidth, i, colsA, sep)
                if i != rowsA[end] || i == rowsA[halfheight]; println(io); end
                if i == rowsA[halfheight]
                    print(io, pre)
                    print_matrix_vdots(io, vdots, columnwidth, sep)
                    println(io)
                end
            end
        else # neither rows nor cols fit, so use all 3 kinds of dots
            c = div(screenwidth-length(hdots)+1,2)+1
            Rcolumnwidth = reverse(alignment_xyz(io, X, rowsA, reverse(colsA), c, c, length(sep)))
            c = screenwidth - sum(map(sum,Rcolumnwidth)) - (length(Rcolumnwidth)-1)*length(sep) - length(hdots)
            Lcolumwidth = alignment_xyz(io, X, rowsA, colsA, c, c, length(sep))
            for i in rowsA
                print(io, pre)
                print_matrix_xyz(io, X, Y, Z, Lcolumwidth, i, colsA[1:length(Lcolumwidth)], sep)
                print(io, (i - first(rowsA)) % hmod == 0 ? hdots : repeat(" ", length(hdots)))
                print_matrix_xyz(io, X, Y, Z, Rcolumnwidth, i, (n-length(Rcolumnwidth)).+colsA, sep)
                if i != rowsA[end] || i == rowsA[halfheight]; println(io); end
                if i == rowsA[halfheight]
                    print(io, pre)
                    print_matrix_vdots(io, vdots, Lcolumwidth, sep)
                    print(io, ddots)
                    print_matrix_vdots(io, vdots, Rcolumnwidth, sep)
                    println(io)
                end
            end
        end
        if isempty(rowsA)
            print(io, vdots)
            length(colsA) > 1 && print(io, "    ", ddots)
            print(io, post)
        end
    end
end


