"""
    clusterkcenters(X::AbstractMatrix, kcluster::Int; nReplicates::Int=10) -> F

Perform clustering with K-center algorithm. Input data `X` should belong to AbstractMatrix type 
and its columns corresponds to variables, rows are frames. Also, the number of clusters `kcluster` should be specified. 
Returns a object `F` which contains the indices of cluster for each sample in `F.indexOfCluster`,
the coordinates of cluster centers in `F.center`, and distances of samples  from the nearest centers in `distanceFromCenter`.
    
#  Example
```julia-repl
julia> X = rand(1000, 2)
julia> F = clusterkcenters(X, 3)
julia> scatter(t[:, 1], t[:, 2], c = F.indexOfCluster)
```
# References
```
This function uses the method described in
[1] S. Dasgupta and P. M. Long, J. Comput. Syst. Sci. 70, 555 (2005).
[2] J. Sun, Y. Yao, X. Huang, V. Pande, G. Carlsson, and L. J. Guibas, Learning 24, 2 (2009).
```
"""
function clusterkcenters(t::AbstractMatrix, kcluster::Int; nReplicates::Int=10)
    nframe = size(t, 1)
    #ta2, com = decenter(ta)
    dim = size(t, 2)

    indexOfCenter = zeros(Int64, kcluster)
    indexOfCluster = zeros(Int64, nframe)
    distanceFromCenter = zeros(Float64, nframe, 1)

    indexOfCenter_out = similar(indexOfCenter)
    indexOfCluster_out = similar(indexOfCluster)
    distanceFromCenter_out = similar(distanceFromCenter)
    center_out = similar(t, kcluster, dim)
    distanceMax_out = Inf64

    for ireplica = 1:nReplicates
        # create the center of the 1st cluster
        indexOfCenter[1] = rand(1:nframe)
        # first, all points belong to the 1st cluster
        indexOfCluster .= ones(Int64, nframe)
        # distances of the points from the 1st center
        ref = t[indexOfCenter[1]:indexOfCenter[1], :]
        distanceFromCenter .= sum((ref .- t).^2, dims=2)

        for i = 2:kcluster
            indexOfCenter[i] = argmax(distanceFromCenter[:])
            ref = t[indexOfCenter[i]:indexOfCenter[i], :]
            dist = sum((ref .- t).^2, dims=2)
            index = dist[:] .< distanceFromCenter[:]
            if any(index)
                # updated if the dist to a new cluster is smaller than the previous one
                distanceFromCenter[index] .= dist[index]
                indexOfCluster[index] .= i
            end
        end

        distanceMax = maximum(distanceFromCenter)
        if (ireplica == 1) | (distanceMax < distanceMax_out)
          distanceMax_out = distanceMax
          indexOfCenter_out = indexOfCenter
          indexOfCluster_out = indexOfCluster
          center_out = t[indexOfCenter, :]
          distanceFromCenter_out .= distanceFromCenter
        end
        Printf.@printf("%d iteration  distance_max = %f  kcluster = %d\n", ireplica, sqrt(distanceMax_out), kcluster)
    end
    distanceFromCenter_out .= sqrt.(distanceFromCenter_out)

    return (indexOfCluster=indexOfCluster_out, center=center_out, distanceFromCenter=distanceFromCenter, indexOfCenter=indexOfCenter_out)
end

function compute_cov(X::AbstractMatrix; lagtime::Int=0)
    nframe = size(X, 1)
    X_centerized = X .- mean(X, dims=1)
    cov = X_centerized[1:(end-lagtime), :]' * X_centerized[(1+lagtime):end, :] ./ (nframe - 1)
end

function rsvd(A::AbstractMatrix, k::Number=10)
    T = eltype(A)
    m, n = size(A)
    l = k + 2
    @assert l < n
    G = randn(T, n, l)
    #G .= G ./ sqrt.(sum(G.^2, dims=1))
    H = A * G
    @assert m > l
    Q = Matrix(qr!(H).Q)
    @assert m == size(Q, 1)
    @assert l == size(Q, 2)
    T = A' * Q
    V, σ, W = svd(T)
    U = Q * W
    λ = σ .* σ ./ m
    return (V=V[:,1:k], S=λ[1:k], U=U[:,1:k])
end

"""
    pca(X::AbstractMatrix; k=dimension) -> F

Perform principal component analysis. Input data `X` should belong to AbstractMatrix type 
and its columns corresponds to variables, rows are frames. 
Returns a object `F` which contains the prjections of `X` onto the principal modes or principal components in `F.projection`, 
the prncipal modes in the columns of the matrix `F.mode`, and the variances of principal components in `F.variance`. 

#  Example
```julia-repl
julia> X = cumsum(rand(1000, 10))
julia> F = pca(X)
julia> plot(F.projection[:, 1], F.projection[:, 2])
```
"""
function pca(X::AbstractMatrix; k=nothing)
    is_randomized_pca = false
    if !isnothing(k)
        is_randomized_pca = true
        @printf "Warning: a randomized SVD approximation is used for PCA with reduced dimension k = %d\n" k
    end
    dim = size(X, 2)
    if !is_randomized_pca & (dim > 5000)
        k = 1000
        is_randomized_pca = true
        @printf "Warning: the dimension of input data is too large (dim > 5000)\n"
        @printf "Warning: randomized SVD approximation is used for PCA with reduced dimension k = %d\n" k
    end
    if is_randomized_pca
        nframe = size(X, 1)
        X_centerized = X .- mean(X, dims=1)
        F = rsvd(X_centerized, k)
        variance = F.S.^2 ./ (nframe - 1)
        mode = F.V
        projection = X_centerized * mode
    else
        # eigendecomposition of covariance matrix
        covar = compute_cov(X)
        F = eigen(covar, sortby = x -> -x)
        #lambda = F.values[end:-1:1]
        #W = F.vectors[:, end:-1:1]
        variance = F.values
        mode = F.vectors
        # projection
        X_centerized = X .- mean(X, dims=1)
        projection = X_centerized * mode
    end

    return (projection=projection, mode=mode, variance=variance)
end

function tica(X::AbstractMatrix, lagtime::Int=1)
    # standard and time-lagged covariance matrices
    covar0 = compute_cov(X, lagtime=0)
    covar  = compute_cov(X, lagtime=lagtime)

    # symmetrize the time-lagged covariance matrix
    covar .= 0.5 .* (covar .+ covar')

    # calc pseudo-inverse of covar0
    #covar0_inv = pinv(covar0)

    # remove degeneracy for solving the generalized eigenvalue problem
    #F = eigen(covar0, sortby = x -> -x)
    F = pca(X)
    pvariance = F.variance
    pmode = F.mode
    index = pvariance .> 10^(-6)
    pmode = pmode[:, index]
    covar0 = pmode'*covar0*pmode
    covar = pmode'*covar*pmode

    # solve the generalized eigenvalue problem
    F = eigen(covar, covar0, sortby = x -> -x)
    variance = F.values
    mode = F.vectors

    # projection
    mode = pmode * mode
    X_centerized = X .- mean(X, dims=1)
    projection = X_centerized * mode

    # normalize mode vectors
    fac = sqrt.(sum(mode.^2, dims=1))
    mode .= mode ./ fac

    return (projection=projection, mode=mode, variance=variance)
end
