GLM
===
This algorithm is the implementation of our
`Open Access Paper <https://www.mdpi.com/1999-4893/15/7/243>`_.

The term generalized linear model (GLM) refers to a larger class of models
popularized by McCullagh and Nelder (1982, 2nd edition 1989). In these models,
the response variable :math:`y_i` is assumed to follow an exponential family
distribution with mean :math:`\mu_i`, which is assumed to be some (often
nonlinear) function of :math:`x_i^T \beta`.

Authors
  :bdg-success-line:`M. Cellamare` :bdg-success-line:`A. J. van Gestel`
  :bdg-success-line:`H. Alradhi` :bdg-success-line:`F.C. Martin`
  :bdg-success-line:`A. Moncada-Torres`
Image:
  :bdg-primary-line:`harbor2.vantage6.ai/algorithms/glm`

Source:
  :bdg-link-primary-line:`https://github.com/iknl/vantage6-algorithms`

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
:math:`k`-th data source such that the total sample size of the study is
:math:`n=n_1+\cdots+n_K`. Furthermore, let us denote by :math:`y_{(k)}` the
:math:`n_k`-vector of response variable and by :math:`X_{(k)}` the
:math:`(n_k\times p)`-matrix of :math:`p` covariates for the data source
:math:`k=1,\ldots,K`. It is easy to prove that

.. math::
    :label: federated-part

    \begin{eqnarray*}
    X^TWX&=\Big[ X_{(1)}^TW_{(1)}X_{(1)}\Big]+\cdots+\Big[X_{(K)}^TW_{(K)}X_{(K)}\Big] \\
    X^TWz&=\Big[ X_{(1)}^TW_{(1)}z_{(1)}\Big]+\cdots+\Big[X_{(K)}^TW_{(K)}z_{(K)}\Big]
    \end{eqnarray*}

where :math:`z_{(K)}=\eta_{(k)}+\frac{y_{(k)}-\mu_{(k)}}{\Delta g_{(k)}'}` and
:math:`W_{(k)}=diag \Big[ Var\big(y_{(k)}\big) \Delta g_{(K)}'^2 \Big]^{-1}`.

A final federated step is to compute the deviance of the model. This can be
done by computing the deviance of each data source and then summing them up.
To compute the deviance at each data source, we can use:

.. math::
    :label: deviance

    dev^{(j)} = f\Big(X_{(1)}\beta^{(t+1)}g'(\eta_{(1)})\Big) + \cdots + X_{(K)}\beta^{t+1}



Implementation Details
----------------------
The implementation consists of a central part and a federated part. Both parts
are implemented in R. The central part can be executed both by the user or by
a central container. In case the user wants to execute the central part, he/she
needs to have a R environment. When using the central container, the user can
use any language to initiate The algorithm.

Central Part
^^^^^^^^^^^^
The main function is ``dglm``. This function is responsible for the
initialization, creating federated tasks at the *vantage6-server*, combining
the partial results, and finally checking the convergence of the algorithm.
The function creates several federated tasks iterations until the algorithm
converges.

The function ``dglm`` has the following arguments:

    formula
        A string representation of that can be parsed to the "formula" class:
        a symbolic description of the model to be fitted. The details of model
        specification are given in the `R documentation
        <https://www.rdocumentation.org/link/formula?package=stats&version=3.6.2>`_.

        Example: ``num_awards ~ prog + math``.

    family
        A string representation of the family of the model. The details of model
        specification are given in the `R documentation
        <https://www.rdocumentation.org/link/family?package=stats&version=3.6.2>`_.

        Example: ``poisson``.

    tol
        The tolerance for the convergence criterion. The algorithm stops when the
        difference between two consecutive deviances is smaller than ``tol``.

        Example: ``1e-08``.

    maxit
        The maximum number of iterations.

        Example: ``25``.

    types
        A dictionary that contains the types of the variables in the model.

        Example: ``{'prog': {'type': 'factor', 'levels':
        ['General','Vocational','Academic']}}``.

..
.. 'kwargs': {
..             'formula': 'num_awards ~ prog + math',
..             'types': {
..                 'prog': {
..                     'type': 'factor',
..                     'levels': ['General','Vocational','Academic']
..                 }
..             },
..             'family': 'poisson',
..             'tol': 1e-08,
..             'maxit': 25
..         },

Federated Parts
^^^^^^^^^^^^^^^
There are two federated parts: (I) ``RPC_node_beta`` which is the part that
computes :eq:`federated-part`, and (II) ``RPC_node_deviamce`` which is the
part that computes :eq:`deviance`.

Additional Notes
^^^^^^^^^^^^^^^^

1. ``as.GLM.R`` is used to convert the result to a ``glm/lm`` object

    * Simply wrap the object with the ``as.GLM`` -> ``as.GLM(object)`` where
      ``object`` is the final output (i.e., the trained model).

2. The ``as.GLM()`` function misses some outputs compared to the ``R`` built-in
   ``glm`` function:

    * For now, ``AIC`` output is set to 1. It isn't properly implemented yet.
    * ``Deviance Residuals`` printed by ``R``'s ``summary.glm(glm-output)`` are not
      included yet.
    * ``Number of Fisher Scoring iterations`` printed by ``R``'s
      ``summary.glm(glm-output)`` is not included yet.
    * ``Signif. codes:  ...`` printed by ``R``'s ``summary.glm(glm-output)`` are not
      included yet.


.. Privacy Risks
.. -------------
.. TODO

Validation
----------
The code used for the validation of the algorithm (i.e., comparing its
performance against its centralized counterpart) can be found in
`./src/validation <https://github.com/IKNL/vantage6-algorithms>`_.

The `R` notebook `validation.ipynb` contains the complete procedure, while
the `Python` script `create_data.py` allows generating the data needed.

So far, the current implementation is validated for the following model
families:

* `gaussian(link = "identity")`: Linear regression
* `poisson(link = "log")`: Poisson regression
* `binomial(link = "logit")`: Logistic regression

Load the datasets:

.. code-block:: R

    datasets <- list(
        read.csv('../data/poisson_party1.csv'),
        read.csv('../data/poisson_party2.csv'),
        read.csv('../data/poisson_party3.csv')
    )
    datasets_combined <- do.call(rbind.data.frame, datasets)

Then we can compute the centralized GLM as:

.. code-block:: R

    results_centralized <- glm(data=datasets_combined, formula = y ~ x1 + x2, family=poisson(link = "log"))

And we can compute the federated GLM as:

.. code-block:: R

    client <- vtg::MockClient$new(datasets, "vtg.glm")
    results_federated <- dglm(client, formula = y ~ x1 + x2, family=poisson(link = "log"))


Usage examples
--------------
In order to run the following examples, you need to have prepared:

* A vantage6 server
* A user
* A collaboration with 3 organizations and 3 nodes

Additionally, each node should host and have configured the datasets
`data_user1.csv`, `data_user2.csv`, `data_user3.csv` which you can find in
``iknl/vantage6-algorithms/models/glm/src/data``.


Run from R
^^^^^^^^^^
First we need to install the vantage6-algorithms package.

.. code-block:: R

    # install devtools if haven't got it already
    install.packages("devtools")

    # This also installs the package vtg
    devtools::install_github(repo='iknl/vantage6-algorithms', ref='glm', subdir='models/glm/src')

    # This will become the following in the future (when the glm branch is merged)
    devtools::install_github('iknl/vantage6-algorithms', subdir='models/glm/src')

Then we can run the algorithm as:

.. code-block:: R

    setup.client <- function() {
    # Define parameters
    username <- 'admin'
    password <- 'password'
    host <- 'http://127.0.0.1:5000'
    api_path <- ''

    # Create the client
    client <- vtg::Client$new(host, api_path=api_path)
    client$authenticate(username, password)

    return(client)
    }

    # Create a client
    client <- setup.client()

    # Get a list of available collaborations
    print( client$getCollaborations() )

    # Should output something like this:
    #   id     name
    # 1  1 ZEPPELIN
    # 2  2 PIPELINE

    # Select a collaboration
    client$setCollaborationId(1)

    # vtg.glm contains the function `dglm`.
    result <- vtg.glm::dglm(client, formula = num_awards ~ prog + math, family='poisson', tol=1e-08, maxit=25)


Run from Python
^^^^^^^^^^^^^^^

.. code-block:: python

    import time
    from vantage6.client import Client

    username = 'username@example.com'
    password = 'password'
    host = 'https://address-to-vantage6-server.domain'
    port = 5000 # specify the correct port, 5000 is an example
    api_path = '' # specify the correct path

    client = Client(host, port, api_path)
    client.authenticate(username, password)
    client.setup_encryption(None)

    # Get a list of available collaborations
    print(client.collaboration.list(fields=['id', 'name']))

    # Should output something like this:
    # [{'id': 1, 'name': 'ZEPPELIN'}, {'id': 2, 'name': 'PIPELINE'}]

    # Select a collaboration
    COLLABORATION_ID = 1 # specify the correct id

    # Get all organizations in the collaboration
    ORGANIZATION_IDS = [i['id'] for i in client.collaboration.get(COLLABORATION_ID).get('organizations')]

    # Prepare task input
    input_ = {
        'master': True,
        'method': 'dglm',
        'args': [],
        'kwargs': {
            'formula': 'num_awards ~ prog + math',
            'types': {
                'prog': {
                    'type': 'factor',
                    'levels': ['General','Vocational','Academic']
                }
            },
            'family': 'poisson',
            'tol': 1e-08,
            'maxit': 25
        },
        'output_format': 'json'
    }

    # Sending the analysis task to the server
    my_task = client.task.create(
        collaboration=COLLABORATION_ID,
        organizations=[ORGANIZATION_IDS[0]],
        name='GLM-example',
        description='Testing the GLM algorithm.',
        image='harbor2.vantage6.ai/algorithms/glm:latest',
        input=input_,
        data_format='json'
    )

    task_id = my_task.get('id')
    print(f'Task id: {task_id}')

    # Polling for results
    client.wait_for_results(task_id)

    # Retrieve result
    result = client.result.from_task(task_id)[0].get('result')
    print(result)

References
----------
If you are using this algorithm, please cite the accompanying paper as follows:

* Matteo Cellamare, Anna J. van Gestel, Hasan Alradhi, Frank Martin,
  Arturo Moncada-Torres, "A Federated Generalized Linear Model for
  Privacy-Preserving Analysis". *Algorithms*, vol. 15, no. 7, 2022, p. 1-12.
  `BibTeX <https://arturomoncadatorres.com/bibtex/cellamare2022federated.txt>`_,
  `PDF Open Access <https://mdpi.com/1999-4893/15/7/243/>`_


Additionally, if you are using this algorithm in
`vantage6 <https://github.com/vantage6/vantage6>`_, please cite the following
papers as well:

* Arturo Moncada-Torres, Frank Martin, Melle Sieswerda, Johan van Soest,
  Gijs Gelijnse. VANTAGE6: an open source priVAcy preserviNg federaTed
  leArninG infrastructurE for Secure Insight eXchange. AMIA Annual Symposium
  Proceedings, 2020, p. 870-877.
  `BibTeX <https://arturomoncadatorres.com/bibtex/moncada-torres2020vantage6.txt>`_,
  `PDF <https://vantage6.ai/vantage6/>`_

* D. Smits\*, B. van Beusekom\*, F. Martin, L. Veen, G. Geleijnse,
  A. Moncada-Torres, An Improved Infrastructure for Privacy-Preserving Analysis
  of Patient Data, Proceedings of the International Conference of Informatics,
  Management, and Technology in Healthcare (ICIMTH), vol. 25, 2022, p. 144-147.
  `BibTeX <https://arturomoncadatorres.com/bibtex/smits2022improved.txt>`_,
  `PDF <https://ebooks.iospress.nl/volumearticle/60190>`_