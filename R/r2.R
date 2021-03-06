#' @title Compute the model's R2
#' @name r2
#'
#' @description Calculate the R2 value for different model objects. Depending
#'   on the model, R2, pseudo-R2 or marginal / adjusted R2 values are returned.
#'
#' @param model A statistical model.
#' @param ... Arguments passed down to the related r2-methods.
#'
#' @return Returns a list containing values related to the most appropriate R2
#'   for the given model. See the list below:
#' \itemize{
#'   \item Logistic models: \link[=r2_tjur]{Tjur's R2}
#'   \item General linear models: \link[=r2_nagelkerke]{Nagelkerke's R2}
#'   \item Multinomial Logit: \link[=r2_mcfadden]{McFadden's R2}
#'   \item Models with zero-inflation: \link[=r2_zeroinflated]{R2 for zero-inflated models}
#'   \item Mixed models: \link[=r2_nakagawa]{Nakagawa's R2}
#'   \item Bayesian models: \link[=r2_bayes]{R2 bayes}
#' }
#'
#' @seealso \code{\link{r2_bayes}}, \code{\link{r2_coxsnell}}, \code{\link{r2_kullback}},
#'   \code{\link{r2_loo}}, \code{\link{r2_mcfadden}}, \code{\link{r2_nagelkerke}},
#'   \code{\link{r2_nakagawa}}, \code{\link{r2_tjur}}, \code{\link{r2_xu}} and
#'   \code{\link{r2_zeroinflated}}.
#'
#' @examples
#' model <- glm(vs ~ wt + mpg, data = mtcars, family = "binomial")
#' r2(model)
#'
#' if (require("lme4")) {
#'   model <- lmer(Sepal.Length ~ Petal.Length + (1 | Species), data = iris)
#'   r2(model)
#' }
#' @export
r2 <- function(model, ...) {
  UseMethod("r2")
}




# Default models -----------------------------------------------


#' @importFrom insight print_color
#' @export
r2.default <- function(model, ...) {
  insight::print_color(sprintf("'r2()' does not support models of class '%s'.\n", class(model)[1]), "red")
  return(NA)
}


#' @importFrom stats pf
#' @export
r2.lm <- function(model, ...) {
  model_summary <- summary(model)

  out <- list(
    R2 = model_summary$r.squared,
    R2_adjusted = model_summary$adj.r.squared
  )

  names(out$R2) <- "R2"
  names(out$R2_adjusted) <- "adjusted R2"

  f.stat <- model_summary$fstatistic[1]
  DoF <- model_summary$fstatistic[2]
  DoF_residual <- model_summary$fstatistic[3]

  if (!is.null(f.stat)) {
    attr(out, "p") <- stats::pf(f.stat, DoF, DoF_residual, lower.tail = FALSE)
    attr(out, "F") <- f.stat
    attr(out, "df") <- DoF
    attr(out, "df_residual") <- DoF_residual
  }

  attr(out, "model_type") <- "Linear"
  structure(class = "r2_generic", out)
}



#' @importFrom stats summary.lm
#' @export
r2.aov <- function(model, ...) {
  model_summary <- stats::summary.lm(model)

  out <- list(
    R2 = model_summary$r.squared,
    R2_adjusted = model_summary$adj.r.squared
  )

  names(out$R2) <- "R2"
  names(out$R2_adjusted) <- "adjusted R2"

  attr(out, "model_type") <- "Anova"
  structure(class = "r2_generic", out)
}



#' @importFrom stats pf
#' @export
r2.mlm <- function(model, ...) {
  model_summary <- summary(model)

  out <- lapply(names(model_summary), function(i) {
    tmp <- list(
      R2 = model_summary[[i]]$r.squared,
      R2_adjusted = model_summary[[i]]$adj.r.squared,
      Response = sub("Response ", "", i)
    )
    names(tmp$R2) <- "R2"
    names(tmp$R2_adjusted) <- "adjusted R2"
    names(tmp$Response) <- "Response"
    tmp
  })

  names(out) <- names(model_summary)

  attr(out, "model_type") <- "Multivariate Linear"
  structure(class = "r2_mlm", out)
}



#' @importFrom insight model_info
#' @export
r2.glm <- function(model, ...) {
  if (insight::model_info(model)$is_logit) {
    list("R2_Tjur" = r2_tjur(model))
  } else {
    list("R2_Nagelkerke" = r2_nagelkerke(model))
  }
}

#' @export
r2.glmx <- r2.glm





# Cox & Snell R2 ---------------------


#' @export
r2.BBreg <- function(model, ...) {
  list("R2_CoxSnell" = r2_coxsnell(model))
}

#' @export
r2.crch <- r2.BBreg






# Nagelkerke R2 ----------------------


#' @export
r2.censReg <- function(model, ...) {
  list("R2_Nagelkerke" = r2_nagelkerke(model))
}

#' @export
r2.cpglm <- r2.censReg

#' @export
r2.clm <- r2.censReg

#' @export
r2.clm2 <- r2.censReg

#' @export
r2.coxph <- r2.censReg

#' @export
r2.multinom <- r2.censReg

#' @export
r2.mclogit <- r2.censReg

#' @export
r2.polr <- r2.censReg

#' @export
r2.survreg <- r2.censReg

#' @export
r2.truncreg <- r2.censReg

#' @export
r2.bracl <- r2.censReg

#' @export
r2.brmultinom <- r2.censReg

#' @export
r2.bife <- r2.censReg









# Zeroinflated R2 ------------------


#' @export
r2.hurdle <- function(model, ...) {
  r2_zeroinflated(model)
}

#' @export
r2.zerotrunc <- r2.hurdle

#' @export
r2.zeroinfl <- r2.hurdle






# Nakagawa R2 ----------------------


#' @export
r2.merMod <- function(model, ...) {
  r2_nakagawa(model, ...)
}

#' @export
r2.glmmTMB <- r2.merMod

#' @export
r2.cpglmm <- r2.merMod

#' @export
r2.glmmadmb <- r2.merMod

#' @export
r2.lme <- r2.merMod

#' @export
r2.clmm <- r2.merMod

#' @export
r2.mixed <- r2.merMod

#' @export
r2.MixMod <- r2.merMod

#' @export
r2.rlmerMod <- r2.merMod


#' @export
r2.wbm <- function(model, ...) {
  out <- r2_nakagawa(model)

  if (is.null(out) || is.na(out)) {
    s <- summary(model)

    r2_marginal <- s$mod_info_list$pR2_fe
    r2_conditional <- s$mod_info_list$pR2_total

    names(r2_conditional) <- "Conditional R2"
    names(r2_marginal) <- "Marginal R2"

    out <- list(
      "R2_conditional" = r2_conditional,
      "R2_marginal" = r2_marginal
    )

    attr(out, "model_type") <- "Fixed Effects"
    class(out) <- "r2_nakagawa"
  }

  out
}






# Bayes R2 ------------------------


#' @export
r2.brmsfit <- function(model, ...) {
  r2_bayes(model, ...)
}

#' @export
r2.stanreg <- r2.brmsfit







# Other methods ------------------------------


#' @export
r2.betareg <- function(model, ...) {
  list(
    R2 = c(`Pseudo R2` = model$pseudo.r.squared)
  )
}


#' @export
r2.rma <- function(model, ...) {
  s <- summary(model)

  if (is.null(s$R2)) {
    return(NULL)
  }

  out <- list(R2 = s$R2 / 100)
  attr(out, "model_type") <- "Meta-Analysis"
  structure(class = "r2_generic", out)
}



#' @export
r2.feis <- function(model, ...) {
  out <- list(
    R2 = c(`R2` = model$r2),
    R2_adjusted = c(`adjusted R2` = model$adj.r2)
  )

  attr(out, "model_type") <- "Fixed Effects Individual Slope"
  structure(class = "r2_generic", out)
}



#' @export
r2.fixest <- function(model, ...) {
  if (!requireNamespace("fixest", quietly = TRUE)) {
    stop("Package 'fixest' needed to calculate R2. Please install it.")
  }

  r2 <- fixest::r2(model)

  out_normal <- .compact_list(list(
    R2 = r2["r2"],
    R2_adjusted = r2["ar2"],
    R2_within = r2["wr2"],
    R2_within_adjusted = r2["war2"]
  ), remove_na = TRUE)

  out_pseudo <- .compact_list(list(
    R2 = r2["pr2"],
    R2_adjusted = r2["apr2"],
    R2_within = r2["wpr2"],
    R2_within_adjusted = r2["wapr2"]
  ), remove_na = TRUE)

  if (length(out_normal)) {
    out <- out_normal
  } else {
    out <- out_pseudo
  }

  attr(out, "model_type") <- "Fixed Effects"
  structure(class = "r2_generic", out)
}



#' @export
r2.felm <- function(model, ...) {
  model_summary <- summary(model)
  out <- list(
    R2 = c(`R2` = model_summary$r2),
    R2_adjusted = c(`adjusted R2` = model_summary$r2adj)
  )

  attr(out, "model_type") <- "Fixed Effects"
  structure(class = "r2_generic", out)
}




#' @export
r2.iv_robust <- function(model, ...) {
  out <- list(
    R2 = c(`R2` = model$r.squared),
    R2_adjusted = c(`adjusted R2` = model$adj.r.squared)
  )

  attr(out, "model_type") <- "Two-Stage Least Squares Instrumental-Variable"
  structure(class = "r2_generic", out)
}



#' @export
r2.ivreg <- function(model, ...) {
  model_summary <- summary(model)
  out <- list(
    R2 = c(`R2` = model_summary$r.squared),
    R2_adjusted = c(`adjusted R2` = model_summary$adj.r.squared)
  )

  attr(out, "model_type") <- "Instrumental-Variable"
  structure(class = "r2_generic", out)
}



#' @export
r2.bigglm <- function(model, ...) {
  list("R2_CoxSnell" = summary(model)$rsq)
}



#' @export
r2.biglm <- function(model, ...) {
  df.int <- ifelse(insight::has_intercept(model), 1, 0)
  n <- insight::n_obs(model)

  rsq <- summary(model)$rsq
  adj.rsq <- 1 - (1 - rsq) * ((n - df.int) / model$df.resid)

  out <- list(
    R2 = rsq,
    R2_adjusted = adj.rsq
  )

  names(out$R2) <- "R2"
  names(out$R2_adjusted) <- "adjusted R2"

  attr(out, "model_type") <- "Linear"
  structure(class = "r2_generic", out)
}



#' @export
r2.lmrob <- function(model, ...) {
  model_summary <- summary(model)
  out <- list(
    R2 = c(`R2` = model_summary$r.squared),
    R2_adjusted = c(`adjusted R2` = model_summary$adj.r.squared)
  )

  attr(out, "model_type") <- "Robust Linear"
  structure(class = "r2_generic", out)
}

#' @export
r2.complmrob <- r2.lmrob



#' @export
r2.mlogit <- function(model, ...) {
  list("R2_McFadden" = r2_mcfadden(model))
}



#' @export
r2.mmclogit <- function(model, ...) {
  list(R2 = NA)
}



#' @export
r2.Arima <- function(model, ...) {
  if (!requireNamespace("forecast", quietly = TRUE)) {
    list(R2 = NA)
  } else {
    list(R2 = stats::cor(stats::fitted(model), insight::get_data(model))^2)
  }
}



#' @export
r2.plm <- function(model, ...) {
  model_summary <- summary(model)
  out <- list(
    "R2" = c(`R2` = model_summary$r.squared[1]),
    "R2_adjusted" = c(`adjusted R2` = model_summary$r.squared[2])
  )

  attr(out, "model_type") <- "Panel Data"
  structure(class = "r2_generic", out)
}



#' @export
r2.svyglm <- function(model, ...) {
  rsq <- (model$null.deviance - model$deviance) / model$null.deviance
  rsq.adjust <- 1 - ((1 - rsq) * (model$df.null / model$df.residual))

  out <- list(
    R2 = c(`R2` = rsq),
    R2_adjusted = c(`adjusted R2` = rsq.adjust)
  )

  attr(out, "model_type") <- "Survey"
  structure(class = "r2_generic", out)
}



#' @export
r2.vglm <- function(model, ...) {
  list("R2_McKelvey" = r2_mckelvey(model))
}

#' @export
r2.vgam <- r2.vglm



#' @export
r2.DirichletRegModel <- function(model, ...) {
  list("R2_Nagelkerke" = r2_nagelkerke(model))
}
