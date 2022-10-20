GLM
===
The term generalized linear model (GLM) refers to a larger class of models
popularized by McCullagh and Nelder (1982, 2nd edition 1989). In these models,
the response variable :math:`y_i` is assumed to follow an exponential family
distribution with mean :math:`\mu_i`, which is assumed to be some (often
nonlinear) function of :math:`x_i^T \beta`.

Author(s):
Paper:

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

      g(\mu)=\eta

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

    \frac{\delta l}{\delta \beta_j}&=\frac{y-\mu}{Var(y)}\Bigg(\frac{\delta
    \mu}{\delta \eta} \Bigg) x_{ij}

    -\mathbb{E}\Bigg(\frac{\delta^2 l}{\delta \beta_j \delta \beta_k} \Bigg)&=
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

    % This quicksort algorithm is extracted from Chapter 7, Introduction to Algorithms (3rd edition)
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


Implementation
--------------

Risks
-----

Validation
----------

Usage examples
--------------