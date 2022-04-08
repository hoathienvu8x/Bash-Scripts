---
title: Word2vec Tutorial
link: https://rare-technologies.com/word2vec-tutorial/
author: Radim Řehůřek's
---

I never got round to writing a tutorial on how to use word2vec in gensim.
It’s simple enough and the [API docs](http://radimrehurek.com/gensim/models/word2vec.html) are straightforward, but I know some
people prefer more verbose formats. Let this post be a tutorial and a
reference example.

UPDATE: the complete HTTP server code for the interactive word2vec demo
below is now [open sourced on Github](https://github.com/RaRe-Technologies/w2v_server_googlenews). For a high-performance similarity
server for documents, see [ScaleText.com](https://scaletext.com/).

## Preparing the Input

Starting from the beginning, gensim’s word2vec expects a sequence of
sentences as its input. Each sentence a list of words (utf8 strings):

```python
# import modules & set up logging
import gensim, logging
logging.basicConfig(format='%(asctime)s : %(levelname)s : %(message)s', level=logging.INFO)
 
sentences = [['first', 'sentence'], ['second', 'sentence']]
# train word2vec on the two sentences
model = gensim.models.Word2Vec(sentences, min_count=1)
```

Keeping the input as a Python built-in list is convenient, but can use up
a lot of RAM when the input is large.

Gensim only requires that the input must provide sentences _sequentially_,
when iterated over. No need to keep everything in RAM: we can provide one
sentence, process it, forget it, load another sentence...

For example, if our input is strewn across several files on disk, with one
sentence per line, then instead of loading everything into an in-memory
list, we can process the input file by file, line by line:

```python
class MySentences(object):
    def __init__(self, dirname):
        self.dirname = dirname
 
    def __iter__(self):
        for fname in os.listdir(self.dirname):
            for line in open(os.path.join(self.dirname, fname)):
                yield line.split()
 
sentences = MySentences('/some/directory') # a memory-friendly iterator
model = gensim.models.Word2Vec(sentences)
```

Say we want to further preprocess the words from the files - convert to unicode,
lowercase, remove numbers, extract named entities… All of this can be done
inside the MySentences iterator and word2vec doesn’t need to know. All that
is required is that the input yields one sentence (list of utf8 words) after another.

**Note to advanced users**: calling `Word2Vec(sentences, iter=1)` will run two
passes over the sentences iterator (or, in general `iter+1` passes; default `iter=5`).
The first pass collects words and their frequencies to build an internal
dictionary tree structure. The second and subsequent passes train the neural
model. These two (or, `iter+1`) passes can also be initiated manually, in
case your input stream is non-repeatable (you can only afford one pass),
and you’re able to initialize the vocabulary some other way:

```python
model = gensim.models.Word2Vec(iter=1)  # an empty model, no training yet
model.build_vocab(some_sentences)  # can be a non-repeatable, 1-pass generator
model.train(other_sentences)  # can be a non-repeatable, 1-pass generator
```

In case you’re confused about iterators, iterables and generators in Python,
check out our tutorial on [Data Streaming in Python](https://rare-technologies.com/data-streaming-in-python-generators-iterators-iterables/).

## Training

Word2vec accepts several parameters that affect both training speed and quality.

One of them is for pruning the internal dictionary. Words that appear only
once or twice in a billion-word corpus are probably uninteresting typos and
garbage. In addition, there’s not enough data to make any meaningful training
on those words, so it’s best to ignore them:

```python
model = Word2Vec(sentences, min_count=10)  # default value is 5
```

A reasonable value for `min_count` is between `0-100`, depending on the size
of your dataset.

Another parameter is the size of the NN layers, which correspond to the "degrees"
of freedom the training algorithm has:

```python
model = Word2Vec(sentences, size=200)  # default value is 100
```

Bigger `size` values require more training data, but can lead to better
(more accurate) models. Reasonable values are in the tens to hundreds.

The last of the major parameters (full list [here](http://radimrehurek.com/gensim/models/word2vec.html#gensim.models.word2vec.Word2Vec))
is for training parallelization, to speed up training:

```python
model = Word2Vec(sentences, workers=4) # default = 1 worker = no parallelization
```

The workers parameter has only effect if you have Cython installed. Without
[Cython](http://cython.org/), you’ll only be able to use one core because
of the [GIL](https://wiki.python.org/moin/GlobalInterpreterLock) (and `word2vec`
training will be [miserably slow](http://radimrehurek.com/2013/09/word2vec-in-python-part-two-optimizing/)).

## Memory

At its core, `word2vec` model parameters are stored as matrices (NumPy arrays).
Each array is **#vocabulary** (controlled by `min_count` parameter) times
**#size** (`size` parameter) of floats (single precision aka 4 bytes).

Three such matrices are held in RAM (work is underway to reduce that number
to two, or even one). So if your input contains `100,000` unique words,
and you asked for layer `size=200`, the model will require approx. `100,000*200*4*3 bytes = ~229MB`.

There’s a little extra memory needed for storing the vocabulary tree (`100,000`
words would take a few megabytes), but unless your words are extremely
loooong strings, memory footprint will be dominated by the three matrices above.

# Evaluating

Word2vec training is an unsupervised task, there’s no good way to objectively
evaluate the result. Evaluation depends on your end application.

Google have released their testing set of about 20,000 syntactic and semantic
test examples, following the “A is to B as C is to D” task:

[https://raw.githubusercontent.com/RaRe-Technologies/gensim/develop/gensim/test/test_data/questions-words.txt](https://raw.githubusercontent.com/RaRe-Technologies/gensim/develop/gensim/test/test_data/questions-words.txt)

Gensim support the same evaluation set, in exactly the same format:

```bash
model.accuracy('/tmp/questions-words.txt')
2014-02-01 22:14:28,387 : INFO : family: 88.9% (304/342)
2014-02-01 22:29:24,006 : INFO : gram1-adjective-to-adverb: 32.4% (263/812)
2014-02-01 22:36:26,528 : INFO : gram2-opposite: 50.3% (191/380)
2014-02-01 23:00:52,406 : INFO : gram3-comparative: 91.7% (1222/1332)
2014-02-01 23:13:48,243 : INFO : gram4-superlative: 87.9% (617/702)
2014-02-01 23:29:52,268 : INFO : gram5-present-participle: 79.4% (691/870)
2014-02-01 23:57:04,965 : INFO : gram7-past-tense: 67.1% (995/1482)
2014-02-02 00:15:18,525 : INFO : gram8-plural: 89.6% (889/992)
2014-02-02 00:28:18,140 : INFO : gram9-plural-verbs: 68.7% (482/702)
2014-02-02 00:28:18,140 : INFO : total: 74.3% (5654/7614)
```

This `accuracy` takes an [optional parameter](http://radimrehurek.com/gensim/models/word2vec.html#gensim.models.word2vec.Word2Vec.accuracy)
`restrict_vocab` which limits which test examples are to be considered.

Once again, **good performance on this test set doesn’t mean word2vec will
work well in your application, or vice versa**. It’s always best to evaluate
directly on your intended task.

## Storing and loading models

You can store/load models using the standard gensim methods:

```python
model.save('/tmp/mymodel')
new_model = gensim.models.Word2Vec.load('/tmp/mymodel')
```

which uses pickle internally, optionally `mmap`'ing the model’s internal large
NumPy matrices into virtual memory directly from disk files, for inter-process
memory sharing.

In addition, you can load models created by the original C tool, both using
its text and binary formats:

```python
model = Word2Vec.load_word2vec_format('/tmp/vectors.txt', binary=False)
# using gzipped/bz2 input works too, no need to unzip:
model = Word2Vec.load_word2vec_format('/tmp/vectors.bin.gz', binary=True)
```

## Online training / Resuming training

Advanced users can load a model and continue training it with more sentences:

```python
model = gensim.models.Word2Vec.load('/tmp/mymodel')
model.train(more_sentences)
```

You may need to tweak the `total_words` parameter to `train()`, depending on
what learning rate decay you want to simulate.

Note that it’s not possible to resume training with models generated by the
C tool, `load_word2vec_format()`. You can still use them for querying/similarity,
but information vital for training (the vocab tree) is missing there.

## Using the model

Word2vec supports several word similarity tasks out of the box:

```bash
model.most_similar(positive=['woman', 'king'], negative=['man'], topn=1)
[('queen', 0.50882536)]
model.doesnt_match("breakfast cereal dinner lunch";.split())
'cereal'
model.similarity('woman', 'man')
0.73723527
```

If you need the raw output vectors in your application, you can access these
either on a word-by-word basis

```python
model['computer']  # raw NumPy vector of a word
array([-0.00449447, -0.00310097,  0.02421786, ...], dtype=float32)
```

...or en-masse as a 2D NumPy matrix from `model.syn0`.

## Bonus app

As before with [finding similar articles in the English Wikipedia with Latent
Semantic Analysis](http://radimrehurek.com/2014/01/performance-shootout-of-nearest-neighbours-querying/#wikisim),
here’s a bonus web app for those who managed to read this far. It uses the
`word2vec` model trained by Google on the Google News dataset, on about **100
billion words**:

The model contains **3,000,000 unique phrases** built with **layer size of 300**.

Note that the similarities were trained on a news dataset, and that Google
did very little preprocessing there. So the phrases are case sensitive:
**watch out**! Especially with proper nouns.

On a related note, I noticed about half the queries people entered into the
[LSA@Wiki demo](http://radimrehurek.com/2014/01/performance-shootout-of-nearest-neighbours-querying/#wikisim) contained typos/spelling errors, so they found nothing. Ouch.

To make it a little less challenging this time, I added **phrase suggestions**
to the forms above. Start typing to see a list of valid phrases from the
actual vocabulary of Google News’ `word2vec` model.

The “suggested” phrases are simply ten phrases starting from whatever
`bisect_left(all_model_phrases_alphabetically_sorted, prefix_you_typed_so_far)`
from Python’s built-in [bisect module](https://docs.python.org/2/library/bisect.html) returns.

See the complete HTTP server code for this “bonus app” on [github](https://github.com/RaRe-Technologies/w2v_server_googlenews) (using CherryPy).

## Outro

Full word2vec API docs [here](http://radimrehurek.com/gensim/models/word2vec.html); get gensim [here](http://radimrehurek.com/gensim/).
Original C toolkit and word2vec papers by Google [here](https://code.google.com/p/word2vec/).

And here’s me talking about the optimizations behind word2vec at [PyData Berlin 2014](https://pydata.org/berlin2014/)
