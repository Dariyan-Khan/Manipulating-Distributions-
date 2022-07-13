using ClassicalOrthogonalPolynomials, Plots


function legendreft(m) 
    f = x -> 2 * (-1im)^m * sphericalbesselj(m, x)
    return f
end


# compute legendre series of a poly
function legendrecoeff(f; N=nothing)
    T = Legendre()
    x = axes(T, 1)
    N == nothing ? T \ f.(x) : T[:,1:N] \ f.(x)
end


function legendreseries(f; N=nothing)
    T = Legendre()
    c = legendrecoeff(f, N=N)
    N == nothing ? T * c : T[:, 1:N] * c
end


function bleft_inner(k::Int, n::Int, f, g, α, β; N=100)
    if k >= n
        if n == 0
            if k == 0
                return α[1] - α[2]/3
            else
                return α[k]/(2k-1) - α[k+2]/(2k+3)
            end
        elseif n == 1
            if k == 0
                return -bleft_inner(1, 0, f, g, α, β, N=N)/3
            else
                return bleft_inner(k-1, 0, f, g, α, β, N=N)/(2k-1) - 
                       bleft_inner(k, 0, f, g, α, β, N=N) - 
                       bleft_inner(k+1, 0, f, g, α, β, N=N)/(2k+3)
            end
        else
            return -(2n-1)/(2k+3) * bleft_inner(k+1, n-1, f, g, α, β, N=N) + 
                   (2n-1)/(2k-1) * bleft_inner(k-1,n-1,f, g, α, β, N=N) + 
                   bleft_inner(k, n-2, f, g, α, β, N=N)
        end
    else
        return bleft_inner(n, k, f, g, α, β, N=N) * (-1)^(n+k) * (2k+1)/(2n+1)
    end
end


function bleft(k::Int, n::Int, f, g; N=100)
    bleft_inner(k::Int, n::Int, f, g, legendrecoeff(f, N=N),
                legendrecoeff(g, N=N), N=N)
end


function bright_inner(k::Int, n::Int, f, g, α, β; N=100)
    if k >= n
        if n == 0
            if k == 0
                return α[1] + α[2]/3
            else
                return α[k]/(2k-1) + α[k+2]/(2k+3)
            end
        elseif n == 1
            if k == 0
                return -bright_inner(1, 0, f, g, α, β, N=N)/3
            else
                return bright_inner(k-1, 0, f, g, α, β, N=N)/(2k-1) + 
                       bright_inner(k, 0, f, g, α, β, N=N) - 
                       bright_inner(k+1, 0, f, g, α, β, N=N)/(2k+3)
            end
        else
            return -(2n-1)/(2k+3) * bright_inner(k+1, n-1, f, g, α, β, N=N) + 
                   (2n-1)/(2k-1) * bright_inner(k-1, n-1, f, g, α, β, N=N) + 
                   bright_inner(k, n-2, f, g, α, β, N=N)
        end
    else
        return bright_inner(n, k, f, g, α, β, N=N) * (-1)^(n+k) * (2k+1)/(2n+1)
    end
end


function bright(k::Int, n::Int, f, g; N=100)
    bright_inner(k::Int, n::Int, f, g, legendrecoeff(f, N=N),
                legendrecoeff(g, N=N), N=N)
end


function gammaleft(k::Int, f, g; N=100)
    # find degree of f 
    # take sum and use bleft 
    β = legendrecoeff(f; N=N)
    ret = 0 
    for i in 0:(N-1)
        ret += β[i+1] * bleft(k, i, f, g, N=N+1)
    end
    return ret
end


# find γₖ right
function gammaright(k::Int, f, g; N=100)
    β = legendrecoeff(f; N=N)
    ret = 0 
    for i in 0:N
        ret += β[i+1] * bright(k, i, f, g, N=N)
    end
    return ret
end


function left_conv_unit(f, g; N=100)
    U = 2*N + 1
    gamma_left = k -> gammaleft(k, f, g; N=N)
    γₗ = gamma_left.(0:U)
    legendre(-2..0) * γₗ
end


function right_conv_unit(f, g; N=100)
    U = 2*N + 1
    gamma_right = k -> gammaright(k, f, g; N=N)
    γᵣ = gamma_right.(0:U)
    legendre(0..2) * γᵣ
end


function legendre_same_length(f, g, dom_f, dom_g; N=100)
    @assert dom_f[2] - dom_f[1] == dom_g[2] - dom_g[1]
    L = dom_f[2] - dom_f[1]
    #Inverse of each of the phi functions in the paper
    ϕ_f_inv = x -> (((dom_f[2] - dom_f[1]) / 2) * (x + 1)) + dom_f[1]
    ϕ_g_inv = x -> (((dom_g[2] - dom_g[1]) / 2) * (x + 1)) + dom_g[1]
    fᵣ = x -> f(ϕ_f_inv(x))
    gᵣ = x -> g(ϕ_g_inv(x))
    return (L/2) * left_conv_unit(fᵣ, gᵣ, N=N), (L/2) * right_conv_unit(fᵣ, gᵣ, N=N)
end


function h_12(f, g, dom_f, dom_g,  x::Float64; N=100)
    g1 = x -> g(x)*(x in dom_g[1]..(dom_g[1] + dom_f[2] - dom_f[1]))
    g2 = x -> g(x)*(x in (dom_f[1] + dom_g[1])..(dom_g[2] - dom_f[2] + 2*dom_f[1]))
    g3 = x -> g(x)*(x in (dom_g[2] - dom_f[2] + dom_f[1])..dom_g[2])
    g4 = x -> g(x)*(x in (dom_g[2] - dom_f[2] + dom_f[1])..dom_g[2])
    f1 = x -> f(x)*(x in (2*dom_f[2] + dom_g[1] - dom_g[2] - dom_f[1])..dom_f[2])
    if x in (domf[1] + dom_g[1])..(dom_f[2] + dom_g[1])
        return legendre_same_length(f, g1, dom_f, dom_g, N=N)(x)
    elseif x in (dom_f[2] + dom_g[1])..(dom_f[1] + dom_g[2])
        return legendre_same_length(f1, g2, dom_f, dom_g, N=N)(x) + legendre_same_length(f, g3,  N=N)(x)
    elseif x in (dom_f[1] + dom_g[2])..(dom_f[2] + dom_g[2])
        return legendre_same_length(f, g4, N=N)(x)
    else
        return 0.0
    end
end


function legendre_general(f, g, dom_f, dom_g; N=100)
    rat = (dom_g[2] - dom_g[1])/(dom_f[2] - dom_f[1])
    @assert rat >= 1
    r = modf(rat)[2]
    if dom_f[2] - dom_f[1] == dom_g[2] - dom_g[1]
        return legendre_same_length(f, g, dom_f, dom_g, N=N)
    else
        if modf(rat)[1] == 0.0
        # d-c / b-a > 1 and integer
        # partition g into (d-c)/(b-a) subdomains and add
            first = dom_g[1] + (j-1)*(dom_f[2] - dom_f[1])
            last = dom_g[1] + j*(dom_f[2]-dom_f[1])
            dⱼ = first..last
            gⱼ = x -> g(x)*(x in dⱼ)
            h = x -> sum(legendre_same_length(f, gⱼ, dom_f, dom_g,
                                              N=N)(x) for j in 1:r)
            return h
        elseif 1 < rat < 2
        # d-c/b-a > 2
        # h is piecewise on 3 intervals
            return x -> h_12(f, g, dom_f, dom_g, x)
        else
        # split into sum satisfying conditions 1 and 2 
            i₁ = dom_g[1]..(dom_g[1] + (r-1)*(dom_f[2]-dom_f[1]))
            i₂ = (dom_g[1] + (r-1)*(dom_f[2]-dom_f[1]))..dom_g[2]
            g1 = x -> g(x)*(x in i₁)
            g2 = x -> g(x)*(x in i₂)
            h1 = x -> legendre_general(f, g1, dom_f, dom_g, N=N)(x)
            h2 = x -> h_12(f, g2, dom_f, dom_g, N=N, x)
            h = x -> h1(x) + h2(x)
            return h   
        end  
    end
end

f = x -> x^2
g = x -> x+1


for k in 1:1
    println(gammaleft(k, f, g, N=100))
end




# for k in 0:2
#     for n in 0:2
#         println(bleft(k, n, f, g; N=100))
#     end
# end

