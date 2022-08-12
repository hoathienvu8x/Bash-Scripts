---
title: "Word2vec from Scratch"
link: "https://jaketae.github.io/study/word2vec/"
publish: "July 13, 2020"
author: "Jake Tae"
---

In a previous post, we discussed how we can use tf-idf vectorization to
encode documents into vectors. While probing more into this topic and geting
a taste of what NLP is like, I decided to take a jab at another closely
related, classic topic in NLP: word2vec. word2vec is a technique introduced
by Google engineers in 2013, popularized by statements such as "king - man
\+ woman = queen." The gist of it, as you may know, is that we can express
words as vectors that encode their semantics in a meaningful way.

When I was just getting starting to learn TensorFlow, I came across the
embedding layer, which performed exactly this operation: transforming words
into vectors. While I thought this process was extremely interesting, I didn't
know about the internals of this structure until today, particularly after
reading this wonderful tutorial by Chris McCornick. In this post, we will
be implementing word2vec, a popular embedding technique, from scratch with
`NumPy`. Let's get started!

## Preparing DataPermalink

Instead of going over the concepts and implementations separately, let's
jump straight into the whole implementation process and elaborate on what
is necessary along the way.

In order to create word embeddings, we need some sort of data. Here is a
text on machine learning from Wikipedia. I've removed some parentheses and
citation brackets to make things slightly easier.

```python
text = '''Machine learning is the study of computer algorithms that \
improve automatically through experience. It is seen as a \
subset of artificial intelligence. Machine learning algorithms \
build a mathematical model based on sample data, known as \
training data, in order to make predictions or decisions without \
being explicitly programmed to do so. Machine learning algorithms \
are used in a wide variety of applications, such as email filtering \
and computer vision, where it is difficult or infeasible to develop \
conventional algorithms to perform the needed tasks.'''
```

## Tokenization

Since we can't feed raw string texts into our model, we will need to preprocess
this text. The first step, as is the approach taken in many NLP tasks, is
to tokenize the text, i.e. splitting the text up into smaller units like
words, getting rid of punctuations, and so on. Here is a function that does
this trick using regular expressions.

```python
import re

def tokenize(text):
    pattern = re.compile(r'[A-Za-z]+[\w^\']*|[\w^\']*[A-Za-z]+[\w^\']*')
    return pattern.findall(text.lower())
```

Let's create tokens using the Wikipedia excerpt shown above. The returned
object will be a list containing all the tokens in `text`.

```python
tokens = tokenize(text)
```

Another useful operation is to create a map between tokens and indices,
and vice versa. In a sense, we are creating a lookup table that allows us
to easily convert from words to indices, and indices to words. This will
be particularly useful later on when we perform operations such as `one-hot`
encoding.

```python
def mapping(tokens):
    word_to_id = {}
    id_to_word = {}
    
    for i, token in enumerate(set(tokens)):
        word_to_id[token] = i
        id_to_word[i] = token
    
    return word_to_id, id_to_word
```

Let's check if the word-to-index and index-to-word maps have successfully
been created.

```python
word_to_id, id_to_word = mapping(tokens)
word_to_id
```

```
{'it': 0,
 'wide': 1,
 'variety': 2,
 'build': 3,
 'improve': 4,
 'computer': 5,
 'a': 6,
 'make': 7,
 'decisions': 8,
 'difficult': 9,
 'on': 10,
 'applications': 11,
 'based': 12,
 'filtering': 13,
 'explicitly': 14,
 'email': 15,
 'study': 16,
 'without': 17,
 'learning': 18,
 'of': 19,
 'vision': 20,
 'perform': 21,
 'machine': 22,
 'known': 23,
 'or': 24,
 'automatically': 25,
 'so': 26,
 'seen': 27,
 'training': 28,
 'sample': 29,
 'artificial': 30,
 'in': 31,
 'to': 32,
 'the': 33,
 'being': 34,
 'where': 35,
 'tasks': 36,
 'conventional': 37,
 'do': 38,
 'predictions': 39,
 'such': 40,
 'mathematical': 41,
 'model': 42,
 'used': 43,
 'and': 44,
 'through': 45,
 'programmed': 46,
 'develop': 47,
 'are': 48,
 'needed': 49,
 'data': 50,
 'subset': 51,
 'order': 52,
 'as': 53,
 'intelligence': 54,
 'that': 55,
 'algorithms': 56,
 'is': 57,
 'experience': 58,
 'infeasible': 59}
```

As we can see, the lookup table is a dictionary object containing the relationship
between words and ids. Note that each entry in this lookup table is a token
created using the `tokenize()` function we defined earlier.

## Generating Training Data

Now that we have tokenized the text and created lookup tables, we can now
proceed to generating the actual training data, which are going to take
the form of matrices. Since tokens are still in the form of strings, we
need to encode them numerically using one-hot vectorization. We also need
to generate a bundle of input and target values, as this is a supervised
learning technique.

This then begs the question of what the input and target values are going
to look like. What is the value that we are trying to approximate, and what
sort of input will we be feeding into the model to generate predictions?
The answer to these questions and how they tie into word2vec is at the heart
of understanding word embeddings—as you may be able to tell, word2vec is
not some sort of blackbox magic, but a result of careful training with input
and output values, just like any other machine learning task.

So here comes the crux of word2vec: we loop through each word (or token)
in the sentence. In each loop, we look at words to the left and right of
the input word, as shown below. This illustration was taken from this article
by Ramzi Karam.

![](https://miro.medium.com/max/1400/1*Mmp1vbFOxrmiCF17lYJWRA.png)

In the particular example as shown above, we would generate the following
input and prediction pairs part of the training data.

```python
["back-alleys", "little"]
["back-alleys", "dark"]
["back-alleys", "behind"]
["back-alleys", "the"]
```

Note that the window size is two, which is why we look up to two words to
the left and right of the input word. So in a way, we can understand this
as forcing the model to understand a rough sense of context—the ability to
see which words tend to stick together. In our own example, for instance,
we would see a lot of `["machine", "learning"]`, meaning that the model should
be able to capture the close contextual affinity between these two words.

Below is the code that generates training data using the algorithm described
above. We basically iterate over the tokenized data and generate pairs.
One technicality here is that, for the first and last few tokens, it may
not be possible to obtain words to the left or right of that input token.
In those cases, we simply don't consider these word pairs and look at only
what is feasible without causing `IndexErrors`. Also note that we create `X`
and `y` separately instead of putting them in tuple form as demonstrated above.
This is just for convenience with other matrix operations later on in the post.

```python
import numpy as np

np.random.seed(42)

def generate_training_data(tokens, word_to_id, window):
    X = []
    y = []
    n_tokens = len(tokens)
    
    for i in range(n_tokens):
        idx = concat(
            range(max(0, i - window), i), 
            range(i, min(n_tokens, i + window + 1))
        )
        for j in idx:
            if i == j:
                continue
            X.append(one_hot_encode(word_to_id[tokens[i]], len(word_to_id)))
            y.append(one_hot_encode(word_to_id[tokens[j]], len(word_to_id)))
    
    return np.asarray(X), np.asarray(y)
```

Below is the definition for `concat`, an auxiliary function we used above
to combine two `range()` objects.

```python
def concat(*iterables):
    for iterable in iterables:
        yield from iterable
```

Also, here is the code we use to one-hot vectorize tokens. This process is
necessary in order to represent each token as a vector, which can then be
stacked to create the matrices `X` and `y`.

```python
def one_hot_encode(id, vocab_size):
    res = [0] * vocab_size
    res[id] = 1
    return res
```

Finally, let's generate some training data with a window size of two.

```python
X, y = generate_training_data(tokens, word_to_id, 2)
```

Let's quickly check the dimensionality of the data to get a sense of what
matrices we are working with. This intuition will become important in particular
when training and writing equations for backpropagation in the next section.

```python
X.shape
```

```
(330, 60)
```

```python
y.shape
```

```
(330, 60)
```

Both `X` and `y` are matrices with 330 rows and 60 columns. Here, 330 is the
number of training examples we have. We would expect this number to have
been larger had we used a larger window. 60 is the size of our corpus, or
the number of unique tokens we have in the original text. Since we have
one-hot encoded both the input and output as 60-dimensional sparse vectors,
this is expected.

Now, we are finally ready to build and train our embedding network.

## The Embedding ModelPermalink

At this point, you might be wondering how it is that training a neural network
that predicts some nearby context word given an input token can be used to
embed words into vectors. After all, the output of the network is going to
be some probability vector that passed through a softmax layer, not an
embedding vector.

This is entirely correct, and this is a question that came to my mind as
well. However, this is the part that gets the most interesting: the rows
of the intermediate weight matrix is the embedding we are looking for! This
becomes much more apparent once we consider the dimensions of the weight
matrices that compose the model. For simplicity purposes, say we have a
total of 5 words in the corpus, and that we want to embed these words as
three-dimensional vectors.

More specifically, here is the first weight layer of the model:

$$
\underset{input}{
    \underbrace{
        \begin{pmatrix}
            0 & 1 & 0 & 0 & 0\\ 
            1 & 0 & 0 & 0 & 0\\ 
            0 & 0 & 0 & 1 & 0\\ 
            \vdots & \vdots & \vdots & \vdots & \vdots
        \end{pmatrix}
    }
}
.
\underset{weight}{
    \underbrace{
        \begin{pmatrix}
            1 & 8 & 6\\ 
            2 & 1 & 7\\ 
            7 & 5 & 5\\ 
            \vdots & \vdots & \vdots
        \end{pmatrix}
    }
}
=
\underset{embedding}{
    \underbrace{
        \begin{pmatrix}
            1 & 8 & 6\\ 
            2 & 1 & 7\\ 
            7 & 5 & 5\\ 
            \vdots & \vdots & \vdots
        \end{pmatrix}
    }
}
(1)
$$

A crucial observation to make is that, because the input is a sparse vector
containing one-hot encoded vectors, the weight matrix effectively acts as
a lookup table that moves one-hot encoded vectors to dense vectors in a
different dimension—more precisely, the row space of the weight matrix.
In this particular example, the weight matrix was a transformation of
$\mathbb{R}^{5} \rightarrow \mathbb{R}^{3}$ This is exactly what we want
to achieve with embedding: representing words as dense vectors, a step-up
from simple one-hot encoding. This process is exactly what embedding is:
as we start training this model with the training data generated above,
we would expect the row space of this weight matrix to encode meaningful
semantic information from the training data.

Continuing onwards, here is the second layer that receives as input the
embeddings, then uses them to generate a set of outputs.

$$
\underset{embedding}{
    \underbrace{
        \begin{pmatrix}
            1 & 8 & 6\\ 
            2 & 1 & 7\\ 
            7 & 5 & 5\\ 
            \vdots & \vdots & \vdots
        \end{pmatrix}
    }
}
.
\underset{weight}{
    \underbrace{
        \begin{pmatrix}
            8 & 4 & 5 & 1 & 8\\
            1 & 6 & 2 & 5 & 7\\
            0 & 2 & 0 & 3 & 4
        \end{pmatrix}
    }
}
=
\underset{output}{
    \underbrace{
        \begin{pmatrix}
            16 & 64 & 21 & 59 & 84\\
            17 & 28 & 12 & 26 & 51\\
            61 & 68 & 45 & 47 & 111\\
            \vdots & \vdots & \vdots & \vdots & \vdots
        \end{pmatrix}
    }
}
(2)
$$

We are almost done. All we now need in the last layer is a softmax layer.
When the output is passed into this layer, it is converted into probability
vectors whose elements sum up to one. This final output can be considered
as context predictions, i.e. which words are likely to be in the window
vicinity of the input word.

$$
softmax
\begin{pmatrix}
    \underset{output}{
        \underbrace{
            \begin{pmatrix}
                16 & 64 & 21 & 59 & 84\\
                17 & 28 & 12 & 26 & 51\\
                61 & 68 & 45 & 47 & 111\\
                \vdots & \vdots & \vdots & \vdots & \vdots
            \end{pmatrix}
        }
    }
\end{pmatrix}
=
\underset{prediction}{
    \underbrace{
        \begin{pmatrix}
            0.1 & 0.2 & 0.1 & 0.2 & 0.4\\
            0.2 & 0.2 & 0.1 & 0.2 & 0.3\\
            0.2 & 0.2 & 0.1 & 0.1 & 0.4\\
            \vdots & \vdots & \vdots & \vdots & \vdots
        \end{pmatrix}
    }
}
(3)
$$

In training—specifically error calculation and backpropagation - we would
be comparing this prediction of probability vectors with its true one-hot
encoded targets. The error function that we use with softmax is cross
entropy, defined as

$$
H(p,q) = - \sum_{x \in \chi }{ p(x) \log{ q(x) } } (4)
$$

I like to think of this as a dot product of the target vector and the log
of the prediction, because that is essentially what the summation is doing.
In this alternate formulation, the cross entropy formula can be rewritten as

$$
H(p,q) = -p . \log{(q)} (5)
$$

Because $p$ a one-hot encoded vector in this case, all the elements in $p$
whose entry is zero will have no effect on the final outcome. Indeed, we
simply end up taking the negative log of the prediction. Notice that the
closer the value of the prediction is to 1, the smaller the cross entropy,
and vice versa. This aligns with the behavior we want, since we want the
predicted probability to be as close to 1 as possible.

So let's summarize the entire process a little bit. First, embeddings are
simply the rows of the first weight matrix, denoted as $W_1$. Through training
and backpropgation, we adjust the weights of $W_1$, along with the weight
matrix in the second layer, denoted as $W_2$, using cross entropy loss.
Overall, our model takes on the following structure:

$$
A_1 = XW_1\\
A_2 = XW_2\\
X = softmax(A_2)
$$

where $Z$ is the matrix contains the prediction probability vectors. With
this in mind, let's actual start building and train our model.

## Code Implementation

Let's start implement this model in code. The implementation we took here
is extremely similar to the approach we took in [this post](https://jaketae.github.io/study/neural-net/).
For an in-depth review of backpropagation derivation with matrix calculus,
I highly recommend that you check out the linked post.

The representation we will use for the model is a Python dictionary, whose
values are the weight matrices and keys, the name with which we will refer
to the weight matrices. In accordance with the nomenclature established
earlier, we stick with `"w1"` and `"w2"` to refer to these weights.

```python
def init_network(vocab_size, n_embedding):
    model = {
        "w1": np.random.randn(vocab_size, n_embedding),
        "w2": np.random.randn(n_embedding, vocab_size)
    }
    return model
```

Let's specify our model to create ten-dimensional embeddings. In other words,
each token will be represented as vectors living in ten-dimensional space.
Note that actual models tend to use much higher dimensions, most commonly
300, but for our purposes this is not necessary.

```python
model = init_network(len(word_to_id), 10)
```

## Forward PropagationPermalink

Let's begin with forward propagation. Coding the forward propagation process
simply amounts to transcribing the three matrix multiplication equations
in $(6)$ into NumPy code.

```python
def forward(model, X, return_cache=True):
    cache = {}
    
    cache["a1"] = X @ model["w1"]
    cache["a2"] = cache["a1"] @ model["w2"]
    cache["z"] = softmax(cache["a2"])
    
    if not return_cache:
        return cache["z"]
    return cache
```

For backpropagation, we will need all the intermediate variables, so we
hold them in a dictionary called `cache`. However, if we simply want the final
prediction vectors only, not the cache, we set `return_cache` to `False`.
This is just a little auxiliary feature to make things slightly easier later.

We also have to implement the `softmax()` function we used above. Note that
this function receives a matrix as input, not a vector, so we will need to
slightly tune things up a bit using a simple loop.

```python
def softmax(X):
    res = []
    for x in X:
        exp = np.exp(x)
        res.append(exp / exp.sum())
    return res
```

At this point, we are done with implementing the forward pass. However,
before we move on, it's always a good idea to check the dimensionality of
the matrices, as this will provide us with some useful intuition while
coding backward propagation later on.

The dimensionality of the matrix after passing the first layer, or the
embedding layer, is as follows:

```python
(X @ model["w1"]).shape
```

```
(330, 10)
```

This is expected, since we want all the 330 tokens in the text to be
converted into ten-dimensional vectors.

Next, let's check the dimensionality after passing through the second layer.
This time, it is a 330-by-60 matrix. This also makes sense, since we want
the output to be sixty dimensional, back to the original dimensions following
one-hot encoding. This result can then be passed onto the softmax layer,
the result of which will be a bunch probability vectors.

```python
(X @ model["w1"] @ model["w2"]).shape
```

```
(330, 60)
```

## Backpropagation

Implementing backward propagation is slightly more difficult than forward
propagation. However, the good news is that we have already derived the
equation for backpropagation given a softmax layer with cross entropy loss
in this post, where we built a neural network from scratch. The conclusion
of the lengthy derivation was ultimately that

$$
\frac{\partial L}{\partial A_2} = Z - y
$$

given our model

$$
A_1 = XW_1\\
A_2 = A_1W_2\\
Z = softmax(A_2)
$$

Since we know the error, we can now backpropagate it throughout the entire
network, recalling basic principles of matrix calculus. If backprop is still
confusing to you due to all the tranposes going on, one pro-tip is to think
in terms of dimensions. After all, the dimension of the gradient must equal
to the dimension of the original matrix. With that in mind, let's implement
the backpropagation function.

```python
def backward(model, X, y, alpha):
    cache  = forward(model, X)
    da2 = cache["z"] - y
    dw2 = cache["a1"].T @ da2
    da1 = da2 @ model["w2"].T
    dw1 = X.T @ da1
    assert(dw2.shape == model["w2"].shape)
    assert(dw1.shape == model["w1"].shape)
    model["w1"] -= alpha * dw1
    model["w2"] -= alpha * dw2
    return cross_entropy(cache["z"], y)
```

To keep a log of the value of the error throughout the backpropagation
process, I decided to make the final return value of `backward()` to be
the cross entropy loss between the prediction and the target labels. The
cross entropy loss function can easily be implemented as follows.

```python
def cross_entropy(z, y):
    return - np.sum(np.log(z) * y)
```

Now we're ready to train and test the model!

## Testing the Model

As we only have a small number of training data-coupled with the fact that
the backpropagation algorithm is simple batch gradient descent—let's just
iterate for 50 epochs. While training, we will be caching the value of the
cross entropy error function in a `history` list. We can then plot this
result to get a better sense of whether the training worked properly.

```python
import matplotlib.pyplot as plt
%matplotlib inline
%config InlineBackend.figure_format = 'svg'
plt.style.use("seaborn")

n_iter = 50
learning_rate = 0.05

history = [backward(model, X, y, learning_rate) for _ in range(n_iter)]

plt.plot(range(len(history)), history, color="skyblue")
plt.show()
```

![](https://jaketae.github.io/assets/images/2020-07-13-word2vec_files/2020-07-13-word2vec_56_0.svg)

And indeed it seems like we did well! We can thus say with some degree of
confidence that the embedding layer has been trained as well.

An obvious sanity check we can perform is to see which token our model
predicts given the word "learning." If the model was trained properly, the
most likely word should understandably be "machine." And indeed, when that
is the result we get: notice that "machine" is at the top of the list of
tokens, sorted by degree of affinity with "learning."

```python
learning = one_hot_encode(word_to_id["learning"], len(word_to_id))
result = forward(model, [learning], return_cache=False)[0]

for word in (id_to_word[id] for id in np.argsort(result)[::-1]):
    print(word)
```

```
machine
intelligence
the
is
so
build
are
computer
perform
it
learning
conventional
a
improve
subset
automatically
model
algorithms
do
based
artificial
through
that
known
experience
vision
wide
programmed
data
tasks
infeasible
develop
applications
used
seen
on
explicitly
of
study
predictions
such
filtering
where
needed
decisions
mathematical
email
variety
or
order
training
and
being
without
in
sample
to
make
difficult
as
```

## Embedding

Building and training was fun and all, but our end goal was not to build
a neural network; we wanted to get word embeddings. As stated earlier in
this post, the key behind word embeddings is that the rows of the first
weight matrix is effectively a dense representation of one-hot encoded
vectors each corresponding to various tokens in the text dataset. In our
example, therefore, the embedding can simply be obtained by

```python
model["w1"]
```

```
array([[-0.76943888,  0.66419101,  0.52185522,  0.53416045,  0.74682309,
         1.29778774,  0.80174038, -0.42762792, -2.44509237,  0.69461262],
       [-0.03049168,  0.72713564, -1.07892615, -2.12632703, -1.40504585,
         0.16007463, -1.44169316,  0.06812903,  0.15341611, -2.16828595],
       [-0.68684491, -1.53318024,  0.27274833, -2.04037677,  0.13802059,
        -0.3005966 , -0.80421765, -0.31677644, -0.46332806, -1.34717872],
       [ 1.0935606 ,  1.24492109, -0.035054  , -0.75192887,  0.15263928,
        -1.26221765, -0.50342996, -2.77013745,  0.1399199 , -0.77001316],
       [ 0.4748796 ,  0.71693722, -0.79135941,  2.60869716, -0.58760833,
        -0.08669239, -0.01178457, -1.0893234 , -0.66961562, -0.7323576 ],
       [-1.21903306, -0.9770747 ,  0.82938815,  1.66171912,  0.49097782,
         1.70764463,  0.21741346, -1.27341364,  0.7001402 , -1.17027829],
       [ 0.76302718, -1.45370483, -0.00798623, -1.54434253, -0.02672187,
         1.73680874, -0.81259019, -1.41251393,  1.29134638,  0.4373011 ],
       [-0.25147232,  2.07658396,  0.04017748,  1.47709408, -2.49219074,
        -0.54824483,  0.34565281, -0.1765285 ,  1.63189504, -0.26635877],
       [-1.07492131,  0.86480382, -0.33732251,  1.8539463 , -1.8351204 ,
         0.32488649,  0.07781584, -0.79155451,  0.22268128,  1.45353606],
       [ 0.96564502,  0.40326434,  0.39062086, -0.07369607, -2.08306135,
        -0.24240214,  1.08098237,  0.62831061, -0.28851627,  1.88856504],
       [ 0.67039387,  0.11089601, -0.06260896, -1.14201765,  0.85214818,
         0.79699652,  1.60140494,  1.55860074,  1.48830133,  0.62505581],
       [-1.7260562 ,  0.27865698, -0.02611865, -1.79222164, -0.26568484,
         1.02098073,  0.13923429,  0.12880677,  1.14611787, -0.21745726],
       [ 2.34618366,  0.09627182,  0.73429031, -0.3795417 ,  1.00384797,
         2.29688517, -0.54519017, -0.15382528,  1.02290422,  0.67138609],
       [-0.8199847 ,  0.81764305,  0.77442068,  0.41361639, -0.815798  ,
         3.25822674, -0.1863631 , -0.04673113,  0.56506795, -0.02778286],
       [-1.76193113,  0.18080273, -1.61259579,  1.13134183, -0.39194156,
        -0.14657422, -1.13627271, -1.5667357 , -0.27150137,  0.74683337],
       [-1.66879205,  0.43920843, -0.1663464 , -0.64556484,  1.15383694,
         1.99026613,  1.29054758, -0.51452775,  0.36076408,  0.13917934],
       [-0.26512035,  0.79767559,  1.80033249, -1.14609988, -0.78927055,
        -0.43497097,  0.70769172,  1.83098455, -0.96178864, -1.30140586],
       [-0.36679925, -0.08888034, -0.69805165,  1.01032096,  0.53327293,
         0.71142215, -0.61919103,  0.91489913, -0.23415597,  3.07246695],
       [ 1.54042926, -1.49268108,  0.06412402,  0.27555874, -0.5140873 ,
        -1.00779784,  1.06187732,  0.64988687, -0.84064087, -0.62033715],
       [-0.24097777, -0.53801309,  0.53763453, -0.5195818 , -0.52441574,
         0.24175162,  1.33209536, -1.18518131, -0.1644457 , -0.98436401],
       [ 0.09167709,  0.59763758,  2.780052  ,  0.42059586, -0.61414259,
         0.53536983,  2.42227754,  0.13680908,  0.28311335,  1.31975233],
       [ 0.78859384,  1.26704417,  1.3230788 ,  1.75579178, -0.45166329,
        -1.27266035, -0.740434  , -1.21728119,  0.68298206, -1.15872753],
       [ 1.03411644, -0.68148228, -0.49401597, -1.04198152, -1.96143292,
        -0.68325082,  0.74263224, -0.46497574, -0.33083338,  0.29300595],
       [-0.2745763 ,  0.56636408,  0.03976089, -1.05114299,  2.55634587,
         1.13019543, -1.30645221,  0.84024957,  0.1047002 ,  0.73783628],
       [-1.65721097,  0.95894771,  0.37856505,  0.19945248, -2.24372733,
         0.06383841, -0.9127448 ,  0.46130851, -0.50089233,  0.36800566],
       [-0.45980465,  1.25934841,  0.62539097,  3.30279986,  0.04255758,
        -0.13354921,  0.79207247,  0.06972181, -0.69901224,  0.21201475],
       [ 0.85073146,  0.08781509, -1.92623443, -0.16817443, -1.30259218,
        -2.38615797, -0.24495606,  0.17137503,  0.77936833, -1.01965967],
       [ 1.05778013,  0.76342693,  1.77232962, -0.96104539, -0.08811641,
         0.33674077, -0.21148717, -1.49066675, -1.32453886, -1.3802293 ],
       [ 0.80501948,  1.2564309 , -0.05850006, -1.96858002,  1.5098404 ,
        -0.82138883, -1.43376613, -0.20117943,  0.09781934, -0.11332511],
       [ 1.77450867,  0.67732937, -0.34216724, -0.44971138,  1.79136373,
        -0.66177269,  1.00676265,  0.29106454,  0.89493555, -0.21369749],
       [ 1.00692478, -0.70579108,  0.37119276, -1.7544736 , -0.50768877,
        -0.13920805,  0.98780768,  1.05706905,  0.43222048, -1.56338747],
       [-0.65672547, -0.09103197, -1.178256  , -0.36917564,  2.00815605,
        -1.11143611, -0.19733534, -0.67585454,  0.91811814, -0.60532824],
       [ 0.08459137,  0.49163205, -1.13671431,  0.2685497 , -0.26500548,
        -1.88354056,  0.84902147, -0.14644722,  0.76311656,  1.44498978],
       [-0.54624827,  0.38542096,  1.63246864, -0.2585312 , -0.91037463,
        -1.11468131, -1.97914078,  0.03496614, -1.06421765, -0.8295912 ],
       [-1.42148053, -0.95180815, -0.25972599,  0.4707728 ,  0.06931999,
        -0.82176286, -0.88083009, -1.00956624, -0.00897779,  2.2308322 ],
       [ 0.84266984,  1.30408572,  0.20015039,  0.5615169 , -0.65296663,
         0.97015807,  1.38700084,  0.4951084 , -1.44448973, -1.16752713],
       [ 0.4985632 ,  2.3945698 ,  1.38710141,  0.46910109,  0.33734053,
        -1.23949995, -0.61190318,  0.32451539, -0.05789326, -1.23558975],
       [ 0.38291206, -0.00759767,  0.93585618,  1.70632753,  1.01893822,
        -1.06911745, -0.84419934, -0.67012947,  1.66929492, -0.25548583],
       [-0.85385692, -1.56233021, -1.78991592, -0.37255036, -0.9249025 ,
        -1.6846726 ,  0.32114733,  1.31372489,  1.05408442, -1.39430468],
       [-1.5018825 ,  0.26488359, -0.53076249,  1.6708959 ,  0.27143629,
         0.1466047 , -1.31955686,  1.71370231,  0.65300717,  1.61281628],
       [-1.51203259, -0.39572513,  0.38419586, -0.6823474 ,  0.07519616,
         1.66390286, -1.97019699, -0.38811612, -0.44951716, -0.77662094],
       [ 0.83704632, -1.96031949,  0.18797492,  0.91590376,  1.15283072,
         0.51642011,  0.84241534,  0.44585173,  1.45640509, -1.83124556],
       [ 1.92206704,  1.47056032, -0.00406   ,  0.76778018,  0.4053105 ,
         1.07126801, -0.026245  , -0.89590521,  1.41038388, -2.36215574],
       [ 1.29458536, -0.83621381, -1.9517757 , -0.1324523 ,  0.83403392,
        -0.1774459 , -1.02376095, -1.16475156, -0.17342272, -0.6319843 ],
       [ 0.17336049,  0.04089555, -1.27560476,  0.60595067, -1.23526217,
         2.11755679,  0.67800316,  0.9816548 , -0.53819726, -1.48369522],
       [ 1.35176837,  1.12930276,  0.45335844,  2.09004711, -0.2852887 ,
        -0.52948827, -0.21326742,  1.09567641, -1.45861346,  0.07245137],
       [ 0.21232134,  0.07740626, -2.60893894,  1.32348304, -0.08148714,
        -0.95045501, -0.63220659,  0.03582499,  0.07313937,  0.93465466],
       [-0.6344957 , -2.01719472, -1.58639108,  1.92451622,  0.0250036 ,
        -0.2535994 ,  0.27991245,  0.28675205,  3.23885619,  1.23512829],
       [ 0.23324629, -0.81385165, -1.08401507, -0.80369496, -0.11238495,
        -0.80819993, -1.69063394, -2.0135628 ,  1.31387044,  0.47585681],
       [-0.49963994,  1.35849991,  0.28112175, -1.28978621,  0.15313457,
        -2.10441061, -0.37593203,  0.35531336, -1.37029975, -0.92553935],
       [ 0.25499162,  2.6937966 , -1.22866972, -0.6009424 ,  1.15582671,
         0.17963652, -0.35502042, -0.07955323,  0.61564226, -0.67431376],
       [-0.71675356,  0.21037284,  1.06208761, -1.26838047, -0.98813322,
        -0.19912103,  0.2661799 , -1.84027428,  0.4893086 , -1.40526423],
       [-0.91220952,  1.05346427, -1.27416819, -1.38112843,  0.5872168 ,
        -1.07982749, -1.03267073,  1.16666964,  0.88234566, -0.00877552],
       [ 0.59294741, -0.49930866, -0.34625371, -1.74482878,  1.43377496,
         0.83467315, -0.31859294,  0.65827638, -1.56715242, -1.13192011],
       [ 0.08064387, -1.07407349,  0.65194826, -0.78843376, -2.35459065,
        -1.18905639, -0.03351356,  0.22030413,  0.90017831, -0.94312275],
       [ 1.51333243, -0.51659202,  0.46177897,  2.30785006, -1.41201759,
         0.20665316, -0.45131595,  0.04248109, -0.13719135, -0.80603153],
       [ 0.50464748, -1.45981521,  0.98524436,  0.55793713, -0.13645376,
        -0.83605131, -1.02010683,  0.47506778,  0.01444452, -0.54525131],
       [ 0.6517877 ,  0.03670637,  2.00810018, -0.30927333,  0.28418133,
        -0.60868821, -0.57513864, -0.21019374,  0.09730159,  0.78116411],
       [ 1.16652747,  0.14898179,  0.604168  ,  1.70981243, -0.42754722,
        -0.4983158 , -0.20120526, -0.98475908, -2.10225298, -0.0247042 ],
       [-0.18418601,  1.17537944,  1.11715622,  1.01818565,  0.45409776,
        -0.55228828, -1.51367743, -0.02330498,  0.54634913,  0.83452307]])
```

But of course, this is not a user-friendly way of displaying the embeddings.
In particular, what we want is to be able to input a word through a function
and receive as output the embedding vector for that given word. Below is
a function that implements this feature.

```python
def get_embedding(model, word):
    try:
        idx = word_to_id[word]
    except KeyError:
        print("`word` not in corpus")
    one_hot = one_hot_encode(idx, len(word_to_id))
    return forward(model, one_hot)["a1"]
```

When we test out the word "machine," we get a dense ten-dimensional vector
as expected.

```python
get_embedding(model, "machine")
```

```
array([ 1.03411644, -0.68148228, -0.49401597, -1.04198152, -1.96143292,
       -0.68325082,  0.74263224, -0.46497574, -0.33083338,  0.29300595])
```

And of course, this vector is not a collection of some randomly initialized
numbers, but a result of training with context data generated through the
sliding window algorithm described above. In other words, these vectors
encode meaningful semantic information that tells us which words tend to
go along with each other.

## Conclusion

While this is a relatively simple, basic implementation of word2vec, the
underlying principle remains the same nonetheless. The idea is that, we
can train a neural network to generate word embeddings in the form of a
weight matrix. This is why embedding layers can be trained to generate
custom embeddings in popular neural network libraries like TensorFlow or
PyTorch. If you end up training word embeddings on large datasets like
Wikipedia, you end up with things like word2vec and GloVe, another extremely
popular alternative to word2vec. In general, it's fascinating to think that,
with enough data, we can encode enough semantics into these embedding
vectors to see relationships such as `"king - man + woman = queen."`
