GLM
===
This algorithm is the implementation of our
`Open Access Paper <https://www.mdpi.com/1999-4893/15/7/243>`_.

The term generalized linear model (GLM) refers to a larger class of models
popularized by McCullagh and Nelder (1982, 2nd edition 1989). In these models,
the response variable :math:`y_i` is assumed to follow an exponential family
distribution with mean :math:`\mu_i`, which is assumed to be some (often
nonlinear) function of :math:`x_i^T \beta`.

Mathmatics
----------
Central
^^^^^^^
There are three components to any GLM:

* **Random component** - refers to the probability distribution of the response
  variable :math:`y`; e.g. normally distributed in the linear regression, or
  binomially distributed in the binary logistic regression. More generally, we
  consider all distribution that can be expressed in the form:

  .. math::

    f(y;\theta)=exp \Bigg\lbrace \frac{y\theta-b(\theta)}{a(\phi)}+c(y,\phi)
    \Bigg\rbrace,

  where :math:`\theta` is the canonical parameter, such that
  :math:`\mathbb{E}(y)=\mu=b'(\theta)` and :math:`Var(y)=a(\phi)b''(\theta)`.
  This is also called exponential family. Can be easily showed that, for
  instance, the canonical parameter for :math:`y \sim N(\mu, \sigma^2)` is
  :math:`\theta = \mu`, and the canonical parameter for :math:`y\sim Bin(n, \pi)`
  is :math:`\theta = logit(\pi)=log\Big(\frac{\pi}{1-\pi}\Big)`.

* **Systematic Component** - specifies the explanatory variables
  :math:`x=(x_1, x_2, \ldots, x_k)` in the model, more specifically their
  linear combination define the so called linear predictor

  .. math::

    \eta=x^T\beta,

  where :math:`\beta` must be estimated.

* **Link Function** :math:`g(\cdot)` - specifies the link between random and
  systematic components. It says how the expected value of the response relates
  to the linear predictor of explanatory variables

  .. math::

    g(\mu)=\eta.

  The most commonly used link function for a normal model is
  :math:`\eta = \mu`, and the most commonly used link function for the binomial
  model is :math:`\eta = logit(\pi)`. When :math:`\eta=\theta` we say that the
  model has a canonical link.

Estimation procedure
""""""""""""""""""""
In the GLM estimation procedure, the maximum likelihood estimation for
:math:`\beta` can be carried out via Fisher scoring. The generic
:math:`(j+1)`-th step can be calculate by

.. math::

    \beta^{(j+1)}=\beta^{(j)}+ \Big[ -\mathbb{E}l''\big( \beta^{(j)} \big)
    \Big]^{-1} l'(\beta^{(j)})

where :math:`l` is the log-likelihood of the entire sample. Ignoring constants,
the log-likelihood is

.. math::

    l(\theta; y) = \frac{y \theta - b(\theta)}{a(\phi)}

After some mathematical operations and using the canonical link
:math:`\eta=\theta`, the first derivative and expected second derivative of
the log-likelihood are

.. math::
    :label: step

    \frac{\delta l}{\delta \beta_j}=\frac{y-\mu}{Var(y)}\Bigg(\frac{\delta
    \mu}{\delta \eta} \Bigg) x_{ij}

.. math::
    :label: stepB

    -\mathbb{E}\Bigg(\frac{\delta^2 l}{\delta \beta_j \delta \beta_k} \Bigg)=
    \frac{1}{Var(y)}\Bigg(\frac{\delta \mu}{\delta \eta} \Bigg)^2 x_{ij}x_{ik}

where :math:`x_{ij}` (or :math:`x_{ik}`) is the :math:`j`-th element of the
covariate vector :math:`x_i = x` for the :math:`i`-th observation.

It follows that the score vector for the entire data set
:math:`y_1,\ldots, y_N` can be written as

.. math::
    \frac{\delta l}{\delta \beta}=X^TA(y-\mu)

where :math:`X=(x_1,\ldots,x_N)^T`, and
:math:`A=diag \Big[ Var(y_i) \Big(\frac{\delta \eta_i}{\delta \mu_i} \Big) \Big]^{-1}`
and the expected Hessian matrix becomes

.. math::

    -\mathbb{E}\Bigg(\frac{\delta^2 l}{\delta \beta_j \delta \beta_k} \Bigg)=X^TWX

where
:math:`W=diag \Big[ Var(y_i) \Big(\frac{\delta \eta_i}{\delta \mu_i} \Big)^2 \Big]^{-1}`.

Therefore the Fisher scoring iteration in :eq:`step` can be expressed as

.. math::
    :label: step2

    \beta^{(j+1)}=\beta^{(j)}+ \big(X^TWX\big)^{-1} X^TA(y-\mu)

We can arrange the step of Fisher scoring to make it resemble weighted least
squares.

Noting that :math:`X\beta=\eta` and :math:`A=W \frac{\delta \eta}{\delta \mu}`,
we can rewrite :eq:`step2` as

.. math::
    :label: step4

    \beta^{(j+1)}=\big(X^TWX\big)^{-1} X^TWz


where :math:`z=\eta + \frac{\delta \eta}{\delta \mu}(y-\mu)`. Therefore, Fisher
scoring can be regarded as Iteratively Reweighted Least Squares (IRWLS) carried
out on a transformed version of the response variable.

The IRWLS algorithm can be describe as

.. pcode::
   :linenos:

    \begin{algorithm}
    \caption{GLM Fisher Scoring algorithm}
    \begin{algorithmic}
    \PROCEDURE{GLM}{$\epsilon$}
        \STATE $\beta^{(0)}$
        \STATE $\eta=X\beta^{(0)}$
        \STATE $dev^{(0)}$

        \REPEAT
        \STATE $\mu=g'(\eta)$
        \STATE $z=\eta+\frac{y-\mu}{\Delta g'}$
        \STATE $W=w\frac{\Delta g'^2}{Var(\mu)}$

        \STATE $\beta^{(j)}=\big(X^TWX\big)^{-1} X^TWz$
        \STATE $\eta=X\beta^{(j)}$
        \STATE compute $dev^{(j)}$
        \UNTIL{{$|dev^{(j)}-dev^{(j-1)}|< \epsilon$}}

    \ENDPROCEDURE
    \end{algorithmic}
    \end{algorithm}


Federated
^^^^^^^^^
The main idea behind the federated GLM algorithm is that components of equation
:eq:`step4` can be partially computed in each data sources :math:`k` and merged
together afterwords without pulling together the data.

Let us consider :math:`K\geq2` data sources (i.e. cancer registries, schools,
banks etc..) and let's denote by :math:`n_k` the number of observations in the
`k`-th data source such that the total sample size of the study is
:math:`n=n_1+\cdots+n_K`. Furthermore, let us denote by :math:`y_{(k)}` the
:math:`n_k`-vector of response variable and by :math:`X_{(k)}` the
:math:`(n_k\times p)`-matrix of :math:`p` covariates for the data source
:math:`k=1,\ldots,K`. It is easy to prove that

.. math::

    \begin{eqnarray*}
    X^TWX&=\Big[ X_{(1)}^TW_{(1)}X_{(1)}\Big]+\cdots+\Big[X_{(K)}^TW_{(K)}X_{(K)}\Big] \\
    X^TWz&=\Big[ X_{(1)}^TW_{(1)}z_{(1)}\Big]+\cdots+\Big[X_{(K)}^TW_{(K)}z_{(K)}\Big]
    \end{eqnarray*}

where :math:`z_{(K)}=\eta_{(k)}+\frac{y_{(k)}-\mu_{(k)}}{\Delta g_{(k)}'}` and
:math:`W_{(k)}=diag \Big[ Var\big(y_{(k)}\big) \Delta g_{(K)}'^2 \Big]^{-1}`.




Implementation
--------------

Secutiry Risks
--------------
[1] https://doi.org/10.1155/2022/2886795

This section discusses the risks that are involved in using the federated GLM.
We distinquish two types of thread models: Semi-honest and Malicious [1].

**Semi-honest**
    The attacker tries to disclose sensitive information by observing the
    results but not changing the protocol.

**Malicious**
    An attacker can actively perform arbitrary attacks in an attempt to steal
    sensitive information from global model parameters shared during the
    training process. Moreover, the malicious attacker can also conduct
    devastating attacks on the global model by deviating from the protocol or
    tampering with data.

Systematic Queries
^^^^^^^^^^^^^^^^^^


Validation
----------

Usage examples
--------------