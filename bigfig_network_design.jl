### Importation of relevant packages
using JuMP
using Gurobi
using CSV
using DataFrames

### Specify preferred version of JuMP
Pkg.pin(PackageSpec(name="JuMP", version="0.18.6"))

### Data importation for the problem
demand17 = convert(Array, CSV.read("demand17.csv";  header=false));
demand19 = convert(Array, CSV.read("demand19.csv";  header=false));
dist_m2p = convert(Array, CSV.read("dist_m2p.csv"; header=false));
dist_p2c = convert(Matrix, CSV.read("dist_p2c.csv"; header=false));
plants = convert(Array, CSV.read("plants.csv"; header=false));
customers = convert(Array, CSV.read("customers.csv"; header=false));
y_1 = convert(Matrix, CSV.read("base_allocation.csv"; header=false));

### Definition of number of plants and customers
num_plant = size(dist_p2c)[2];
num_cust = size(dist_p2c)[1];

### Definition of cases per truck
fig_cpt = 7000
bot_cpt = 1296

### Question 1: Base case calculation with 2017 data
capacity = [250000,175000,150000,200000,15000] # cases/week for Stockton, Rockwall, Joliet, Atlanta, York
x_1 = ones(5,1)
for i in 1:5
    x_1[i] = sum(y_1[j,i] for j in 1:num_cust)
end
fig_cost_1 = sum(dist_m2p[i] * x_1[i] for i in 1:5) / fig_cpt
bot_cost_1 = sum(dist_p2c[j,i] * y_1[j,i] for i in 1:5, j in 1:num_cust) / bot_cpt
total_cost_1 = fig_cost_1 + bot_cost_1

### Question 2: Optimize the allocation with 2017 network
mod2 = Model(solver = GurobiSolver(MIPGap=0.0001));
@variable(mod2, x[1:5] >= 0);
@variable(mod2, y[1:num_cust,1:5] >= 0);
@variable(mod2, z[1:5], Bin);

@objective(mod2, Min,
    sum(dist_m2p[i] * x[i] for i in 1:5) / fig_cpt +
    sum(dist_p2c[j,i] * y[j,i] for i in 1:5, j in 1:num_cust) / bot_cpt
    );

@constraint(mod2, [j in 1:num_cust], sum(y[j,i] for i in 1:5) >= demand17[j]);
@constraint(mod2, [i in 1:5], sum(y[j,i] for j in 1:num_cust) <= x[i]);
@constraint(mod2, [i in 1:5], sum(y[j,i] for j in 1:num_cust) <= z[i] * capacity[i]);
# N = 5
# @constraint(mode, sum(z[i] for i in 1:num:plant) <= N)

status = solve(mod2);
total_cost_2 = getobjectivevalue(mod2);
x_2 = getvalue(x) # m2p allo
CSV.write("x_2.csv",DataFrame(Plants=plants[1,1:5], x=x_2))
y_2 = getvalue(y) # p2c allo
CSV.write("y_2.csv",DataFrame(Customers=customers[:,1], Stockton=y_2[:,1], Rockwall=y_2[:,5], Joliet=y_2[:,2], Atlanta=y_2[:,3], York=y_2[:,4]))
z_2 = getvalue(z) # plant open/closed
CSV.write("z_2.csv",DataFrame(Plants=plants[1,1:5], z=z_2))
fig_cost_2 = sum(dist_m2p[i] * x_2[i] for i in 1:5) / fig_cpt
bot_cost_2 = sum(dist_p2c[j,i] * y_2[j,i] for i in 1:5, j in 1:num_cust) / bot_cpt
CSV.write("util_2.csv",DataFrame(Plants=plants[1,1:5], capacity=capacity, util=x_2, util_perc=x_2./capacity))

### Question 3.1: Optimize the allocation with unconstrained capacity and 2017 network
mod3_1 = Model(solver = GurobiSolver(MIPGap=0.0001));
@variable(mod3_1, x[1:5] >= 0);
@variable(mod3_1, y[1:num_cust,1:5] >= 0);
@variable(mod3_1, z[1:5], Bin);

@objective(mod3_1, Min,
    sum(dist_m2p[i] * x[i] for i in 1:5) / fig_cpt +
    sum(dist_p2c[j,i] * y[j,i] for i in 1:5, j in 1:num_cust) / bot_cpt
    );

@constraint(mod3_1, [j in 1:num_cust], sum(y[j,i] for i in 1:5) >= demand17[j]);
@constraint(mod3_1, [i in 1:5], sum(y[j,i] for j in 1:num_cust) <= x[i]);
# @constraint(mod3_1, [i in 1:5], sum(y[j,i] for j in 1:num_cust) <= z[i] * capacity[i]);
# N = 5
# @constraint(mod3_1, sum(z[i] for i in 1:num:plant) <= N)

status = solve(mod3_1);
total_cost_3_1 = getobjectivevalue(mod3_1);
x_3_1 = getvalue(x) # m2p allo
CSV.write("x_3_1.csv",DataFrame(Plants=plants[1,1:5], x=x_3_1))
y_3_1 = getvalue(y) # p2c allo
CSV.write("y_3_1.csv",DataFrame(Customers=customers[:,1], Stockton=y_3_1[:,1], Rockwall=y_3_1[:,5], Joliet=y_3_1[:,2], Atlanta=y_3_1[:,3], York=y_3_1[:,4]))
# z_3_1 = getvalue(z) # plant open/closed
# CSV.write("z_3_1.csv",DataFrame(Plants=plants[1,1:5], z=z_3_1))
fig_cost_3_1 = sum(dist_m2p[i] * x_3_1[i] for i in 1:5) / fig_cpt
bot_cost_3_1 = sum(dist_p2c[j,i] * y_3_1[j,i] for i in 1:5, j in 1:num_cust) / bot_cpt
CSV.write("util_3_1.csv",DataFrame(Plants=plants[1,1:5], capacity=capacity, util=x_3_1, util_perc=x_3_1./capacity))


### Question 3.2: Optimize the allocation with unconstrained capacity and 2017 network with service level of 700 miles
new_dist_p2c = dist_p2c + 999999*(dist_p2c.>1500)
mod3_2 = Model(solver = GurobiSolver(MIPGap=0.0001));
@variable(mod3_2, x[1:5] >= 0);
@variable(mod3_2, y[1:num_cust,1:5] >= 0);
@variable(mod3_2, z[1:5], Bin);

@objective(mod3_2, Min,
    sum(dist_m2p[i] * x[i] for i in 1:5) / fig_cpt +
    sum(new_dist_p2c[j,i] * y[j,i] for i in 1:5, j in 1:num_cust) / bot_cpt
    );

@constraint(mod3_2, [j in 1:num_cust], sum(y[j,i] for i in 1:5) >= demand17[j]);
@constraint(mod3_2, [i in 1:5], sum(y[j,i] for j in 1:num_cust) <= x[i]);
# @constraint(mod3_1, [i in 1:5], sum(y[j,i] for j in 1:num_cust) <= z[i] * capacity[i]);
# N = 5
# @constraint(mod3_1, sum(z[i] for i in 1:num:plant) <= N)

status = solve(mod3_2);
total_cost_3_2 = getobjectivevalue(mod3_2);
x_3_2 = getvalue(x) # m2p allo
CSV.write("x_3_2.csv",DataFrame(Plants=plants[1,1:5], x=x_3_2))
y_3_2 = getvalue(y) # p2c allo
CSV.write("y_3_2.csv",DataFrame(Customers=customers[:,1], Stockton=y_3_2[:,1], Rockwall=y_3_2[:,5], Joliet=y_3_2[:,2], Atlanta=y_3_2[:,3], York=y_3_2[:,4]))
# z_3_2 = getvalue(z) # plant open/closed
# CSV.write("z_3_2.csv",DataFrame(Plants=plants[1,1:5], z=z_3_2))
fig_cost_3_2 = sum(dist_m2p[i] * x_3_2[i] for i in 1:5) / fig_cpt
bot_cost_3_2 = sum(dist_p2c[j,i] * y_3_2[j,i] for i in 1:5, j in 1:num_cust) / bot_cpt
CSV.write("util_3_2.csv",DataFrame(Plants=plants[1,1:5], capacity=capacity, util=x_3_2, util_perc=x_3_2./capacity))


### Question 4-1: Optimize 2 new plant locations and allocation with 2019 data
new_capacity = [250000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000] # cases/week
mod4 = Model(solver = GurobiSolver(MIPGap=0.0001));
@variable(mod4, x[1:num_plant] >= 0);
@variable(mod4, y[1:num_cust,1:num_plant] >= 0);
@variable(mod4, z[1:num_plant], Bin);

@objective(mod4, Min,
    sum(dist_m2p[i] * x[i] for i in 1:num_plant) / fig_cpt +
    sum(dist_p2c[j,i] * y[j,i] for i in 1:num_plant, j in 1:num_cust) / bot_cpt
    );

@constraint(mod4, [i in 1:4], z[i] == 1)
@constraint(mod4, [j in 1:num_cust], sum(y[j,i] for i in 1:num_plant) >= demand19[j]);
@constraint(mod4, [i in 1:num_plant], sum(y[j,i] for j in 1:num_cust) <= x[i]);
@constraint(mod4, [i in 1:num_plant], sum(y[j,i] for j in 1:num_cust) <= z[i] * new_capacity[i]);
N = 2
@constraint(mod4, sum(z[i] for i in 5:num_plant) <= N)

status = solve(mod4);
total_cost_4_1 = getobjectivevalue(mod4);
x_4 = getvalue(x) # m2p allo
CSV.write("x_4_1.csv",DataFrame(Plants=plants[1,1:num_plant], x=x_4))
y_4 = getvalue(y) # p2c allo
CSV.write("y_4_1.csv",DataFrame(vcat(hcat("Customers",plants),hcat(customers,y_4))))
z_4 = getvalue(z) # plant open/closed
CSV.write("z_4_1.csv",DataFrame(Plants=plants[1,1:num_plant], z=z_4))
fig_cost_4_1 = sum(dist_m2p[i] * x_4[i] for i in 1:num_plant) / fig_cpt
bot_cost_4_1 = sum(dist_p2c[j,i] * y_4[j,i] for i in 1:num_plant, j in 1:num_cust) / bot_cpt
CSV.write("util_4_1.csv",DataFrame(Plants=plants[1,1:num_plant], capacity=new_capacity, util=x_4, util_perc=x_4./new_capacity))

### Question 4-2
demand19_2 = convert(Array, CSV.read("demand19-2.csv";  header=false));
new_capacity = [250000,200000,200000,200000,0,0,0,0,0,0,0,200000,0,0,0,0,0,0,200000,0,0,0] # cases/week
mod4 = Model(solver = GurobiSolver(MIPGap=0.0001));
@variable(mod4, x[1:num_plant] >= 0);
@variable(mod4, y[1:num_cust,1:num_plant] >= 0);
@variable(mod4, z[1:num_plant], Bin);

@objective(mod4, Min,
    sum(dist_m2p[i] * x[i] for i in 1:num_plant) / fig_cpt +
    sum(dist_p2c[j,i] * y[j,i] for i in 1:num_plant, j in 1:num_cust) / bot_cpt
    );

@constraint(mod4, [i in 1:num_plant], z[i] == 1)
@constraint(mod4, [j in 1:num_cust], sum(y[j,i] for i in 1:num_plant) >= demand19_2[j]);
@constraint(mod4, [i in 1:num_plant], sum(y[j,i] for j in 1:num_cust) <= x[i]);
@constraint(mod4, [i in 1:num_plant], sum(y[j,i] for j in 1:num_cust) <= z[i] * new_capacity[i]);
# N = 2
# @constraint(mod4, sum(z[i] for i in 5:num_plant) <= N)

status = solve(mod4);
total_cost_4_2 = getobjectivevalue(mod4);
x_4 = getvalue(x) # m2p allo
CSV.write("x_4_2.csv",DataFrame(Plants=plants[1,1:num_plant], x=x_4))
y_4 = getvalue(y) # p2c allo
CSV.write("y_4_2.csv",DataFrame(vcat(hcat("Customers",plants),hcat(customers,y_4))))
z_4 = getvalue(z) # plant open/closed
CSV.write("z_4_2.csv",DataFrame(Plants=plants[1,1:num_plant], z=z_4))
fig_cost_4_2 = sum(dist_m2p[i] * x_4[i] for i in 1:num_plant) / fig_cpt
bot_cost_4_2 = sum(dist_p2c[j,i] * y_4[j,i] for i in 1:num_plant, j in 1:num_cust) / bot_cpt
CSV.write("util_4_2.csv",DataFrame(Plants=plants[1,1:num_plant], capacity=new_capacity, util=x_4, util_perc=x_4./new_capacity))

### Question 4-3
demand19_3 = convert(Array, CSV.read("demand19-3.csv";  header=false));
new_capacity = [250000,200000,200000,200000,0,0,0,0,0,0,0,200000,0,0,0,0,0,0,200000,0,0,0] # cases/week
mod4 = Model(solver = GurobiSolver(MIPGap=0.0001));
@variable(mod4, x[1:num_plant] >= 0);
@variable(mod4, y[1:num_cust,1:num_plant] >= 0);
@variable(mod4, z[1:num_plant], Bin);

@objective(mod4, Min,
    sum(dist_m2p[i] * x[i] for i in 1:num_plant) / fig_cpt +
    sum(dist_p2c[j,i] * y[j,i] for i in 1:num_plant, j in 1:num_cust) / bot_cpt
    );

@constraint(mod4, [i in 1:num_plant], z[i] == 1)
@constraint(mod4, [j in 1:num_cust], sum(y[j,i] for i in 1:num_plant) >= demand19_3[j]);
@constraint(mod4, [i in 1:num_plant], sum(y[j,i] for j in 1:num_cust) <= x[i]);
@constraint(mod4, [i in 1:num_plant], sum(y[j,i] for j in 1:num_cust) <= z[i] * new_capacity[i]);
# N = 2
# @constraint(mod4, sum(z[i] for i in 5:num_plant) <= N)

status = solve(mod4);
total_cost_4_3 = getobjectivevalue(mod4);
x_4 = getvalue(x) # m2p allo
CSV.write("x_4_3.csv",DataFrame(Plants=plants[1,1:num_plant], x=x_4))
y_4 = getvalue(y) # p2c allo
CSV.write("y_4_3.csv",DataFrame(vcat(hcat("Customers",plants),hcat(customers,y_4))))
z_4 = getvalue(z) # plant open/closed
CSV.write("z_4_3.csv",DataFrame(Plants=plants[1,1:num_plant], z=z_4))
fig_cost_4_3 = sum(dist_m2p[i] * x_4[i] for i in 1:num_plant) / fig_cpt
bot_cost_4_3 = sum(dist_p2c[j,i] * y_4[j,i] for i in 1:num_plant, j in 1:num_cust) / bot_cpt
CSV.write("util_4_3.csv",DataFrame(Plants=plants[1,1:num_plant], capacity=new_capacity, util=x_4, util_perc=x_4./new_capacity))

### Question 4-4
demand19_4 = convert(Array, CSV.read("demand19-4.csv";  header=false));
new_capacity = [250000,200000,200000,200000,0,0,0,0,0,0,0,200000,0,0,0,0,0,0,200000,0,0,0] # cases/week
mod4 = Model(solver = GurobiSolver(MIPGap=0.0001));
@variable(mod4, x[1:num_plant] >= 0);
@variable(mod4, y[1:num_cust,1:num_plant] >= 0);
@variable(mod4, z[1:num_plant], Bin);

@objective(mod4, Min,
    sum(dist_m2p[i] * x[i] for i in 1:num_plant) / fig_cpt +
    sum(dist_p2c[j,i] * y[j,i] for i in 1:num_plant, j in 1:num_cust) / bot_cpt
    );

@constraint(mod4, [i in 1:num_plant], z[i] == 1)
@constraint(mod4, [j in 1:num_cust], sum(y[j,i] for i in 1:num_plant) >= demand19_4[j]);
@constraint(mod4, [i in 1:num_plant], sum(y[j,i] for j in 1:num_cust) <= x[i]);
@constraint(mod4, [i in 1:num_plant], sum(y[j,i] for j in 1:num_cust) <= z[i] * new_capacity[i]);
# N = 2
# @constraint(mod4, sum(z[i] for i in 5:num_plant) <= N)

status = solve(mod4);
total_cost_4_4 = getobjectivevalue(mod4);
x_4 = getvalue(x) # m2p allo
CSV.write("x_4_4.csv",DataFrame(Plants=plants[1,1:num_plant], x=x_4))
y_4 = getvalue(y) # p2c allo
CSV.write("y_4_4.csv",DataFrame(vcat(hcat("Customers",plants),hcat(customers,y_4))))
z_4 = getvalue(z) # plant open/closed
CSV.write("z_4_4.csv",DataFrame(Plants=plants[1,1:num_plant], z=z_4))
fig_cost_4_4 = sum(dist_m2p[i] * x_4[i] for i in 1:num_plant) / fig_cpt
bot_cost_4_4 = sum(dist_p2c[j,i] * y_4[j,i] for i in 1:num_plant, j in 1:num_cust) / bot_cpt
CSV.write("util_4_4.csv",DataFrame(Plants=plants[1,1:num_plant], capacity=new_capacity, util=x_4, util_perc=x_4./new_capacity))


### Question 4-5: without I-10
new_capacity = [250000,200000,200000,200000,200000,200000,200000,200000,200000,200000,0,200000,0,200000,200000,200000,0,0,0,200000,200000,0] # cases/week
mod4 = Model(solver = GurobiSolver(MIPGap=0.0001));
@variable(mod4, x[1:num_plant] >= 0);
@variable(mod4, y[1:num_cust,1:num_plant] >= 0);
@variable(mod4, z[1:num_plant], Bin);

@objective(mod4, Min,
    sum(dist_m2p[i] * x[i] for i in 1:num_plant) / fig_cpt +
    sum(dist_p2c[j,i] * y[j,i] for i in 1:num_plant, j in 1:num_cust) / bot_cpt
    );

@constraint(mod4, [i in 1:4], z[i] == 1)
@constraint(mod4, [j in 1:num_cust], sum(y[j,i] for i in 1:num_plant) >= demand19[j]);
@constraint(mod4, [i in 1:num_plant], sum(y[j,i] for j in 1:num_cust) <= x[i]);
@constraint(mod4, [i in 1:num_plant], sum(y[j,i] for j in 1:num_cust) <= z[i] * new_capacity[i]);
N = 2
@constraint(mod4, sum(z[i] for i in 5:num_plant) <= N)

status = solve(mod4);
total_cost_4_5 = getobjectivevalue(mod4);
x_4 = getvalue(x) # m2p allo
CSV.write("x_4_5.csv",DataFrame(Plants=plants[1,1:num_plant], x=x_4))
y_4 = getvalue(y) # p2c allo
CSV.write("y_4_5.csv",DataFrame(vcat(hcat("Customers",plants),hcat(customers,y_4))))
z_4 = getvalue(z) # plant open/closed
CSV.write("z_4_5.csv",DataFrame(Plants=plants[1,1:num_plant], z=z_4))
fig_cost_4_5 = sum(dist_m2p[i] * x_4[i] for i in 1:num_plant) / fig_cpt
bot_cost_4_5 = sum(dist_p2c[j,i] * y_4[j,i] for i in 1:num_plant, j in 1:num_cust) / bot_cpt
CSV.write("util_4_5.csv",DataFrame(Plants=plants[1,1:num_plant], capacity=new_capacity, util=x_4, util_perc=x_4./new_capacity))

### Question 4-6
new_capacity = [250000,200000,200000,200000,0,0,0,0,0,0,0,200000,0,0,200000,0,0,0,0,0,0,0] # cases/week
mod4 = Model(solver = GurobiSolver(MIPGap=0.0001));
@variable(mod4, x[1:num_plant] >= 0);
@variable(mod4, y[1:num_cust,1:num_plant] >= 0);
@variable(mod4, z[1:num_plant], Bin);

@objective(mod4, Min,
    sum(dist_m2p[i] * x[i] for i in 1:num_plant) / fig_cpt +
    sum(dist_p2c[j,i] * y[j,i] for i in 1:num_plant, j in 1:num_cust) / bot_cpt
    );

@constraint(mod4, [i in 1:num_plant], z[i] == 1)
@constraint(mod4, [j in 1:num_cust], sum(y[j,i] for i in 1:num_plant) >= demand19_2[j]);
@constraint(mod4, [i in 1:num_plant], sum(y[j,i] for j in 1:num_cust) <= x[i]);
@constraint(mod4, [i in 1:num_plant], sum(y[j,i] for j in 1:num_cust) <= z[i] * new_capacity[i]);
# N = 2
# @constraint(mod4, sum(z[i] for i in 5:num_plant) <= N)

status = solve(mod4);
total_cost_4_6 = getobjectivevalue(mod4);
x_4 = getvalue(x) # m2p allo
CSV.write("x_4_6.csv",DataFrame(Plants=plants[1,1:num_plant], x=x_4))
y_4 = getvalue(y) # p2c allo
CSV.write("y_4_6.csv",DataFrame(vcat(hcat("Customers",plants),hcat(customers,y_4))))
z_4 = getvalue(z) # plant open/closed
CSV.write("z_4_6.csv",DataFrame(Plants=plants[1,1:num_plant], z=z_4))
fig_cost_4_6 = sum(dist_m2p[i] * x_4[i] for i in 1:num_plant) / fig_cpt
bot_cost_4_6 = sum(dist_p2c[j,i] * y_4[j,i] for i in 1:num_plant, j in 1:num_cust) / bot_cpt
CSV.write("util_4_6.csv",DataFrame(Plants=plants[1,1:num_plant], capacity=new_capacity, util=x_4, util_perc=x_4./new_capacity))

### Question 4-7
new_capacity = [250000,200000,200000,200000,0,0,0,0,0,0,0,200000,0,0,200000,0,0,0,0,0,0,0] # cases/week
mod4 = Model(solver = GurobiSolver(MIPGap=0.0001));
@variable(mod4, x[1:num_plant] >= 0);
@variable(mod4, y[1:num_cust,1:num_plant] >= 0);
@variable(mod4, z[1:num_plant], Bin);

@objective(mod4, Min,
    sum(dist_m2p[i] * x[i] for i in 1:num_plant) / fig_cpt +
    sum(dist_p2c[j,i] * y[j,i] for i in 1:num_plant, j in 1:num_cust) / bot_cpt
    );

@constraint(mod4, [i in 1:num_plant], z[i] == 1)
@constraint(mod4, [j in 1:num_cust], sum(y[j,i] for i in 1:num_plant) >= demand19_3[j]);
@constraint(mod4, [i in 1:num_plant], sum(y[j,i] for j in 1:num_cust) <= x[i]);
@constraint(mod4, [i in 1:num_plant], sum(y[j,i] for j in 1:num_cust) <= z[i] * new_capacity[i]);
# N = 2
# @constraint(mod4, sum(z[i] for i in 5:num_plant) <= N)

status = solve(mod4);
total_cost_4_7 = getobjectivevalue(mod4);
x_4 = getvalue(x) # m2p allo
CSV.write("x_4_7.csv",DataFrame(Plants=plants[1,1:num_plant], x=x_4))
y_4 = getvalue(y) # p2c allo
CSV.write("y_4_7.csv",DataFrame(vcat(hcat("Customers",plants),hcat(customers,y_4))))
z_4 = getvalue(z) # plant open/closed
CSV.write("z_4_7.csv",DataFrame(Plants=plants[1,1:num_plant], z=z_4))
fig_cost_4_7 = sum(dist_m2p[i] * x_4[i] for i in 1:num_plant) / fig_cpt
bot_cost_4_7 = sum(dist_p2c[j,i] * y_4[j,i] for i in 1:num_plant, j in 1:num_cust) / bot_cpt
CSV.write("util_4_7.csv",DataFrame(Plants=plants[1,1:num_plant], capacity=new_capacity, util=x_4, util_perc=x_4./new_capacity))

### Question 4-8
new_capacity = [250000,200000,200000,200000,0,0,0,0,0,0,0,200000,0,0,200000,0,0,0,0,0,0,0] # cases/week
mod4 = Model(solver = GurobiSolver(MIPGap=0.0001));
@variable(mod4, x[1:num_plant] >= 0);
@variable(mod4, y[1:num_cust,1:num_plant] >= 0);
@variable(mod4, z[1:num_plant], Bin);

@objective(mod4, Min,
    sum(dist_m2p[i] * x[i] for i in 1:num_plant) / fig_cpt +
    sum(dist_p2c[j,i] * y[j,i] for i in 1:num_plant, j in 1:num_cust) / bot_cpt
    );

@constraint(mod4, [i in 1:num_plant], z[i] == 1)
@constraint(mod4, [j in 1:num_cust], sum(y[j,i] for i in 1:num_plant) >= demand19_4[j]);
@constraint(mod4, [i in 1:num_plant], sum(y[j,i] for j in 1:num_cust) <= x[i]);
@constraint(mod4, [i in 1:num_plant], sum(y[j,i] for j in 1:num_cust) <= z[i] * new_capacity[i]);
# N = 2
# @constraint(mod4, sum(z[i] for i in 5:num_plant) <= N)

status = solve(mod4);
total_cost_4_8 = getobjectivevalue(mod4);
x_4 = getvalue(x) # m2p allo
CSV.write("x_4_8.csv",DataFrame(Plants=plants[1,1:num_plant], x=x_4))
y_4 = getvalue(y) # p2c allo
CSV.write("y_4_8.csv",DataFrame(vcat(hcat("Customers",plants),hcat(customers,y_4))))
z_4 = getvalue(z) # plant open/closed
CSV.write("z_4_8.csv",DataFrame(Plants=plants[1,1:num_plant], z=z_4))
fig_cost_4_8 = sum(dist_m2p[i] * x_4[i] for i in 1:num_plant) / fig_cpt
bot_cost_4_8 = sum(dist_p2c[j,i] * y_4[j,i] for i in 1:num_plant, j in 1:num_cust) / bot_cpt
CSV.write("util_4_8.csv",DataFrame(Plants=plants[1,1:num_plant], capacity=new_capacity, util=x_4, util_perc=x_4./new_capacity))


### Question 5-1: Optimize the allocation with 2017 network extended capacity on 2019 demand
new_capacity = [250000,200000,200000,200000,200000]
mod2 = Model(solver = GurobiSolver(MIPGap=0.0001));
@variable(mod2, x[1:5] >= 0);
@variable(mod2, y[1:num_cust,1:5] >= 0);
@variable(mod2, z[1:5], Bin);

@objective(mod2, Min,
    sum(dist_m2p[i] * x[i] for i in 1:5) / fig_cpt +
    sum(dist_p2c[j,i] * y[j,i] for i in 1:5, j in 1:num_cust) / bot_cpt
    );

@constraint(mod2, [j in 1:num_cust], sum(y[j,i] for i in 1:5) >= demand19[j]);
@constraint(mod2, [i in 1:5], sum(y[j,i] for j in 1:num_cust) <= x[i]);
@constraint(mod2, [i in 1:5], sum(y[j,i] for j in 1:num_cust) <= z[i] * new_capacity[i]);
# N = 5
# @constraint(mode, sum(z[i] for i in 1:num:plant) <= N)

status = solve(mod2);
total_cost_5_1 = getobjectivevalue(mod2);
x_2 = getvalue(x) # m2p allo
CSV.write("x_5_1.csv",DataFrame(Plants=plants[1,1:5], x=x_2))
y_2 = getvalue(y) # p2c allo
CSV.write("y_5_1.csv",DataFrame(Customers=customers[:,1], Stockton=y_2[:,1], Rockwall=y_2[:,5], Joliet=y_2[:,2], Atlanta=y_2[:,3], York=y_2[:,4]))
z_2 = getvalue(z) # plant open/closed
CSV.write("z_5_1.csv",DataFrame(Plants=plants[1,1:5], z=z_2))
fig_cost_5_1 = sum(dist_m2p[i] * x_2[i] for i in 1:5) / fig_cpt
bot_cost_5_1 = sum(dist_p2c[j,i] * y_2[j,i] for i in 1:5, j in 1:num_cust) / bot_cpt
CSV.write("util_5_1.csv",DataFrame(Plants=plants[1,1:5], capacity=new_capacity, util=x_2, util_perc=x_2./new_capacity))


### Question 5-2: Fixed Rockwall with I-10
new_capacity = [250000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000,200000] # cases/week
mod4 = Model(solver = GurobiSolver(MIPGap=0.0001));
@variable(mod4, x[1:num_plant] >= 0);
@variable(mod4, y[1:num_cust,1:num_plant] >= 0);
@variable(mod4, z[1:num_plant], Bin);

@objective(mod4, Min,
    sum(dist_m2p[i] * x[i] for i in 1:num_plant) / fig_cpt +
    sum(dist_p2c[j,i] * y[j,i] for i in 1:num_plant, j in 1:num_cust) / bot_cpt
    );

@constraint(mod4, [i in 1:5], z[i] == 1)
@constraint(mod4, [j in 1:num_cust], sum(y[j,i] for i in 1:num_plant) >= demand19[j]);
@constraint(mod4, [i in 1:num_plant], sum(y[j,i] for j in 1:num_cust) <= x[i]);
@constraint(mod4, [i in 1:num_plant], sum(y[j,i] for j in 1:num_cust) <= z[i] * new_capacity[i]);
N = 1
@constraint(mod4, sum(z[i] for i in 6:num_plant) <= N)

status = solve(mod4);
total_cost_5_2 = getobjectivevalue(mod4);
x_4 = getvalue(x) # m2p allo
CSV.write("x_5_2.csv",DataFrame(Plants=plants[1,1:num_plant], x=x_4))
y_4 = getvalue(y) # p2c allo
CSV.write("y_5_2.csv",DataFrame(vcat(hcat("Customers",plants),hcat(customers,y_4))))
z_4 = getvalue(z) # plant open/closed
CSV.write("z_5_2.csv",DataFrame(Plants=plants[1,1:num_plant], z=z_4))
fig_cost_5_2 = sum(dist_m2p[i] * x_4[i] for i in 1:num_plant) / fig_cpt
bot_cost_5_2 = sum(dist_p2c[j,i] * y_4[j,i] for i in 1:num_plant, j in 1:num_cust) / bot_cpt
CSV.write("util_5_2.csv",DataFrame(Plants=plants[1,1:num_plant], capacity=new_capacity, util=x_4, util_perc=x_4./new_capacity))

### Question 5-3: Fixed Rockwall without I-10
new_capacity = [250000,200000,200000,200000,200000,200000,200000,200000,200000,200000,0,200000,0,200000,200000,200000,0,0,0,200000,200000,0] # cases/week
mod4 = Model(solver = GurobiSolver(MIPGap=0.0001));
@variable(mod4, x[1:num_plant] >= 0);
@variable(mod4, y[1:num_cust,1:num_plant] >= 0);
@variable(mod4, z[1:num_plant], Bin);

@objective(mod4, Min,
    sum(dist_m2p[i] * x[i] for i in 1:num_plant) / fig_cpt +
    sum(dist_p2c[j,i] * y[j,i] for i in 1:num_plant, j in 1:num_cust) / bot_cpt
    );

@constraint(mod4, [i in 1:5], z[i] == 1)
@constraint(mod4, [j in 1:num_cust], sum(y[j,i] for i in 1:num_plant) >= demand19[j]);
@constraint(mod4, [i in 1:num_plant], sum(y[j,i] for j in 1:num_cust) <= x[i]);
@constraint(mod4, [i in 1:num_plant], sum(y[j,i] for j in 1:num_cust) <= z[i] * new_capacity[i]);
N = 1
@constraint(mod4, sum(z[i] for i in 6:num_plant) <= N)

status = solve(mod4);
total_cost_5_3 = getobjectivevalue(mod4);
x_4 = getvalue(x) # m2p allo
CSV.write("x_5_3.csv",DataFrame(Plants=plants[1,1:num_plant], x=x_4))
y_4 = getvalue(y) # p2c allo
CSV.write("y_5_3.csv",DataFrame(vcat(hcat("Customers",plants),hcat(customers,y_4))))
z_4 = getvalue(z) # plant open/closed
CSV.write("z_5_3.csv",DataFrame(Plants=plants[1,1:num_plant], z=z_4))
fig_cost_5_3 = sum(dist_m2p[i] * x_4[i] for i in 1:num_plant) / fig_cpt
bot_cost_5_3 = sum(dist_p2c[j,i] * y_4[j,i] for i in 1:num_plant, j in 1:num_cust) / bot_cpt
CSV.write("util_5_3.csv",DataFrame(Plants=plants[1,1:num_plant], capacity=new_capacity, util=x_4, util_perc=x_4./new_capacity))

### Final cost export
CSV.write("cost.csv",DataFrame(scenario=[1,2,31,32,41,42,43,44,45,46,47,48],
        fig_cost=[fig_cost_1,fig_cost_2,fig_cost_3_1,fig_cost_3_2,fig_cost_4_1,fig_cost_4_2,fig_cost_4_3,fig_cost_4_4,fig_cost_4_5,fig_cost_4_6,fig_cost_4_7,fig_cost_4_8],
        bot_cost=[bot_cost_1,bot_cost_2,bot_cost_3_1,bot_cost_3_2,bot_cost_4_1,bot_cost_4_2,bot_cost_4_3,bot_cost_4_4,bot_cost_4_5,bot_cost_4_6,bot_cost_4_7,bot_cost_4_8],
        total_cost=[total_cost_1,total_cost_2,total_cost_3_1,total_cost_3_2,total_cost_4_1,total_cost_4_2,total_cost_4_3,total_cost_4_4,total_cost_4_5,total_cost_4_6,total_cost_4_7,total_cost_4_8]))
