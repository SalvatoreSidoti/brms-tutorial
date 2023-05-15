# Greetings, Fellow Bayesians!
## Discussion Points for Bayesian Journal Club 05/15/2023

Another issue that the tutorial does not explain: If you want to do `loo()` comparisons, run the `brm()` models with `save_pars = save_pars(all = TRUE)`. For example, the first model should be written as:

    france1_mbrms <- brm(
    pop ~ I(year - 1975),
    data = France,
    family = poisson(),
    save_pars = save_pars(all = TRUE),
    chains = 3,
    iter = 3000,
    warmup = 1000)

### Review: What is LOO?

LOO (leave-one-out cross-validation) is a method used to estimate the out-of-sample predictive performance of a model. Essentially, it evaluates how well the model performs on data it has not seen before, which is a critical aspect of model validation.

The option `save_pars = save_pars(all = TRUE)` is used when fitting a model with brm(). This tells brm() to save all of the parameters of the model. This includes not only the typical regression coefficients, but also other parameters like variance components and parameters of the prior distributions.

The reason you need to save all parameters when you want to use `loo()` is that `loo()` operates by reweighting the importance of the different data points in your sample, which is done in the parameter space. If some parameters are not saved, then loo() will not have access to the full information it needs to perform the reweighting correctly. Thus, to ensure that loo() can do its job accurately and effectively, you must fit your model with `save_pars = save_pars(all = TRUE)`.

### Output from 'loo()'

    Output of model 'france1_mbrms':

    Computed from 6000 by 70 log-likelihood matrix

    Estimate	SE
    elpd_loo	-89859.0	13087.6
    p_loo		3377.5		450.4
    looic		179717.9	26175.2
    ------
    Monte Carlo SE of elpd_loo is 0.5.

    Pareto k diagnostic values:
    						Count	Pct.	Min. n_eff
    (-Inf, 0.5]	(good)		58		82.9%	103 
    (0.5, 0.7]	(ok)	    12		17.1%	55 
    (0.7, 1]	(bad)		0		0.0%	<NA> 
    (1, Inf)	(very bad)	0		0.0%	<NA> 

    All Pareto k estimates are ok (k < 0.7).
    See help('pareto-k-diagnostic') for details.

    Output of model 'france5_mbrms':

    Computed from 6000 by 70 log-likelihood matrix

    		    Estimate	SE
    elpd_loo	-44270.6	7059.0
    p_loo		2430.8		315.6
    looic		88541.1		14118.0
    ------
    Monte Carlo SE of elpd_loo is 0.5.

    Pareto k diagnostic values:
    					Count	Pct.	Min. n_eff
    (-Inf, 0.5] (good)	59		84.3% 	224 
    (0.5, 0.7] (ok)		11		15.7% 	26 
    (0.7, 1] (bad)		0		0.0% 	<NA> 
    (1, Inf) (very bad)	0		0.0% 	<NA> 

    All Pareto k estimates are ok (k < 0.7).
    See help('pareto-k-diagnostic') for details.

    Model comparisons:
    				elpd_diff   se_diff
    france5_mbrms	0.0 0.0
    france1_mbrms	-45588.4	10391.8

Note the following warnings that result:

    Warning messages:
    1: Some Pareto k diagnostic values are slightly high. See help('pareto-k-diagnostic') for details.
    2: Some Pareto k diagnostic values are slightly high. See help('pareto-k-diagnostic') for details.`

### Dissecting the output

The output from `loo()` includes two main components: the estimated log pointwise predictive density (`elpd_loo`), and the Pareto _k_ diagnostic values.

`elpd_loo`
This is a measure of the predictive accuracy of the model, with a higher (less negative) value indicating better predictive accuracy. Looking at the output, france5_mbrms has a higher elpd_loo value (-44270.6) compared to france1_mbrms (-89859.0), suggesting it provides a better predictive accuracy.

Pareto _k_ diagnostic values: The Pareto _k_ diagnostics are a measure of the reliability of the loo() estimates. They are based on the idea of Pareto smoothed importance sampling (PSIS), a method used to approximate the leave-one-out cross-validation procedure. Specifically, each _k_ value gives us an indication of the reliability of the corresponding out-of-sample predictive likelihood estimate.

Values of _k_ < 0.5 suggest that the estimates are reliable. Values between 0.5 and 0.7 are a cause for some concern, but the estimates can still be somewhat useful. Values of _k_ > 0.7 (especially _k_ > 1) suggest that the estimates are not reliable. Looking at the output, both models have some k values between 0.5 and 0.7, but none above 0.7. This means that while most of the estimates are reliable (_k_ < 0.5), some of them are less so (0.5 < _k_ < 0.7). This is what the warning messages are referring to.

In practice, having some Pareto _k_ values between 0.5 and 0.7 is not necessarily a problem, especially if the proportion is not large and the associated observations are not particularly influential. However, it's worth examining the data points associated with these higher _k_ values, as they may be outliers or otherwise unusual observations. You may also want to consider whether modifications to the model or the use of a more robust model might be warranted.

### How to interpret `elpd_loo`

The `elpd_loo` values (expected log pointwise predictive density) are a measure of out-of-sample predictive accuracy, with higher values indicating better accuracy. In this case, the `elpd_loo` for `france5_mbrms` is higher than that for `france1_mbrms`, indicating that `france5_mbrms` has better predictive accuracy.

However, since `elpd_loo` values are in log scale, direct percentage difference may not provide a meaningful interpretation. Instead, one could compute the difference in `elpd_loo` values between two models, which gives us the expected log predictive density difference.

For the models, the difference would be `-44270.6 - (-89859.0) = 45588.4`. This value is also provided in the `loo()` output under the `elpd_diff` column in the model comparisons section.

This difference in `elpd_loo` means that, on average, for each new observation, the `france5_mbrms` model is expected to assign a probability exp(45588.4) times higher to the observed outcome than the `france1_mbrms` model. However, given the large magnitude of these numbers, this ratio is not easily interpretable.

Moreover, you should also take into account the standard error (`se_diff`) of this difference to assess its uncertainty. In this instance, the standard error of the difference is `10391.8`, which is quite high, suggesting that there is considerable uncertainty around this estimate.

Finally, it's worth noting that loo() is just one tool for model comparison, and decisions about which model to use should also take into account other considerations, such as the purpose of the model, the plausibility of its assumptions, and its interpretability.

### Bayesian Terminology: Parameter Space

In the context of statistical models, the "parameter space" refers to the collection of all possible values that the parameters of the model can take. Each parameter in the model corresponds to a dimension in this space. 

For instance, consider a simple linear regression model `y = mx + b + e`, where `m` is the slope, `b` is the y-intercept, and `e` is the error term. In this case, the parameter space is two-dimensional: one dimension for `m` and one dimension for `b`. Any point in this two-dimensional space corresponds to a specific pair of values `(m, b)`, and thus a specific model.

In a more complex model, like a multivariate regression with `p` predictors, the parameter space would be `p+1` dimensional (one dimension for each of the `p` coefficients, plus one for the intercept).

Parameter space becomes particularly important in the context of Bayesian statistics, where one typically defines a prior distribution over the parameter space, and then updates this distribution in light of the data to obtain a posterior distribution. The goal of Bayesian inference is to learn about the posterior distribution over the parameter space.

When we sample from the posterior distribution in a process like Markov chain Monte Carlo (MCMC), we are essentially exploring the parameter space, looking for regions that are highly probable given the data and the model. The resulting samples can then be used to estimate various quantities of interest, such as the mean or variance of each parameter, or predictive distributions for new data.