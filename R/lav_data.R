# constructor for the 'lavData' class
#
# the lavData class describes how the data looks like
#  - do we have a full data frame, or only sample statistics?
#    (TODO: allow for patterns + freq, if data is categorical)
#  - variable type ("numeric", "ordered", ...)
#  - how many groups, how many observations, ...
#  - what about missing patterns?
#
# initial version: YR 14 April 2012

# extract the data we need for this particular model
lavData <- function(data          = NULL,          # data.frame
                    group         = NULL,          # multiple groups?
                    group.label   = NULL,          # custom group labels?
                    ov.names      = NULL,          # variables needed in model
                    ordered       = NULL,          # ordered variables
                    ov.names.x    = character(0),  # exo variables
                    std.ov        = FALSE,         # standardize ov's?
                    missing       = "listwise",    # remove missings?
                    sample.cov    = NULL,          # sample covariance(s)
                    sample.mean   = NULL,          # sample mean vector(s)
                    sample.nobs   = NULL,          # sample nobs
                    warn          = TRUE,          # produce warnings?
                    allow.single.case = FALSE      # allow single case (for newdata in predict)
                   ) 
{
    # four scenarios:
    #    0) data is already a lavData object: do nothing
    #    1) data is full data.frame (or a matrix)
    #    2) data are sample statistics only
    #    3) no data at all

    # 1) full data
    if(!is.null(data)) {
 
       # catch lavaan/lavData objects
        if(inherits(data, "lavData")) {
            return(data)
        } else if(inherits(data, "lavaan")) {
            return(data@Data)
        }

        # catch matrix 
        if(!is.data.frame(data)) {
            # is it a matrix?
            if(is.matrix(data)) {
                if(nrow(data) == ncol(data)) {
                    # perhaps it is a covariance matrix?
                    stop("lavaan WARNING: data argument looks like a covariance matrix; please use the sample.cov argument instead")
                } else {
                    # or perhaps it is a data matrix?
                    warning("lavaan WARNING: data argument has been coerced to a data.frame")
                    ### FIXME, we should avoid as.data.frame() and handle
                    ### data matrices directly
                    data <- as.data.frame(data, stringsAsFactors = FALSE)
                }
            } else {
                stop("lavaan ERROR: data object of class ", class(data))
            }
        }

        lavData <- lav_data_full(data              = data,
                                 group             = group,
                                 group.label       = group.label,
                                 ov.names          = ov.names,
                                 ordered           = ordered,
                                 ov.names.x        = ov.names.x,
                                 std.ov            = std.ov,
                                 missing           = missing,
                                 warn              = warn,
                                 allow.single.case = allow.single.case)
        sample.cov <- NULL # not needed, but just in case
    }
    
    
    # 2) sample moments
    if(is.null(data) && !is.null(sample.cov)) {
        
        # we also need the number of observations (per group)
        if(is.null(sample.nobs))
            stop("lavaan ERROR: please specify number of observations")

        # if meanstructure=TRUE, we need sample.mean
        #if(meanstructure == TRUE && is.null(sample.mean))
        #    stop("lavaan ERROR: please provide sample.mean if meanstructure=TRUE")
        # if group.equal contains "intercepts", we need sample.mean
        #if("intercepts" %in% group.equal && is.null(sample.mean))
        #    stop("lavaan ERROR: please provide sample.mean if group.equal contains \"intercepts\"")

        # list?
        if(is.list(sample.cov)) {
            # multiple groups, multiple cov matrices
            if(!is.null(sample.mean)) {
                stopifnot(length(sample.mean) == length(sample.cov))
            }
            # multiple groups, multiple cov matrices
            ngroups     <- length(sample.cov)
            LABEL <- names(sample.cov)
            if(is.null(group.label)) {
                if(is.null(LABEL))
                    group.label <- paste("Group ", 1:ngroups, sep="")
                else
                    group.label <- LABEL
            } else {
                if(is.null(LABEL)) {
                    stopifnot(length(group.label) == ngroups)
                } else {
                    # FIXME!!!!
                    # check if they match
                }   
            }
        } else {
            ngroups <- 1L; group.label <- character(0)
            if(!is.matrix(sample.cov))
                stop("lavaan ERROR: sample.cov must be a matrix or a list of matrices")
            sample.cov <- list(sample.cov)
        }

        # get ov.names
        if (is.null(ov.names)) {
            ov.names <- lapply(sample.cov, row.names)            
        } else if (!is.list(ov.names)) {
            # duplicate ov.names for each group
            tmp <- ov.names; ov.names <- vector("list", length=ngroups)
            ov.names[1:ngroups] <- list(tmp)
        } else {
            if (length(ov.names) != ngroups)
                stop("lavaan ERROR: ov.names assumes ", length(ov.names),
                     " groups; data contains ", ngroups, " groups")
            # nothing to do
        }

        # handle ov.names.x
        if(!is.list(ov.names.x)) {
            tmp <- ov.names.x; ov.names.x <- vector("list", length=ngroups)
            ov.names.x[1:ngroups] <- list(tmp)
        } else {
            if(length(ov.names.x) != ngroups)
                stop("lavaan ERROR: ov.names.x assumes ", length(ov.names.x),
                     " groups; data contains ", ngroups, " groups")
        }

        ov <- list()
        ov$name <- unique(unlist(c(ov.names,ov.names.x)))
        nvar    <- length(ov$name)
        ov$idx  <- rep(NA, nvar)
        ov$nobs <- rep(sample.nobs, nvar)
        ov$type <- rep("numeric", nvar)

        # if std.ov = TRUE, give a warning (suggested by Peter Westfall)
        if(std.ov) {
            warning("lavaan WARNING: std.ov argument is ignored if only sample statistics are provided.")
        }

        # construct lavData object
        lavData <- new("lavData",
                       data.type   = "moment",
                       ngroups     = ngroups, 
                       group       = character(0L),
                       group.label = group.label,
                       nobs        = as.list(sample.nobs),
                       norig       = as.list(sample.nobs),
                       ov.names    = ov.names, 
                       ov.names.x  = ov.names.x,
                       ov          = ov,
                       std.ov      = FALSE,
                       missing     = "listwise",
                       case.idx    = vector("list", length=ngroups),
                       Mp          = vector("list", length=ngroups),
                       Rp          = vector("list", length=ngroups),
                       X           = vector("list", length=ngroups),
                       eXo         = vector("list", length=ngroups)
                      )

    }

    # 3) data.type = "none":  both data and sample.cov are NULL
    if(is.null(data) && is.null(sample.cov)) {
        if(is.null(sample.nobs)) sample.nobs <- 0L
        sample.nobs <- as.list(sample.nobs)
        ngroups <- length(unlist(sample.nobs))
        if(ngroups > 1L)
            group.label <- paste("Group ", 1:ngroups, sep="")
        else
            group.label <- character(0)

        # handle ov.names
        if(is.null(ov.names)) {
            warning("lavaan WARNING: ov.names is NULL")
            ov.names <- character(0L)
        }
        if(!is.list(ov.names)) {
            tmp <- ov.names; ov.names <- vector("list", length=ngroups)
            ov.names[1:ngroups] <- list(tmp)
        } else {
            if (length(ov.names) != ngroups)
                stop("lavaan ERROR: ov.names assumes ", length(ov.names),
                     " groups; sample.nobs suggests ", ngroups, " groups")
            # nothing to do    
        }
        # handle ov.names.x
        if(!is.list(ov.names.x)) {
            tmp <- ov.names.x; ov.names.x <- vector("list", length=ngroups)
            ov.names.x[1:ngroups] <- list(tmp)
        }

        ov <- list()
        ov$name <- unique(unlist(c(ov.names,ov.names.x)))
        nvar    <- length(ov$name)
        ov$idx  <- rep(NA, nvar)
        ov$nobs <- rep(0L, nvar)
        ov$type <- rep("numeric", nvar)

        # construct lavData object
        lavData <- new("lavData",
                       data.type   = "none",
                       ngroups     = ngroups,
                       group       = character(0L),
                       group.label = group.label,
                       nobs        = sample.nobs,
                       norig       = sample.nobs,
                       ov.names    = ov.names, 
                       ov.names.x  = ov.names.x,
                       ov          = ov,
                       missing     = "listwise",
                       case.idx    = vector("list", length=ngroups),
                       Mp          = vector("list", length=ngroups),
                       Rp          = vector("list", length=ngroups),
                       X           = vector("list", length=ngroups),
                       eXo         = vector("list", length=ngroups)
                      )
    }

    lavData
}


# handle full data
lav_data_full <- function(data          = NULL,          # data.frame
                          group         = NULL,          # multiple groups?
                          group.label   = NULL,          # custom group labels?
                          ov.names      = NULL,          # variables needed 
                                                         # in model
                          ordered       = NULL,          # ordered variables
                          ov.names.x    = character(0),  # exo variables
                          std.ov        = FALSE,         # standardize ov's?
                          missing       = "listwise",    # remove missings?
                          warn          = TRUE,          # produce warnings?
                          allow.single.case = FALSE      # allow single case?
                        )
{
    # number of groups and group labels
    if(!is.null(group) && length(group) > 0L) {
        if(!(group %in% names(data))) {
            stop("lavaan ERROR: grouping variable ", sQuote(group),
                 " not found;\n  ",
                 "variable names found in data frame are:\n  ", 
                 paste(names(data), collapse=" "))
        }
        # note: by default, we use the order as in the data; 
        # not as in levels(data[,group])
        if(length(group.label) == 0L) {
            group.label <- unique(as.character(data[,group]))
            if(warn && any(is.na(group.label))) {
                warning("lavaan WARNING: group variable ", sQuote(group), 
                        " contains missing values\n", sep="")
            }
            group.label <- group.label[!is.na(group.label)]
        } else {
            group.label <- unique(as.character(group.label))
            # check if user-provided group labels exist
            LABEL <- unique(as.character(data[,group]))
            idx <- match(group.label, LABEL)
            if(warn && any(is.na(idx))) {
                warning("lavaan WARNING: some group.labels do not appear ",
                        "in the grouping variable: ",  
                        paste(group.label[which(is.na(idx))], collapse=" "))
            }
            group.label <- group.label[!is.na(idx)]
            # any groups left?
            if(length(group.label) == 0L)
                stop("lavaan ERROR: no group levels left; check the group.label argument")
        }
        ngroups     <- length(group.label)
    } else {
        if(warn && length(group.label) > 0L)
            warning("lavaan WARNING: `group.label' argument",
                    " will be ignored if `group' argument is missing")
        ngroups <- 1L
        group.label <- character(0L)
        group <- character(0L)
    }

    # ov.names
    if(is.null(ov.names)) {
        ov.names <- names(data)
        # remove 'group' name from ov.names
        if(length(group) > 0L) {
            group.idx <- which(ov.names == group)
            ov.names <- ov.names[-group.idx]
        }
    }

    if(ngroups > 1L) {
        if(is.list(ov.names)) {
            if(length(ov.names) != ngroups)
                stop("lavaan ERROR: ov.names assumes ", length(ov.names),
                     " groups; data contains ", ngroups, " groups")
        } else {
            tmp <- ov.names
            ov.names <- vector("list", length=ngroups)
            ov.names[1:ngroups] <- list(tmp)
        }
        if(is.list(ov.names.x)) {
            if(length(ov.names.x) != ngroups)
                stop("lavaan ERROR: ov.names assumes ", length(ov.names.x),
                     " groups; data contains ", ngroups, " groups")
        } else {
            tmp <- ov.names.x
            ov.names.x <- vector("list", length=ngroups)
            ov.names.x[1:ngroups] <- list(tmp)
        }
    } else {
        if(is.list(ov.names)) {
            if(length(ov.names) > 1L)
                stop("lavaan ERROR: model syntax defines multiple groups; data suggests a single group")
        } else {
            ov.names <- list(ov.names)
        }
        if(is.list(ov.names.x)) {
            if(length(ov.names.x) > 1L)
                stop("lavaan ERROR: model syntax defines multiple groups; data suggests a single group")
        } else {
            ov.names.x <- list(ov.names.x)
        }
    }

    # construct OV list -- FIXME: surely, this can be done more elegantly??
    for(g in 1:ngroups) {
        # does the data contain all the observed variables
        # needed in the user-specified model for this group
        ov.all <- unique(ov.names[[g]], ov.names.x[[g]]) # no overlap if categ
        idx.missing <- which(!(ov.all %in% names(data)))
        if(length(idx.missing)) {
            stop("lavaan ERROR: missing observed variables in dataset: ",
                 paste(ov.all[idx.missing], collapse=" "))
        }
    }


    # here, we know for sure all ov.names exist in the data.frame
    # create varTable
    # FIXME: should we add the 'group' variable (no for now)
    ov <- lav_dataframe_vartable(frame = data, ov.names = ov.names, 
                                 ov.names.x = ov.names.x, ordered = ordered,
                                 as.data.frame. = FALSE)

    # do some checking
    # check for unordered factors (but only if nlev > 2)
    if("factor" %in%  ov$type) {
        f.names <- ov$name[ov$type == "factor" & ov$nlev > 2L]
        if(warn && any(f.names %in% unlist(ov.names)))
            warning(paste("lavaan WARNING: unordered factor(s) with more than 2 levels detected in data:", paste(f.names, collapse=" ")))
    }
    # check for ordered exogenous variables
    if("ordered" %in% ov$type[ov$name %in% unlist(ov.names.x)]) {
        f.names <- ov$name[ov$type == "ordered" & 
                           ov$name %in% unlist(ov.names.x)]
        if(warn && any(f.names %in% unlist(ov.names.x)))
            warning(paste("lavaan WARNING: exogenous variable(s) declared as ordered in data:", paste(f.names, collapse=" ")))
    }
    # check for zero-cases
    idx <- which(ov$nobs == 0L | ov$var == 0)
    if(length(idx) > 0L) {
        OV <- as.data.frame(ov)
        rn <- rownames(OV)
        rn[idx] <- paste(rn[idx], "***", sep="")
        rownames(OV) <- rn
        print(OV)
        stop("lavaan ERROR: some variables have no values (only missings) or no variance")
    }
    # check for single cases (no variance!)
    idx <- which(ov$nobs == 1L | (ov$type == "numeric" & !is.finite(ov$var)))
    if(!allow.single.case && length(idx) > 0L) {
        OV <- as.data.frame(ov)
        rn <- rownames(OV)
        rn[idx] <- paste(rn[idx], "***", sep="")
        rownames(OV) <- rn
        print(OV)
        stop("lavaan ERROR: some variables have only 1 observation or no finite variance")
    }
    # check for ordered variables with only 1 level
    idx <- which(ov$type == "ordered" & ov$nlev == 1L)
    if(length(idx) > 0L) {
        OV <- as.data.frame(ov)
        rn <- rownames(OV)
        rn[idx] <- paste(rn[idx], "***", sep="")
        rownames(OV) <- rn
        print(OV)
        stop("lavaan ERROR: ordered variable(s) has/have only 1 level")
    }
    # check for mix small/large variances (NOT including exo variables)
    if(!std.ov && !allow.single.case && warn && any(ov$type == "numeric")) {
        num.idx <- which(ov$type == "numeric" & ov$exo == 0L)
        if(length(num.idx) > 0L) {
            min.var <- min(ov$var[num.idx])
            max.var <- max(ov$var[num.idx])
            rel.var <- max.var/min.var
            if(rel.var > 1000) {
                warning("lavaan WARNING: some observed variances are (at least) a factor 1000 times larger than others; use varTable(fit) to investigate")
            }
        }
    }
    # check for all-exogenous variables (eg in f <~ x1 + x2 + x3)
    if(all(ov$exo == 1L)) {
        warning("lavaan WARNING: all observed variables are exogenous; model may not be identified")
    }

    # prepare empty list for data.matrix per group
    case.idx <- vector("list", length=ngroups)
    nobs     <- vector("list", length=ngroups)
    norig    <- vector("list", length=ngroups)
    Mp       <- vector("list", length=ngroups)
    X        <- vector("list", length=ngroups)
    eXo      <- vector("list", length=ngroups)
    Rp       <- vector("list", length=ngroups)

    # for each group
    for(g in 1:ngroups) {

        # extract variables in correct order
        ov.idx  <- ov$idx[match(ov.names[[g]],   ov$name)]
        exo.idx <- ov$idx[match(ov.names.x[[g]], ov$name)] 
        all.idx <- unique(c(ov.idx, exo.idx))

        # extract cases per group
        if(ngroups > 1L || length(group.label) > 0L) {
            if(missing == "listwise") {
                case.idx[[g]] <- which(data[, group] == group.label[g] &
                                       complete.cases(data[,all.idx]))
                nobs[[g]] <- length(case.idx[[g]])
                norig[[g]] <- length(which(data[, group] == group.label[g]))
            } else if(missing == "pairwise" && length(exo.idx) > 0L) {
                case.idx[[g]] <- which(data[, group] == group.label[g] &
                                       complete.cases(data[,exo.idx]))
                nobs[[g]] <- length(case.idx[[g]])
                norig[[g]] <- length(which(data[, group] == group.label[g]))    
            } else {
                case.idx[[g]] <- which(data[, group] == group.label[g])
                nobs[[g]] <- norig[[g]] <- length(case.idx[[g]])
            }
        } else {
            if(missing == "listwise") {
                case.idx[[g]] <- which(complete.cases(data[,all.idx]))
                nobs[[g]] <- length(case.idx[[g]])
                norig[[g]] <- nrow(data)
            } else if(missing == "pairwise" && length(exo.idx) > 0L) {
                case.idx[[g]] <- which(complete.cases(data[,exo.idx]))
                nobs[[g]] <- length(case.idx[[g]])
                norig[[g]] <- nrow(data)
            } else {
                case.idx[[g]] <- 1:nrow(data)
                nobs[[g]] <- norig[[g]] <- length(case.idx[[g]])
            }
        }

        # extract data
        X[[g]] <- data.matrix( data[case.idx[[g]], ov.idx, drop=FALSE] )
        dimnames(X[[g]]) <- NULL ### copy?

        # manually construct integers for user-declared 'ordered' factors
        # FIXME: is this really (always) needed???
        #  (but it is still better than doing lapply(data[,idx], ordered) which
        #   generated even more copies)
        user.ordered.names <- ov$name[ov$type == "ordered" &
                                      ov$user == 1L]
        user.ordered.idx <- which(ov.names[[g]] %in% user.ordered.names)
        if(length(user.ordered.idx) > 0L) {
            for(i in user.ordered.idx) {
                X[[g]][,i] <- as.numeric(as.factor(X[[g]][,i]))
            }
        }

        ## FIXME: 
        ## - why also in X? (for samplestats, for now)
        if(length(exo.idx) > 0L) {
            eXo[[g]] <- data.matrix( data[case.idx[[g]], exo.idx, drop=FALSE] )
            dimnames(eXo[[g]]) <- NULL
        } else {
            eXo[g] <- list(NULL)
        }
        #print( tracemem(X[[g]]) )

        # standardize observed variables? numeric only!
        if(std.ov) {
            num.idx <- which(ov.names[[g]] %in% ov$name & ov$type == "numeric")
            if(length(num.idx) > 0L) {
                X[[g]][,num.idx]  <- scale(X[[g]][,num.idx,drop=FALSE])[,] 
                # three copies are made!!!!!
            }
            if(length(exo.idx) > 0L) {
                eXo[[g]] <- scale(eXo[[g]])[,]
            }
        }

        # missing data
        if(missing != "listwise") {
            # get missing patterns
            Mp[[g]] <- getMissingPatterns(X[[g]])
            # checking!
            if(length(Mp[[g]]$empty.idx) > 0L) {
                X[[g]] <- X[[g]][-Mp[[g]]$empty.idx,,drop=FALSE]
                # remove from case.idx
                # idx <- which(case.idx[[g]] %in% Mp[[g]]$empty.idx)
                empty.idx <- Mp[[g]]$empty.idx
                empty.case.idx <- case.idx[[g]][empty.idx]
                case.idx[[g]] <- case.idx[[g]][-empty.idx]
                # remove from eXo
                if(length(exo.idx) > 0L) {
                    eXo[[g]] <- eXo[[g]][-empty.idx,,drop=FALSE]
                }
                if(warn) {
                    warning("lavaan WARNING: some cases are empty and will be removed:\n  ", paste(empty.case.idx, collapse=" "))
                }
                # give empty.idx case.idx? (for multiple groups):
                Mp[[g]]$empty.idx <- empty.case.idx
            }
            if(warn && any(Mp[[g]]$coverage < 0.1)) {
                warning("lavaan WARNING: due to missing values, some pairwise combinations have less than 10% coverage")
            }
            # in case we had observations with only missings
            nobs[[g]] <- Mp[[g]]$nobs
        }

        # response patterns (categorical only, no exogenous variables)
        all.ordered <- all(ov.names[[g]] %in% ov$name[ov$type == "ordered"])
        if(length(exo.idx) == 0L && all.ordered) {
            Rp[[g]] <- lav_data_resppatterns(X[[g]])
        }

        # warn if we have a small number of observations (but NO error!)
        if( !allow.single.case && warn && 
            nobs[[g]] < (nvar <- length(ov.idx)) ) {
            txt <- ""
            if(ngroups > 1L) txt <- paste(" in group ", g, sep="")
            warning("lavaan WARNING: small number of observations (nobs < nvar)", txt,
                    "\n  nobs = ", nobs[[g]], " nvar = ", nvar)
        }

    } # ngroups

    lavData <- new("lavData",
                      data.type       = "full",
                      ngroups         = ngroups,
                      group           = group,
                      group.label     = group.label,
                      std.ov          = std.ov,
                      nobs            = nobs,
                      norig           = norig,
                      ov.names        = ov.names,
                      ov.names.x      = ov.names.x,
                      #ov.types        = ov.types,
                      #ov.idx          = ov.idx,
                      ov              = ov,
                      case.idx        = case.idx,
                      missing         = missing,
                      X               = X,
                      eXo             = eXo,
                      Mp              = Mp,
                      Rp              = Rp
                     )
    lavData                     
}

# get response patterns (empty records have already been removed!)
lav_data_resppatterns <- function(X) {

    ntotal <- nrow(X); nvar <- ncol(X)

    # identify, label and sort response patterns 
    id <- apply(X, MARGIN = 1, paste, collapse = "")

    # sort patterns (from high occurence to low occurence)
    TABLE <- sort(table(id), decreasing = TRUE)
    order <- names(TABLE)
    npatterns <- length(TABLE)
    pat <- X[match(order, id), , drop = FALSE]
    row.names(pat) <- as.character(TABLE)

    total.patterns <- prod(apply(X, 2, max))
    empty.patterns <- total.patterns - npatterns
    # return a list
    #out <- list(nobs=ntotal, nvar=nvar,
    #            id=id, npatterns=npatterns,
    #            order=order, pat=pat)

    # only return pat
    out <- list(npatterns=npatterns, pat=pat, total.patterns=total.patterns,
                empty.patterns=empty.patterns)

    out
}

setMethod("show", "lavData",
function(object) {
    # print 'lavData' object
    lav_data_print_short(object)
})

lav_data_print_short <- function(object) {
     # flag
     listwise <- object@missing == "listwise"

     if(object@ngroups == 1L) {
        if(listwise) {
            cat(sprintf("  %-40s", ""), sprintf("  %10s", "Used"),
                                        sprintf("  %10s", "Total"),
                "\n", sep="")
        }
        t0.txt <- sprintf("  %-40s", "Number of observations")
        t1.txt <- sprintf("  %10i", object@nobs[[1L]])
        t2.txt <- ifelse(listwise,
                  sprintf("  %10i", object@norig[[1L]]), "")
        cat(t0.txt, t1.txt, t2.txt, "\n", sep="")
    } else {
        if(listwise) {
            cat(sprintf("  %-40s", ""), sprintf("  %10s", "Used"),
                                        sprintf("  %10s", "Total"),
                "\n", sep="")
        }
        t0.txt <- sprintf("  %-40s", "Number of observations per group")
        cat(t0.txt, "\n")
        for(g in 1:object@ngroups) {
            t.txt <- sprintf("  %-40s  %10i", object@group.label[[g]],
                                              object@nobs[[g]])
            t2.txt <- ifelse(listwise,
                      sprintf("  %10i", object@norig[[g]]), "")
            cat(t.txt, t2.txt, "\n", sep="")
        }
    }
    cat("\n")

    # missing patterns?
    if(!is.null(object@Mp[[1L]])) {
        if(object@ngroups == 1L) {
            t0.txt <- sprintf("  %-40s", "Number of missing patterns")
            t1.txt <- sprintf("  %10i",
                              object@Mp[[1L]]$npatterns)
            cat(t0.txt, t1.txt, "\n\n", sep="")
        } else {
            t0.txt <- sprintf("  %-40s", "Number of missing patterns per group")
            cat(t0.txt, "\n")
            for(g in 1:object@ngroups) {
                t.txt <- sprintf("  %-40s  %10i", object@group.label[[g]],
                                 object@Mp[[g]]$npatterns)
                cat(t.txt, "\n", sep="")
            }
            cat("\n")
        }
    }
}

