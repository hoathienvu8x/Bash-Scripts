![](https://miro.medium.com/max/2972/1*7DkqpU3E-E9yknyw9c7vCQ.png)

# [Named Entity Recognition and Classification with Scikit-Learn](https://towardsdatascience.com/named-entity-recognition-and-classification-with-scikit-learn-f05372f07ba2)

> How to train machine learning models for NER using Scikit-Learn’s libraries

[Named Entity Recognition and Classification](https://en.wikipedia.org/wiki/Named-entity_recognition) (NERC) is a process of recognizing information units like names, including person, organization and location names, and numeric expressions including time, date, money and percent expressions from unstructured text. The goal is to develop practical and domain-independent techniques in order to detect named entities with high accuracy automatically.

Last week, we gave [an introduction on Named Entity Recognition (NER) in NLTK and SpaCy](https://towardsdatascience.com/named-entity-recognition-with-nltk-and-spacy-8c4a7d88e7da). Today, we go a step further, — training machine learning models for NER using some of Scikit-Learn’s libraries. Let’s get started!

# The Data

The data is feature engineered corpus annotated with [IOB](https://en.wikipedia.org/wiki/Inside%E2%80%93outside%E2%80%93beginning_(tagging)) and [POS](https://en.wikipedia.org/wiki/Part-of-speech_tagging) tags that can be found at [Kaggle](https://www.kaggle.com/abhinavwalia95/how-to-loading-and-fitting-dataset-to-scikit/data). We can have a quick peek of first several rows of the data.

![Figure 1](https://miro.medium.com/max/700/1*bP_mN9GaZ-6J1ssmpzdzzQ.png)

> Figure 1

**Essential info about entities**:

- geo = Geographical Entity
- org = Organization
- per = Person
- gpe = Geopolitical Entity
- tim = Time indicator
- art = Artifact
- eve = Event
- nat = Natural Phenomenon

**Inside–outside–beginning (tagging)**

[The **IOB**](https://en.wikipedia.org/wiki/Inside%E2%80%93outside%E2%80%93beginning_(tagging)) (short for inside, outside, beginning) is a common tagging format for tagging tokens.

- I- prefix before a tag indicates that the tag is inside a chunk.
- B- prefix before a tag indicates that the tag is the beginning of a chunk.
- An O tag indicates that a token belongs to no chunk (outside).

```python
import pandas as pd
import numpy as np
from sklearn.feature_extraction import DictVectorizer
from sklearn.feature_extraction.text import HashingVectorizer
from sklearn.linear_model import Perceptron
from sklearn.model_selection import train_test_split
from sklearn.linear_model import SGDClassifier
from sklearn.linear_model import PassiveAggressiveClassifier
from sklearn.naive_bayes import MultinomialNB
from sklearn.metrics import classification_report
```

The entire data set can not be fit into the memory of a single computer, so we select the first 100,000 records, and use [Out-of-core learning algorithms](https://en.wikipedia.org/wiki/External_memory_algorithm) to efficiently fetch and process the data.

```python
df = pd.read_csv('ner_dataset.csv', encoding = "ISO-8859-1")
df = df[:100000]
df.head()
```

![](https://miro.medium.com/max/498/1*FdxVbqcoy-dON4HFfLScOQ.png)

> Figure 2

```python
df.isnull().sum()
```

![](https://miro.medium.com/max/415/1*dkcB-H4CBQUknbhovFOGag.png)

> Figure 3

# Data Preprocessing

We notice that there are many NaN values in ‘Sentence #” column, and we fill NaN by preceding values.

```python
df = df.fillna(method='ffill')
df['Sentence #'].nunique(), df.Word.nunique(), df.Tag.nunique()
```

**_(4544, 10922, 17)_**

We have 4,544 sentences that contain 10,922 unique words and tagged by 17 tags.

The tags are not evenly distributed.

```python
df.groupby('Tag').size().reset_index(name='counts')
```

![](https://miro.medium.com/max/535/1*kEpRnRueEzEQ5-P_uYZdtQ.png)

> Figure 4

The following code transform the text date to vector using `[ **DictVectorizer**](http://scikit-learn.org/stable/modules/generated/sklearn.feature_extraction.DictVectorizer.html#sklearn.feature_extraction.DictVectorizer)` ** **and then split to train and test sets.

```python
X = df.drop('Tag', axis=1)
v = DictVectorizer(sparse=False)
X = v.fit_transform(X.to_dict('records'))
y = df.Tag.values
classes = np.unique(y)
classes = classes.tolist()
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size = 0.33, random_state=0)
X_train.shape, y_train.shape
```

**_((67000, 15507), (67000,))_**

# Out-of-core Algorithms

We will try some of the out-of-core algorithms that are designed to process data that is too large to fit into a single computer memory that support ` **partial_fit**` ** **method.

## Perceptron

```python
per = Perceptron(verbose=10, n_jobs=-1, max_iter=5)
per.partial_fit(X_train, y_train, classes)
```

![](https://miro.medium.com/max/700/1*X-BsapLE5QgedbIFoYne1g.png)

> Figure 5

Because tag “O” (outside) is the most common tag and it will make our results look much better than they actual are. So we remove tag “O” when we evaluate classification metrics.

```python
new_classes = classes.copy()
new_classes.pop()
new_classes
```

![](https://miro.medium.com/max/365/1*jxZjucMMkKKvz7mye0As7A.png)

> Figure 6

```python
print(classification_report(y_pred=per.predict(X_test), y_true=y_test, labels=new_classes))
```

![](https://miro.medium.com/max/700/1*DyeL0kaJ-O0c7iX54om5AA.png)

> Figure 7

**Linear classifiers with SGD training**

```python
sgd = SGDClassifier()
sgd.partial_fit(X_train, y_train, classes)
```

![](https://miro.medium.com/max/700/1*kJ5hYVmwLUcGiaHi_1bqaQ.png)

> Figure 8

```python
print(classification_report(y_pred=sgd.predict(X_test), y_true=y_test, labels=new_classes))
```

![](https://miro.medium.com/max/700/1*eDO2n25b88qY9sumhcOdiQ.png)

> Figure 9

**Naive Bayes classifier for multinomial models**

```python
nb = MultinomialNB(alpha=0.01)
nb.partial_fit(X_train, y_train, classes)
```

![](https://miro.medium.com/max/700/1*yQTsXhQPGws1w9_Mqa8WCw.png)

> Figure 10

```python
print(classification_report(y_pred=nb.predict(X_test), y_true=y_test, labels = new_classes))
```

![](https://miro.medium.com/max/700/1*W6F7y5n7_344HT8kUYFr4g.png)

> Figure 11

**Passive Aggressive Classifier**

```python
pa =PassiveAggressiveClassifier()
pa.partial_fit(X_train, y_train, classes)
```

![](https://miro.medium.com/max/700/1*CXi2Vvlr_yZCY9YobXhkIg.png)

> Figure 12

```python
print(classification_report(y_pred=pa.predict(X_test), y_true=y_test, labels=new_classes))
```

![](https://miro.medium.com/max/700/1*67Hb_9LYoLgSFk_fRJ7kqQ.png)

> Figure 13

None of the above classifiers produced satisfying results. It is obvious that it is not going to be easy to classify named entities using regular classifiers.

# Conditional Random Fields (CRFs)

[CRFs](https://en.wikipedia.org/wiki/Conditional_random_field) is often used for labeling or parsing of sequential data, such as natural language processing and CRFs find applications in POS Tagging, named entity recognition, among others.

## sklearn-crfsuite

We will train a CRF model for named entity recognition using sklearn-crfsuite on our data set.

```python
import sklearn_crfsuite
from sklearn_crfsuite import scorers
from sklearn_crfsuite import metrics
from collections import Counter
```

The following code is to retrieve sentences with their POS and tags. Thanks [Tobias](https://www.depends-on-the-definition.com/named-entity-recognition-conditional-random-fields-python/) for the tip.

```python
class SentenceGetter(object):
    
    def __init__(self, data):
        self.n_sent = 1
        self.data = data
        self.empty = False
        agg_func = lambda s: [(w, p, t) for w, p, t in zip(s['Word'].values.tolist(), 
                                                           s['POS'].values.tolist(), 
                                                           s['Tag'].values.tolist())]
        self.grouped = self.data.groupby('Sentence #').apply(agg_func)
        self.sentences = [s for s in self.grouped]
        
    def get_next(self):
        try: 
            s = self.grouped['Sentence: {}'.format(self.n_sent)]
            self.n_sent += 1
            return s 
        except:
            return None
getter = SentenceGetter(df)
sentences = getter.sentences
```

**Feature Extraction**

Next, we extract more features (word parts, simplified POS tags, lower/title/upper flags, features of nearby words) and convert them to ` **sklearn-crfsuite**` format — each sentence should be converted to a list of dicts. The following code were taken from [sklearn-crfsuites official site](https://sklearn-crfsuite.readthedocs.io/en/latest/tutorial.html).

```python
def word2features(sent, i):
    word = sent[i][0]
    postag = sent[i][1]
    
    features = {
        'bias': 1.0, 
        'word.lower()': word.lower(), 
        'word[-3:]': word[-3:],
        'word[-2:]': word[-2:],
        'word.isupper()': word.isupper(),
        'word.istitle()': word.istitle(),
        'word.isdigit()': word.isdigit(),
        'postag': postag,
        'postag[:2]': postag[:2],
    }
    if i > 0:
        word1 = sent[i-1][0]
        postag1 = sent[i-1][1]
        features.update({
            '-1:word.lower()': word1.lower(),
            '-1:word.istitle()': word1.istitle(),
            '-1:word.isupper()': word1.isupper(),
            '-1:postag': postag1,
            '-1:postag[:2]': postag1[:2],
        })
    else:
        features['BOS'] = True
    if i < len(sent)-1:
        word1 = sent[i+1][0]
        postag1 = sent[i+1][1]
        features.update({
            '+1:word.lower()': word1.lower(),
            '+1:word.istitle()': word1.istitle(),
            '+1:word.isupper()': word1.isupper(),
            '+1:postag': postag1,
            '+1:postag[:2]': postag1[:2],
        })
    else:
        features['EOS'] = True
return features
def sent2features(sent):
    return [word2features(sent, i) for i in range(len(sent))]
def sent2labels(sent):
    return [label for token, postag, label in sent]
def sent2tokens(sent):
    return [token for token, postag, label in sent]
```

**Split train and test sets**

```python
X = [sent2features(s) for s in sentences]
y = [sent2labels(s) for s in sentences]
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.33, random_state=0)
```

**Train a CRF model**

```python
crf = sklearn_crfsuite.CRF(
    algorithm='lbfgs',
    c1=0.1,
    c2=0.1,
    max_iterations=100,
    all_possible_transitions=True
)
crf.fit(X_train, y_train)
```

![](https://miro.medium.com/max/700/1*77lzl34IIYrr98qruOOEKw.png)

> Figure 14

**Evaluation**

```python
y_pred = crf.predict(X_test)
print(metrics.flat_classification_report(y_test, y_pred, labels = new_classes))
```

![](https://miro.medium.com/max/700/1*_Y5WyOBIZfHw_x9i_sPxGg.png)

> Figure 15

Way better! We will stick to sklearn-crfsuite and explore more!

**What our classifier learned?**

```python
def print_transitions(trans_features):
    for (label_from, label_to), weight in trans_features:
        print("%-6s -> %-7s %0.6f" % (label_from, label_to, weight))
print("Top likely transitions:")
print_transitions(Counter(crf.transition_features_).most_common(20))
print("\nTop unlikely transitions:")
print_transitions(Counter(crf.transition_features_).most_common()[-20:])
```

![](https://miro.medium.com/max/405/1*vOxX1s9wcAJcYpFt_mefow.png)

> Figure 16

**Interpretation**: It is very likely that the beginning of a geographical entity (B-geo) will be followed by a token inside geographical entity (I-geo), but transitions to inside of an organization name (I-org) from tokens with other labels are penalized hugely.

**Check the state features**

```python
def print_state_features(state_features):
    for (attr, label), weight in state_features:
        print("%0.6f %-8s %s" % (weight, label, attr))
print("Top positive:")
print_state_features(Counter(crf.state_features_).most_common(30))
print("\nTop negative:")
print_state_features(Counter(crf.state_features_).most_common()[-30:])
```

![](https://miro.medium.com/max/597/1*jMm1tyL5kq_N1ZSY5b1hmA.png)

![](https://miro.medium.com/max/614/1*UeZDZMyblwvcRg5-hTDLEg.png)

> Figure 17

**Observations**:

1). `**5.183603 B-tim word[-3]:day**` The model learns that if a nearby word was “day” then the token is likely a part of a Time indicator.

2). `**3.370614 B-per word.lower():president**` The model learns that token "president" is likely to be at the beginning of a person name.

3). `**-3.521244 O postag:NNP**` The model learns that proper nouns are often entities.

4). `**-3.087828 O word.isdigit()**` Digits are likely entities.

5). `**-3.233526 O word.istitle()**` TitleCased words are likely entities.

## ELI5

[ELI5](https://eli5.readthedocs.io/en/latest/index.html) is a Python package which allows to check weights of sklearn_crfsuite.CRF models.

**Inspect model weights**

```python
import eli5
eli5.show_weights(crf, top=10)
```

![](https://miro.medium.com/max/700/1*ah129oQLxIy2wrZzPCAojw.png)

![](https://miro.medium.com/max/2000/1*JXNzsB1LgKagTQq3B6cs8w.png)

> Figure 18

**Observations**:

1. It does make sense that I-entity must follow B-entity, such as I-geo follows B-geo, I-org follows B-org, I-per follows B-per, and so on.
2. We can also see that it is not common in this data set to have a person right after an organization name (B-org -> I-per has a large negative weight).
3. The model learned large negative weights for impossible transitions like O -> I-geo, O -> I-org and O -> I-tim, and so on.

For easy to read, we can check only a subset of tags.

```python
eli5.show_weights(crf, top=10, targets=['O', 'B-org', 'I-per'])
```

![](https://miro.medium.com/max/2000/1*X4qr2uh80onsHFBBfaiX-w.png)

> Figure 19

Or check only some of the features for all tags.

```python
eli5.show_weights(crf, top=10, feature_re='^word\.is',
                  horizontal_layout=False, show=['targets'])
```

![](https://miro.medium.com/max/580/1*-7xoJ1eFal75USDe7JlelQ.png)

![](https://miro.medium.com/max/500/1*n6N-7HXF-2aPYrqpJH7fog.png)

![](https://miro.medium.com/max/508/1*WqkEVJ82zhV-sLHqm0iRfg.png)

> Figure 20

That was it, for now. I enjoyed making my hands dirty on sklearn-crfsuite and ELI5, hope you did too. Source code can be found at [Github](https://github.com/susanli2016/NLP-with-Python/blob/master/NER_sklearn.ipynb). Have a great week!

References:

- [sklearn-crfsuite](https://sklearn-crfsuite.readthedocs.io/en/latest/index.html)
- [ELI5](https://eli5.readthedocs.io/en/latest/index.html)
