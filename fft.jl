using LinearAlgebra
using Plots


function dftmatrix(n)
    z = range(0, 2π, length=n+1)[1:end-1]
    [exp(-im*(k-1)*z[j]) for k=1:n, j=1:n] *(1 / sqrt(n))
end


function fftmatrix(n)
    σ = [1:2:2n-1;2:2:2n]
    P_σ = I(2n)[σ,:]
    Qₙ = dftmatrix(n)
    Dₙ = Diagonal([exp(im*k*π/n) for k=0:n-1])
    Q₂ₙ_adj = P_σ'*[Qₙ' Qₙ'; Qₙ'*Dₙ -Qₙ'*Dₙ] * 1/sqrt(2)

    return Q₂ₙ_adj'
end


function fourierconv(f, g, n)
    z = range(0, 2π, length=2n+1)[1:end-1]
    A = fftmatrix(n)
    f̂ = (1 / sqrt(2n))*A*(f.(z))
    ĝ = (1 / sqrt(2n))*A*(g.(z))
    ĉ = [f̂[k]*ĝ[k] for k in 1:2n]
    return ĉ
end


function conv(f, g, n)
    A = fftmatrix(n)
    # B = conj.(A)
    ĉ = fourierconv(f, g, n)
    return 2π*(sqrt(2n))*A'*ĉ
end




