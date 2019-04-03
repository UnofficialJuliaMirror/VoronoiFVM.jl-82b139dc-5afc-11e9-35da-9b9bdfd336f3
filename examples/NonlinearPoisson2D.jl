module NonlinearPoisson2D

using Printf
using TwoPointFluxFVM

if isinteractive()
    using PyPlot
end


mutable struct Physics
    reaction::Function
    flux::Function
    source::Function
    storage::Function
    eps::Float64 
    Physics()=new()
end


function main(;n=10,pyplot=false,verbose=false)
    
    h=1.0/convert(Float64,n)
    X=collect(0.0:h:1.0)
    Y=collect(0.0:h:1.0)


    grid=TwoPointFluxFVM.Grid(X,Y)
    
    physics=Physics()
    physics.eps=1.0e-2
    
    physics.reaction=function(physics,node,f,u)
        f[1]=u[1]^2
    end
    
    physics.flux=function(physics,edge,f,uk,ul)
        f[1]=physics.eps*(uk[1]^2-ul[1]^2)
    end 
    
    physics.source=function(physics,node,f)
        x1=node.coord[1]-0.5
        x2=node.coord[2]-0.5
        f[1]=exp(-20*(x1^2+x2^2))
    end 
    
    physics.storage=function(physics,node, f,u)
        f[1]=u[1]
    end
    
    
    sys=TwoPointFluxFVM.System(grid,physics,1)
    add_species(sys,1,[1])

    sys.boundary_values[1,2]=0.1
    sys.boundary_values[1,4]=0.1
    
    sys.boundary_factors[1,2]=TwoPointFluxFVM.Dirichlet
    sys.boundary_factors[1,4]=TwoPointFluxFVM.Dirichlet
    
    inival=unknowns(sys)
    inival.=0.5


    control=TwoPointFluxFVM.NewtonControl()
    control.verbose=verbose
    control.tol_linear=1.0e-5
    control.max_lureuse=10
    tstep=0.01
    time=0.0
    u15=0
    while time<1.0
        time=time+tstep
        U=solve(sys,inival,control=control,tstep=tstep)
        u15=U[15]
        inival.=U

        if verbose
            @printf("time=%g\n",time)
        end

        tstep*=1.0
        if pyplot
            levels=collect(0:0.01:1)
            PyPlot.clf()
            contourf(X,Y,reshape(values(U),length(X),length(Y)), cmap=ColorMap("hot"),levels=levels)
            colorbar()
            pause(1.0e-10)
        end
    end
    return u15
end

end