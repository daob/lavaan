# class definitions
# 
# initial version: YR 25/03/2009
# added ModelSyntax: YR 02/08/2010
# deleted ModelSyntax: YR 01/11/2010 (using flattened model syntax now)

setClass("lavData",
    representation(
        data.type="character",     # "full", "moment" or "none"
        ngroups="integer",         # number of groups
        group="character",         # group variable
        group.label="character",   # group labels
        std.ov="logical",          # standardize observed variables?
        nobs="list",               # effective number of observations
        norig="list",              # original number of observations
        ov.names="list",           # variable names (per group)
        ov.names.x="list",         # exo variable names (per group)
        #ov.types="list",           # variable types (per group)
        #ov.idx="list",             # column indices (all observed variables)
        ov="list",                 # variable table
        case.idx="list",           # case indices per group
        missing="character",       # "listwise" or not?
        Mp="list",                 # if not complete, missing patterns
                                   # we need this here, to get nobs right!
        Rp="list",                 # response patterns (categorical only)
        eXo="list",                # local copy exo only
        X="list"                   # local copy
    )
)


setClass("lavSampleStats",         # sample moments
    representation(
        CAT="list",
        var="list",                # variances
        cov="list",                # observed var/cov matrix (per group)
        mean="list",               # observed mean vector (per group)
        th="list",                 # thresholds for non-numeric var (per group)
        th.nox="list",             # thresholds ignoring eXo
        th.idx="list",
        th.names="list",           # threshold names
        slopes="list",             # slopes exo
        mean.x="list",             # mean exo
        cov.x="list",              # variance/covariance exo
        bifreq="list",             # bivariate frequency tables
        group.w="list",            # group weight

        nobs="list",               # effective number of obs (per group)
        ntotal="integer",          # total number of obs (all groups)
        ngroups="integer",         # number of groups

        icov="list",               # inverse of observed cov (per group)
        cov.log.det="list",        # log det of observed cov (per group)
        ridge="numeric",           # ridge constant
        WLS.obs="list",            # all relevant observed stats in a vector
        WLS.V="list",              # weight matrix for GLS/WLS
        WLS.VD="list",             # diagonal of weight matrix only
        NACOV="list",              # N times the asymptotic covariance matrix

        missing.flag="logical",    # missing patterns?
        missing="list",            # missingness information
        missing.h1="list"          # h1 model
    )
)

setClass("Model",          # MATRIX representation of the sem model
    representation(
        GLIST="list",              # list of all model matrices (for all groups)
        dimNames="list",           # dim names for the model matrices
        isSymmetric="logical",     # model matrix symmetric?
        mmSize="integer",          # model matrix size (unique only)

        representation="character",  # stub, until we define more classes
        meanstructure="logical",
        categorical="logical",
        group.w.free="logical",
        link="character",
        control="list",

        ngroups="integer",
        nmat="integer",
        nvar="integer",
        num.idx="list",
        th.idx="list",

        nx.free="integer",
        nx.unco="integer",
        nx.user="integer",

        m.free.idx="list",
        x.free.idx="list",
        m.unco.idx="list",
        x.unco.idx="list",
        m.user.idx="list",
        x.user.idx="list",
        x.def.idx="integer",
        x.ceq.idx="integer",
        x.cin.idx="integer",
        #x.free.var.idx="integer",

        eq.constraints="logical",
        eq.constraints.K="matrix",
        eq.constraints.k0="numeric",

        def.function="function",
        ceq.function="function",
        ceq.jacobian="function",
        ceq.linear.idx="integer",
        ceq.nonlinear.idx="integer",
        cin.function="function",
        cin.jacobian="function",
        cin.linear.idx="integer",
        cin.nonlinear.idx="integer",
        con.jac="matrix",
        con.lambda="numeric",

        nexo="integer",
        fixed.x="logical",
        parameterization="character",
        ov.x.dummy.ov.idx="list",
        ov.x.dummy.lv.idx="list",
        ov.y.dummy.ov.idx="list",
        ov.y.dummy.lv.idx="list"

    )
)

setClass("Fit",
    representation(
        npar="integer",            # number of free parameters
        #ndat="integer",
        #df="integer",
        x="numeric",               # x
        partrace="matrix",         # parameter trace
        start="numeric",           # starting values
        est="numeric",             # estimated values
        se="numeric",              # standard errors
        fx="numeric",
        fx.group="numeric",
        iterations="integer",      # number of iterations
        converged="logical",
        control="list",
        Sigma.hat="list",
        Mu.hat="list",
        TH="list",
        test="list"
    )
)

setClass("lavaan",
    representation(
        call        = "call",            # matched call
        timing      = "list",            # timing information
        Options     = "list",            # lavaanOptions
        ParTable    = "list",            # parameter table user-specified model
        pta         = "list",            # parameter table attributes
        Data        = "lavData",         # full data
        SampleStats = "lavSampleStats",  # sample statistics
        Model       = "Model",           # internal matrix representation
        Cache       = "list",            # housekeeping stuff
        Fit         = "Fit"              # fitted results
    ) 
)






                      
