using Plots

# Parameters
β_low = -0.01   # Elasticity for low-education workers
β_high = -0.002 # Elasticity for high-education workers
T = 20          # Number of periods
init_r = [10.0, 5.0, 2.0] # Initial housing prices in locations 1, 2, 3
land_supply = [1000.0, 800.0, 600.0] # Fixed supply of land per location

# Housing price dynamics parameters
γ = 0.9    # Persistence of housing prices (0 < γ < 1 for stability)
η = 0.05   # Sensitivity of prices to congestion/population pressure

# Initialize worker populations (arbitrary starting values)
low_edu_pop = [1000.0, 800.0, 600.0]  # Low-education workers in locations 1, 2, 3
high_edu_pop = [500.0, 400.0, 300.0]  # High-education workers in locations 1, 2, 3

# Arrays to store ratios over time
ratios = [Vector{Float64}() for _ in 1:3]

# Logit share function
logit_share(β, r, pop) = exp.(β .* r) .* pop ./ sum(exp.(β .* r) .* pop)

# Function to update housing prices based on total population and fixed land supply
function update_prices!(r, low_pop, high_pop, land_supply, γ, η)
    @inbounds for j in eachindex(r)
        # Ensure strictly positive price before log
        rj = max(r[j], 1e-8)
        congestion = (low_pop[j] + high_pop[j]) / land_supply[j]
        log_r_next = γ * log(rj) + η * congestion
        r[j] = exp(log_r_next)
        # Optional: prevent underflow
        r[j] = max(r[j], 1e-12)
    end
    return r
end

# Simulation over time
r = copy(init_r) # Current housing prices
for t in 1:T
    # Calculate new shares for low- and high-education workers
    low_shares = logit_share(β_low, r, low_edu_pop)
    high_shares = logit_share(β_high, r, high_edu_pop)

    # Update populations based on shares
    total_low = sum(low_edu_pop)
    total_high = sum(high_edu_pop)
    low_edu_pop .= low_shares .* total_low
    high_edu_pop .= high_shares .* total_high

    # Record the ratios of high-edu to low-edu for each location
    for i in 1:3
        push!(ratios[i], high_edu_pop[i] / low_edu_pop[i])
    end

    # Update housing prices using the log rule
    update_prices!(r, low_edu_pop, high_edu_pop, land_supply, γ, η)
end

# Plotting
plot(1:T, ratios[1], label="Location 1", xlabel="Time", ylabel="High-Edu to Low-Edu Ratio", lw=2)
plot!(1:T, ratios[2], label="Location 2", lw=2)
plot!(1:T, ratios[3], label="Location 3", lw=2)

savefig("residential_segregation_illustration.png")