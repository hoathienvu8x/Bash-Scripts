---
title: "Support Vector Machine (SVM) Implementation In Python"
link: "https://laid-back-scientist.com/en/svm-imple"
---

## Introduction

In my previous article, I discussed the theory of hard-margin SVM. This time,
we will implement it using Python.

Also, the following code works with [Google Colab](https://colab.research.google.com/drive/1evmYX0Fbj0xpCIoOMvxJtKmsU9fucEjL?usp=sharing).

## Theoretical Overview of Hard Margin SVM

The $n$ $p$ -dimensional data observed are denoted by $X$ and the $n$ label
variable pairs are denoted by $y$, respectively, as follows.

$$
\underset{\left \[ n \times p \right \]}{X} = \left (
\begin{matrix}
x_{1}^{(1)} & x_{2}^{(1)} & ... & x_{p}^{(1)} \\ 
x_{1}^{(2)} & x_{2}^{(2)} & ... & x_{p}^{(2)} \\
\vdots & \vdots & \ddots & \vdots \\ 
x_{1}^{(n)} & x_{2}^{(n)} & ... & x_{p}^{(n)} 
\end{matrix} \right ) =\left ( \begin{matrix}
\- & x^{(1)T} & \- \\ 
\- & x^{(2)T} & \- \\ 
 & \vdots & \\
\- & x^{(n)T} & \- 
\end{matrix} \right ),\underset{\left [ n \times 1 \right ]}{y} = \left ( \begin{matrix}
y^{(1)}\\ 
y^{(2)}\\ 
\vdots \\ 
y^{(n)}
\end{matrix} \right ).$$

From the [previous consequence](https://laid-back-scientist.com/en/svm-theory),
the parameter that determines the separating hyperplane could be calculated
as follows.

$$
\widehat{w}=\sum_{x^{(i)}\in S}{\widehat{\alpha}_iy^{(i)}x^{i} },(1)
$$

$$
\widehat{b}=\frac{1}{\left | S \right |}\sum_{x^{(i)}\in S}{\left ( y^{(i)} - \widehat{w}^{T}x^{i} \right )} (2)
$$

(where $S$ is the set of support vectors)

Also, $\alpha = \left ( \alpha_{1}, \alpha_2,\dots,\alpha_{n} \right )^{T}$
is a pair of Lagrangian undetermined multipliers, and we use the steepest
descent method to find its optimal solution $\widehat{\alpha}$

$$
\alpha^{\left[t+1 \right ]} = \alpha^{t} + \eta \frac{\partial \tilde{L}(\alpha)}{\partial \alpha}.
$$

The value of the gradient vector $\eta \frac{\partial \tilde{L}(\alpha)}{\partial \alpha}$
is.

$$
\underset{\left [n \times n \right ]}{H} \equiv \underset{\left [n \times 1 \right ]}{y}\underset{\left [1 \times n \right ]}{y^{T}} \bigodot \underset{\left [n \times p \right ]}{X}\underset{\left[p\times n \right ]}{X^{T}} (3)\\ \frac{\partial \tilde{L}(\alpha)}{\partial \alpha}=1-H\alpha. (4)
$$

## Full-scratch implementation of hard-margin SVM

From the above, a hard-margin SVM will be implemented in full scratch.

```python
import numpy as np

class HardMarginSVM:
    """
    Attributes
    ----------
    eta : float
    epoch : int
    random_state : int
    is_trained : bool
    num_samples : int
    num_features : int
    w : NDArray[float]
    b : float
    alpha : NDArray[float]

    Methods
    -------
    fit -> None
        Fitting parameter vectors for training data
    predict -> NDArray[int]
        Return predicted value
    """
    def __init__(self, eta=0.001, epoch=1000, random_state=42):
        self.eta = eta
        self.epoch = epoch
        self.random_state = random_state
        self.is_trained = False

    def fit(self, X, y):
        """
        Fitting parameter vectors for training data

        Parameters
        ----------
        X : NDArray[NDArray[float]]
        y : NDArray[float]
        """
        self.num_samples = X.shape[0]
        self.num_features = X.shape[1]
        self.w = np.zeros(self.num_features)
        self.b = 0
        rgen = np.random.RandomState(self.random_state)
        self.alpha = rgen.normal(loc=0.0, scale=0.01, size=self.num_samples)

        for _ in range(self.epoch):
            self._cycle(X, y)
        
        indexes_sv = [i for i in range(self.num_samples) if self.alpha[i] != 0]
        for i in indexes_sv:
            self.w += self.alpha[i] * y[i] * X[i]
        for i in indexes_sv:
            self.b += y[i] - (self.w @ X[i])
        self.b /= len(indexes_sv)
        self.is_trained = True

    def predict(self, X):
        """
        Return predicted value

        Parameters
        ----------
        X : NDArray[NDArray[float]]

        Returns
        -------
        result : NDArray[int]
        """
        if not self.is_trained:
            raise Exception('This model is not trained.')

        hyperplane = X @ self.w + self.b
        result = np.where(hyperplane > 0, 1, -1)
        return result
        
    def _cycle(self, X, y):
        """
        One cycle of gradient descent method

        Parameters
        ----------
        X : NDArray[NDArray[float]]
        y : NDArray[float]
        """
        y = y.reshape([-1, 1])
        H = (y @ y.T) * (X @ X.T)
        grad = np.ones(self.num_samples) - H @ self.alpha
        self.alpha += self.eta * grad
        self.alpha = np.where(self.alpha < 0, 0, self.alpha)

```

## Confirmation of SVM operation using iris dataset

The data used as an example is the iris dataset. The iris dataset consists
of petal and sepal lengths for three varieties: Versicolour, Virginica, and Setosa.

![](https://laid-back-scientist.com/wp-content/uploads/2021/03/iris.jpg)

Let's read the iris dataset using the scikit-learn library.

```python
import pandas as pd
from sklearn.datasets import load_iris

iris = load_iris()
df_iris = pd.DataFrame(iris.data, columns=iris.feature_names)
df_iris['class'] = iris.target
df_iris

```

![](https://laid-back-scientist.com/wp-content/uploads/2021/03/iris_data.png)

This time we will perform a binary logistic regression classification, focusing
only on data with class = `0, 1`. For simplicity, we assume that the two
features are petal length and petal width.

```python
df_iris = df_iris[df_iris['class'] != 2]
df_iris = df_iris[['petal length (cm)', 'petal width (cm)', 'class']]
X = df_iris.iloc[:, :-1].values
y = df_iris.iloc[:, -1].values
y = np.where(y==0, -1, 1)

```

The data set is standardized to have a mean of 0 and a standard deviation of 1.

```python
from sklearn.preprocessing import StandardScaler

sc = StandardScaler()
X_std = sc.fit_transform(X)

```

To evaluate the generalization performance of the model, the data set is
split into a training data set and a test data set. In this case, we split
the training data at a ratio of 80% and the test data at a ratio of 20%.

```python
from sklearn.model_selection import train_test_split

X_train, X_test, y_train, y_test = train_test_split(X_std, y, test_size=0.2, random_state=42, stratify=y)

```

The plot class should also be defined here.

```python
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap

class DecisionPlotter:
    def __init__(self, X, y, classifier, test_idx=None):
        self.X = X
        self.y = y
        self.classifier = classifier
        self.test_idx = test_idx
        self.colors = ['#de3838', '#007bc3', '#ffd12a']
        self.markers = ['o', 'x', ',']
        self.labels = ['setosa', 'versicolor', 'virginica']
    
    def plot(self):
        cmap = ListedColormap(self.colors[:len(np.unique(self.y))])
        xx1, xx2 = np.meshgrid(
            np.arange(self.X[:,0].min()-1, self.X[:,0].max()+1, 0.01),
            np.arange(self.X[:,1].min()-1, self.X[:,1].max()+1, 0.01))
        Z = self.classifier.predict(np.array([xx1.ravel(), xx2.ravel()]).T)
        Z = Z.reshape(xx1.shape)
        plt.contourf(xx1, xx2, Z, alpha=0.2, cmap=cmap)
        plt.xlim(xx1.min(), xx1.max())
        plt.ylim(xx2.min(), xx2.max())
        for idx, cl, in enumerate(np.unique(self.y)):
            plt.scatter(
                x=self.X[self.y==cl, 0], y=self.X[self.y==cl, 1], 
                alpha=0.8, 
                c=self.colors[idx],
                marker=self.markers[idx],
                label=self.labels[idx])
        if self.test_idx is not None:
            X_test, y_test = self.X[self.test_idx, :], self.y[self.test_idx]
            plt.scatter(
                X_test[:, 0], X_test[:, 1], 
                alpha=0.9, 
                c='None', 
                edgecolor='gray', 
                marker='o', 
                s=100, 
                label='test set')
        plt.legend()

```

We will now check the operation of SVM using the iris dataset.

```python
hard_margin_svm = HardMarginSVM()
hard_margin_svm.fit(X_train, y_train)

X_comb = np.vstack((X_train, X_test))
y_comb = np.hstack((y_train, y_test))

dp = DecisionPlotter(X=X_comb, y=y_comb, classifier=hard_margin_svm, test_idx=range(len(y_train), len(y_comb)))
dp.plot()
plt.xlabel('petal length [standardized]')
plt.ylabel('petal width [standardized]')
plt.show()

```

![](https://laid-back-scientist.com/wp-content/uploads/2021/05/fig.svg)

The decision curve could be plotted in this way.

## SVM implementation using scikit-learn

You can run SVM using scikit-learn as follows

```python
from sklearn import svm

sk_svm = svm.LinearSVC(C=1e10, random_state=42)
sk_svm.fit(X_train, y_train)

X_comb = np.vstack((X_train, X_test))
y_comb = np.hstack((y_train, y_test))

dp = DecisionPlotter(X=X_comb, y=y_comb, classifier=sk_svm, test_idx=range(len(y_train), len(y_comb)))
dp.plot()
plt.xlabel('petal length [standardized]')
plt.ylabel('petal width [standardized]')
plt.show()

```

![](https://laid-back-scientist.com/wp-content/uploads/2021/05/fig2.svg)

We were also able to plot the decision curve this way in scikit-learn. You
can try the above [code here](https://colab.research.google.com/drive/1evmYX0Fbj0xpCIoOMvxJtKmsU9fucEjL?usp=sharing)
