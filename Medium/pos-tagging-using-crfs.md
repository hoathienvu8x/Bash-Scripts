# [POS Tagging Using CRFs](https://towardsdatascience.com/pos-tagging-using-crfs-ea430c5fb78b)

> Experimenting with POS tagging, a standard sequence labeling task using Conditional Random Fields, Python, and the NLTK library.

For an introduction to NLP and basic text preprocessing, refer to [this](https://towardsdatascience.com/text-preprocessing-with-nltk-9de5de891658) article. For an introduction to language models and how to build them, take a look at [this](https://medium.com/swlh/language-modelling-with-nltk-20eac7e70853) article. If you’re familiar with NLP and its tools, continue reading!

## Contents
1. [What is POS tagging?](https://towardsdatascience.com/pos-tagging-using-crfs-ea430c5fb78b#a60c)
2. [How can POS tags be used?](https://towardsdatascience.com/pos-tagging-using-crfs-ea430c5fb78b#9c79)
3. [What are Conditional Random Fields?](https://towardsdatascience.com/pos-tagging-using-crfs-ea430c5fb78b#1c6a)
4. [Initial Steps](https://towardsdatascience.com/pos-tagging-using-crfs-ea430c5fb78b#51b9)
5. [Feature Functions](https://towardsdatascience.com/pos-tagging-using-crfs-ea430c5fb78b#6430)
6. [Training the Model](https://towardsdatascience.com/pos-tagging-using-crfs-ea430c5fb78b#5e92)
7. [Obtaining Transitions](https://towardsdatascience.com/pos-tagging-using-crfs-ea430c5fb78b#cd61)
8. [Conclusion](https://towardsdatascience.com/pos-tagging-using-crfs-ea430c5fb78b#0742)
9. [Further Reading](https://towardsdatascience.com/pos-tagging-using-crfs-ea430c5fb78b#0186)
## What is POS Tagging?

POS or part-of-speech tagging is the technique of assigning special labels to each token in text, to indicate its part of speech, and usually even other grammatical connotations, which can later be used in text analysis algorithms. For example, for the sentence -

> She is reading a book.

‘ *She*’ would the POS tag of **pronoun**, ‘ *is*’ would get an * * **article** tag, ‘ *reading*’ a **verb** tag, ‘ *a*’ would get an * * **article** tag and ‘ *book*’ would get a **noun** tag. We can then do a search for all verbs which would pull up the word *reading*, and also use these tags in other algorithms.

![POS tagging — Photo by Angèle Kamp on Unsplash](https://miro.medium.com/max/700/1*GTwLlu2DgKCjRT40P-KTFg.jpeg)

> POS tagging — Photo by Angèle Kamp on Unsplash

## How can POS tags be used?

Some of the important uses of POS tags are -

- Named entity recognition (NER)
- Statistical language models based on the frequencies of different tags
- Text generation by models trained with POS tagged datasets
- Pattern identification in corpus datasets
- Distinguishing between different occurrences of the same word, for example, between the word ‘ *time*’ when it is used as a verb or a noun
- Sentiment analysis
## What are Conditional Random Fields?

An entity, or a part of text that is of interest would be of great use if it could be recognized, named and called to identify similar entities. A CRF is a sequence modeling algorithm which is used to identify entities or patterns in text, such as POS tags. This model not only assumes that features are dependent on each other, but also considers future observations while learning a pattern. In terms of performance, it is considered to be the best method for entity recognition.

Since these models take into account previous data, we use features which are modelled from the data to feed into the CRF. These feature functions express certain characteristic of the sequence that the data point represents, such as the tag sequence **noun -> verb -> adjective**. When y is the hidden state and x is the observed variable, the CRF formula is given by -

![](https://miro.medium.com/max/700/1*q12iCs8fXHn7qE1k93fE3w.jpeg)

Normalization is performed since the output is a probability. The weight estimation is performed by maximum likelihood estimation(MLE) using the feature functions we define.

In this article, we will be training a CRF using feature functions to predict POS tags and testing the model to obtain its accuracy and other metrics. To train a CRF, we will be using the *sklearn-crfsuite* wrapper.

## Initial Steps

First, we import the required toolkits and libraries.

```python
 #importing all the needed libraries
 import pandas as pd
 import nltk
 import sklearn
 import sklearn_crfsuite
 import scipy.stats
 import math, string, re

 from sklearn.metrics import make_scorer
 from sklearn.metrics import accuracy_score
 from sklearn.model_selection import cross_val_score
 from sklearn.model_selection import RandomizedSearchCV
 from sklearn_crfsuite import scorers
 from sklearn_crfsuite import metrics
 from itertools import chain
 from sklearn.preprocessing import MultiLabelBinarizer
```

Now we can read and store the data. We will be using the universal dependency Hindi train and test set in *conllu *format. We read the data as a comma-separated or CSV file. The train dataset can be found [here](https://github.com/ruthussanketh/natural-language-processing/blob/main/conditional-random-field/hi-ud-train.conllu), and the test dataset [here](https://github.com/ruthussanketh/natural-language-processing/blob/main/conditional-random-field/hi-ud-test%20.conllu).

```python
#reading and storing the data
data = {}
data['train'] = pd.read_csv('/Users/ruthu/Desktop/hi-ud-train.conllu')
data['test'] = pd.read_csv('/Users/ruthu/Desktop/hi-ud-test.conllu', sep = '\t')

print(data['train'], data['test'], sep = '\n\n')
```

![Data preview — Image by author](https://miro.medium.com/max/246/1*2-0vl64m9YJ2I3hBDbtZnw.png)

> Data preview — Image by author

We can see a preview of the data and observe the different rows of data and their associated tags to get an idea of the preprocessing to be done and the features that can be extracted.

## Feature Functions

Now that we have an idea of what the data looks like, let us extract some features from the dataset. The features we will be considering in this article are -

1. The word
2. The word in lowercase
3. Prefixes and suffixes of the word of varying lengths
4. If the word is a digit
5. If the word is a punctuation mark
6. If the word is at the beginning of the sentence (BOS) or the end of the sentence (EOS) or neither
7. The length of the word - no. of characters (since shorter words are expected to be more likely to belong to a particular POS, eg. prepositions or pronouns)
8. Stemmed version of the word, which deletes all vowels along with g, y, n from the end of the word, but leaves at least a 2 character long stem
9. Features mentioned above for the previous word, the following word, and the words two places before and after

Features are qualitative functions and can differ from person to person. Feel free to experiment with the features to see which combination gives the most accuracy. Let us extract the features from the dataset now.

```python
def word2features(sent, i):
    word = sent[i][0]

    features = {
        'bias': 1.0,
        'word': word,
        'len(word)': len(word),
        'word[:4]': word[:4],
        'word[:3]': word[:3],
        'word[:2]': word[:2],
        'word[-3:]': word[-3:],
        'word[-2:]': word[-2:],
        'word[-4:]': word[-4:],
        'word.lower()': word.lower(),
        'word.stemmed': re.sub(r'(.{2,}?)([aeiougyn]+$)',r'\1', word.lower()),
        'word.ispunctuation': (word in string.punctuation),
        'word.isdigit()': word.isdigit(),
    }
    if i > 0:
        word1 = sent[i-1][0]
        features.update({
            '-1:word': word1,
            '-1:len(word)': len(word1),
            '-1:word.lower()': word1.lower(),
            '-1:word.stemmed': re.sub(r'(.{2,}?)([aeiougyn]+$)',r'\1', word1.lower()),
            '-1:word[:3]': word1[:3],
            '-1:word[:2]': word1[:2],
            '-1:word[-3:]': word1[-3:],
            '-1:word[-2:]': word1[-2:],
            '-1:word.isdigit()': word1.isdigit(),
            '-1:word.ispunctuation': (word1  **in** string.punctuation),
        })
    else:
        features['BOS'] =  True

    if i > 1:
        word2 = sent[i-2][0]
        features.update({
            '-2:word': word2,
            '-2:len(word)': len(word2),
            '-2:word.lower()': word2.lower(),
            '-2:word[:3]': word2[:3],
            '-2:word[:2]': word2[:2],
            '-2:word[-3:]': word2[-3:],
            '-2:word[-2:]': word2[-2:],
            '-2:word.isdigit()': word2.isdigit(),
            '-2:word.ispunctuation': (word2  in string.punctuation),
        })

    if i < len(sent)-1:
        word1 = sent[i+1][0]
        features.update({
            '+1:word': word1,
            '+1:len(word)': len(word1),
            '+1:word.lower()': word1.lower(),
            '+1:word[:3]': word1[:3],
            '+1:word[:2]': word1[:2],
            '+1:word[-3:]': word1[-3:],
            '+1:word[-2:]': word1[-2:],
            '+1:word.isdigit()': word1.isdigit(),
            '+1:word.ispunctuation': (word1 in string.punctuation),
        })

    else:
        features['EOS'] =  **True**
    if i < len(sent) - 2:
        word2 = sent[i+2][0]
        features.update({
            '+2:word': word2,
            '+2:len(word)': len(word2),
            '+2:word.lower()': word2.lower(),
            '+2:word.stemmed': re.sub(r'(.{2,}?)([aeiougyn]+$)',r'\1', word2.lower()),
            '+2:word[:3]': word2[:3],
            '+2:word[:2]': word2[:2],
            '+2:word[-3:]': word2[-3:],
            '+2:word[-2:]': word2[-2:],
            '+2:word.isdigit()': word2.isdigit(),
            '+2:word.ispunctuation': (word2 in string.punctuation),
        })

    return features


def sent2features(sent):
    return [word2features(sent, i) for i in range(len(sent))]

def sent2labels(sent):
    return [word[1] for word in sent]

def sent2tokens(sent):
    return [word[0] for word in sent]
```

Now that we have a feature extraction function, let us get our data ready to be passed to the function. Since it is in CSV format, we convert it into sentences.

```python
#formatting the data into sentences
def format_data(csv_data):
    sents = []
    for i in range(len(csv_data)):
        if math.isnan(csv_data.iloc[i, 0]):
            continue
        elif csv_data.iloc[i, 0] == 1.0:
            sents.append([[csv_data.iloc[i, 1], csv_data.iloc[i, 2]]])
        else:
            sents[-1].append([csv_data.iloc[i, 1], csv_data.iloc[i, 2]])
    for sent in sents:
        for i, word  **in** enumerate(sent):
            if type(word[0]) != str:
                del sent[i]
    return sents
```

We can now use the above 2 functions to extract features from all the sentences formed from the input CSV file.

```python
#extracting features from all the sentences
train_sents = format_data(data['train'])
test_sents = format_data(data['test'])

Xtrain = [sent2features(s) for s in train_sents]
ytrain = [sent2labels(s) for s in train_sents]

Xtest = [sent2features(s) for s in test_sents]
ytest = [sent2labels(s) for s in test_sents]
```
## Training the Model

Let us train the CRF on the processed train set. *c1* and *c2* are the parameters for *L1* and *L2* regularization respectively, and they usually range from 0.2 to 0.3. They can be tweaked to give better results in model performance.

```
%%time                                  
crf = sklearn_crfsuite.CRF(
    algorithm = 'lbfgs',
    c1 = 0.25,
    c2 = 0.3,
    max_iterations = 100,
    all_possible_transitions= True
)
crf.fit(Xtrain, ytrain)                  
#training the model
```

![Training the CRF — Image by author](https://miro.medium.com/max/555/1*jV321TJ5v7Hr3teeNzq26A.png)

> Training the CRF — Image by author

We can now obtain the accuracy and other metrics of the model on the train and test datasets.

```python
#obtaining metrics such as accuracy, etc. on the train set
labels = list(crf.classes_)
labels.remove('X')

ypred = crf.predict(Xtrain)
print('F1 score on the train set = {}\n'.format(metrics.flat_f1_score(ytrain, ypred, average='weighted', labels=labels)))
print('Accuracy on the train set = {}\n'.format(metrics.flat_accuracy_score(ytrain, ypred)))

sorted_labels = sorted(
    labels,
    key= lambda name: (name[1:], name[0])
)
print('Train set classification report:  \n\n{}'.format(metrics.flat_classification_report(
ytrain, ypred, labels=sorted_labels, digits=3
)))
#obtaining metrics such as accuracy, etc. on the test set
ypred = crf.predict(Xtest)
print('F1 score on the test set =  {}\n'.format(metrics.flat_f1_score(ytest, ypred,
average='weighted', labels=labels)))
print('Accuracy on the test set = {}\n'.format(metrics.flat_accuracy_score(ytest, ypred)))

sorted_labels = sorted(
    labels,
    key= lambda name: (name[1:], name[0])
)
print('Test set classification report: \n\n{}'.format(metrics.flat_classification_report(ytest, ypred, labels=sorted_labels, digits=3)))
```

![Statistics of the trained model — Image by author](https://miro.medium.com/max/902/1*5WlKYomvFSt-7twSxephow.png)

![](https://miro.medium.com/max/928/1*OGiKvioSnfX2qsceb9YobQ.png)

> Model performance on the train and test datasets — Image by author

We can see that the model has an accuracy of around 99% on the train set and 87% on the test set. Playing around with the *L1* and *L2* regularization parameters might help give us a better performance on the test set and prevent overfitting.

## Obtaining Transitions

We can also predict the top 10 most likely as well as least likely transitions in the model using the *Counter* module.

```python
#obtaining the most likely and the least likely transitions
from collections import Counter

def print_transitions(transition_features):
    for (label_from, label_to), weight in transition_features:
        print("%-6s -> %-7s %0.6f" % (label_from, label_to, weight))

print("Top 10 likely transitions -  \n")
print_transitions(Counter(crf.transition_features_).most_common(10))

print("\nTop 10 unlikely transitions - \n")
print_transitions(Counter(crf.transition_features_).most_common()[-10:])
```

![Likely and unlikely transitions in the dataset — Image by author](https://miro.medium.com/max/231/1*4zTD7yhsHb5UzIwwZBHdZA.png)

> Likely and unlikely transitions in the dataset — Image by author

## Conclusion

I hope this article was a good introduction to CRFs, and how to build them with the *sklearn crfsuite* wrapper without much mathematical knowledge of their working. Apart from POS tags, CRFs can also be trained to predict other entities or patterns. The entire code used in this article, as well the datasets, can be found [here](https://github.com/ruthussanketh/natural-language-processing/tree/main/conditional-random-field).

## Further Reading
- [Edwin Chen — Introduction to Conditional Random Fields](https://blog.echen.me/2012/01/03/introduction-to-conditional-random-fields/)
- [Aditya Prasad — Conditional Random Fields Explained](https://towardsdatascience.com/conditional-random-fields-explained-e5b8256da776)
- [Word and Character Based LSTM Models](https://towardsdatascience.com/word-and-character-based-lstms-12eb65f779c2)
- [Naive Bayes and LSTM Based Classifier Models](https://towardsdatascience.com/naive-bayes-and-lstm-based-classifier-models-63d521a48c20)
